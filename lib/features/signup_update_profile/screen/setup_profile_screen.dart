import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/global_widgets/app_back_button.dart';
import 'package:get/utils.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:logger/logger.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_size.dart';
import 'package:spanx/core/const/country_list.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';
import 'package:spanx/core/global_widgets/custom_textfield_widget.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/features/auth/widget/heading_title_subtitle_widget.dart';
import 'package:spanx/features/signup_update_profile/controller/setup_profile_controller.dart';


import '../../../core/user_info/user_info_controller.dart';

class SetupProfileScreen extends StatelessWidget {
  SetupProfileScreen({super.key});

  final SetupProfileController setupProfileController = Get.put(
    SetupProfileController(),
  );
  final name = Get.arguments;
  final userInfoController = Get.put(UserInfoController());
  final logger = Logger();

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppBackButton(),
                SizedBox(height: 10.h),
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
                  sectionTitle: "Address",
                  hintText: 'address',
                  textEditingController: setupProfileController.fullAddress,
                  keyboardType: TextInputType.text,
                ),
                SizedBox(height: 13.h),
                // Phone
                // CustomTextFormWidget(
                //   sectionTitle: "Phone",
                //   hintText: 'XX XXX XXXX',
                //   textEditingController: setupProfileController.phoneNumber,
                //   keyboardType: TextInputType.number,
                //   prefixWidget: Row(
                //     mainAxisSize: MainAxisSize.min,
                //     children: [
                //       // flag icon
                //       Image.asset(
                //         AppIcons.uk_flag_png,
                //         height: AppSizes.h(20),
                //         width: AppSizes.h(20),
                //       ),
                //       SizedBox(width: AppSizes.w(5)),
                //       Text(
                //         "+44 |",
                //         style: AppFonts.spaceGrotesk.copyWith(
                //           fontWeight: FontWeight.w500,
                //           fontSize: 14,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
            
                CustomTextFormWidget(
                  sectionTitle: "Phone",
                  hintText:'xxxx xxxx xxx',
                  textEditingController:   setupProfileController.phoneNumber,
                  keyboardType: TextInputType.number,
                  prefixWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Country code dropdown
                      Obx(() {
                        return DropdownButton<String>(
                          value: setupProfileController.selectedCountryCode.value,
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setupProfileController.selectedCountryCode.value = newValue;
                              setupProfileController.selectedCountryFlag.value =
                                  setupProfileController.getFlagByCode(newValue);
                            }
                          },
                          items: countryList.map<DropdownMenuItem<String>>((
                              Map<String, String> country,
                              ) {
                            return DropdownMenuItem<String>(
                              value: country['code'],
                              child: Row(
                                children: [
                                  Text(
                                    country['icon']!,
                                    style: TextStyle(fontSize: 18.sp),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    country['code']!,
                                    style: AppFonts.spaceGrotesk.copyWith(
                                      fontSize: 14.sp,
                                      color: AppColors.blackColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          underline: Container(),
                          // remove default underline
                          style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp),
                          icon: Icon(Icons.arrow_drop_down, size: 16.w),
                          iconSize: 16.w,
                          dropdownColor: AppColors.lightPinkColor,
                          borderRadius: BorderRadius.circular(10.r),
                          isDense: true,
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 6.h,
                          ),
                        );
                      }),
                      // SizedBox(width: 2.w),
                      Text(
                        '|',
                        style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp),
                      ),
                      SizedBox(width: 2.w),
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
                            setupProfileController.saveProfileInfo(name);
                          },
                          buttonText: "Continue",
                        );
                }),
                SizedBox(height: 13.h),
                // button
                TextButton(
                  onPressed: () async{
                    // Get.offNamed(AppRoutes.uploadProfilePictureScreen);
                    logger.d("TOKEN: ${await LocalService().getToken()}");
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
      ),
    );
  }
}
