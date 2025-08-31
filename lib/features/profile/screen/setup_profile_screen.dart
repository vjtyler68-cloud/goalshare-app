import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/get_state.dart';
import 'package:get/utils.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_icons.dart';
import 'package:spanx/core/const/app_size.dart';
import 'package:spanx/core/const/country_list.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';
import 'package:spanx/core/global_widgets/custom_textfield_widget.dart';
import 'package:spanx/features/auth/widget/heading_title_subtitle_widget.dart';
import 'package:spanx/features/profile/controller/setup_profile_controller.dart';
import 'package:spanx/routes/app_routes.dart';

class SetupProfileScreen extends StatelessWidget {
  const SetupProfileScreen({super.key});

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
              HeadingTitleSubtitleWidget(
                headingTitle: "Set Up Your Profile",
                headingSubTitle: "",
              ),
              // SizedBox(height: AppSizes.h(10)),
              // Business Type
              CustomTextFormWidget(
                sectionTitle: "Business Type",
                hintText: 'others',
                textEditingController: TextEditingController(),
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: AppSizes.h(15)),
              // Describe Profession
              CustomTextFormWidget(
                sectionTitle: "Describe Profession",
                hintText: 'describe',
                textEditingController: TextEditingController(),
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: AppSizes.h(15)),
              // City
              CustomTextFormWidget(
                sectionTitle: "City",
                hintText: 'city',
                textEditingController: TextEditingController(),
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: AppSizes.h(15)),
              // Full Address
              CustomTextFormWidget(
                sectionTitle: "Full Address",
                hintText: 'address',
                textEditingController: TextEditingController(),
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: AppSizes.h(15)),
              // Phone
              CustomTextFormWidget(
                sectionTitle: "Phone",
                hintText: 'XX XXX XXXX',
                textEditingController: TextEditingController(),
                keyboardType: TextInputType.number,
                prefixWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // flag icon
                    Image.asset(AppIcons.uk_flag_png, height: AppSizes.h(20), width: AppSizes.h(20)),
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
              CustomButtonWidget(onTap: () {
                Get.toNamed(AppRoutes.uploadProfilePictureScreen);
              }, buttonText: "Continue"),
              SizedBox(height: AppSizes.h(15)),
              // button
              TextButton(
                onPressed: () {},
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
