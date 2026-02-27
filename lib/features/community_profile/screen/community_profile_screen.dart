
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/alertdialogs/new_community.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_icons.dart';
import 'package:spanx/core/const/app_images.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/profile_card_widget.dart';
import 'package:spanx/core/global_widgets/subpage_appbar_widget.dart';
import 'package:spanx/features/community_profile/controller/community_profile_controller.dart';

import '../../../core/global_widgets/app_loading.dart';

class CommunityProfileScreen extends StatelessWidget {
  CommunityProfileScreen({super.key});

  final CommunityProfileController controller = Get.put(
    CommunityProfileController(),
  );

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
        minimum: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // appbar
            SubPageAppbarWidget(
              appbarTitle: 'Community Profile',
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            SizedBox(height: 10.h),

            // Community Profiles
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () {
                  NewCommunity.show();
                },
                child: Container(
                  width: 150.w,
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(AppImages.bg_minicard),
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: Row(
                    children: [
                      Image.asset(AppIcons.box_add, height: 15.h),
                      SizedBox(width: 5.w),
                      Text(
                        'Create Community',
                        style: AppFonts.spaceGrotesk.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 10.sp,
                          color: AppColors.greyColor70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),

            Expanded(
              child: Obx(() {
                if (controller.isInitialLoading.value) {
                  return Center(child: loading());
                }

                if (controller.data.isEmpty) {
                  return const Center(child: Text('No users found'));
                }

                final itemCount =
                    controller.data.length + (controller.hasMore.value ? 1 : 0);

                return RefreshIndicator(
                  onRefresh: () async => controller.onRefresh,
                  child: ListView.builder(
                    controller: controller.scrollController,
                    // itemCount: controller.allUserList.length,
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (index >= controller.data.length) {
                        // bottom loader row
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: controller.isFetchingMore.value
                                ? const CircularProgressIndicator()
                                : const SizedBox.shrink(),
                          ),
                        );
                      }
                      final user = controller.data[index];
                      return ProfileCardWidget(profileModel: user);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
