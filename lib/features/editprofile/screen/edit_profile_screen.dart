// edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/subpage_appbar_widget.dart';
import 'package:spanx/features/editprofile/controller/edit_profile_controller.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/const/app_fonts.dart';
import '../../../core/const/country_list.dart';
import '../../../core/global_widgets/app_network_image.dart';
import '../../../core/global_widgets/custom_button_widget.dart';
import '../../../core/global_widgets/custom_textfield_widget.dart';
import '../../../core/user_info/user_info_controller.dart';

class EditProfileScreen extends StatelessWidget {
  EditProfileScreen({super.key});

  // IMPORTANT: do NOT Get.put() here every build.
  // Use Get.find() if already injected via bindings/route.
  // If not injected anywhere, keep Get.put(EditProfileController(), permanent:false) in your route binding.
  final EditProfileController editController = Get.find<EditProfileController>();
  final userInfoController = Get.find<UserInfoController>();

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              SubPageAppbarWidget(
                appbarTitle: 'Edit Profile',
                onPressed: () => Navigator.pop(context),
              ),
              SizedBox(height: 15.h),

              _ProfileImage(editController: editController, userInfoController: userInfoController),

              SizedBox(height: 10.h),

              CustomTextFormWidget(
                sectionTitle: "Full Name",
                hintText: "Enter your full name",
                textEditingController: editController.fullName,
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: 15.h),

              CustomTextFormWidget(
                sectionTitle: "Business Type",
                hintText: "Enter your business type",
                textEditingController: editController.businessType,
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: 15.h),

              CustomTextFormWidget(
                sectionTitle: "Describe Profession",
                hintText: "Write a short description",
                textEditingController: editController.describeProfession,
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: 15.h),

              CustomTextFormWidget(
                sectionTitle: "City",
                hintText: "Enter your city",
                textEditingController: editController.city,
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: 15.h),

              CustomTextFormWidget(
                sectionTitle: "Address",
                hintText: "Enter your address",
                textEditingController: editController.fullAddress,
                keyboardType: TextInputType.text,
              ),
              SizedBox(height: 15.h),

              CustomTextFormWidget(
                sectionTitle: "Phone",
                hintText: "Phone number",
                textEditingController: editController.phoneNumber,
                keyboardType: TextInputType.phone,
                prefixWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                        items: countryList.map<DropdownMenuItem<String>>(
                              (Map<String, String> country) {
                            return DropdownMenuItem<String>(
                              value: country['code'],
                              child: Row(
                                children: [
                                  Text(country['icon'] ?? '🌍',
                                      style: TextStyle(fontSize: 18.sp)),
                                  SizedBox(width: 8.w),
                                  Text(
                                    country['code'] ?? '',
                                    style: AppFonts.spaceGrotesk.copyWith(
                                      fontSize: 14.sp,
                                      color: AppColors.blackColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ).toList(),
                        underline: const SizedBox.shrink(),
                        style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp),
                        icon: Icon(Icons.arrow_drop_down, size: 18.sp),
                        dropdownColor: AppColors.lightPinkColor,
                        borderRadius: BorderRadius.circular(10.r),
                        isDense: true,
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                      );
                    }),
                    Text('|', style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp)),
                    SizedBox(width: 6.w),
                  ],
                ),
              ),

              SizedBox(height: 18.h),

              Obx(() {
                final loading = editController.isSaving.value || editController.isPictureLoading.value;
                if (loading) {
                  return Center(
                    child: LoadingAnimationWidget.staggeredDotsWave(
                      color: AppColors.primaryColor,
                      size: 30.h,
                    ),
                  );
                }

                return CustomButtonWidget(
                  onTap: () => editController.saveAllProfileChanges(),
                  buttonText: "Save Changes",
                );
              }),

              SizedBox(height: 10.h),

              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'Cancel',
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.blackColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileImage extends StatelessWidget {
  const _ProfileImage({
    required this.editController,
    required this.userInfoController,
  });

  final EditProfileController editController;
  final UserInfoController userInfoController;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
                  final file = editController.profileImage.value;
                  final url = editController.profileImageUrl.value;

                  if (file != null) {
                    return Image.file(file, fit: BoxFit.cover);
                  }

                  final fallback = userInfoController.userData.value?.profile ?? '';

                  if (url.isNotEmpty) {
                    return Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return ResponsiveNetworkImage(
                          imageUrl: fallback.isNotEmpty ? fallback : "loading...",
                          fit: BoxFit.cover,
                        );
                      },
                    );
                  }

                  return ResponsiveNetworkImage(
                    imageUrl: fallback.isNotEmpty ? fallback : "loading...",
                    fit: BoxFit.cover,
                  );
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
                  child: const Icon(Icons.edit, color: Colors.white),
                ),
              ),
            ),
          ],
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
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Get.back();
                    editController.pickImageFromCamera();
                  },
                ),
                _buildImageOption(
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

  Widget _buildImageOption({
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
