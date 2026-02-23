import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';
import 'package:spanx/features/profile_tab/controller/profile_tab_controller.dart';

import '../const/app_colors.dart';
import '../const/app_fonts.dart';

class ConfirmAccountDeleteDialog extends StatelessWidget {
  const ConfirmAccountDeleteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileTabController controller = Get.find<ProfileTabController>();
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
                  'Really want to\n Delete Account',
                  textAlign: TextAlign.center,
                  textHeightBehavior: const TextHeightBehavior(),
                  style: AppFonts.spaceGrotesk.copyWith(
                    color: AppColors.maroonColor,
                    fontSize: 30.sp,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                SizedBox(height: 30.h),
                Obx(() {
                  return controller.isAccountDeleteLoading.value
                      ? CircularProgressIndicator(color: AppColors.primaryColor)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: CustomButtonWidget(
                                onTap: () {
                                  Get.back();
                                },
                                buttonText: 'Cancel',
                                bgColor: AppColors.greyColor70,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: CustomButtonWidget(
                                onTap: () {
                                  controller.deleteAccount();
                                },
                                buttonText: 'Delete Account',
                              ),
                            ),
                          ],
                        );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Static method to show the popup
  static void show() {
    Get.dialog(const ConfirmAccountDeleteDialog(), barrierDismissible: false);
  }
}
