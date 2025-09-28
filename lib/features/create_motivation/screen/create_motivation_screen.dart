import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:spanx/core/const/app_icons.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_textfield_widget.dart';
import 'package:spanx/core/global_widgets/subpage_appbar_widget.dart';
import 'package:spanx/features/create_motivation/controller/create_motivation_controller.dart';
import 'package:spanx/features/vision_board_create/controller/vision_board_create_controller.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/const/app_fonts.dart';
import '../../../core/global_widgets/custom_button_widget.dart';
import '../../../routes/app_routes.dart';
import 'package:path/path.dart' as p;

class CreateMotivationScreen extends StatelessWidget {
  CreateMotivationScreen({super.key});

  final createMotivationController = Get.put(CreateMotivationController());

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
        minimum: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: Column(
          children: [
            // appbar
            SubPageAppbarWidget(
              appbarTitle: 'Create New Motivation',
              onPressed: () {
                Get.back();
              },
            ),

            SizedBox(height: 20.h),

            // select year
            CustomTextFormWidget(
              sectionTitle: 'Write your own Motivational Speech',
              textEditingController:
                  createMotivationController.createMotivation,
              hintText: 'write',
            ),

            SizedBox(height: 20.h),

            // image container
            Align(
              alignment: AlignmentGeometry.centerLeft,
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
                dashPattern: [6, 4],
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
                  child: createMotivationController.profileImage.value == null
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
                            createMotivationController.profileImage.value!,
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
              alignment: AlignmentGeometry.centerLeft,
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
                      borderRadius: BorderRadiusGeometry.circular(5.w),
                      side: BorderSide(color: AppColors.primaryColor, width: 1),
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
                      createMotivationController.profileImage.value == null
                          ? "No File Chosen"
                          : p.basename(
                              createMotivationController.profileImage.value
                                  .toString(),
                            ),
                      overflow: TextOverflow.ellipsis,
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
            Obx(() {
              return createMotivationController.isLoading.value
                  ? Center(
                      child: LoadingAnimationWidget.staggeredDotsWave(
                        color: AppColors.primaryColor,
                        size: 30.h,
                      ),
                    )
                  : CustomButtonWidget(
                      onTap: () {
                        createMotivationController.saveMotivation();
                      },
                      buttonText: "Save",
                    );
            }),
            SizedBox(height: 15.h),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(10.w)),
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
                    createMotivationController.pickImageFromCamera();
                  },
                ),
                _buildImageOption(
                  context,
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Get.back();
                    createMotivationController.pickImageFromGallery();
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
                createMotivationController.removeProfileImage();
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
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primaryColor).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: (color ?? AppColors.primaryColor).withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 25.sp, color: color ?? AppColors.primaryColor),
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
