import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
import 'package:spanx/features/motivationalNudges/controller/motivational_nudges_controller.dart';
import 'package:spanx/routes/app_routes.dart';

import '../../../core/alertdialogs/create_my_why_dialog.dart';
import '../../../core/const/app_size.dart';
import '../../../core/global_widgets/app_loading.dart';
import '../../../core/global_widgets/motivation_card_widget.dart';
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
    final myWhyList = controller.homeMyWhyList;
    final myAffList = controller.homeMyAffirmationList;
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
                  name: userInfoController.userData.value?.fullName ?? "loading...",
                );
              }),
              SizedBox(height: AppSizes.h(20)),

              // motivational card
              Obx(() {
                return MotivationCardWidget(
                  title: controller.randomMotivationLine.value,
                  buttonText: 'Set new >>',
                  imgPath: '',
                  onTap: () {
                    controller.randomMotivationLine.value = motivationController
                        .motivationNudgesList[controller.randomIndex()]
                        .title!;
                  },
                );
              }),
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
              _ViewBudgetButton(
                "View Your Budget >>",
                () {
                  Get.toNamed(AppRoutes.myBudgetScreen);
                },
                true,
                AppIcons.budget_trend,
              ),
              SizedBox(height: AppSizes.h(20)),

              // my why
              _createSectionTextButton(
                title: 'My Why',
                buttonText: 'Create New',
                ontap: () {
                  CreateMyWhyDialog.show(
                    'My Why',
                    controller.myWhyAffirmation,
                    controller.isLoading,
                    () {
                      controller.createHomeMyWhy();
                    },
                  );
                },
              ),
              SizedBox(height: 10.h),
              Obx(() {
                return controller.isLoading.value
                    ? loading()
                    : Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 15.h,
                        ),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.whiteColor.withAlpha(400),
                          borderRadius: BorderRadius.circular(AppSizes.w(15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(
                            myWhyList.length,
                            (index) => InkWell(
                              onLongPress: () {
                                Get.defaultDialog(
                                  backgroundColor: AppColors.lightPinkColor,
                                  title: "Delete My Why?",
                                  middleText:
                                      "Are you sure you want to delete this item?",
                                  confirm: TextButton(
                                    onPressed: () {
                                      Get.back();
                                      controller.deleteHomeMyWhy(
                                        myWhyList[index].id!,
                                      );
                                    },
                                    child: const Text(
                                      "Yes",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                  cancel: TextButton(
                                    onPressed: () => Get.back(),
                                    child: const Text("Cancel"),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 4.h),
                                child: Text(
                                  '${index + 1}. ${myWhyList[index].text}',
                                  style: AppFonts.spaceGrotesk.copyWith(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
              }),

              SizedBox(height: 20.h),

              // Affirmations
              _createSectionTextButton(
                title: 'Affirmations',
                buttonText: 'Create New',
                ontap: () {
                  CreateMyWhyDialog.show(
                    'Affirmations',
                    controller.myWhyAffirmation,
                    controller.isLoading,
                    () {
                      controller.createHomeAffirmation();
                    },
                  );
                },
              ),
              SizedBox(height: 20.h),
              Obx(() {
                return controller.isLoading.value
                    ? loading()
                    : Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 15.h,
                        ),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.whiteColor.withAlpha(400),
                          borderRadius: BorderRadius.circular(AppSizes.w(15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(
                            myAffList.length,
                            (index) => InkWell(
                              onLongPress: () {
                                Get.defaultDialog(
                                  title: "Delete Affirmation?",
                                  middleText:
                                      "Are you sure you want to delete this affirmation?",
                                  confirm: TextButton(
                                    onPressed: () {
                                      Get.back();
                                      controller.deleteHomeAffirmation(
                                        myAffList[index].id!,
                                      );
                                    },
                                    child: const Text(
                                      "Yes",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                  cancel: TextButton(
                                    onPressed: () => Get.back(),
                                    child: const Text("Cancel"),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 4.h),
                                child: Text(
                                  '${index + 1}. ${myAffList[index].text}',
                                  style: AppFonts.spaceGrotesk.copyWith(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
              }),

              SizedBox(height: 20.h),

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
                    '',
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

Widget _createSectionTextButton({
  required String title,
  required String buttonText,
  required VoidCallback ontap,
}) {
  return Row(
    children: [
      Text(
        title,
        style: AppFonts.spaceGrotesk.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: AppSizes.sp(18),
          color: AppColors.greyColor70,
        ),
      ),
      Spacer(),
      GestureDetector(
        onTap: ontap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.w(10),
            vertical: AppSizes.h(5),
          ),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppImages.bg_minicard),
              fit: BoxFit.fill,
            ),
          ),
          child: Row(
            children: [
              Image.asset(AppIcons.box_add, height: AppSizes.h(20)),
              SizedBox(width: AppSizes.w(5)),
              Text(
                buttonText,
                style: AppFonts.spaceGrotesk.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: AppSizes.sp(12),
                  color: AppColors.greyColor70,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

// this is the widget of two buttons here start priming
Widget _ViewBudgetButton(
  String text,
  VoidCallback ontap,
  bool isImage,
  String? imgPath,
) {
  return GestureDetector(
    onTap: ontap,
    child: Container(
      height: AppSizes.h(60),
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.w(20),
        vertical: AppSizes.w(12),
      ),

      decoration: BoxDecoration(
        // boxShadow: [BoxShadow(color: AppColors.greyColor70, spreadRadius: 1)],
        border: Border.all(color: AppColors.greyColor70.withAlpha(80)),
        borderRadius: BorderRadius.circular(AppSizes.w(20)),
        image: DecorationImage(
          image: AssetImage(AppImages.bg_minicard),
          fit: BoxFit.fill,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // image
          isImage ? Image.asset(imgPath!) : SizedBox(),
          SizedBox(width: AppSizes.w(10)),
          // text
          Text(
            text,
            style: AppFonts.spaceGrotesk.copyWith(
              fontSize: AppSizes.sp(16),
              fontWeight: FontWeight.w700,
              color: AppColors.greyColor70,
            ),
          ),
        ],
      ),
    ),
  );
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
