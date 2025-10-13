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
            colors: [Color(0xFFFFB6B6), Color(0xFFFFA07A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(controller),
              SizedBox(height: 16.h),
              _buildTabBar(controller),
              SizedBox(height: 20.h),
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
          Tab(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Obx(
                () => normalText(
                  text: 'Search',
                  color: controller.currentTabIndex.value == 2
                      ? Colors.white
                      : Colors.white70,
                  fontWeight: controller.currentTabIndex.value == 2
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
        _buildUsersList(controller, isFollowingsTab: true),
        _buildUsersList(controller, isFollowingsTab: false),
        _buildSearchTab(controller),
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
            return _buildUserItem(user, controller, isFollowingsTab);
          },
        ),
      );
    });
  }

  Widget _buildSearchTab(FollowingsFollowersController controller) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: TextField(
            controller: controller.searchController,
            onChanged: (value) => controller.searchUsers(value),
            decoration: InputDecoration(
              hintText: 'Search users by name...',
              hintStyle: TextStyle(color: Colors.black54),
              prefixIcon: Icon(Icons.search, color: Colors.black54),
              suffixIcon: controller.searchController.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        controller.searchController.clear();
                        controller.clearSearch();
                      },
                      child: Icon(Icons.close, color: Colors.black54),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withOpacity(0.8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.36),
                  width: 1.w,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.36),
                  width: 1.w,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(
                  color: Color.fromARGB(255, 240, 78, 2),
                  width: 1.w,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            if (controller.isSearchLoading.value) {
              return Center(child: loading());
            }

            if (controller.searchResults.isEmpty &&
                controller.searchController.text.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_search,
                      size: 80.w,
                      color: Colors.black54,
                    ),
                    SizedBox(height: 16.h),
                    normalText(text: 'No users found', color: Colors.black54),
                    SizedBox(height: 8.h),
                    smallText(
                      text: 'Try searching with a different name',
                      color: Colors.black38,
                    ),
                  ],
                ),
              );
            }

            if (controller.searchResults.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search, size: 80.w, color: Colors.black54),
                    SizedBox(height: 16.h),
                    normalText(text: 'Search for users', color: Colors.black54),
                    SizedBox(height: 8.h),
                    smallText(
                      text: 'Enter a username to get started',
                      color: Colors.black38,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: controller.searchResults.length,
              itemBuilder: (context, index) {
                final user = controller.searchResults[index];
                return _buildUserItem(user, controller, false, isSearch: true);
              },
            );
          }),
        ),
      ],
    );
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
    bool isFollowingsTab, {
    bool isSearch = false,
  }) {
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
                GestureDetector(
                  onTap: () => controller.onFollowToggle(
                    user,
                    isFollowingsTab,
                    isSearch,
                  ),
                  child: Obx(() {
                    final isFollowing = user.isFollowing;

                    return Container(
                      width: 32.w,
                      height: 32.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFollowing
                            ? Colors.orange
                            : Colors.white.withOpacity(0.3),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.36),
                          width: 1.w,
                        ),
                      ),
                      child: Icon(
                        isFollowing ? Icons.check : Icons.person_add,
                        color: isFollowing ? Colors.white : Colors.black54,
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
