import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:spanx/features/community_profile/controller/create_community_controller.dart';

import '../const/app_colors.dart';
import '../const/app_fonts.dart';
import '../global_widgets/custom_button_widget.dart';

class CommunityUploadPictureDialog extends StatelessWidget {
  CommunityUploadPictureDialog({super.key});
  final communityUploadPictureController = Get.put(CreateCommunityController());

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blackColor.withAlpha(35),
      child: Center(
        child: Container(
          width: 320.w,
          height: 500.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.r),
            color: const Color(0xffFFDCCD),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // New Community
                Text(
                  'Upload Community Picture ',
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 20.sp,
                    color: AppColors.blackColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 20.h),

                // image container
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Upload Photo',
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 16.sp,
                      color: AppColors.blackColor,
                      // fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),

                DottedBorder(
                  options: RoundedRectDottedBorderOptions(
                    dashPattern: const [6, 4],
                    radius: Radius.circular(10.r),
                    padding: EdgeInsets.zero,
                  ),
                  child: Obx(() {
                    return Container(
                      width: 250.w,
                      height: 200.h,
                      decoration: BoxDecoration(
                        color: AppColors.formBackgroundColor,
                        borderRadius: BorderRadius.circular(10.w),
                        // border: Border.all(
                        //   color: AppColors.greyColor.withAlpha(100),
                        //   width: 1,
                        // ),
                      ),
                      child: communityUploadPictureController.communityImage.value == null
                          ? Center(
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.deepOrange,
                          size: 50.h,
                        ),
                      )
                          : ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(
                          communityUploadPictureController.communityImage.value!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }),
                ),
                SizedBox(height: 10.h),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Formats: JPG, PNG, JPEG – Max 5MB each',
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 12.sp,
                      color: AppColors.blackColor,
                      // fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),

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
                            5.w,
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
                    SizedBox(width: 10.w),
                    // text
                    Obx(() {
                      return Expanded(
                        child: Text(
                          communityUploadPictureController.communityImage.value == null
                              ? "No File Chosen"
                              : p.basename(
                            communityUploadPictureController.communityImage.value
                                .toString(),
                          ),
                          style: AppFonts.spaceGrotesk.copyWith(
                            color: AppColors.greyColor70,
                            fontSize: 15.sp,
                          ),
                        ),
                      );
                    }),
                  ],
                ),

                SizedBox(height: 30.h),

                // button
                CustomButtonWidget(
                  onTap: () {
                    // communityUploadPictureController.saveMotivation();
                  },
                  buttonText: "Save",
                ),
                SizedBox(height: 10.h),
                TextButton(
                  onPressed: () {
                    // Get.offNamed(AppRoutes.uploadProfilePictureScreen);
                  },
                  child: Text(
                    'Skip',
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 14.sp,
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
  // Static method to show the popup
  static void show() {
    Get.dialog(CommunityUploadPictureDialog(), barrierDismissible: false);
  }

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(10.w),
        ),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(15.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.greyColor70,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            SizedBox(height: 15.h),
            Text(
              'Select Profile Picture',
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.blackColor,
              ),
            ),
            SizedBox(height: 15.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                  context,
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Get.back();
                    communityUploadPictureController.pickImageFromCamera();
                  },
                ),
                _buildImageOption(
                  context,
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Get.back();
                    communityUploadPictureController.pickImageFromGallery();
                  },
                ),
              ],
            ),
            SizedBox(height: 15.h),
            _buildImageOption(
              context,
              icon: Icons.delete,
              label: 'Remove',
              color: Colors.red,
              onTap: () {
                Get.back();
                communityUploadPictureController.removeCommunityImage();
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
        padding: EdgeInsets.symmetric(
          vertical: 10.h,
          horizontal: 15.w,
        ),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primaryColor).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: (color ?? AppColors.primaryColor).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 25.sp,
              color: color ?? AppColors.primaryColor,
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 12.sp,
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
