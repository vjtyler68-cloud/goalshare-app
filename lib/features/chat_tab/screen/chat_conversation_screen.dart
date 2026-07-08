import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/const/app_fonts.dart';
import '../controller/chat_conversation_controller.dart';
import '../model/chat_bubble_model.dart';

const _kRed   = Color(0xffE84040);
const _kRedDk = Color(0xff9B1414);
const _kBg    = Color(0xffF6F4F2);
const _kCard  = Color(0xffFFFFFF);
const _kText  = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

class ChatConversationScreen extends StatelessWidget {
  const ChatConversationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Guard: if navigated to directly without a registered controller, go back
    if (!Get.isRegistered<ChatConversationController>()) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Get.back());
      return const Scaffold(body: SizedBox.shrink());
    }
    final controller = Get.find<ChatConversationController>();

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildHeader(controller),
          Expanded(child: _buildMessageList(controller)),
          _buildInputBar(controller),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(ChatConversationController c) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kRed, _kRedDk],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20.r,
                    backgroundColor: Colors.white24,
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: c.otherUserAvatar,
                        width: 40.r,
                        height: 40.r,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.person,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (c.isOtherOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 11.r,
                        height: 11.r,
                        decoration: BoxDecoration(
                          color: const Color(0xff22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(color: _kRed, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.otherUserName,
                      style: AppFonts.spaceGrotesk.copyWith(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      c.isOtherOnline ? 'Online' : 'Offline',
                      style: AppFonts.spaceGrotesk.copyWith(
                        color: Colors.white70,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Message list ──────────────────────────────────────────────────────────

  Widget _buildMessageList(ChatConversationController c) {
    return Obx(() {
      if (c.messages.isEmpty) {
        return _buildEmptyChat(c.otherUserName);
      }
      return ListView.builder(
        controller: c.scrollController,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        itemCount: c.messages.length,
        itemBuilder: (context, i) {
          final bubble = c.messages[i];
          final showDate = i == 0 ||
              !_sameDay(c.messages[i - 1].timestamp, bubble.timestamp);
          return Column(
            children: [
              if (showDate) _buildDateSeparator(bubble.timestamp),
              _buildBubble(bubble),
            ],
          );
        },
      );
    });
  }

  Widget _buildEmptyChat(String name) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72.r,
              height: 72.r,
              decoration: BoxDecoration(
                color: _kRed.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                color: _kRed,
                size: 34.r,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Start a conversation',
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: _kText,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Send $name a message to kick things off.',
              textAlign: TextAlign.center,
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 13.sp,
                color: _kMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSeparator(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    String label;
    if (day == today) {
      label = 'Today';
    } else if (day == today.subtract(const Duration(days: 1))) {
      label = 'Yesterday';
    } else {
      label = '${dt.day}/${dt.month}/${dt.year}';
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          Expanded(child: Divider(color: _kMuted.withOpacity(0.3))),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Text(
              label,
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 11.sp,
                color: _kMuted,
              ),
            ),
          ),
          Expanded(child: Divider(color: _kMuted.withOpacity(0.3))),
        ],
      ),
    );
  }

  Widget _buildBubble(ChatBubble bubble) {
    return Align(
      alignment:
          bubble.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 0.72.sw),
        child: Container(
          margin: EdgeInsets.only(bottom: 6.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: bubble.isMe ? _kRed : _kCard,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18.r),
              topRight: Radius.circular(18.r),
              bottomLeft:
                  bubble.isMe ? Radius.circular(18.r) : Radius.circular(4.r),
              bottomRight:
                  bubble.isMe ? Radius.circular(4.r) : Radius.circular(18.r),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: bubble.isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                bubble.text,
                style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 13.sp,
                  color: bubble.isMe ? Colors.white : _kText,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                bubble.formattedTime,
                style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 9.sp,
                  color: bubble.isMe
                      ? Colors.white60
                      : _kMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────

  Widget _buildInputBar(ChatConversationController c) {
    return SafeArea(
      top: false,
      child: _InputBarContent(c: c),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _InputBarContent extends StatelessWidget {
  final ChatConversationController c;
  const _InputBarContent({required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kCard,
      padding: EdgeInsets.only(
        left: 16.w,
        right: 12.w,
        top: 10.h,
        bottom: 10.h,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: _kMuted.withOpacity(0.2)),
              ),
              child: TextField(
                controller: c.textController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => c.sendMessage(),
                style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 14.sp,
                  color: _kText,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 14.sp,
                    color: _kMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                ),
                maxLines: null,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Obx(
            () => GestureDetector(
              onTap: c.isSending.value ? null : c.sendMessage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: c.isSending.value
                        ? [_kMuted, _kMuted]
                        : [_kRed, _kRedDk],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _kRed.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 18.r,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
