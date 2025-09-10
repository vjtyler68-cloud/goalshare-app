import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';
import 'package:spanx/core/global_widgets/custom_textfield_widget.dart';
import 'package:spanx/features/home/alertdialogs/task_created_successful.dart';
import 'package:spanx/features/home/controller/home_controller.dart';

import '../../../core/const/app_fonts.dart';

class CreateNewGoal extends StatelessWidget {
  final VoidCallback onContinue;

  CreateNewGoal({super.key, required this.onContinue});

  final HomeController controller = Get.put(HomeController());

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
                Text(
                  'Create New Goal',
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 20.sp,
                    color: AppColors.greyColor70,
                  ),
                ),
                SizedBox(height: 10.h),
                CustomTextFormWidget(
                  sectionTitle: 'Goal Tittle',
                  textEditingController: TextEditingController(),
                  hintText: 'Enter goal tittle',
                ),
                SizedBox(height: 10.h),
                CustomTextFormWidget(
                  sectionTitle: 'Client Target',
                  textEditingController: TextEditingController(),
                  hintText: '8 person',
                ),
                SizedBox(height: 10.h),
                CustomTextFormWidget(
                  sectionTitle: 'Description',
                  textEditingController: TextEditingController(),
                  hintText: 'Describe your goal',
                ),
                SizedBox(height: 10.h),
                Text(
                  'Category',
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 16.sp,
                    color: AppColors.greyColor70,
                  ),
                ),SizedBox(height: 10.h),

                Obx(
                  () => Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: controller.categoryList.map((option) {
                      final isSelected =
                          controller.selectedCategory.value == option;
                      return GestureDetector(
                        onTap: () => controller.selectCategory(option),
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
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),SizedBox(height: 10.h),

                Text(
                  'Priority',
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 16.sp,
                    color: AppColors.greyColor70,
                  ),
                ),SizedBox(height: 10.h),
                Obx(
                      () => Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: controller.priorityList.map((option) {
                      final isSelected =
                          controller.selectedPriority.value == option;
                      return GestureDetector(
                        onTap: () => controller.selectPriority(option),
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
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),SizedBox(height: 10.h),
                CustomTextFormWidget(
                  sectionTitle: 'Due Date',
                  textEditingController: TextEditingController(),
                  hintText: 'DDMMYY',
                ),
                SizedBox(height: 10.h),
                CustomButtonWidget(onTap: () {
                  Get.back();
                  TaskCreatedSuccessful.show(onContinue: (){});


                }, buttonText: 'Create Goal'),
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
      CreateNewGoal(onContinue: onContinue),
      barrierDismissible: false,
    );
  }
}
