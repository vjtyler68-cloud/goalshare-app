import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:get/utils.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_icons.dart';
import 'package:spanx/core/const/app_size.dart';
import 'package:spanx/core/const/country_list.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';
import 'package:spanx/core/global_widgets/custom_textfield_widget.dart';
import 'package:spanx/features/auth/widget/heading_title_subtitle_widget.dart';
import 'package:spanx/features/editprofile/controller/edit_profile_controller.dart';
import 'package:spanx/features/signup_update_profile/controller/setup_profile_controller.dart';
import 'package:spanx/routes/app_routes.dart';

class SetupProfileScreen extends StatelessWidget {
  SetupProfileScreen({super.key});

  final SetupProfileController setupProfileController = Get.put(
    SetupProfileController(),
  );

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // heading
              HeadingTitleSubtitleWidget(
                headingTitle: "Set Up Your Profile",
                headingSubTitle: "",
              ),
              // SizedBox(height: AppSizes.h(10)),
              // Business Type
              CustomTextFormWidget(
                sectionTitle: "Business Type",
                hintText: 'others',
                textEditingController: setupProfileController.businessType,
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: 13.h),
              // Describe Profession
              CustomTextFormWidget(
                sectionTitle: "Describe Profession",
                hintText: 'describe',
                textEditingController: setupProfileController.describeProfession,
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: 13.h),
              // City
              CustomTextFormWidget(
                sectionTitle: "City",
                hintText: 'city',
                textEditingController: setupProfileController.city,
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: 13.h),
              // Full Address
              CustomTextFormWidget(
                sectionTitle: "Full Address",
                hintText: 'address',
                textEditingController: setupProfileController.fullAddress,
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: 13.h),
              // Phone
              CustomTextFormWidget(
                sectionTitle: "Phone",
                hintText: 'XX XXX XXXX',
                textEditingController: setupProfileController.phoneNumber,
                keyboardType: TextInputType.number,
                prefixWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // flag icon
                    Image.asset(
                      AppIcons.uk_flag_png,
                      height: AppSizes.h(20),
                      width: AppSizes.h(20),
                    ),
                    SizedBox(width: AppSizes.w(5)),
                    Text(
                      "+44 |",
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppSizes.h(30)),

              // button
              Obx(() {
                return setupProfileController.isInfoLoading.value
                    ? LoadingAnimationWidget.staggeredDotsWave(
                        color: AppColors.primaryColor,
                        size: 30.h,
                      )
                    : CustomButtonWidget(
                        onTap: () {
                          // Get.toNamed(AppRoutes.uploadProfilePictureScreen);
                          setupProfileController.saveProfileInfo();
                        },
                        buttonText: "Continue",
                      );
              }),
              SizedBox(height: 13.h),
              // button
              TextButton(
                onPressed: () {
                  Get.offNamed(AppRoutes.uploadProfilePictureScreen);
                },
                child: Text(
                  'Skip',
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
