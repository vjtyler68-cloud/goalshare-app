import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:pinput/pinput.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_size.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';
import 'package:spanx/features/auth/controller/apply_code_controller.dart';
import 'package:spanx/features/auth/widget/heading_title_subtitle_widget.dart';


class ApplyCodeScreen extends StatelessWidget {
  const ApplyCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = Get.arguments as Map<String, dynamic>;
    final passedEmail = arguments['email'] ?? "";
    final fullName = arguments['fullName'] ?? "";
    ApplyCodeController applyCodeController = Get.put(ApplyCodeController());
    return BackgroundScreen(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 50.h),
              // heading
              HeadingTitleSubtitleWidget(
                headingTitle: "Apply Code Here",
                headingSubTitle:
                    "Please check your email. Give correct authentication code here.",
              ),
              SizedBox(height: 25.h),
              // otp box
              Pinput(
                length: 6,
                showCursor: true,
                controller: applyCodeController.pinController,
                // onCompleted: resetCodeController.onPinCompleted,
                obscureText: false,
                defaultPinTheme: PinTheme(
                  width: 40.w,
                  height: 40.h,
                  textStyle: TextStyle(
                    fontSize: 20.sp,
                    color: AppColors.greyColor70,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.formBackgroundColor,
                    border: Border.all(
                      color: AppColors.greyColor70,
                      width: 1.w,
                    ),
                    borderRadius: BorderRadius.circular(13.r),
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // button
              Obx(() {
                return applyCodeController.isLoading.value
                    ? LoadingAnimationWidget.staggeredDotsWave(
                        color: AppColors.primaryColor,
                        size: 30.h,
                      )
                    : CustomButtonWidget(
                        onTap: () {
                          if (applyCodeController.isPinEmpty()) {
                            applyCodeController.handleOTPVerification(
                              passedEmail,
                              fullName,
                            );
                          } else {
                            Fluttertoast.showToast(
                              msg: "Please enter a 6-digit OTP.",
                              backgroundColor: AppColors.redColor,
                            );
                          }
                        },
                        buttonText: 'Apply Code',
                      );
              }),

              SizedBox(height: AppSizes.h(10)),
              // button
              TextButton(
                onPressed: () {},
                child: Text(
                  'Send Again',
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 14.sp,
                    color: AppColors.blackColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
