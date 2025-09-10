import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/goal_tracking_widget.dart';
import 'package:spanx/core/global_widgets/subpage_appbar_widget.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/const/app_fonts.dart';
import '../../../core/const/app_images.dart';

class GoalDetailsScreen extends StatelessWidget {
   GoalDetailsScreen({super.key});
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
    return BackgroundScreen(child: SafeArea(child: SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: 20.w,
        vertical: 30.h,
      ),
      child: Column(
        children: [
          //  app bar
          SubPageAppbarWidget(appbarTitle: 'Goal Details', onPressed: (){}),
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
                        border: Border.all(color: AppColors.whiteColor.withAlpha(90)),
                        color: getPriorityColor(GoalPriority.HIGH).withAlpha(20),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        "${getPriorityText(GoalPriority.HIGH)} Priority",
                        style: AppFonts.spaceGrotesk.copyWith(
                          color: getPriorityColor(GoalPriority.HIGH),
                          fontSize: 15.sp,
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
                      'Due Date: $dueDate',
                      style: AppFonts.spaceGrotesk.copyWith(
                        color: AppColors.greyColor70,
                        fontSize: AppSizes.w(16),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                // there will a be a condition. if user click on 'Start Your Day' button it will redirect to a new page
                // and this button will disappear and few new infos will appear.
                !goalStarted ?   Padding(
                  padding: EdgeInsets.only(top: AppSizes.h(20)),
                  child: CustomButtonWidget(
                    onTap: onPressed,
                    buttonText: 'Start Your Day',
                  ),
                ) : SizedBox(),

                // total works an rest of the linear progress part here
                goalStarted ?
                Column(
                  children: [
                    SizedBox(height: AppSizes.h(5)),
                    // total worked
                    Row(
                      children: [
                        SvgPicture.asset(AppIcons.totalworked),
                        SizedBox(width: AppSizes.w(10)),
                        Text(
                          'Total Worked- $totalWorked Hours',
                          style: AppFonts.spaceGrotesk.copyWith(
                            color: AppColors.greyColor70,
                            fontSize: AppSizes.w(16),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // total break
                    SizedBox(height: AppSizes.h(5)),
                    Row(
                      children: [
                        SvgPicture.asset(AppIcons.totalbreak),
                        SizedBox(width: AppSizes.w(10)),
                        Text(
                          'Total Break Taken: $totalBreak Hours',
                          style: AppFonts.spaceGrotesk.copyWith(
                            color: AppColors.greyColor70,
                            fontSize: AppSizes.w(16),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSizes.h(20)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: AppSizes.sp(15),
                          ),
                        ),
                        Text(
                          '$completeGoal/$clientTarget',
                          style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: AppSizes.sp(15),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSizes.h(10)),
                    LinearProgressIndicator(
                      backgroundColor: AppColors.whiteColor,
                      value: completeGoal / clientTarget,
                      color: getPriorityColor(priority),
                      borderRadius: BorderRadius.circular(AppSizes.w(15)),
                      minHeight: AppSizes.h(8),
                    ),
                  ],
                ) : SizedBox(),
              ],
            ),
          ),

          //
          SizedBox(height: 20.h),
          // cards
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _goalsDetailsDashboard('Client Reached', '06')),
                SizedBox(width: 10.w),
                Expanded(child: _goalsDetailsDashboard('Talked With Client', '03')),
                SizedBox(width: 10.w),
                Expanded(child: _goalsDetailsDashboard('Complete Sales', '07')),
              ],
            ),
          ),
          SizedBox(height: 20.h),

        ],
      ),
    )));
  }
}

// this is the widget of Client Reached - Talked With Client - Complete Sales
Widget _goalsDetailsDashboard(String title, String boldText) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: 20.w,
      vertical: 12.h,
    ),
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
enum GoalPriority {
  HIGH,
  MEDIUM,
  LOW,
}