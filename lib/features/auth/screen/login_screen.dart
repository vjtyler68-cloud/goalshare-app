import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:get/route_manager.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_icons.dart';
import 'package:spanx/core/const/app_size.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';
import 'package:spanx/core/global_widgets/custom_textfield_widget.dart';
import 'package:spanx/core/global_widgets/oauth_button_widget.dart';
import 'package:spanx/features/auth/controller/login_controller.dart';
import 'package:spanx/features/auth/widget/heading_title_subtitle_widget.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    LoginController loginController = Get.put(LoginController());
    return BackgroundScreen(
      child: SingleChildScrollView(
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
                HeadingTitleSubtitleWidget(),
                SizedBox(height: AppSizes.h(30)),
                // email
                CustomTextFormWidget(
                  sectionTitle: 'Email Address',
                  hintText: 'email address',
                  textEditingController: loginController.emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: AppSizes.h(15)),
                // password
                Obx(() {
                  return CustomTextFormWidget(
                    sectionTitle: 'Password',
                    hintText: '148568',
                    keyboardType: TextInputType.text,
                    isPassword: true,
                    isPasswordVisible: !loginController.isPasswordVisible.value,
                    onTogglePasswordVisibility:
                        loginController.makePasswordVisible,
                    textEditingController: loginController.passwordController,
                  );
                }),
                // forgot password
                Align(
                  alignment: AlignmentGeometry.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      'Forgot Password',
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: AppSizes.sp(16),
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSizes.h(30)),
                // button
                CustomButtonWidget(onTap: () {}, buttonText: 'Continue'),
                SizedBox(height: AppSizes.h(20)),
                // don't have any account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don’t have an account?",
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: AppSizes.sp(16),
                        color: AppColors.greyColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: AppSizes.w(10)),
                    GestureDetector(
                      onTap: () {},
                      child: Text(
                        'Register',
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
      ),
    );
  }
}
