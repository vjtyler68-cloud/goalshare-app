import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/subpage_appbar_widget.dart';
import 'package:spanx/features/editprofile/controller/edit_profile_controller.dart';
import 'package:spanx/features/profile_tab/controller/profile_tab_controller.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/const/app_fonts.dart';
import '../../../core/const/country_list.dart';
import '../../../core/global_widgets/app_network_image.dart';
import '../../../core/global_widgets/custom_button_widget.dart';
import '../../../core/global_widgets/custom_textfield_widget.dart';
import '../../../core/user_info/user_info_controller.dart';

class EditProfileScreen extends StatelessWidget {
  EditProfileScreen({super.key});

  final ProfileTabController controller = Get.find<ProfileTabController>();
  final editController = Get.put(EditProfileController());
  final userInfoController = Get.find<UserInfoController>();

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 0.h),
          child: Column(
            children: [
              // top app bar
              SubPageAppbarWidget(
                appbarTitle: 'Edit Profile',
                onPressed: () {
                  Get.back();
                },
              ),
              SizedBox(height: 15.h),

              // Profile Image
              // ResponsiveNetworkImage(
              //   imageUrl: controller.userImageUrl.value,
              //   shape: ImageShape.circle,
              //   widthPercent: 0.2,
              //   heightPercent: 0.1,
              //   fit: BoxFit.cover,
              // ),
              GestureDetector(
                onTap: () => _showImagePickerOptions(context),
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 105,
                        width: 105,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: Colors.purple.shade50,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Obx(() {
                            if (editController.profileImage.value != null) {
                              return Image.file(
                                editController.profileImage.value!,
                                fit: BoxFit.cover,
                              );
                            } else if (editController
                                .profileImageUrl
                                .value
                                .isNotEmpty) {
                              return Image.network(
                                editController.profileImageUrl.value,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: ResponsiveNetworkImage(
                                      imageUrl:
                                          userInfoController
                                              .userData
                                              .value
                                              ?.profile ??
                                          "loading...",
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                },
                              );
                            } else {
                              return Center(
                                child: ResponsiveNetworkImage(
                                  imageUrl:
                                      userInfoController
                                          .userData
                                          .value
                                          ?.profile ??
                                      "loading...",
                                  fit: BoxFit.cover,
                                ),
                              );
                            }
                          }),
                        ),
                      ),
                      Positioned(
                        bottom: -6,
                        child: InkWell(
                          onTap: () => _showImagePickerOptions(context),
                          child: Container(
                            height: 30,
                            width: 30,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Icon(Icons.edit, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // full name
              CustomTextFormWidget(
                sectionTitle: "Full Name",
                hintText:
                    userInfoController.userData.value?.fullName ?? "loading...",
                textEditingController: editController.fullName,
                keyboardType: TextInputType.text,
              ),
              // SizedBox(height: 15.h),
              // // Email Address
              // CustomTextFormWidget(
              //   sectionTitle: "Email Address",
              //   readOnly: true,
              //   hintText: userInfoController.email.value,
              //   textEditingController: editController.email,
              //   keyboardType: TextInputType.emailAddress,
              // ),
              SizedBox(height: 15.h),

              // Business Type
              CustomTextFormWidget(
                sectionTitle: "Business Type",
                hintText:
                    userInfoController.userData.value?.businessType ??
                    "loading...",
                textEditingController: editController.businessType,
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: 15.h),
              // Describe Profession
              CustomTextFormWidget(
                sectionTitle: "Describe Profession",
                hintText:
                    userInfoController.userData.value?.describe ?? "loading...",
                textEditingController: editController.describeProfession,
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: 15.h),
              // City
              CustomTextFormWidget(
                sectionTitle: "City",
                hintText:
                    userInfoController.userData.value?.city ?? "loading...",
                textEditingController: editController.city,
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: 15.h),
              // Full Address
              CustomTextFormWidget(
                sectionTitle: "Full Address",
                hintText:
                    userInfoController.userData.value?.address ?? "loading...",
                textEditingController: editController.fullAddress,
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: 15.h),

              // Phone
              // CustomTextFormWidget(
              //   sectionTitle: "Phone",
              //   hintText: userInfoController.phoneNumber.value.length > 3
              //       ? userInfoController.phoneNumber.value.substring(3)
              //       : userInfoController.phoneNumber.value,
              //   textEditingController: editController.phoneNumber,
              //   keyboardType: TextInputType.number,
              //   prefixWidget: Row(
              //     mainAxisSize: MainAxisSize.min,
              //     children: [
              //       Image.asset(
              //         AppIcons.uk_flag_png,
              //         height: 20.h,
              //         width: 20.w,
              //       ),
              //       SizedBox(width: 8.w),
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

              // SizedBox(height: 15.h),
              CustomTextFormWidget(
                sectionTitle: "Phone",
                hintText:
                    userInfoController.userData.value!.phoneNumber
                            .toString()
                            .length >
                        3
                    ? userInfoController.userData.value!.phoneNumber
                          .toString()
                          .substring(4)
                    : userInfoController.userData.value!.phoneNumber.toString(),
                textEditingController: editController.phoneNumber,
                keyboardType: TextInputType.phone,
                prefixWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Country code dropdown
                    Obx(() {
                      return DropdownButton<String>(
                        value: editController.selectedCountryCode.value,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            editController.selectedCountryCode.value = newValue;
                            editController.selectedCountryFlag.value =
                                editController.getFlagByCode(newValue);
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

              SizedBox(height: 15.h),

              // button
              Obx(() {
                return editController.isPictureLoading.value
                    ? Center(
                        child: LoadingAnimationWidget.staggeredDotsWave(
                          color: AppColors.primaryColor,
                          size: 30.h,
                        ),
                      )
                    : CustomButtonWidget(
                        onTap: () {
                          editController.saveAllProfileChanges();
                        },
                        buttonText: "Save Changes",
                      );
              }),
              SizedBox(height: 10.h),
              // button
              TextButton(
                onPressed: () {
                  Get.back();
                },
                child: Text(
                  'Cancel',
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 12.sp,
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

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.h,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Select Profile Picture',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.blackColor,
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                  context,
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Get.back();
                    editController.pickImageFromCamera();
                  },
                ),
                _buildImageOption(
                  context,
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Get.back();
                    editController.pickImageFromGallery();
                  },
                ),
              ],
            ),
            SizedBox(height: 20.h),
            _buildImageOption(
              context,
              icon: Icons.delete,
              label: 'Remove',
              color: Colors.red,
              onTap: () {
                Get.back();
                editController.removeProfileImage();
              },
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 20.w),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primaryColor).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: (color ?? AppColors.primaryColor).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30.sp, color: color ?? AppColors.primaryColor),
            SizedBox(height: 8.h),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: color ?? AppColors.blackColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
