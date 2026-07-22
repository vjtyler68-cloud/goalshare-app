import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/const/app_fonts.dart';
import '../../../core/global_widgets/app_loading.dart';
import '../../../core/global_widgets/app_network_image.dart';
import '../controller/chat_controller.dart';
import '../model/chat_model.dart';
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
            ],
          ),
        ),
      ),
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
      if (messages.isEmpty) return _buildEmptyState(isPersonalTab);
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

  Widget _buildEmptyState(bool isPersonalTab) {
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
            Text(isPersonalTab ? 'Start a conversation with someone' : 'Join a community to see group messages',
              style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, color: _kMuted, height: 1.5), textAlign: TextAlign.center),
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
