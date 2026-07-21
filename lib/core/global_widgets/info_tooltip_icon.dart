import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';

/// Small "?" icon that explains what a section is for. Tapping opens a short
/// bottom sheet with the explanation and a "Got it" button.
///
/// Used next to home-dashboard section headers (My Why, Affirmations,
/// Daily Spark) so new users understand each section without cluttering the UI.
class InfoTooltipIcon extends StatelessWidget {
  final String label;
  final String description;

  const InfoTooltipIcon({
    super.key,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showInfoSheet(context),
      behavior: HitTestBehavior.opaque,
      // Padding keeps the tap target comfortable without visually enlarging
      // the icon or disturbing the header's spacing.
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
        child: Icon(Icons.help_outline,
            size: 16.r, color: AppColors.primaryColor),
      ),
    );
  }

  void _showInfoSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 18.h),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            Text(
              label,
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xff1A1010),
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              description,
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 14.sp,
                height: 1.5,
                color: const Color(0xff6b6060),
              ),
            ),
            SizedBox(height: 22.h),
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.primaryColor,
                    AppColors.primaryDarkColor,
                  ]),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Center(
                  child: Text(
                    'Got it',
                    style: AppFonts.spaceGrotesk.copyWith(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
