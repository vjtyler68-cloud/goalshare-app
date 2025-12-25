import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_images.dart';
import 'package:spanx/core/const/app_size.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/features/auth/widget/heading_title_subtitle_widget.dart';
import 'package:spanx/routes/app_routes.dart';
import 'package:path/path.dart' as p;

import '../controller/setup_profile_controller.dart';

class UploadProfilePicture extends StatelessWidget {
  UploadProfilePicture({super.key});

  final SetupProfileController setupProfileController = Get.put(
    SetupProfileController(),
  );

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 20.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // heading
              HeadingTitleSubtitleWidget(
                headingTitle: "Upload Profile Picture",
                headingSubTitle: '',
              ),

              // image container
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Upload Photo',
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: AppSizes.sp(16),
                    color: AppColors.blackColor,
                    // fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: AppSizes.h(10)),

              DottedBorder(
                options: RoundedRectDottedBorderOptions(
                  dashPattern: [6, 4],
                  radius: Radius.circular(AppSizes.w(10)),
                  padding: EdgeInsets.zero,
                ),
                child: Obx(() {
                  return Container(
                    width: AppSizes.w(300),
                    height: AppSizes.h(250),
                    decoration: BoxDecoration(
                      color: AppColors.formBackgroundColor,
                      borderRadius: BorderRadius.circular(AppSizes.w(10)),
                      // border: Border.all(
                      //   color: AppColors.greyColor.withAlpha(100),
                      //   width: 1,
                      // ),
                    ),
                    child: setupProfileController.profileImage.value == null
                        ? Center(
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.deepOrange,
                              size: AppSizes.h(50),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.file(
                              setupProfileController.profileImage.value!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                  );
                }),
              ),
              SizedBox(height: AppSizes.h(10)),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Formats: JPG, PNG, JPEG – Max 5MB each',
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: AppSizes.sp(12),
                    color: AppColors.blackColor,
                    // fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: AppSizes.h(10)),

              // file button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _showImagePickerOptions(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.formBackgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadiusGeometry.circular(
                          AppSizes.w(5),
                        ),
                        side: BorderSide(
                          color: AppColors.primaryColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      'Choose File',
                      style: AppFonts.spaceGrotesk.copyWith(
                        color: AppColors.greyColor70,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSizes.w(10)),
                  // text
                  Obx(() {
                    return Expanded(
                      child: Text(
                        setupProfileController.profileImage.value == null
                            ? "No File Chosen"
                            : p.basename(
                                setupProfileController.profileImage.value
                                    .toString(),
                              ),
                        style: AppFonts.spaceGrotesk.copyWith(
                          color: AppColors.greyColor70,
                          fontSize: AppSizes.sp(15),
                        ),
                      ),
                    );
                  }),
                ],
              ),

              SizedBox(height: AppSizes.h(30)),

              // button
              Obx(() {
                return setupProfileController.isPictureLoading.value
                    ? LoadingAnimationWidget.staggeredDotsWave(
                        color: AppColors.primaryColor,
                        size: 30.h,
                      )
                    : CustomButtonWidget(
                        onTap: () async {
                          setupProfileController.saveProfilePicture();
                          await LocalService().clearUserData();
                        },
                        buttonText: "Continue",
                      );
              }),
              SizedBox(height: AppSizes.h(15)),

              // button
              TextButton(
                onPressed: () async {
                  Get.offNamed(AppRoutes.loginScreen);
                  await LocalService().clearUserData();
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

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.w(10)),
        ),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(AppSizes.w(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSizes.w(40),
              height: AppSizes.h(4),
              decoration: BoxDecoration(
                color: AppColors.greyColor70,
                borderRadius: BorderRadius.circular(AppSizes.w(10)),
              ),
            ),
            SizedBox(height: AppSizes.h(20)),
            Text(
              'Select Profile Picture',
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: AppSizes.sp(18),
                fontWeight: FontWeight.w600,
                color: AppColors.blackColor,
              ),
            ),
            SizedBox(height: AppSizes.h(20)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                  context,
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Get.back();
                    setupProfileController.pickImageFromCamera();
                  },
                ),
                _buildImageOption(
                  context,
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Get.back();
                    setupProfileController.pickImageFromGallery();
                  },
                ),
              ],
            ),
            SizedBox(height: AppSizes.h(20)),
            _buildImageOption(
              context,
              icon: Icons.delete,
              label: 'Remove',
              color: Colors.red,
              onTap: () {
                Get.back();
                setupProfileController.removeProfileImage();
              },
            ),
            SizedBox(height: AppSizes.h(20)),
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
        padding: EdgeInsets.symmetric(
          vertical: AppSizes.h(15),
          horizontal: AppSizes.w(20),
        ),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primaryColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.w(12)),
          border: Border.all(
            color: (color ?? AppColors.primaryColor).withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: AppSizes.sp(30),
              color: color ?? AppColors.primaryColor,
            ),
            SizedBox(height: AppSizes.h(8)),
            Text(
              label,
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: AppSizes.sp(14),
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
