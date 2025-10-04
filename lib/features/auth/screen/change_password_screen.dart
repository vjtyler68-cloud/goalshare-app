import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_size.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';
import 'package:spanx/core/global_widgets/custom_textfield_widget.dart';
import 'package:spanx/features/auth/controller/change_password_controller.dart';
import 'package:spanx/features/auth/controller/reset_code_controller.dart';
import 'package:spanx/features/auth/controller/reset_password_controller.dart';
import 'package:spanx/features/auth/widget/heading_title_subtitle_widget.dart';
import 'package:spanx/routes/app_routes.dart';

class ChangePasswordScreen extends StatelessWidget {
   ChangePasswordScreen({super.key});
   final passedEmail = Get.arguments;

  @override
  Widget build(BuildContext context) {
    ChangePasswordController changePasswordController = Get.put(
      ChangePasswordController(),
    );
    return BackgroundScreen(
      child: SafeArea(
        child: Padding(
          padding:EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // heading
              HeadingTitleSubtitleWidget(
                headingTitle: "Change Password",
                headingSubTitle:
                    "Please provide a valid and strong password here",
              ),
              SizedBox(height: AppSizes.h(30)),

              // old password
              Obx(() {
                return CustomTextFormWidget(
                  sectionTitle: 'Old Password',
                  hintText: 'enter password',
                  keyboardType: TextInputType.text,
                  isPassword: true,
                  isPasswordVisible:
                  !changePasswordController.isOldPasswordVisible.value,
                  onTogglePasswordVisibility:
                  changePasswordController.makeOldPasswordVisible,
                  textEditingController:
                  changePasswordController.oldPasswordController,
                );
              }),
              SizedBox(height: 10.h),

              // new password
              Obx(() {
                return CustomTextFormWidget(
                  sectionTitle: 'New Password',
                  hintText: 'enter password',
                  keyboardType: TextInputType.text,
                  isPassword: true,
                  isPasswordVisible:
                      !changePasswordController.isNewPasswordVisible.value,
                  onTogglePasswordVisibility:
                  changePasswordController.makeNewPasswordVisible,
                  textEditingController:
                  changePasswordController.newPasswordController,
                );
              }),
              SizedBox(height: 10.h),

              // confirm password
              Obx(() {
                return CustomTextFormWidget(
                  sectionTitle: 'Confirm Password',
                  hintText: 'enter password',
                  keyboardType: TextInputType.text,
                  isPassword: true,
                  isPasswordVisible:
                      !changePasswordController.isConfirmPasswordVisible.value,
                  onTogglePasswordVisibility:
                  changePasswordController.makeConfirmPasswordVisible,
                  textEditingController:
                  changePasswordController.confirmPasswordController,
                );
              }),

              SizedBox(height: 20.h),
              // button

          Obx(() {
                return changePasswordController.isLoading.value
                    ? LoadingAnimationWidget.staggeredDotsWave(
                        color: AppColors.primaryColor,
                        size: 30.h,
                      )
                    : CustomButtonWidget(onTap: () {
                // Get.offAllNamed(AppRoutes.loginScreen);

                  if(changePasswordController.isPasswordFilled()){
                    if(changePasswordController.isPassLengthOkay()){
                      if(changePasswordController.isPasswordDifferent()){
                        changePasswordController.handleResetPassword(passedEmail);
                      }
                      else{
                        Fluttertoast.showToast(
                          msg: "password can't be different",
                          backgroundColor: AppColors.redColor,
                        );
                      }
                    }else{
                      Fluttertoast.showToast(
                        msg: "minimum 8 digit password needed",
                        backgroundColor: AppColors.redColor,
                      );
                    }
                  }
                  else{
                    Fluttertoast.showToast(
                      msg: "Password fields can't be empty",
                      backgroundColor: AppColors.redColor,
                    );
                  }

                  changePasswordController.handleResetPassword(passedEmail);
              }, buttonText: 'Change Password');
              }),

              
            ],
          ),
        ),
      ),
    );
  }
}
