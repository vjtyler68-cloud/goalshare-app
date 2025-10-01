import 'dart:developer';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_icons.dart';
import 'package:spanx/core/const/app_images.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/profile_header_widget.dart';
import 'package:spanx/core/user_info/user_info_controller.dart';
import 'package:spanx/features/community_profile/screen/community_profile_screen.dart';
import 'package:spanx/features/home/controller/home_controller.dart';
import 'package:spanx/features/home/model/home_screen_model.dart';
import 'package:spanx/core/alertdialogs/create_new_mission.dart';
import 'package:spanx/features/motivationalNudges/controller/motivational_nudges_controller.dart';
import 'package:spanx/routes/app_routes.dart';

import '../../../core/const/app_size.dart';
import '../../../core/global_widgets/motivation_card_widget.dart';
import '../../../core/global_widgets/profile_card_widget.dart';
import '../../chat_tab/ui/chat_message.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final HomeController controller = Get.put(HomeController());
  final userInfoController = Get.find<UserInfoController>();
  final motivationController = Get.find<MotivationalNudgesController>();

  // void _showCreateGoalPopup() {
  //   CreateNewGoal.show(
  //     onContinue: () {
  //       Get.back();
  //       // Get.off(() => SignInScreen()); // Navigate to SignInScreen
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // profile header
              Obx(() {
                return ProfileHeaderWidget(
                  messageTap: () {
                    Get.to(() => MessagesPage());
                  },

                  communityTap: () {
                    Get.to(() => CommunityProfileScreen());
                  },
                  name: userInfoController.fullName.value,
                );
              }),
              SizedBox(height: AppSizes.h(20)),

              // motivational card
              Obx(() {
                  return MotivationCardWidget(
                    title: controller.randomMotivationLine.value,
                    buttonText: 'Set new >>',
                    imgPath: AppImages.motivation1,
                    onTap: () {
                      controller.randomMotivationLine.value = motivationController
                          .motivationNudgesList[controller.randomIndex()]
                          .title!;
                    },
                  );
                }
              ),
              SizedBox(height: AppSizes.h(20)),

              // priming and vision board
              Row(
                spacing: 5.w,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _goalsButton(
                      "Start Priming >>",
                      () {
                        Get.toNamed(AppRoutes.primingScreen);
                      },
                      true,
                      AppImages.priming,
                    ),
                  ),

                  // vision board
                  Expanded(
                    child: _goalsButton(
                      "Vision Board >>",
                      () {
                        Get.toNamed(AppRoutes.visionPageScreen);
                      },
                      true,
                      AppIcons.target,
                    ),
                  ),

                  // Bible
                  Expanded(
                    child: _goalsButton(
                      "Bible >>",
                      () {
                        controller.launchBibleSite(
                          'https://www.kingjamesbibleonline.org/',
                        );
                      },
                      true,
                      AppIcons.bible,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.h(20)),
              // Recent Activity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Activity',
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: AppSizes.sp(18),
                      color: AppColors.greyColor70,
                    ),
                  ),
                  Text(
                    'View All',
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: AppSizes.sp(18),
                      color: AppColors.greyColor70,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.h(20)),
              ...List.generate(RecentActivityModel.recentActivity.length, (
                index,
              ) {
                final activity = RecentActivityModel.recentActivity[index];
                return Container(
                  margin: EdgeInsets.symmetric(vertical: AppSizes.h(5)),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.w(10),
                    vertical: AppSizes.h(15),
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.whiteColor),
                    image: DecorationImage(
                      image: AssetImage(AppImages.bg_profiles),
                      fit: BoxFit.fill,
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.w(15)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: AppSizes.w(30),
                        height: AppSizes.h(30),
                        child: Image.asset(activity.iconPath),
                      ),
                      SizedBox(width: AppSizes.w(15)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.title,
                            style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: AppSizes.sp(15),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            activity.time,
                            style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: AppSizes.sp(10),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              SizedBox(height: AppSizes.h(100)),
            ],
          ),
        ),
      ),
    );
  }
}

// this is the widget of two buttons here start priming
Widget _goalsButton(
  String text,
  VoidCallback ontap,
  bool isImage,
  String? imgPath,
) {
  return GestureDetector(
    onTap: ontap,
    child: Container(
      height: 70.h,
      // width: 100.w,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.greyColor70.withAlpha(80)),
        borderRadius: BorderRadius.circular(10.r),
        image: DecorationImage(
          image: AssetImage(AppImages.bg_profiles),
          fit: BoxFit.fill,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // image
          isImage
              ? SizedBox(
                  height: 25.h,
                  width: 25.h,
                  child: Image.asset(imgPath!),
                )
              : SizedBox(),
          SizedBox(height: 5.h),
          // text
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppFonts.spaceGrotesk.copyWith(
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.greyColor70,
            ),
          ),
        ],
      ),
    ),
  );
}
