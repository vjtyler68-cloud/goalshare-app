import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:spanx/core/global_widgets/app_back_button.dart';
import 'package:get/utils.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_size.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';
import 'package:spanx/core/global_widgets/custom_textfield_widget.dart';
import 'package:spanx/features/auth/controller/forgetpassword_controller.dart';
import 'package:spanx/features/auth/widget/heading_title_subtitle_widget.dart';


class ForgetPasswordScreen extends StatelessWidget {
  ForgetPasswordScreen({super.key});

  final ForgetPasswordController forgetPasswordController = Get.put(
    ForgetPasswordController(),
  );

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
              AppBackButton(),
              SizedBox(height: 50.h),
              // heading
              HeadingTitleSubtitleWidget(
                headingTitle: "Forget Password",
                headingSubTitle:
                    "Enter your email here. Give valid email to reset your password",
              ),
              SizedBox(height: AppSizes.h(30)),
              // email
              CustomTextFormWidget(
                sectionTitle: 'Email Address',
                hintText: 'email address',
                textEditingController:
                    forgetPasswordController.forgetPasswordEditingController,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: AppSizes.h(30)),

              // button
              Obx(() {
                return forgetPasswordController.isLoading.value
                    ? LoadingAnimationWidget.staggeredDotsWave(
                        color: AppColors.primaryColor,
                        size: 30.h,
                      )
                    : CustomButtonWidget(
                        onTap: () {
                          if(forgetPasswordController.isFieldFilled()){
                            forgetPasswordController.handleForgetPassword();
                          }
                          else{
                            Fluttertoast.showToast(msg: "Email can't be empty", backgroundColor: AppColors.redColor);
                          }
                        },
                        buttonText: 'Send Email',
                      );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
