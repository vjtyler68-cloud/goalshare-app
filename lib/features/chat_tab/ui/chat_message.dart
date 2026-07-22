import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/const/app_fonts.dart';
import '../../../core/global_widgets/app_loading.dart';
import '../../../core/global_widgets/app_network_image.dart';
import '../controller/chat_controller.dart';
import '../model/chat_model.dart';
import '../../friends/controller/friends_controller.dart';
import '../../friends/screen/friends_hub_screen.dart';
import 'package:spanx/core/const/app_colors.dart';

Color get _kRed   => AppColors.primaryColor;
Color get _kRedDk => AppColors.primaryDarkColor;
const _kBg    = Color(0xffF6F4F2);
const _kCard  = Color(0xffFFFFFF);
const _kText  = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

class MessagesPage extends StatelessWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MessagesController>();

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildHeader(controller),
          SizedBox(height: 12.h),
          _buildTabBar(controller),
          SizedBox(height: 12.h),
          Expanded(child: _buildTabBarView(controller)),
        ],
      ),
    );
  }

  Widget _buildHeader(MessagesController controller) {
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
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 20.h),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 38.r, height: 38.r,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.2)),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Connect', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white70, fontSize: 12.sp)),
                    Text('Messages', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Obx(() {
                final unread = controller.totalUnreadCount;
                if (unread == 0) return const SizedBox.shrink();
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    style: AppFonts.spaceGrotesk.copyWith(fontSize: 12.sp, fontWeight: FontWeight.w800, color: _kRed),
                  ),
                );
              }),
              SizedBox(width: 10.w),
              // Compose a new chat — pick a friend to message.
              GestureDetector(
                onTap: () => _openNewChat(controller),
                child: Container(
                  width: 38.r,
                  height: 38.r,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2)),
                  child: Icon(Icons.add_comment_rounded,
                      color: Colors.white, size: 18.r),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom sheet listing the user's friends — tap one to open (or start) a
  /// chat with them. The single "start a chat" entry point, used by the header
  /// button and the empty-state button.
  void _openNewChat(MessagesController controller) {
    final friendsC = FriendsController.to;
    friendsC.refreshAll();
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.72),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r)),
            ),
            SizedBox(height: 14.h),
            Text('Start a chat',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 17.sp, fontWeight: FontWeight.w800, color: _kText)),
            SizedBox(height: 4.h),
            Text('Pick a friend to message',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 12.sp, color: _kMuted)),
            SizedBox(height: 12.h),
            Flexible(
              child: Obx(() {
                final list = friendsC.friends;
                if (list.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.fromLTRB(32.w, 20.h, 32.w, 30.h),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.group_outlined, color: _kMuted, size: 40.r),
                        SizedBox(height: 12.h),
                        Text('No friends yet',
                            style: AppFonts.spaceGrotesk.copyWith(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                                color: _kText)),
                        SizedBox(height: 6.h),
                        Text('Add friends first, then you can message them here.',
                            textAlign: TextAlign.center,
                            style: AppFonts.spaceGrotesk.copyWith(
                                fontSize: 12.sp, color: _kMuted, height: 1.4)),
                        SizedBox(height: 16.h),
                        GestureDetector(
                          onTap: () {
                            Get.back();
                            Get.to(() => FriendsHubScreen());
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20.w, vertical: 12.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [_kRed, _kRedDk]),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Text('Find people',
                                style: AppFonts.spaceGrotesk.copyWith(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final f = list[i];
                    final hasPhoto = (f.profile ?? '').trim().isNotEmpty;
                    return GestureDetector(
                      onTap: () {
                        Get.back();
                        controller.startChatWith(
                            userId: f.id, name: f.name, image: f.profile ?? '');
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 8.h),
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 10.h),
                        decoration: BoxDecoration(
                            color: _kBg,
                            borderRadius: BorderRadius.circular(12.r)),
                        child: Row(
                          children: [
                            Container(
                              width: 40.r,
                              height: 40.r,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _kRed.withOpacity(0.12),
                                image: hasPhoto
                                    ? DecorationImage(
                                        image: NetworkImage(f.profile!),
                                        fit: BoxFit.cover)
                                    : null,
                              ),
                              child: hasPhoto
                                  ? null
                                  : Icon(Icons.person, color: _kRed, size: 20.r),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(f.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppFonts.spaceGrotesk.copyWith(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w700,
                                          color: _kText)),
                                  if ((f.username ?? '').isNotEmpty)
                                    Text('@${f.username}',
                                        style: AppFonts.spaceGrotesk.copyWith(
                                            fontSize: 11.sp, color: _kMuted)),
                                ],
                              ),
                            ),
                            Icon(Icons.chat_bubble_outline,
                                color: _kRed, size: 18.r),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildTabBar(MessagesController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: TabBar(
          controller: controller.tabController,
          indicator: BoxDecoration(
            gradient: LinearGradient(colors: [_kRed, _kRedDk]),
            borderRadius: BorderRadius.circular(12.r),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: EdgeInsets.all(4.w),
          labelColor: Colors.white,
          unselectedLabelColor: _kMuted,
          dividerColor: Colors.transparent,
          labelStyle: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w700),
          unselectedLabelStyle: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w600),
          tabs: [
            Tab(
              child: Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Personal'),
                  if (controller.personalMessages.any((m) => m.unreadCount > 0)) ...[
                    SizedBox(width: 4.w),
                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                  ],
                ],
              )),
            ),
            Tab(
              child: Obx(() => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Community'),
                  if (controller.communityMessages.any((m) => m.unreadCount > 0)) ...[
                    SizedBox(width: 4.w),
                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                  ],
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBarView(MessagesController controller) {
    return TabBarView(
      controller: controller.tabController,
      children: [
        _buildMessagesList(controller, isPersonalTab: true),
        _buildMessagesList(controller, isPersonalTab: false),
      ],
    );
  }

  Widget _buildMessagesList(MessagesController controller, {required bool isPersonalTab}) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: loading());
      }
      final messages = isPersonalTab ? controller.personalMessages : controller.communityMessages;
      if (messages.isEmpty) return _buildEmptyState(controller, isPersonalTab);
      return RefreshIndicator(
        onRefresh: () async => controller.refreshData(),
        color: _kRed,
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 80.h),
          itemCount: messages.length,
          itemBuilder: (_, i) => _MessageTile(message: messages[i], controller: controller),
        ),
      );
    });
  }

  Widget _buildEmptyState(MessagesController controller, bool isPersonalTab) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72.r, height: 72.r,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _kRed.withOpacity(0.08)),
              child: Icon(isPersonalTab ? Icons.chat_bubble_outline : Icons.group_outlined, color: _kRed, size: 32.r),
            ),
            SizedBox(height: 16.h),
            Text(isPersonalTab ? 'No Messages Yet' : 'No Community Chats',
              style: AppFonts.spaceGrotesk.copyWith(fontSize: 18.sp, fontWeight: FontWeight.w800, color: _kText)),
            SizedBox(height: 8.h),
            Text(isPersonalTab ? 'Tap below to message a friend' : 'Join a community to see group messages',
              style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, color: _kMuted, height: 1.5), textAlign: TextAlign.center),
            if (isPersonalTab) ...[
              SizedBox(height: 20.h),
              GestureDetector(
                onTap: () => _openNewChat(controller),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 13.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_kRed, _kRedDk]),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_comment_rounded, color: Colors.white, size: 18.r),
                      SizedBox(width: 8.w),
                      Text('Start a chat',
                          style: AppFonts.spaceGrotesk.copyWith(
                              color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  final MessageModel message;
  final MessagesController controller;
  const _MessageTile({required this.message, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.onMessageTap(message),
          onLongPress: () => controller.onMessageLongPress(message),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(14.r),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    ResponsiveNetworkImage(
                      imageUrl: message.senderProfileImage,
                      shape: ImageShape.circle,
                      widthPercent: 0.12,
                      heightPercent: 0.06,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        width: 48.r, height: 48.r,
                        decoration: BoxDecoration(
                          color: _kRed.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          message.messageType == MessageType.community ? Icons.group : Icons.person,
                          color: _kRed,
                          size: 22.r,
                        ),
                      ),
                    ),
                    if (message.isOnline && message.messageType == MessageType.personal)
                      Positioned(
                        right: 1, bottom: 1,
                        child: Container(
                          width: 11, height: 11,
                          decoration: BoxDecoration(color: const Color(0xff22C55E), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        ),
                      ),
                    if (message.messageType == MessageType.community)
                      Positioned(
                        right: 1, bottom: 1,
                        child: Container(
                          width: 14, height: 14,
                          decoration: BoxDecoration(color: _kRed, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
                          child: Icon(Icons.group, color: Colors.white, size: 8),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    message.displayName,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppFonts.spaceGrotesk.copyWith(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      color: _kText,
                                    ),
                                  ),
                                ),
                                if (message.isVerified == true) ...[
                                  SizedBox(width: 4.w),
                                  Icon(Icons.verified, color: Colors.blue, size: 13.r),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            message.formattedTime,
                            style: AppFonts.spaceGrotesk.copyWith(fontSize: 10.sp, color: _kMuted),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              message.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.spaceGrotesk.copyWith(
                                fontSize: 12.sp,
                                color: message.unreadCount > 0 ? _kText : _kMuted,
                                fontWeight: message.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (message.unreadCount > 0)
                            Container(
                              margin: EdgeInsets.only(left: 8.w),
                              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                              decoration: BoxDecoration(color: _kRed, borderRadius: BorderRadius.circular(10.r)),
                              child: Text(
                                message.unreadCount > 9 ? '9+' : '${message.unreadCount}',
                                style: AppFonts.spaceGrotesk.copyWith(fontSize: 10.sp, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
