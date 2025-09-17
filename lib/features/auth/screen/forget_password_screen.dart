import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/utils.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_size.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';
import 'package:spanx/core/global_widgets/custom_textfield_widget.dart';
import 'package:spanx/features/auth/controller/forgetpassword_controller.dart';
import 'package:spanx/features/auth/widget/heading_title_subtitle_widget.dart';
import 'package:spanx/routes/app_routes.dart';

class ForgetPasswordScreen extends StatelessWidget {
   ForgetPasswordScreen({super.key});
  final ForgetPasswordController forgetPasswordController = Get.put(ForgetPasswordController());

  @override
  Widget build(BuildContext context) {
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
              HeadingTitleSubtitleWidget(headingTitle: "Forget Password", headingSubTitle: "Enter your email here. Give valid email to reset your password",),
              SizedBox(height: AppSizes.h(30)),
              // email
              CustomTextFormWidget(
                sectionTitle: 'Email Address',
                hintText: 'email address',
                textEditingController: forgetPasswordController.forgetPasswordEditingController,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: AppSizes.h(30)),
              // button
              CustomButtonWidget(onTap: () {
               forgetPasswordController.handleForgetPassword();
              }, buttonText: 'Send Email'),
            ],
          ),
        ),
      ),
    );
  }
}
