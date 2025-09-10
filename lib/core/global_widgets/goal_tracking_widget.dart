import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../const/app_colors.dart';
import '../const/app_fonts.dart';
import '../const/app_icons.dart';
import '../const/app_images.dart';
import '../const/app_size.dart';
import 'custom_button_widget.dart';

class GoalTrackingWidget extends StatelessWidget {

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


  final String category;
  // final String priority;
  final GoalPriority priority;
  final String goalTitle;
  final String goalDes;
  final String dueDate;
  final int clientTarget;
  final int totalWorked;
  final int totalBreak;
  final int completeGoal;
  final bool goalStarted;
  final VoidCallback onPressed;
  final VoidCallback deleteOnTap;
  final VoidCallback cardOnTap;

  const GoalTrackingWidget({
    super.key,
    required this.category,
    required this.priority,
    required this.goalTitle,
    required this.goalDes,
    required this.dueDate,
    required this.clientTarget,
    required this.totalWorked,
    required this.totalBreak,
    required this.completeGoal, required this.goalStarted,
    required this.onPressed,
    required this.deleteOnTap, required this.cardOnTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: cardOnTap,
      child:
      Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.w(15),
          vertical: AppSizes.w(20),
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
                  category,
                  style: AppFonts.spaceGrotesk.copyWith(
                    color: AppColors.greyColor70,
                    fontSize: AppSizes.w(18),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: AppSizes.w(15)),
                Container(
                  padding: EdgeInsets.all(AppSizes.w(10)),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.whiteColor.withAlpha(90)),
                    color: getPriorityColor(priority).withAlpha(20),
                    borderRadius: BorderRadius.circular(AppSizes.w(20)),
                  ),
                  child: Text(
                    "${getPriorityText(priority)} Priority",
                    style: AppFonts.spaceGrotesk.copyWith(
                      color: getPriorityColor(priority),
                      fontSize: AppSizes.w(15),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Spacer(),
                GestureDetector(
                    onTap: deleteOnTap,
                    child: CircleAvatar(child: Image.asset(AppImages.delete))),
              ],
            ),
            SizedBox(height: AppSizes.h(20)),
            // goal title
            Text(
              goalTitle,
              style: AppFonts.spaceGrotesk.copyWith(
                color: AppColors.greyColor70,
                fontSize: AppSizes.w(18),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: AppSizes.h(10)),
            // goal description
            Text(
              goalDes,
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
    );
  }
}

 enum GoalPriority {
  HIGH,
  MEDIUM,
  LOW,
}