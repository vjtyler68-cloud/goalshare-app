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

class CreateNewCustomerScreen extends StatelessWidget {
  final VoidCallback onContinue;
  final createClientController = Get.find<MissionDetailsController>();

  CreateNewCustomerScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blackColor.withAlpha(35),
      child: Center(
        child: Container(
          width: 320.w,
          height: 380.h,
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
                    'Create New Customer',
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 20.sp,
                      color: AppColors.greyColor70,
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                CustomTextFormWidget(
                  sectionTitle: 'Client Name',
                  textEditingController: createClientController.clientName,
                  hintText: 'name',
                ),
                SizedBox(height: 10.h),
                CustomTextFormWidget(
                  sectionTitle: 'Phone Number',
                  textEditingController: createClientController.clientPhoneNumber,
                  hintText: 'phone number',
                ),
                SizedBox(height: 10.h),
                CustomTextFormWidget(
                  sectionTitle: 'Notes',
                  textEditingController: createClientController.clientNotes,
                  hintText: 'describe',
                ),
                SizedBox(height: 10.h),
                Text(
                  'If don’t have any information about client,simply click on the create Client Button and continue.',
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 10.sp,
                    color: AppColors.greyColor70,
                  ),
                ),
                SizedBox(height: 10.h),
               Obx(() {
                return  createClientController.isLoading.value ?
                 Center(child: LoadingAnimationWidget.fourRotatingDots(color: AppColors.primaryColor, size: 30.h)) :
                 CustomButtonWidget(
                   onTap: () {
                     createClientController.createClient();
                   },
                   buttonText: 'Create Client',
                 );
               })
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Static method to show the popup
  static void show({required VoidCallback onContinue}) {
    Get.dialog(
      CreateNewCustomerScreen(onContinue: onContinue),
      barrierDismissible: true,

    );
  }
}
