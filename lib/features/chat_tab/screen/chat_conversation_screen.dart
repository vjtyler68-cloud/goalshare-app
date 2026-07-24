import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/const/app_fonts.dart';
import '../../../core/safety/block_controller.dart';
import '../../../core/safety/report_service.dart';
import '../controller/chat_conversation_controller.dart';
import '../model/chat_bubble_model.dart';
import 'gif_picker_sheet.dart';
import '../../public_profile/model/profile_view.dart';
import '../../public_profile/screen/public_profile_screen.dart';
import 'package:spanx/core/const/app_colors.dart';

Color get _kRed => AppColors.primaryColor;
Color get _kRedDk => AppColors.primaryDarkColor;
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

  /// Open the "View Profile" page for the person you're chatting with.
  void _openProfile(ChatConversationController c) {
    final other = c.conversation;
    Get.to(() => PublicProfileScreen(
          user: ProfileView(
            id: other.senderId,
            name: other.senderName,
            email: other.senderEmail,
            image: other.senderProfileImage,
            isVerified: other.isVerified ?? false,
          ),
          showMessage: false, // already in the conversation
        ));
  }

  Widget _buildHeader(ChatConversationController c) {
    return Container(
      decoration: BoxDecoration(
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
              GestureDetector(
                onTap: () => _openProfile(c),
                child: Stack(
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
              IconButton(
                onPressed: () => _safetyMenu(c),
                icon: const Icon(Icons.more_vert, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Safety menu: Report / Block the person you're chatting with ─────────────
  void _safetyMenu(ChatConversationController c) {
    final who = c.conversation.senderName.trim().isEmpty
        ? 'this user'
        : c.conversation.senderName.trim();
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 8.h),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Report'),
                onTap: () {
                  Get.back();
                  _reportChat(c);
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: Text('Block $who',
                    style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Get.back();
                  _blockChat(c, who);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _reportChat(ChatConversationController c) {
    const reasons = [
      'Spam',
      'Inappropriate content',
      'Harassment or bullying',
      'Something else',
    ];
    Get.bottomSheet(Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Report conversation',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            for (final r in reasons)
              ListTile(
                title: Text(r),
                onTap: () {
                  Get.back();
                  ReportService.report(
                    type: 'chat',
                    targetId: c.conversation.id,
                    targetOwnerId: c.conversation.senderId,
                    reason: r,
                  );
                  Get.snackbar('Report received', "Thanks — we'll review it.",
                      snackPosition: SnackPosition.BOTTOM);
                },
              ),
          ],
        ),
      ),
    ));
  }

  void _blockChat(ChatConversationController c, String who) {
    final other = c.conversation;
    Get.dialog(AlertDialog(
      backgroundColor: Colors.white,
      title: Text('Block $who?'),
      content: const Text("You won't get messages from them anymore."),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            Get.back(); // dialog
            await BlockController.to.block(other.senderId, other.senderName);
            Get.back(); // leave the chat
            Get.snackbar('Blocked', "You won't hear from $who anymore.",
                snackPosition: SnackPosition.BOTTOM);
          },
          child: const Text('Block', style: TextStyle(color: Colors.red)),
        ),
      ],
    ));
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
    // Only your own text messages (not photos/GIFs) can be edited.
    final canEdit = bubble.isMe && !bubble.hasImage && !bubble.hasGif;
    return Align(
      alignment:
          bubble.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress:
            canEdit ? () => _showMessageActions(bubble) : null,
        child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 0.72.sw),
        child: Container(
          margin: EdgeInsets.only(bottom: 6.h),
          padding: (bubble.hasImage || bubble.hasGif)
              ? EdgeInsets.all(4.r)
              : EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
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
              if (bubble.hasImage) _bubbleImage(bubble),
              if (bubble.hasGif) _bubbleGif(bubble),
              if (bubble.text.isNotEmpty)
                Padding(
                  padding: (bubble.hasImage || bubble.hasGif)
                      ? EdgeInsets.fromLTRB(8.w, 6.h, 8.w, 0)
                      : EdgeInsets.zero,
                  child: Text(
                    bubble.text,
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 13.sp,
                      color: bubble.isMe ? Colors.white : _kText,
                      height: 1.4,
                    ),
                  ),
                ),
              Padding(
                padding: (bubble.hasImage || bubble.hasGif)
                    ? EdgeInsets.only(top: 3.h, right: 6.w, bottom: 2.h)
                    : EdgeInsets.only(top: 4.h),
                child: Text(
                  bubble.isEdited
                      ? '${bubble.formattedTime} · edited'
                      : bubble.formattedTime,
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 9.sp,
                    color: bubble.isMe ? Colors.white60 : _kMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  /// Long-press actions for one of your own text messages.
  void _showMessageActions(ChatBubble bubble) {
    final controller = Get.find<ChatConversationController>();
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 8.h),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit message'),
                onTap: () {
                  Get.back();
                  controller.startEdit(bubble);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Get.back(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bubbleImage(ChatBubble bubble) {
    Uint8List bytes;
    try {
      bytes = base64Decode(bubble.imageData);
    } catch (_) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: () => _openFullscreen(bytes),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 280.h),
          child: Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
        ),
      ),
    );
  }

  void _openFullscreen(Uint8List bytes) {
    Get.to(() => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _bubbleGif(ChatBubble bubble) {
    return GestureDetector(
      onTap: () => _openFullscreenUrl(bubble.gifUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14.r),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 280.h),
          child: CachedNetworkImage(
            imageUrl: bubble.gifUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              width: 160.r,
              height: 140.r,
              color: _kBg,
              alignment: Alignment.center,
              child: SizedBox(
                width: 22.r,
                height: 22.r,
                child: CircularProgressIndicator(strokeWidth: 2, color: _kRed),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              width: 160.r,
              height: 120.r,
              color: _kBg,
              alignment: Alignment.center,
              child: Icon(Icons.gif_box_outlined, color: _kMuted, size: 32.r),
            ),
          ),
        ),
      ),
    );
  }

  void _openFullscreenUrl(String url) {
    Get.to(() => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Center(
                  child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  // ── Input bar ─────────────────────────────────────────────────────────────

  Widget _buildInputBar(ChatConversationController c) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() {
            if (c.editingMessage.value == null) return const SizedBox.shrink();
            return Container(
              width: double.infinity,
              color: _kRed.withOpacity(0.08),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, color: _kRed, size: 16.r),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Editing message',
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: _kRed,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: c.cancelEdit,
                    behavior: HitTestBehavior.opaque,
                    child: Icon(Icons.close, color: _kRed, size: 18.r),
                  ),
                ],
              ),
            );
          }),
          _InputBarContent(c: c),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _InputBarContent extends StatelessWidget {
  final ChatConversationController c;
  const _InputBarContent({required this.c});

  /// Open the GIPHY picker; if the user taps a GIF, send it.
  Future<void> _openGifPicker(BuildContext context) async {
    final url = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GifPickerSheet(),
    );
    if (url != null && url.isNotEmpty) {
      c.sendGif(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kCard,
      padding: EdgeInsets.only(
        left: 16.w,
        right: 12.w,
        top: 10.h,
        bottom: MediaQuery.of(context).padding.bottom + 10.h,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: c.sendPhoto,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.only(right: 4.w),
              child: Icon(Icons.add_photo_alternate_outlined,
                  color: _kRed, size: 26.r),
            ),
          ),
          GestureDetector(
            onTap: () => _openGifPicker(context),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: Icon(Icons.gif_box_outlined, color: _kRed, size: 28.r),
            ),
          ),
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
