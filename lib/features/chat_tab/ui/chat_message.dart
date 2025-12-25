import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/global_widgets/app_loading.dart';
import '../../../core/global_widgets/app_network_image.dart';
import '../../../core/global_widgets/custom_text.dart';
import '../controller/chat_controller.dart';
import '../model/chat_model.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MessagesController());

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFB6B6), // Light pink at top
              Color(0xFFFFA07A), // Light salmon at bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              _buildHeader(controller),

              SizedBox(height: 16.h),

              // Tab Bar
              _buildTabBar(controller),

              SizedBox(height: 20.h),

              // Content
              Expanded(child: _buildTabBarView(controller)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(MessagesController controller) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: controller.onBackPressed,
            child: Container(
              padding: EdgeInsets.all(8.w),
              child: Icon(
                Icons.arrow_back_ios,
                color: Colors.black87,
                size: 20.w,
              ),
            ),
          ),

          SizedBox(width: 8.w),

          // Title
          headingText(text: 'Messages', color: Colors.black87),

          const Spacer(),

          // Unread count badge
          Obx(() {
            final unreadCount = controller.totalUnreadCount;
            if (unreadCount > 0) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: smallText(
                  text: unreadCount > 99 ? '99+' : unreadCount.toString(),
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildTabBar(MessagesController controller) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(25.r),
      ),
      child: TabBar(
        controller: controller.tabController,
        indicator: BoxDecoration(
          color: const Color.fromARGB(255, 240, 78, 2),
          borderRadius: BorderRadius.circular(25.r),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: EdgeInsets.all(4.w),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    smallText(
                      text: 'Personal',
                      color: controller.currentTabIndex.value == 0
                          ? Colors.white
                          : Colors.white70,
                      fontWeight: controller.currentTabIndex.value == 0
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    if (controller.personalMessages
                        .where((m) => m.unreadCount > 0)
                        .isNotEmpty) ...[
                      SizedBox(width: 4.w),
                      Container(
                        width: 8.w,
                        height: 8.h,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Tab(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    smallText(
                      text: 'Community',
                      color: controller.currentTabIndex.value == 1
                          ? Colors.white
                          : Colors.white70,
                      fontWeight: controller.currentTabIndex.value == 1
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    if (controller.communityMessages
                        .where((m) => m.unreadCount > 0)
                        .isNotEmpty) ...[
                      SizedBox(width: 4.w),
                      Container(
                        width: 8.w,
                        height: 8.h,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarView(MessagesController controller) {
    return TabBarView(
      controller: controller.tabController,
      children: [
        // Personal Messages Tab
        _buildMessagesList(controller, isPersonalTab: true),

        // Community Messages Tab
        _buildMessagesList(controller, isPersonalTab: false),
      ],
    );
  }

  Widget _buildMessagesList(
    MessagesController controller, {
    required bool isPersonalTab,
  }) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: loading());
      }

      final messages = isPersonalTab
          ? controller.personalMessages
          : controller.communityMessages;

      if (messages.isEmpty) {
        return _buildEmptyState(isPersonalTab);
      }

      return RefreshIndicator(
        onRefresh: () async => controller.refreshData(),
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return _buildMessageItem(message, controller);
          },
        ),
      );
    });
  }

  Widget _buildEmptyState(bool isPersonalTab) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPersonalTab ? Icons.chat_outlined : Icons.group_outlined,
            size: 80.w,
            color: Colors.black54,
          ),
          SizedBox(height: 16.h),
          normalText(
            text: isPersonalTab
                ? 'No Personal Messages'
                : 'No Community Messages',
            color: Colors.black54,
          ),
          SizedBox(height: 8.h),
          smallText(
            text: isPersonalTab
                ? 'Start a conversation with someone'
                : 'Join a community to see messages',
            color: Colors.black38,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(
    MessageModel message,
    MessagesController controller,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.36), width: 1.w),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => controller.onMessageTap(message),
          onLongPress: () => controller.onMessageLongPress(message),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // Profile Image with Online Status
                Stack(
                  children: [
                    ResponsiveNetworkImage(
                      imageUrl: message.senderProfileImage,
                      shape: ImageShape.circle,
                      widthPercent: 0.12,
                      heightPercent: 0.06,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        width: 52.w,
                        height: 52.h,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          message.messageType == MessageType.community
                              ? Icons.group
                              : Icons.person,
                          color: Colors.grey[600],
                          size: 28.w,
                        ),
                      ),
                    ),

                    // Online Status Indicator
                    if (message.isOnline &&
                        message.messageType == MessageType.personal)
                      Positioned(
                        right: 2.w,
                        bottom: 2.h,
                        child: Container(
                          width: 12.w,
                          height: 12.h,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.w),
                          ),
                        ),
                      ),

                    // Community Type Indicator
                    if (message.messageType == MessageType.community)
                      Positioned(
                        right: 2.w,
                        bottom: 2.h,
                        child: Container(
                          width: 12.w,
                          height: 12.h,
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.w),
                          ),
                          child: Icon(
                            Icons.group,
                            color: Colors.white,
                            size: 8.w,
                          ),
                        ),
                      ),
                  ],
                ),

                SizedBox(width: 12.w),

                // Message Info
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
                                  child: smallText(
                                    text: message.displayName,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                    maxLines: 1,
                                  ),
                                ),
                                if (message.isVerified == true) ...[
                                  SizedBox(width: 4.w),
                                  Icon(
                                    Icons.verified,
                                    color: Colors.blue,
                                    size: 14.w,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          smallerText(
                            text: message.formattedTime,
                            color: Colors.black54,
                          ),
                        ],
                      ),

                      SizedBox(height: 4.h),

                      Row(
                        children: [
                          Expanded(
                            child: smallerText(
                              text: message.lastMessage,
                              color: Colors.black54,
                              maxLines: 1,
                            ),
                          ),

                          // Unread Count Badge
                          if (message.unreadCount > 0)
                            Container(
                              margin: EdgeInsets.only(left: 8.w),
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: smallerText(
                                text: message.unreadCount > 9
                                    ? '9+'
                                    : message.unreadCount.toString(),
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
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

// Note: Make sure to import your existing widgets:
// - ResponsiveNetworkImage
// - headingText, normalText, smallText, smallerText
// - loading widget
