import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/global_widgets/app_loading.dart';
import '../../../core/global_widgets/app_network_image.dart';
import '../../../core/global_widgets/custom_text.dart';
import '../controller/follower_controller.dart';
import '../model/follower_model.dart';

class FollowingsFollowersPage extends StatelessWidget {
  const FollowingsFollowersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FollowingsFollowersController());

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

  Widget _buildHeader(FollowingsFollowersController controller) {
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
          headingText(text: 'Followings & Followers', color: Colors.black87),
        ],
      ),
    );
  }

  Widget _buildTabBar(FollowingsFollowersController controller) {
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
                () => normalText(
                  text: 'Followings',
                  color: controller.currentTabIndex.value == 0
                      ? Colors.white
                      : Colors.white70,
                  fontWeight: controller.currentTabIndex.value == 0
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
          Tab(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Obx(
                () => normalText(
                  text: 'Followers',
                  color: controller.currentTabIndex.value == 1
                      ? Colors.white
                      : Colors.white70,
                  fontWeight: controller.currentTabIndex.value == 1
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarView(FollowingsFollowersController controller) {
    return TabBarView(
      controller: controller.tabController,
      children: [
        // Followings Tab
        _buildUsersList(controller, isFollowingsTab: true),

        // Followers Tab
        _buildUsersList(controller, isFollowingsTab: false),
      ],
    );
  }

  Widget _buildUsersList(
    FollowingsFollowersController controller, {
    required bool isFollowingsTab,
  }) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(child: loading());
      }

      final users = isFollowingsTab
          ? controller.followingsList
          : controller.followersList;

      if (users.isEmpty) {
        return _buildEmptyState(isFollowingsTab);
      }

      return RefreshIndicator(
        onRefresh: () async => controller.refreshData(),
        child: ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildUserItem(user, controller);
          },
        ),
      );
    });
  }

  Widget _buildEmptyState(bool isFollowingsTab) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFollowingsTab ? Icons.people_outline : Icons.person_add_outlined,
            size: 80.w,
            color: Colors.black54,
          ),
          SizedBox(height: 16.h),
          normalText(
            text: isFollowingsTab ? 'No Followings' : 'No Followers',
            color: Colors.black54,
          ),
          SizedBox(height: 8.h),
          smallText(
            text: isFollowingsTab
                ? 'You are not following anyone yet'
                : 'No one is following you yet',
            color: Colors.black38,
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(
    UserFollowModel user,
    FollowingsFollowersController controller,
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
          onTap: () => controller.onUserTap(user),
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                // Profile Image
                ResponsiveNetworkImage(
                  imageUrl: user.profileImage,
                  shape: ImageShape.circle,
                  widthPercent: 0.1,
                  heightPercent: 0.05,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    width: 48.w,
                    height: 48.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.grey[600],
                      size: 24.w,
                    ),
                  ),
                ),

                SizedBox(width: 12.w),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      smallText(
                        text: user.name,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      SizedBox(height: 2.h),
                      smallerText(
                        text: user.email,
                        color: Colors.black54,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),

                // Follow/Unfollow Button
                GestureDetector(
                  onTap: () => controller.onFollowToggle(user),
                  child: Obx(() {
                    final isCurrentUserFollowing =
                        controller.currentTabIndex.value == 0
                        ? user.isFollowing
                        : user.isFollowing;

                    return Container(
                      width: 32.w,
                      height: 32.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCurrentUserFollowing
                            ? Colors.orange
                            : Colors.white.withOpacity(0.3),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.36),
                          width: 1.w,
                        ),
                      ),
                      child: Icon(
                        controller.currentTabIndex.value == 0
                            ? (user.isFollowing
                                  ? Icons.check
                                  : Icons.person_remove)
                            : (user.isFollowing
                                  ? Icons.check
                                  : Icons.person_add),
                        color: isCurrentUserFollowing
                            ? Colors.white
                            : Colors.black54,
                        size: 16.w,
                      ),
                    );
                  }),
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
// - headingText, normalText, smallText
// - loading widget
