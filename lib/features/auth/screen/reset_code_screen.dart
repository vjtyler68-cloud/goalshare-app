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
import 'package:spanx/features/auth/controller/reset_code_controller.dart';
import 'package:spanx/features/auth/widget/heading_title_subtitle_widget.dart';


class ResetCodeScreen extends StatelessWidget {
  ResetCodeScreen({super.key});

  ResetCodeController resetCodeController = Get.put(ResetCodeController());
  final passedEmail = Get.arguments;

  @override
  Widget build(BuildContext context) {
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
                headingTitle: "Apply Reset Code",
                headingSubTitle:
                    "Please check your email. Give correct reset 6 digit code here.",
              ),
              SizedBox(height: AppSizes.h(30)),
              // otp box
              Pinput(
                length: 6,
                showCursor: true,
                controller: resetCodeController.pinController,
                // onCompleted: resetCodeController.onPinCompleted,
                obscureText: false,
                defaultPinTheme: PinTheme(
                  width: AppSizes.w(60),
                  height: AppSizes.h(60),
                  textStyle: TextStyle(
                    fontSize: AppSizes.sp(20),
                    color: AppColors.greyColor70,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.formBackgroundColor,
                    border: Border.all(
                      color: AppColors.greyColor70,
                      width: AppSizes.w(1),
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.h(15)),
                  ),
                ),
              ),
              SizedBox(height: AppSizes.h(30)),
              // button
              Obx(() {
                return resetCodeController.isLoading.value
                    ? LoadingAnimationWidget.staggeredDotsWave(
                        color: AppColors.primaryColor,
                        size: 30.h,
                      )
                    : CustomButtonWidget(
                  onTap: () {
                    if (resetCodeController.isPinEmpty()) {
                      resetCodeController.handleOTPVerification(
                        passedEmail,
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
                    fontSize: AppSizes.sp(16),
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
