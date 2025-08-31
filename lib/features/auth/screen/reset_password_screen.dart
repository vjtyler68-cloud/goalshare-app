import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_size.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';
import 'package:spanx/core/global_widgets/custom_textfield_widget.dart';
import 'package:spanx/features/auth/controller/reset_code_controller.dart';
import 'package:spanx/features/auth/controller/reset_password_controller.dart';
import 'package:spanx/features/auth/widget/heading_title_subtitle_widget.dart';
import 'package:spanx/routes/app_routes.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    ResetPasswordController resetPasswordController = Get.put(
      ResetPasswordController(),
    );
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
                headingTitle: "Reset Password",
                headingSubTitle:
                    "Please provide a valid and strong password here",
              ),
              SizedBox(height: AppSizes.h(30)),

              // new password
              Obx(() {
                return CustomTextFormWidget(
                  sectionTitle: 'New Password',
                  hintText: 'enter password',
                  keyboardType: TextInputType.text,
                  isPassword: true,
                  isPasswordVisible:
                      !resetPasswordController.isNewPasswordVisible.value,
                  onTogglePasswordVisibility:
                      resetPasswordController.makeNewPasswordVisible,
                  textEditingController:
                      resetPasswordController.newPasswordController,
                );
              }),
              SizedBox(height: AppSizes.h(20)),

              // confirm password
              Obx(() {
                return CustomTextFormWidget(
                  sectionTitle: 'Confirm Password',
                  hintText: 'enter password',
                  keyboardType: TextInputType.text,
                  isPassword: true,
                  isPasswordVisible:
                      !resetPasswordController.isConfirmPasswordVisible.value,
                  onTogglePasswordVisibility:
                      resetPasswordController.makeConfirmPasswordVisible,
                  textEditingController:
                      resetPasswordController.confirmPasswordController,
                );
              }),

              SizedBox(height: AppSizes.h(30)),
              // button
              CustomButtonWidget(onTap: () {
                Get.offAllNamed(AppRoutes.loginScreen);
              }, buttonText: 'Reset Password'),
            ],
          ),
        ),
      ),
    );
  }
}
