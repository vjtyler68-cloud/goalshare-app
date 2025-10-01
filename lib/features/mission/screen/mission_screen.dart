import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_icons.dart';
import 'package:spanx/core/const/app_images.dart';
import 'package:spanx/core/const/app_size.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/features/mission_details/screen/mission_details_screen.dart'
    hide GoalPriority;
import 'package:spanx/routes/app_routes.dart';

import '../../../core/global_widgets/goal_tracking_widget.dart';
import '../../../core/alertdialogs/create_new_mission.dart';
import '../controller/mission_controller.dart';

class MissionScreen extends StatelessWidget {
  MissionScreen({super.key});

  final MissionController missionController = Get.find<MissionController>();

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // appbar
              Text(
                'Mission',
                style: AppFonts.spaceGrotesk.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: AppSizes.sp(30),
                  color: AppColors.greyColor70,
                ),
              ),
              SizedBox(height: AppSizes.h(20)),
              // daily and calender
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IntrinsicWidth(
                    child: Container(
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
              // // cards
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Expanded(child: _goalsDashboard('Completion\nRate', '85%')),
              //     SizedBox(width: AppSizes.w(10)),
              //     Expanded(child: _goalsDashboard('Priming\nStreak', '03')),
              //     SizedBox(width: AppSizes.w(10)),
              //     Expanded(child: _goalsDashboard('Day\nStreak', '07')),
              //   ],
              // ),
              // SizedBox(height: AppSizes.h(20)),

              // Progress
              Row(
                children: [
                  Text(
                    'Progress',
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: AppSizes.sp(18),
                      color: AppColors.greyColor70,
                    ),
                  ),
                  // Spacer(),
                  // Text(
                  //   'Today',
                  //   style: AppFonts.spaceGrotesk.copyWith(
                  //     fontWeight: FontWeight.w700,
                  //     fontSize: AppSizes.sp(18),
                  //     color: AppColors.greyColor70,
                  //   ),
                  // ),
                  // Icon(Icons.keyboard_arrow_down_rounded, size: AppSizes.h(30)),
                ],
              ),
              SizedBox(height: AppSizes.h(10)),

              // grids
              SizedBox(
                height: AppSizes.h(230),
                child: GridView(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSizes.w(10),
                    mainAxisSpacing: AppSizes.h(10),
                    childAspectRatio: 1.8,
                  ),
                  children: [
                    // all the widgets are written down of this file
                    _progressBackground(
                      _progressInfo(
                        'Sales',
                        AppImages.flame,
                        '500',
                        '(80% completed)',
                      ),
                    ),
                    _progressBackground(
                      _progressInfo(
                        'Client Sessions',
                        AppImages.handshake,
                        '10',
                        '(Total 16 Client)',
                      ),
                    ),
                    _progressBackground(
                      _progressInfo(
                        'Time Management',
                        AppImages.time,
                        '8.5Hr',
                        '(Total 9 hours)',
                      ),
                    ),
                    _progressBackground(
                      _addNewTask('ADD NEW MISSION', () {
                        // Get.toNamed(AppRoutes.motivationalNudgeScreen);
                        CreateNewMission.show();
                      }),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSizes.h(10)),
              _goalsButton(
                "View Your Budget >>",
                () {
                  Get.toNamed(AppRoutes.myBudgetScreen);
                },
                true,
                AppIcons.budget_trend,
              ),
              SizedBox(height: AppSizes.h(20)),

              // task cards
              Obx(() {
                final missions = missionController.getAllMissionList;
                // if (missions.isEmpty) {
                //   return Text("No Available data");
                // }
                return missionController.isLoading.value
                    ? Center(
                        child: LoadingAnimationWidget.staggeredDotsWave(
                          color: AppColors.primaryColor,
                          size: 30.h,
                        ),
                      )
                    : Column(
                        spacing: 10.h,
                        children: missions
                            .map(
                              (e) => GoalTrackingWidget(
                                category: e.category!,
                                priority: missionController.parsePriority(
                                  e.priority!,
                                ),
                                goalTitle: e.title!,
                                goalDes: e.description!,
                                dueDate: missionController.formatDate(
                                  e.dueDate!.toString(),
                                ),
                                clientTarget: e.clientTarget!,
                                totalWorked: e.reachedClientsTime!,
                                totalBreak: e.breakTimeSpent!,
                                completeGoal: e.clientsReachedCount!,
                                goalStarted: e.clients!.isNotEmpty,

                                /*
                                here the logic implemented like this:
                                if the mission has clients, then the card can be tappable
                                otherwise it will only show 'START YOUR DAY'
                                 */
                                cardOnTap: () {
                                  e.clients!.isNotEmpty
                                      ? Get.to(
                                          () => MissionDetailsScreen(),
                                          arguments: e.id,
                                        )
                                      : null;
                                },
                                deleteOnTap: () {
                                  missionController.deleteMotivation(e.id!);
                                },
                                onPressed: () {
                                  e.clients!.isNotEmpty
                                      ? null
                                      : Get.to(
                                          () => MissionDetailsScreen(),
                                          arguments: e.id,
                                        );
                                },
                              ),
                            )
                            .toList(),
                      );
              }),

              // Obx(() {
              //   return GoalTrackingWidget(
              //     category: 'Daily',
              //     priority: GoalPriority.MEDIUM,
              //     goalTitle: 'Complete 8 Client Sessions',
              //     goalDes:
              //         'Provide excellent service to all scheduled clients today',
              //     dueDate: '12/05/2025',
              //     clientTarget: 8,
              //     totalWorked: 7,
              //     totalBreak: 2,
              //     completeGoal: 5,
              //     onPressed: () {
              //       goalsController.startYourDayClicked();
              //     },
              //     goalStarted: goalsController.isStartYourDayClicked.value,
              //     deleteOnTap: () {
              //
              //     },
              //     cardOnTap: (){Get.to(() => MissionDetailsScreen());},
              //   );
              // }),
              SizedBox(height: 80.h),
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
    padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 12.w),
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
Widget _goalsButton(
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

Widget _progressInfo(
  String heading,
  String iconPath,
  String title,
  String subtitle,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // title
      Text(
        heading,
        style: AppFonts.spaceGrotesk.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: AppSizes.sp(15),
          color: AppColors.greyColor70,
        ),
      ),
      SizedBox(height: AppSizes.h(10)),
      // row
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: AppSizes.h(30),
            child: Image.asset(iconPath, fit: BoxFit.cover),
          ),
          SizedBox(width: AppSizes.w(5)),
          Text(
            title,
            style: AppFonts.spaceGrotesk.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: AppSizes.sp(18),
              color: AppColors.greyColor70,
            ),
          ),
          SizedBox(width: AppSizes.w(5)),
          Text(
            subtitle,
            style: AppFonts.spaceGrotesk.copyWith(
              // fontWeight: FontWeight.bold,
              fontSize: AppSizes.sp(9),
              color: AppColors.blackColor,
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _progressBackground(Widget widget) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: AppSizes.w(6),
      vertical: AppSizes.w(15),
    ),
    width: AppSizes.w(220),
    decoration: BoxDecoration(
      image: DecorationImage(
        image: AssetImage(AppImages.bg_minicard),
        fit: BoxFit.fill,
      ),
      // color: AppColors.lightPinkColor,
      borderRadius: BorderRadius.circular(AppSizes.w(15)),
    ),
    child: widget,
  );
}

Widget _addNewTask(String title, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 20.h,
          child: Image.asset(AppImages.add, fit: BoxFit.cover),
        ),
        SizedBox(width: 5.w),
        // Image.asset(AppImages.add),
        Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.spaceGrotesk.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 12.sp,
            color: AppColors.greyColor70,
          ),
        ),
      ],
    ),
  );
}
