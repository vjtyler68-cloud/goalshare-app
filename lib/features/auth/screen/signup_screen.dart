import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_size.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';
import 'package:spanx/core/global_widgets/custom_textfield_widget.dart';
import 'package:spanx/core/global_widgets/oauth_button_widget.dart';
import 'package:spanx/features/auth/controller/signup_controller.dart';
import 'package:spanx/features/auth/widget/heading_title_subtitle_widget.dart';
import 'package:spanx/routes/app_routes.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SignupController signupController = Get.put(SignupController());
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
                headingTitle: "Create an Account",
                headingSubTitle: "",
              ),
              // SizedBox(height: AppSizes.h(10)),
              // full name
              CustomTextFormWidget(
                sectionTitle: "Full Name",
                hintText: 'full name',
                textEditingController: signupController.fullNameTextController,
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: AppSizes.h(15)),
              // Email Address
              CustomTextFormWidget(
                sectionTitle: "Email Address",
                hintText: 'email address',
                textEditingController: signupController.emailTextController,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: AppSizes.h(15)),
              // Password
              Obx(() {
                return CustomTextFormWidget(
                  sectionTitle: "Password",
                  hintText: 'enter password',
                  keyboardType: TextInputType.text,

                  textEditingController:
                      signupController.passwordTextController,
                  isPasswordVisible: !signupController.isPasswordVisible.value,
                  onTogglePasswordVisibility:
                      signupController.makePasswordVisible,
                  isPassword: true,
                );
              }),
              SizedBox(height: AppSizes.h(15)),
              // Confirm Password
              Obx(() {
                return CustomTextFormWidget(
                  sectionTitle: "Confirm Password",
                  hintText: 'enter password',
                  keyboardType: TextInputType.text,
                  textEditingController:
                      signupController.confirmPasswordTextController,
                  isPassword: true,
                  isPasswordVisible:
                      !signupController.isConfirmPasswordVisible.value,
                  onTogglePasswordVisibility:
                      signupController.makeConfirmPasswordVisible,
                );
              }),
              SizedBox(height: AppSizes.h(10)),

              // terms and condition text
              RichText(
                textAlign: TextAlign.start,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text:
                          "By continuing, you confirm that you are 18 years or older and agree to our ",
                      style: AppFonts.spaceGrotesk.copyWith(
                        color: AppColors.greyColor70,
                        fontSize: AppSizes.sp(12),
                      ),
                    ),
                    TextSpan(
                      text: "Terms & Conditions ",
                      style: AppFonts.spaceGrotesk.copyWith(
                        color: AppColors.primaryColor,
                        fontSize: AppSizes.sp(12),
                      ),
                    ),
                    TextSpan(
                      text: "and ",
                      style: AppFonts.spaceGrotesk.copyWith(
                        color: AppColors.greyColor70,
                        fontSize: AppSizes.sp(12),
                      ),
                    ),
                    TextSpan(
                      text: "Privacy Policy.",
                      style: AppFonts.spaceGrotesk.copyWith(
                        color: AppColors.primaryColor,
                        fontSize: AppSizes.sp(12),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSizes.h(20)),

              // button
              CustomButtonWidget(onTap: () {
                Get.offNamed(AppRoutes.setUpProfileScreen);
              }, buttonText: "Continue"),
              SizedBox(height: AppSizes.h(20)),

              // already have account
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account?",
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: AppSizes.sp(16),
                      color: AppColors.greyColor70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: AppSizes.w(10)),
                  GestureDetector(
                    onTap: () {
                      Get.offNamed(AppRoutes.loginScreen);
                    },
                    child: Text(
                      'Log in',
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: AppSizes.sp(16),
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.h(30)),

              // google oAuth
              OAuthButtonWidget(onPressed: () {}),
            ],
          ),
        ),
      ),
    );
  }
}
