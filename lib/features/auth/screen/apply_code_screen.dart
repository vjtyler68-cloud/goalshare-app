import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
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
    ApplyCodeController applyCodeController = Get.put(ApplyCodeController());
    return BackgroundScreen(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.w(30),
            vertical: AppSizes.h(30),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // heading
              HeadingTitleSubtitleWidget(
                headingTitle: "Apply Code Here",
                headingSubTitle:
                    "Please check your email. Give correct authentication code here.",
              ),
              SizedBox(height: AppSizes.h(30)),
              // otp box
              Pinput(
                length: 4,
                showCursor: true,
                controller: applyCodeController.pinController,
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
              CustomButtonWidget(onTap: () {
                applyCodeController.handleOTPVerification();
              }, buttonText: 'Apply Code'),
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
