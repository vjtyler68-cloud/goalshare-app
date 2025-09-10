import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/global_widgets/custom_text.dart';
import '../../../core/const/app_size.dart';
import '../../../core/global_widgets/app_network_image.dart';
import '../controller/profile_tab_controller.dart';

class ProfileTabPage extends StatelessWidget {
  const ProfileTabPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProfileTabController());
    AppSizes.init(context);

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
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Header Section
                _buildProfileHeader(controller),

                SizedBox(height: 24.h),

                // Followers Section
                _buildFollowersSection(controller),

                SizedBox(height: 32.h),

                // Menu Items Section
                _buildMenuSection(controller),

                SizedBox(height: 24.h),

                // Preferences Section
                _buildPreferencesSection(controller),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ProfileTabController controller) {
    return Obx(
      () => Column(
        children: [
          // Profile Image
          ResponsiveNetworkImage(
            imageUrl: controller.userImageUrl.value,
            shape: ImageShape.circle,
            widthPercent: 0.2,
            heightPercent: 0.1,
            fit: BoxFit.cover,
          ),

          SizedBox(height: 16.h),

          // User Name
          headingText(text: controller.userName.value, color: Colors.black87),

          SizedBox(height: 4.h),

          // User Email
          smallText(text: controller.userEmail.value, color: Colors.black54),
        ],
      ),
    );
  }

  Widget _buildFollowersSection(ProfileTabController controller) {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildFollowItem(
            count: controller.followingCount.value,
            label: 'Following',
          ),

          Container(
            height: 30.h,
            width: 1.w,
            color: Colors.black.withOpacity(0.36),
            margin: EdgeInsets.symmetric(horizontal: 24.w),
          ),

          _buildFollowItem(
            count: controller.followersCount.value,
            label: 'Followers',
          ),
        ],
      ),
    );
  }

  Widget _buildFollowItem({required int count, required String label}) {
    return Column(
      children: [
        normalText(
          text: count.toString(),
          color: Colors.black87,
          fontWeight: FontWeight.bold,
        ),
        SizedBox(height: 4.h),
        smallText(text: label, color: Colors.black54),
      ],
    );
  }

  Widget _buildMenuSection(ProfileTabController controller) {
    return Column(
      children: controller.menuItems
          .map((item) => _buildMenuItem(item))
          .toList(),
    );
  }

  Widget _buildPreferencesSection(ProfileTabController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16.w, bottom: 12.h),
          child: normalText(
            text: 'Preferences',
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),

        Column(
          children: controller.preferencesItems
              .map((item) => _buildMenuItem(item))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildMenuItem(ProfileMenuItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.36), width: 1.w),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Row(
              children: [
                // Icon
                Image.asset(
                  item.iconPath,
                  width: 24.w,
                  height: 24.h,
                  color: Colors.black87,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.image, size: 24.w, color: Colors.black87),
                ),

                SizedBox(width: 16.w),

                // Title
                Expanded(
                  child: smallText(text: item.title, color: Colors.black87),
                ),

                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16.w,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
