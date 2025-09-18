import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:get/route_manager.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_icons.dart';
import 'package:spanx/core/const/app_size.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';
import 'package:spanx/core/global_widgets/custom_textfield_widget.dart';
import 'package:spanx/core/global_widgets/oauth_button_widget.dart';
import 'package:spanx/features/auth/controller/login_controller.dart';
import 'package:spanx/features/auth/screen/forget_password_screen.dart';
import 'package:spanx/features/auth/widget/heading_title_subtitle_widget.dart';
import 'package:spanx/routes/app_routes.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    LoginController loginController = Get.put(LoginController());
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
                headingTitle: "Welcome Back",
                headingSubTitle:
                    "Log in to continue managing your clients and boosting your sales.",
              ),
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
                  hintText: 'enter password',
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
                  onPressed: () {
                    Get.toNamed(AppRoutes.forgetPasswordScreen);
                  },
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

              Obx((){
                return loginController.isLoading.value ? Center(child:
                  LoadingAnimationWidget.staggeredDotsWave(color: AppColors.primaryColor, size: 30.h)) :   CustomButtonWidget(
                  // onTap: () {
                  //   // Get.offNamed(AppRoutes.homeScreen);
                  //   Get.offNamed(AppRoutes.mainNavBarScreen);
                  // },
                  onTap: (){
                    loginController.handleLogin();
                    print(loginController.emailController.text);
                    print(loginController.passwordController.text);
                  },
                  buttonText: 'Continue',
                );
              }),



              SizedBox(height: AppSizes.h(20)),
              // don't have any account
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don’t have an account?",
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: AppSizes.sp(16),
                      color: AppColors.greyColor70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: AppSizes.w(10)),
                  GestureDetector(
                    onTap: () {
                      Get.toNamed(AppRoutes.signUpScreen);
                    },
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
    );
  }
}
