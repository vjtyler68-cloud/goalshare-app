import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';

import '../../routes/app_routes.dart';
import '../const/app_colors.dart';
import '../const/app_fonts.dart';
import '../local/local_data.dart';

class ConfirmLogoutDialog extends StatelessWidget {
  const ConfirmLogoutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blackColor.withAlpha(35),
      child: Center(
        child: Container(
          width: 320.w,
          height: 200.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.r),
            color: const Color(0xffFFDCCD),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  textAlign: TextAlign.center,
                  textHeightBehavior: const TextHeightBehavior(),
                  'Really want to\n Log Out',
                  style: AppFonts.spaceGrotesk.copyWith(
                    color: AppColors.maroonColor,
                    fontSize: 30.sp,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                SizedBox(height: 30.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: CustomButtonWidget(
                        onTap: () {
                         Navigator.pop(context);
                        },
                        buttonText: 'Cancel',
                        bgColor: AppColors.greyColor70,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: CustomButtonWidget(
                        onTap: () {
                          LocalService localService = LocalService();
                          localService.clearUserData();
                          Get.offAllNamed(AppRoutes.loginScreen);
                        },
                        buttonText: 'Confirm',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Static method to show the popup
  static void show() {
    Get.dialog(ConfirmLogoutDialog(), barrierDismissible: false);
  }
}
