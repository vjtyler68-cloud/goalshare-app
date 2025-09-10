import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_icons.dart';
import 'package:spanx/core/const/app_images.dart';
import 'package:spanx/core/const/app_size.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';
import 'package:spanx/features/goals/controller/goals_controller.dart';

import '../../../core/global_widgets/goal_tracking_widget.dart';

class GoalsScreen extends StatelessWidget {
  GoalsScreen({super.key});

  final GoalsController goalsController = Get.put(GoalsController());

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.w(20),
            vertical: AppSizes.h(30),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // appbar
              Center(
                child: Text(
                  'Goals',
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: AppSizes.sp(24),
                    color: AppColors.greyColor70,
                  ),
                ),
              ),
              SizedBox(height: AppSizes.h(20)),
              // daily and calender
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: AppSizes.h(10),
                      horizontal: AppSizes.w(10),
                    ),
                    width: AppSizes.w(110),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(AppSizes.w(10)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Today',
                          style: AppFonts.spaceGrotesk.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: AppSizes.sp(15),
                            color: AppColors.whiteColor,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: AppSizes.h(25),
                          color: AppColors.whiteColor,
                        ),
                      ],
                    ),
                  ),
                  // calendar
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.w(10),
                      vertical: AppSizes.w(10),
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.whiteColor),
                      borderRadius: BorderRadius.circular(AppSizes.w(10)),
                      image: DecorationImage(
                        image: AssetImage(AppImages.bg_minicard),
                        fit: BoxFit.fill,
                      ),
                    ),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          AppIcons.calendar,
                          height: AppSizes.h(20),
                        ),
                        SizedBox(width: AppSizes.w(10)),
                        Text(
                          'Calender',
                          style: AppFonts.spaceGrotesk.copyWith(
                            // fontWeight: FontWeight.w700,
                            fontSize: AppSizes.sp(14),
                            color: AppColors.blackColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.h(20)),
              // cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _goalsDashboard('Completion\nRate', '85%')),
                  SizedBox(width: AppSizes.w(10)),
                  Expanded(child: _goalsDashboard('Priming\nStreak', '03')),
                  SizedBox(width: AppSizes.w(10)),
                  Expanded(child: _goalsDashboard('Day\nStreak', '07')),
                ],
              ),
              SizedBox(height: AppSizes.h(20)),

              _goalsButton("Start Priming >>", true, AppImages.priming),
              SizedBox(height: AppSizes.h(20)),
              _goalsButton("View Your Budget >>", false, AppImages.priming),
              SizedBox(height: AppSizes.h(20)),
              // task cards
              Obx( () {
                  return GoalTrackingWidget(
                    category: 'Daily',
                    priority: 'High Priority',
                    goalTitle: 'Complete 8 Client Sessions',
                    goalDes:
                        'Provide excellent service to all scheduled clients today',
                    dueDate: '12/05/2025',
                    clientTarget: 8,
                    totalWorked: 7,
                    totalBreak: 2,
                    completeGoal: 5, onPressed: () { 
                      goalsController.startYourDayClicked();
                  }, goalStarted: goalsController.isStartYourDayClicked.value, deleteOnTap: () {  },
                  );
                }
              ),
            ],
          ),
        ),
      ),
    );
  }
}



// this is the widget of Completion rate - Priming Streak - Day Streak
Widget _goalsDashboard(String title, String boldText) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: AppSizes.w(20),
      vertical: AppSizes.w(12),
    ),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.whiteColor),
      borderRadius: BorderRadius.circular(AppSizes.w(10)),
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
            fontSize: AppSizes.sp(14),
            color: AppColors.blackColor,
          ),
        ),
        SizedBox(height: AppSizes.h(5)),
        Text(
          boldText,
          style: AppFonts.spaceGrotesk.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: AppSizes.sp(25),
            color: AppColors.blackColor,
          ),
        ),
      ],
    ),
  );
}
// this is the widget of two buttons here start priming
Widget _goalsButton(String text, bool isImage, String? imgPath) {
  return GestureDetector(
    onTap: () {
      log('Button clicked');
    },
    child: Container(
      height: AppSizes.h(60),
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.w(20),
        vertical: AppSizes.w(12),
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.whiteColor),
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
