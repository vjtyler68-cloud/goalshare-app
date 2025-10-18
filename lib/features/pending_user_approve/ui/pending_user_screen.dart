import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_images.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:flutter/material.dart';

class PendingUserScreen extends StatelessWidget {
  const PendingUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
        minimum: EdgeInsets.symmetric(horizontal: 15.w, vertical: 20.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AppImages.pending, height: 180.h),
            SizedBox(height: 10.h),
            Text(
              'Waiting for Approval',
              style: TextStyle(
                color: AppColors.primaryColor,
                fontSize: 30.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              'We’ve received your request! Our team is reviewing it carefully — you’ll be notified once it’s approved.',
              style: TextStyle(
                color: AppColors.greyColor70,
                fontSize: 18.sp,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
