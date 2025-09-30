import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:spanx/features/mission_details/controller/mission_details_controller.dart';

import '../const/app_colors.dart';
import '../const/app_fonts.dart';
import '../global_widgets/custom_button_widget.dart';
import '../global_widgets/custom_textfield_widget.dart';

class CreateMyWhyDialog extends StatelessWidget {
  final createClientController = Get.find<MissionDetailsController>();
  final String headingText;

  CreateMyWhyDialog({super.key, required this.headingText});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blackColor.withAlpha(35),
      child: Center(
        child: Container(
          width: 320.w,
          height: 190.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.r),
            color: Color(0xffFFDCCD),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 30.h),
                Center(
                  child: Text(
                    'Create New $headingText',
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 20.sp,
                      color: AppColors.greyColor70,
                    ),
                  ),
                ),
                CustomTextFormWidget(
                  sectionTitle: '',
                  textEditingController:
                      createClientController.myWhyAffirmation,
                  hintText: headingText,
                ),

                SizedBox(height: 20.h),
                Obx(() {
                  return createClientController.isLoading.value
                      ? Center(
                          child: LoadingAnimationWidget.fourRotatingDots(
                            color: AppColors.primaryColor,
                            size: 30.h,
                          ),
                        )
                      : CustomButtonWidget(
                          onTap: () {
                            headingText == "My Why"
                                ? createClientController.createMyWhy()
                                : createClientController.createAffirmation();
                          },
                          buttonText: 'Create $headingText',
                        );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Static method to show the popup
  static void show(String txt) {
    Get.dialog(CreateMyWhyDialog(headingText: txt), barrierDismissible: true);
  }
}
