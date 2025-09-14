import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_images.dart';

import '../../../core/const/app_colors.dart';

class TaskCreatedSuccessful extends StatelessWidget {
  final VoidCallback onContinue;

  TaskCreatedSuccessful({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blackColor.withAlpha(35),
      child: Center(
        child: Container(
          width: 320.w,
          height: 300.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.r),
            color: Color(0xffFFDCCD),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(AppImages.star,height: 100.h),
                SizedBox(height: 10.h),
                Text(
                  textAlign: TextAlign.center,
                  textHeightBehavior: TextHeightBehavior(),
                  'Task Created Successfully!',
                  style: AppFonts.spaceGrotesk.copyWith(
                    color: AppColors.maroonColor,
                    fontSize: 30.sp,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  textAlign: TextAlign.center,
                  'Your task has been added. Stay on track and keep achieving your mission.',
                  style: AppFonts.spaceGrotesk.copyWith(
                    color: AppColors.blackColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Static method to show the popup
  static void show({required VoidCallback onContinue}) {
    Get.dialog(
      TaskCreatedSuccessful(onContinue: onContinue),
      barrierDismissible: false,
    );
  }
}
