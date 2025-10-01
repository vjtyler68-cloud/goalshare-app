import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';
import 'package:spanx/core/global_widgets/custom_textfield_widget.dart';
import 'package:spanx/core/alertdialogs/task_created_successful.dart';
import 'package:spanx/features/home/controller/home_controller.dart';
import 'package:spanx/features/mission/controller/mission_controller.dart';

import '../const/app_fonts.dart';

class CreateNewMission extends StatelessWidget {
  // final VoidCallback onContinue;

  CreateNewMission({super.key});

  final missionController = Get.find<MissionController>();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blackColor.withAlpha(35),
      child: Center(
        child: Container(
          width: 320.w,
          height: 560.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.r),
            color: Color(0xffFFDCCD),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text(
                     'Create New Mission',
                     style: AppFonts.spaceGrotesk.copyWith(
                       fontWeight: FontWeight.w700,
                       fontSize: 20.sp,
                       color: AppColors.greyColor70,
                     ),
                   ),
                   IconButton(onPressed: (){
                     Get.back();
                     missionController.isLoading.value = false;
                     missionController.clearField();

                   }, icon: Icon(Icons.remove_circle_outline))
                 ],
               ),
                SizedBox(height: 10.h),
                CustomTextFormWidget(
                  sectionTitle: 'Mission Tittle',
                  textEditingController: missionController.missionTitle,
                  hintText: 'Enter mission tittle',
                ),
                SizedBox(height: 10.h),
                CustomTextFormWidget(
                  keyboardType: TextInputType.number,
                  sectionTitle: 'Client Target',
                  textEditingController: missionController.clientTarget,
                  hintText: '8',
                ),
                SizedBox(height: 10.h),
                CustomTextFormWidget(
                  sectionTitle: 'Description',
                  textEditingController: missionController.description,
                  hintText: 'Describe your mission',
                ),
                SizedBox(height: 10.h),
                Text(
                  'Category',
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 16.sp,
                    color: AppColors.greyColor70,
                  ),
                ),
                SizedBox(height: 10.h),

                Obx(
                  () => Wrap(
                    spacing: 11.w,
                    runSpacing: 11.h,
                    children: missionController.categoryList.map((option) {
                      final isSelected =
                          missionController.selectedCategory.value == option;
                      return GestureDetector(
                        onTap: () => missionController.selectCategory(option),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.maroonColor
                                : AppColors.lightPinkColor,
                            border: Border.all(color: AppColors.maroonColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            option,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.whiteColor
                                  : AppColors.maroonColor,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 10.h),

                Text(
                  'Priority',
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 16.sp,
                    color: AppColors.greyColor70,
                  ),
                ),
                SizedBox(height: 10.h),
                Obx(
                  () => Wrap(
                    spacing: 11.w,
                    runSpacing: 11.h,
                    children: missionController.priorityList.map((option) {
                      final isSelected =
                          missionController.selectedPriority.value == option;
                      return GestureDetector(
                        onTap: () => missionController.selectPriority(option),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryColor
                                : AppColors.lightPinkColor,
                            border: Border.all(color: AppColors.primaryColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            option,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.whiteColor
                                  : AppColors.primaryColor,
                              fontSize: 13.sp,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                SizedBox(height: 10.h),
                Obx(() {
                  final date = missionController.selectedDate.value;
                  return CustomTextFormWidget(
                    readOnly: true,

                    prefixWidget: IconButton(
                      onPressed: () {
                        missionController.pickDate(context);
                      },
                      icon: Icon(Icons.calendar_month_outlined),
                    ),
                    sectionTitle: 'Due Date',
                    textEditingController: TextEditingController(),
                    hintText: date.isEmpty ? 'DDMMYY' : date,
                  );
                }),
                SizedBox(height: 10.h),
                Obx(() {
                  return missionController.isLoading.value
                      ? Center(
                        child: LoadingAnimationWidget.staggeredDotsWave(
                            color: AppColors.primaryColor,
                            size: 30.h,
                          ),
                      )
                      : CustomButtonWidget(
                          onTap: () {
                            missionController.createMission();

                          },
                          buttonText: 'Create Mission',
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
  static void show() {
    Get.dialog(CreateNewMission(), barrierDismissible: false);
  }
}
