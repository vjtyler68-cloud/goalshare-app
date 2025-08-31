import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_images.dart';
import 'package:spanx/core/const/app_size.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';
import 'package:spanx/features/auth/widget/heading_title_subtitle_widget.dart';
import 'package:spanx/routes/app_routes.dart';

class UploadProfilePicture extends StatelessWidget {
  const UploadProfilePicture({super.key});

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
                headingTitle: "Upload Profile Picture",
                headingSubTitle: '',
              ),

              // image container
              Align(
                alignment: AlignmentGeometry.centerLeft,
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
                  dashPattern: [6,4],
                  radius: Radius.circular(AppSizes.w(10)), padding: EdgeInsets.zero),
                child: Container(
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
                  child:
                      // _image == null
                      //     ?
                      Center(
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.deepOrange,
                          size: AppSizes.h(50),
                        ),
                      ),
                  //     :
                  // ClipRRect(
                  //     borderRadius: BorderRadius.circular(15),
                  //     child: Image.asset(
                  //       AppImages.backgroundScreenGrid,
                  //       width: double.infinity,
                  //       height: double.infinity,
                  //       fit: BoxFit.cover,
                  //     ),
                  //   ),
                ),
              ),
              SizedBox(height: AppSizes.h(10)),

              Align(
                alignment: AlignmentGeometry.centerLeft,
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
                        color: AppColors.greyColor,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSizes.w(10)),
                  // text
                  Text(
                    "No File Chosen",
                    style: AppFonts.spaceGrotesk.copyWith(
                      color: AppColors.greyColor,
                      fontSize: AppSizes.sp(15),
                    ),
                  ),
                ],
              ),

              SizedBox(height: AppSizes.h(30)),

              // button
              CustomButtonWidget(
                onTap: () {
                  Get.toNamed(AppRoutes.splash);
                },
                buttonText: "Continue",
              ),
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

void _showImagePickerOptions(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.w(10))),
    ),
    builder: (context) => Container(
      // padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            // width: 40.w,
            // height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              // borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          // SizedBox(height: 20.h),
          Text(
            'Select Profile Picture',
            // style: GoogleFonts.poppins(
            //   fontSize: 18.sp,
            //   fontWeight: FontWeight.w600,
            //   color: AppColors.blackColor,
            // ),
          ),
          // SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildImageOption(
                context,
                icon: Icons.camera_alt,
                label: 'Camera',
                onTap: () {
                  // Get.back();
                  // controller.pickImageFromCamera();
                },
              ),
              _buildImageOption(
                context,
                icon: Icons.photo_library,
                label: 'Gallery',
                onTap: () {
                  // Get.back();
                  // controller.pickImageFromGallery();
                },
              ),
            ],
          ),
          // SizedBox(height: 20.h),
          _buildImageOption(
            context,
            icon: Icons.delete,
            label: 'Remove',
            color: Colors.red,
            onTap: () {
              // Get.back();
              // controller.removeProfileImage();
            },
          ),
          // SizedBox(height: 20.h),
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
      // padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primaryColor).withOpacity(0.1),
        // borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: (color ?? AppColors.primaryColor).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            // size: 30.sp,
            color: color ?? AppColors.primaryColor,
          ),
          // SizedBox(height: 8.h),
          Text(
            label,
            // style: GoogleFonts.poppins(
            //   fontSize: 14.sp,
            //   fontWeight: FontWeight.w500,
            //   color: color ?? AppColors.blackColor,
            // ),
          ),
        ],
      ),
    ),
  );
}
