
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_textfield_widget.dart';
import 'package:spanx/core/global_widgets/subpage_appbar_widget.dart';
import 'package:spanx/features/create_motivation/controller/create_motivation_controller.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/const/app_fonts.dart';
import '../../../core/global_widgets/custom_button_widget.dart';

class CreateMotivationScreen extends StatelessWidget {
  CreateMotivationScreen({super.key});

  // IMPORTANT: Use Get.find() if added in bindings
  final createMotivationController =
  Get.find<CreateMotivationController>();

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SubPageAppbarWidget(
                appbarTitle: 'Create New Motivation',
                onPressed: () => Navigator.pop(context),
              ),

              SizedBox(height: 20.h),

              CustomTextFormWidget(
                sectionTitle: 'Write your own Motivational Speech',
                textEditingController:
                createMotivationController.createMotivation,
                hintText: 'Write something inspiring...',
              ),

              SizedBox(height: 20.h),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Upload Photo (Optional)',
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 16.sp,
                    color: AppColors.blackColor,
                  ),
                ),
              ),

              SizedBox(height: 10.h),

              GestureDetector(
                onTap: () => _showImagePickerOptions(context),
                child: Obx(() {
                  return Container(
                    width: double.infinity,
                    height: 200.h,
                    decoration: BoxDecoration(
                      color: AppColors.formBackgroundColor,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: createMotivationController.profileImage.value == null
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt,
                            size: 50.sp,
                            color: AppColors.primaryColor),
                        SizedBox(height: 10.h),
                        Text("Tap to select image"),
                      ],
                    )
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Image.file(
                        createMotivationController.profileImage.value!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  );
                }),
              ),

              SizedBox(height: 30.h),

              Obx(() {
                return createMotivationController.isLoading.value
                    ? LoadingAnimationWidget.staggeredDotsWave(
                  color: AppColors.primaryColor,
                  size: 30.h,
                )
                    : CustomButtonWidget(
                  onTap: createMotivationController.saveMotivation,
                  buttonText: "Save",
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) {
        return Container(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _option(Icons.camera_alt, "Camera", () {
                Get.back();
                createMotivationController.pickImageFromCamera();
              }),
              SizedBox(height: 15.h),
              _option(Icons.photo_library, "Gallery", () {
                Get.back();
                createMotivationController.pickImageFromGallery();
              }),
              SizedBox(height: 15.h),
              _option(Icons.delete, "Remove", () {
                Get.back();
                createMotivationController.removeProfileImage();
              }, isDanger: true),
            ],
          ),
        );
      },
    );
  }

  Widget _option(IconData icon, String text, VoidCallback onTap,
      {bool isDanger = false}) {
    return ListTile(
      leading: Icon(icon,
          color: isDanger ? Colors.red : AppColors.primaryColor),
      title: Text(text),
      onTap: onTap,
    );
  }
}

