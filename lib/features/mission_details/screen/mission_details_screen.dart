import 'dart:developer';
import 'package:shimmer/shimmer.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:spanx/core/alertdialogs/create_my_why_dialog.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';
import 'package:spanx/core/global_widgets/subpage_appbar_widget.dart';
import 'package:spanx/core/alertdialogs/create_new_customer_screen.dart';
import 'package:spanx/features/customer_details/ui/customer_details_page.dart';
import 'package:spanx/features/mission/controller/mission_controller.dart';
import 'package:spanx/features/mission_details/controller/mission_details_controller.dart';
import 'package:spanx/routes/app_routes.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/const/app_fonts.dart';
import '../../../core/const/app_icons.dart';
import '../../../core/const/app_images.dart';
import '../../../core/const/app_size.dart';
import '../../../core/const/enums.dart';
import '../../../core/global_widgets/goal_tracking_widget.dart';

class MissionDetailsScreen extends StatelessWidget {
  MissionDetailsScreen({super.key});

  final MissionDetailsController missionDetailsController = Get.put(
    MissionDetailsController(),
  );
  final missionID = Get.arguments;

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

  String getClientStatus(SalesStatus salesStatus) => switch (salesStatus) {
    SalesStatus.PENDING => "Mark as Reached",
    SalesStatus.REACHED => "Mark as Talked",
    SalesStatus.TALKED_TO => "Mark as Completed",
    SalesStatus.COMPLETED => "Success",
  };

  String sendClientStatus(SalesStatus salesStatus) => switch (salesStatus) {
    SalesStatus.PENDING => "REACHED",
    SalesStatus.REACHED => "TALKED_TO",
    SalesStatus.TALKED_TO => "COMPLETED",
    SalesStatus.COMPLETED => "",
  };

  Color getClientColor(SalesStatus salesStatus) => switch (salesStatus) {
    SalesStatus.PENDING => AppColors.greyColor70,
    SalesStatus.REACHED => AppColors.blueColor,
    SalesStatus.TALKED_TO => AppColors.primaryColor,
    SalesStatus.COMPLETED => AppColors.greenColor,
  };

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: Obx(() {
            final mission = missionDetailsController.missionDetails.value;
            final priority = missionDetailsController.parsePriority(
              mission?.priority.toString(),
            );

            return missionDetailsController.isLoading.value
                ? Center(
                    child: LoadingAnimationWidget.staggeredDotsWave(
                      color: AppColors.primaryColor,
                      size: 30.h,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //  app bar
                      SubPageAppbarWidget(
                        appbarTitle: 'Mission Details',
                        onPressed: () {
                          Get.back();
                          Get.find<MissionController>().fetchMission();
                        },
                      ),
                      SizedBox(height: 15.w),
                      // goal tracking card
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 15.w,
                          vertical: 20.w,
                        ),
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
                                  mission!.category ?? "",
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
                                      priority,
                                    ).withAlpha(20),
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Text(
                                    "${getPriorityText(priority)} Priority",
                                    style: AppFonts.spaceGrotesk.copyWith(
                                      color: getPriorityColor(priority),
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
                              mission.title ?? "",
                              style: AppFonts.spaceGrotesk.copyWith(
                                color: AppColors.greyColor70,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 5.h),
                            // goal description
                            Text(
                              mission.description ?? "",
                              style: AppFonts.spaceGrotesk.copyWith(
                                color: AppColors.greyColor70,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 5.h),
                            // due date
                            Row(
                              children: [
                                SvgPicture.asset(AppIcons.calendar),
                                SizedBox(width: 5.w),
                                Text(
                                  'Due Date: ${missionDetailsController.formatDate(mission.dueDate.toString())}',
                                  style: AppFonts.spaceGrotesk.copyWith(
                                    color: AppColors.greyColor70,
                                    fontSize: 13.sp,
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
                                    fontSize: 10.sp,
                                  ),
                                ),
                                Text(
                                  '${mission.totalReached}/${mission.clientTarget ?? ""}',
                                  style: AppFonts.spaceGrotesk.copyWith(
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5.h),
                            LinearProgressIndicator(
                              backgroundColor: AppColors.whiteColor,
                              value:
                                  mission.totalReached! / mission.clientTarget!,
                              color: AppColors.maroonColor,
                              borderRadius: BorderRadius.circular(13.w),
                              minHeight: 5.h,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10.h),

                      // cards
                      Obx(() {
                        final mission =
                            missionDetailsController.missionDetails.value;

                        if (mission == null) {
                          return CircularProgressIndicator(); // or placeholder
                        }

                        return IntrinsicHeight(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: _goalsDetailsDashboard(
                                  'Client Reached',
                                  '${mission.totalReached ?? 0}', // null safe with default 0
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: _goalsDetailsDashboard(
                                  'Talked With Client',
                                  '${mission.totalTalkedTo ?? 0}',
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: _goalsDetailsDashboard(
                                  'Complete Sales',
                                  '${mission.salesCompletedCount ?? 0}',
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      SizedBox(height: 10.h),
                      (mission.clients!.length != mission.clientTarget)
                          ? _createSectionTextButton(
                              title: 'Time spend with client',
                              buttonText: 'Create',
                              ontap: () {
                                CreateNewCustomerScreen.show(onContinue: () {});
                              },
                            )
                          : _createSectionTextButton(
                              title: 'Time spend with client',
                              buttonText: 'Completed',
                              ontap: () {},
                            ),
                      SizedBox(height: 10.h),

                      // grids
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1.3,
                            ),
                        itemCount: mission.clients!.length,
                        itemBuilder: (context, index) {
                          return Obx(() {
                            return _clientDetailsBackground(
                              widget: _clientDetails(
                                clientName: "${mission.clients![index].name}",
                                // mission.clients![index].timeSpent ?? 0,
                                minutes: missionDetailsController
                                    .formattedClientTime(
                                      mission.clients![index].timeSpent!,
                                    ),
                                // minutes: int.parse(
                                //   missionDetailsController.formattedClientTime(
                                //     mission.clients![index].timeSpent!,
                                //   ),
                                // ),
                                ontap: () {
                                  Get.toNamed(
                                    AppRoutes.customerDetailsScreen,
                                    arguments: mission.clients!.first.id,
                                  );
                                },
                                buttonText: "View Details",
                              ),
                              isSelected:
                                  missionDetailsController
                                      .selectedClientIndex
                                      .value ==
                                  index,
                              ontap: () {
                                missionDetailsController.changeClientIndex(
                                  index,
                                );
                              },
                            );
                          });
                        },
                      ),
                      SizedBox(height: 10.h),
                      Obx(() {
                        final clientList = mission.clients;
                        final index =
                            missionDetailsController.selectedClientIndex.value;

                        if (clientList == null ||
                            clientList.isEmpty ||
                            index >= clientList.length) {
                          return SizedBox.shrink();
                        }

                        return TimeCalculationWidget(
                          title: clientList[index].name ?? "",
                          subTitle: "",
                          value: missionDetailsController.progress,
                          timeText: missionDetailsController.formattedTime,
                          resetOnTap: missionDetailsController.resetTimer,
                          saveOnTap: () {
                            missionDetailsController.saveTimer(
                              clientList[index].id!,
                              missionDetailsController.seconds.value,
                            );
                          },
                          playPause: missionDetailsController.toggleTimer,
                          icon: missionDetailsController.isRunning.value
                              ? Icons.pause
                              : Icons.play_arrow,
                        );
                      }),

                      SizedBox(height: 10.h),

                      // Sales Status
                      Text(
                        'Sales Status',
                        style: AppFonts.spaceGrotesk.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15.sp,
                          color: AppColors.greyColor70,
                        ),
                      ),
                      SizedBox(height: 15.h),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 1.3,
                            ),
                        itemCount: mission.clients!.length,
                        itemBuilder: (context, index) {
                          return Obx(() {
                            return _clientDetailsBackground(
                              widget: _clientDetails(
                                // client Name
                                clientName: "${mission.clients![index].name}",
                                // client time
                                minutes: missionDetailsController
                                    .formattedClientTime(
                                      mission.clients![index].timeSpent!,
                                    ),
                                // client status button
                                ontap:
                                    getClientStatus(
                                          missionDetailsController
                                              .parseSalesStatus(
                                                mission.clients![index].status
                                                    .toString(),
                                              ),
                                        ) ==
                                        "Success"
                                    ? () {}
                                    : () {
                                        // log("complete task AGO");
                                        // log(
                                        //   "2 ---- ${missionDetailsController.parseSalesStatus(mission.clients![index].status.toString())}",
                                        // );
                                        //
                                        // log(
                                        //   "3--- ${mission.clients![index].status.toString()}",
                                        // );
                                        missionDetailsController
                                            .updateSalesStatus(
                                              // client id
                                              mission.clients![index].id!,
                                              // status
                                              sendClientStatus(
                                                missionDetailsController
                                                    .parseSalesStatus(
                                                      mission
                                                          .clients![index]
                                                          .status
                                                          .toString(),
                                                    ),
                                              ),
                                            );
                                        // log("complete task AFTER");
                                        // log(
                                        //   "2 ---- ${missionDetailsController.parseSalesStatus(mission.clients![index].status.toString())}",
                                        // );
                                        //
                                        // log(
                                        //   "3--- ${mission.clients![index].status.toString()}",
                                        // );
                                      },

                                // client status text
                                buttonText: getClientStatus(
                                  missionDetailsController.parseSalesStatus(
                                    mission.clients![index].status.toString(),
                                  ),
                                ),
                              ),
                              isSelected:
                                  missionDetailsController
                                      .selectedClientIndex
                                      .value ==
                                  index,
                              ontap: () {
                                missionDetailsController.changeClientIndex(
                                  index,
                                );
                              },
                            );
                          });
                        },
                      ),
                      SizedBox(height: 10.h),

                      // my why
                      _createSectionTextButton(
                        title: 'My Why',
                        buttonText: 'Create New',
                        ontap: () {
                          CreateMyWhyDialog.show(
                            'My Why',
                            missionDetailsController.myWhyAffirmation,
                            missionDetailsController.isLoading,
                            () {
                               missionDetailsController.createMyWhy();

                            },
                          );
                        },
                      ),
                      SizedBox(height: 10.h),
                      Container(
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
                            mission.myWhies!.length,
                            (index) => Text(
                              '${index + 1}. ${mission.myWhies![index].text}',
                              style: AppFonts.spaceGrotesk.copyWith(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Affirmations
                      _createSectionTextButton(
                        title: 'Affirmations',
                        buttonText: 'Create New',
                        ontap: () {
                          CreateMyWhyDialog.show(
                            'Affirmations',
                            missionDetailsController.myWhyAffirmation,
                            missionDetailsController.isLoading,
                                () {
                              missionDetailsController.createAffirmation();

                            },
                          );
                        },
                      ),
                      SizedBox(height: 20.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 15.h,
                        ),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.whiteColor.withAlpha(400),
                          // image: DecorationImage(
                          //   image: AssetImage(AppImages.bg_minicard),
                          //   fit: BoxFit.fill,
                          // ),
                          borderRadius: BorderRadius.circular(AppSizes.w(15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(
                            mission.affirmations!.length,
                            (index) => Text(
                              '${index + 1}. ${mission.affirmations![index].text}',
                              style: AppFonts.spaceGrotesk.copyWith(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // client time calculation
                      Obx(() {
                        return missionDetailsController.isBreakLoading.value
                            ? Center(
                                child: LoadingAnimationWidget.fourRotatingDots(
                                  color: AppColors.primaryColor,
                                  size: 30.h,
                                ),
                              )
                            : TimeCalculationWidget(
                                title: 'Break',
                                value: missionDetailsController.breakProgress,
                                timeText:
                                    missionDetailsController.formattedBreakTime,
                                resetOnTap:
                                    missionDetailsController.resetBreakTimer,
                                saveOnTap: () {
                                  missionDetailsController.saveBreakTimer(
                                    missionDetailsController.secondsBreak.value,
                                  );
                                },
                                playPause:
                                    missionDetailsController.toggleBreakTimer,
                                icon:
                                    missionDetailsController
                                        .isRunningBreak
                                        .value
                                    ? Icons.pause
                                    : Icons.play_arrow,
                              );
                      }),
                      SizedBox(height: 20.h),

                      // end your day button
                      CustomButtonWidget(
                        onTap: () {
                          Get.back();
                        },
                        buttonText: 'End Your Day',
                      ),
                    ],
                  );
          }),
        ),
      ),
    );
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

  Widget _clientDetailsBackground({
    required Widget widget,
    required bool isSelected,
    required VoidCallback ontap,
  }) {
    return GestureDetector(
      onTap: ontap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 14.h),
        width: 200.w,
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.maroonColor : AppColors.whiteColor,
          ),
          // image: DecorationImage(
          //   image: AssetImage(AppImages.bg_minicard),
          //   fit: BoxFit.fill,
          // ),
          color: AppColors.whiteColor.withAlpha(400),
          borderRadius: BorderRadius.circular(13.r),
        ),
        child: widget,
      ),
    );
  }

  Widget _clientDetails({
    required String clientName,
    required String minutes,
    required VoidCallback ontap,
    required String buttonText,
  }) {
    return Column(
      children: [
        Text(
          clientName,
          style: AppFonts.spaceGrotesk.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 12.sp,
            color: AppColors.blackColor,
          ),
        ),
        SizedBox(height: 5.h),
        Text(
          minutes,
          style: AppFonts.spaceGrotesk.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
            color: AppColors.blackColor,
          ),
        ),
        SizedBox(height: 5.h),
        SizedBox(
          // width: 20.w,
          height: 20.h,
          child: ElevatedButton(
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
        ),
      ],
    );
  }

  Widget buildButton({required String text, required VoidCallback onTap}) {
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
    required this.playPause,
    required this.icon,
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
        // image: DecorationImage(
        //   image: AssetImage(AppImages.bg_minicard),
        //   fit: BoxFit.cover,
        // ),
        color: AppColors.whiteColor.withAlpha(400),
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
                    border: Border.all(color: AppColors.primaryColor, width: 2),
                  ),
                  child: Icon(icon, color: AppColors.primaryColor, size: 28),
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
