import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';
import 'package:spanx/core/global_widgets/goal_tracking_widget.dart';
import 'package:spanx/core/global_widgets/subpage_appbar_widget.dart';
import 'package:spanx/features/createnewcustomer/screen/create_new_customer_screen.dart';
import 'package:spanx/features/customer_details/ui/customer_details_page.dart';
import 'package:spanx/features/mission_details/controller/mission_details_controller.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/const/app_fonts.dart';
import '../../../core/const/app_icons.dart';
import '../../../core/const/app_images.dart';
import '../../../core/const/app_size.dart';

class MissionDetailsScreen extends StatelessWidget {
  MissionDetailsScreen({super.key});

  final MissionDetailsController missionDetailsController = Get.put(
    MissionDetailsController(),
  );

  Color getPriorityColor(GoalPriority priority) {
    switch (priority) {
      case GoalPriority.HIGH:
        return AppColors.maroonColor;
      case GoalPriority.MEDIUM:
        return AppColors.blueColor;
      case GoalPriority.LOW:
        return AppColors.primaryColor;
    }
  }

  String getPriorityText(GoalPriority priority) {
    switch (priority) {
      case GoalPriority.HIGH:
        return 'High';
      case GoalPriority.MEDIUM:
        return 'Medium';
      case GoalPriority.LOW:
        return 'Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //  app bar
              SubPageAppbarWidget(
                appbarTitle: 'Mission Details',
                onPressed: () {
                  Get.back();
                },
              ),
              SizedBox(height: 15.w),
              // goal tracking card
              Container(
                padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 20.w),
                decoration: BoxDecoration(
                  // borderRadius: BorderRadius.circular(AppSizes.w(5)),
                  // border: Border.all(color: AppColors.whiteColor),
                  image: DecorationImage(
                    image: AssetImage(AppImages.bg_profiles),
                    fit: BoxFit.fill,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // daily priority delete
                    // these values will come from 'Create New Goal' screen
                    Row(
                      children: [
                        Text(
                          'Daily',
                          style: AppFonts.spaceGrotesk.copyWith(
                            color: AppColors.greyColor70,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 15.w),
                        Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.whiteColor.withAlpha(90),
                            ),
                            color: getPriorityColor(
                              GoalPriority.HIGH,
                            ).withAlpha(20),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            "${getPriorityText(GoalPriority.HIGH)} Priority",
                            style: AppFonts.spaceGrotesk.copyWith(
                              color: getPriorityColor(GoalPriority.HIGH),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    // goal title
                    Text(
                      'Complete 8 Client Sessions',
                      style: AppFonts.spaceGrotesk.copyWith(
                        color: AppColors.greyColor70,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    // goal description
                    Text(
                      'Provide excellent service to all scheduled clients today',
                      style: AppFonts.spaceGrotesk.copyWith(
                        color: AppColors.greyColor70,
                        fontSize: AppSizes.w(14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: AppSizes.h(10)),
                    // due date
                    Row(
                      children: [
                        SvgPicture.asset(AppIcons.calendar),
                        SizedBox(width: AppSizes.w(10)),
                        Text(
                          'Due Date: ',
                          style: AppFonts.spaceGrotesk.copyWith(
                            color: AppColors.greyColor70,
                            fontSize: AppSizes.w(16),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: AppSizes.sp(10),
                          ),
                        ),
                        Text(
                          '5/10',
                          style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: AppSizes.sp(10),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    LinearProgressIndicator(
                      backgroundColor: AppColors.whiteColor,
                      value: 5 / 10,
                      color: AppColors.maroonColor,
                      borderRadius: BorderRadius.circular(AppSizes.w(15)),
                      minHeight: AppSizes.h(8),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // cards
              IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _goalsDetailsDashboard('Client Reached', '06'),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _goalsDetailsDashboard('Talked With Client', '03'),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _goalsDetailsDashboard('Complete Sales', '07'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // Time spend with client
              _createSectionTextButton('Time spend with client', 'Create', () {
                CreateNewCustomerScreen.show(onContinue: () {});
              }),

              SizedBox(height: 20.h),
              // grids
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.3,
                ),
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Obx(() {
                    return _clientDetailsBackground(
                      _clientDetails(index + 1, () {
                        Get.to(() => CustomerDetailsPage());
                      }, "View Details"),
                      missionDetailsController.selectedClientIndex.value ==
                          index,
                      () {
                        missionDetailsController.changeClientIndex(index);
                      },
                    );
                  });
                },
              ),
              SizedBox(height: 20.h),

              // client time calculation
              Obx( () {
                return TimeCalculationWidget(
                  title: 'Client ${missionDetailsController.selectedClientIndex.value + 1}',
                  subTitle: "New Client",
                  value: missionDetailsController.progress,
                  timeText: missionDetailsController.formattedTime,
                  resetOnTap: missionDetailsController.resetTimer,
                  saveOnTap: missionDetailsController.saveTimer,
                  playPause: missionDetailsController.toggleTimer,
                  icon: missionDetailsController.isRunning.value? Icons.pause : Icons.play_arrow,
                );
              }
              ),

              SizedBox(height: 20.h),

              // Sales Status
              Text(
                'Sales Status',
                style: AppFonts.spaceGrotesk.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: AppSizes.sp(18),
                  color: AppColors.greyColor70,
                ),
              ),
              SizedBox(height: 20.h),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.3,
                ),
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Obx(() {
                    return _clientDetailsBackground(
                      _clientDetails(index + 1, () {
                        log("complete task");
                      }, "Mark as Completed"),
                      missionDetailsController.selectedClientIndex.value ==
                          index,
                      () {
                        missionDetailsController.changeClientIndex(index);
                      },
                    );
                  });
                },
              ),
              SizedBox(height: 20.h),

              // my why
              _createSectionTextButton('My Why', 'Create New', () {}),
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal:20.w,
                  vertical: 15.h,
                ),
                width: double.infinity,
                decoration: BoxDecoration(

                  image: DecorationImage(
                    image: AssetImage(AppImages.bg_minicard),
                    fit: BoxFit.fill,
                  ),
                  // color: AppColors.lightPinkColor,
                  borderRadius: BorderRadius.circular(AppSizes.w(15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(3, (index)=> Text('${index+1}. My Why', style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 15.sp, fontWeight: FontWeight.w500
                  ),))
                ),
              ),
              SizedBox(height: 20.h),


              // Affirmations
              _createSectionTextButton('Affirmations', 'Create New', () {}),
              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal:20.w,
                  vertical: 15.h,
                ),
                width: double.infinity,
                decoration: BoxDecoration(

                  image: DecorationImage(
                    image: AssetImage(AppImages.bg_minicard),
                    fit: BoxFit.fill,
                  ),
                  // color: AppColors.lightPinkColor,
                  borderRadius: BorderRadius.circular(AppSizes.w(15)),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(3, (index)=> Text('${index+1}. Affirmations', style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 15.sp, fontWeight: FontWeight.w500
                    ),))
                ),
              ),
              SizedBox(height: 20.h),

              // client time calculation
              Obx( () {
                  return TimeCalculationWidget(
                    title: 'Break',
                    value: missionDetailsController.progress,
                    timeText: missionDetailsController.formattedTime,
                    resetOnTap: missionDetailsController.resetTimer,
                    saveOnTap: missionDetailsController.saveTimer,
                    playPause: missionDetailsController.toggleTimer,
                    icon: missionDetailsController.isRunning.value? Icons.pause : Icons.play_arrow,
                  );
                }
              ),
              SizedBox(height: 20.h),

              // end your day button
              CustomButtonWidget(onTap: () {}, buttonText: 'End Your Day'),
            ],
          ),
        ),
      ),
    );
  }
}

class TimeCalculationWidget extends StatelessWidget {
  const TimeCalculationWidget({
    super.key,
    required this.title,
    this.subTitle,
    required this.value,
    required this.timeText,
    required this.resetOnTap,
    required this.saveOnTap,
    required this.playPause, required this.icon,
  });

  final String title;
  final String? subTitle;
  final double value;
  final String timeText;
  final VoidCallback resetOnTap;
  final VoidCallback saveOnTap;
  final VoidCallback playPause;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.w(6),
        vertical: AppSizes.w(15),
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.whiteColor),
        image: DecorationImage(
          image: AssetImage(AppImages.bg_minicard),
          fit: BoxFit.cover,
        ),
        // color: AppColors.lightPinkColor,
        borderRadius: BorderRadius.circular(AppSizes.w(15)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppFonts.spaceGrotesk.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 20.sp,
              color: AppColors.blackColor,
            ),
          ),
          Text(
            subTitle ?? "",
            style: AppFonts.spaceGrotesk.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 10.sp,
              color: AppColors.greyColor70,
            ),
          ),
          SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120.w,
                height: 120.w,
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 15.w,
                  backgroundColor: AppColors.maroonColor.withAlpha(40),
                  color: AppColors.maroonColor,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                timeText,
                style: AppFonts.spaceGrotesk.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 20.sp,
                  color: AppColors.blackColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 30.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CustomButtonWidget(onTap: resetOnTap, buttonText: 'Reset'),
              // buildButton("Reset", onTap: missionDetailsController.resetTimer),
              GestureDetector(
                onTap: playPause,
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryColor,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primaryColor,
                    size: 28,
                  ),
                ),
              ),
              CustomButtonWidget(onTap: saveOnTap, buttonText: 'Save'),
            ],
          ),
        ],
      ),
    );
  }
}

// this is the widget of Client Reached - Talked With Client - Complete Sales
Widget _goalsDetailsDashboard(String title, String boldText) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.whiteColor),
      borderRadius: BorderRadius.circular(10.w),
      image: DecorationImage(
        image: AssetImage(AppImages.bg_minicard),
        fit: BoxFit.fill,
      ),
    ),
    child: Column(
      // crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppFonts.spaceGrotesk.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 10.sp,
            color: AppColors.blackColor,
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          boldText,
          style: AppFonts.spaceGrotesk.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 25.sp,
            color: AppColors.blackColor,
          ),
        ),
      ],
    ),
  );
}

Widget _clientDetailsBackground(
  Widget widget,
  bool isSelected,
  VoidCallback ontap,
) {
  return GestureDetector(
    onTap: ontap,
    child:
    Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.w(6),
        vertical: AppSizes.w(15),
      ),
      width: AppSizes.w(220),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? AppColors.maroonColor : AppColors.whiteColor,
        ),
        image: DecorationImage(
          image: AssetImage(AppImages.bg_minicard),
          fit: BoxFit.fill,
        ),
        // color: AppColors.lightPinkColor,
        borderRadius: BorderRadius.circular(AppSizes.w(15)),
      ),
      child: widget,
    ),
  );
}

Widget _clientDetails(int clientNumber, VoidCallback ontap, String buttonText) {
  return Column(
    children: [
      Text(
        'Client $clientNumber',
        style: AppFonts.spaceGrotesk.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 12.sp,
          color: AppColors.blackColor,
        ),
      ),
      SizedBox(height: 5.h),
      Text(
        '10 Min',
        style: AppFonts.spaceGrotesk.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 20.sp,
          color: AppColors.blackColor,
        ),
      ),
      ElevatedButton(
        onPressed: ontap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.lightPinkColor.withAlpha(95),
        ),
        child: Text(
          buttonText,
          style: AppFonts.spaceGrotesk.copyWith(
            fontSize: AppSizes.sp(12),
            fontWeight: FontWeight.w600,
            color: AppColors.greyColor70,
          ),
        ),
      ),
    ],
  );
}

Widget buildButton(String text, {required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 100,
      height: 50,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [BoxShadow(color: Colors.black26, offset: Offset(2, 2))],
      ),
      child: Text(text, style: TextStyle(color: Colors.white, fontSize: 16)),
    ),
  );
}

Widget _createSectionTextButton(
  String title,
  String buttonText,
  VoidCallback ontap,
) {
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

enum GoalPriority { HIGH, MEDIUM, LOW }
