import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_images.dart';
import 'package:spanx/core/const/app_size.dart';
import 'package:spanx/features/mainnavbar/controller/main_navbar_controller.dart';

class MainNavbarScreen extends GetView<MainNavBarController> {
  const MainNavbarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
      Stack(
        alignment: AlignmentGeometry.center,
        children: [
          Obx(() => controller.pages[controller.selectedIndex.value]),
          Positioned(
            bottom: AppSizes.h(20),
            left: 0,
            right: 0,
            child: Container(
              height: 75.h,
              padding: EdgeInsets.symmetric(horizontal: 10.w),
              // color: AppColors.maroonColor,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Nav Bar Container
                  Container(
                    width: double.infinity,
                    height: AppSizes.h(80),
                    decoration: BoxDecoration(
                      color: Color(0xffF2D1C3E5).withAlpha(90),
                      border: Border.all(color: AppColors.whiteColor),
                      borderRadius: BorderRadius.circular(AppSizes.w(40)),
                      image: DecorationImage(
                        image: AssetImage(AppImages.bg_profiles),
                        fit: BoxFit.fill,
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 8),
                      ],
                    ),
                    padding: EdgeInsets.symmetric(horizontal: AppSizes.h(25)),
                    child: Obx(() {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(controller.labels.length, (index) {
                          if (index == 1) {
                            return Row(
                              children: [
                                _buildNavItem(index, controller),
                                SizedBox(width: AppSizes.w(30)), // Space for FAB
                              ],
                            );
                          }
                          return _buildNavItem(index, controller);
                        }),
                      );
                    }),
                  ),

                  // FAB - Centered on top of nav bar
                  Positioned(
                    bottom: AppSizes.h(40),
                    left: 0,
                    right: 0,
                    child: Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: (){
                          log("FAB tapped");
                        },
                        child: Container(
                          width: AppSizes.w(70),
                          height: AppSizes.w(70),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [AppColors.primaryColor, AppColors.maroonColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.4),
                                blurRadius: AppSizes.h(10),
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.add,
                            color: AppColors.whiteColor,
                            size: AppSizes.w(30),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, MainNavBarController controller) {
    bool isSelected = controller.selectedIndex.value == index;
    return GestureDetector(
      onTap: () => controller.changeIndex(index),
      // onTap: () {
      //   controller.changeIndex(index);
      //   log("clicked");
      // },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            controller.icons[index],
            height: AppSizes.h(25),
            color: isSelected ? AppColors.primaryColor : Colors.grey,
          ),
          SizedBox(height: AppSizes.w(5)),
          Text(
            controller.labels[index],
            style: AppFonts.spaceGrotesk.copyWith(
              color: isSelected ? AppColors.primaryColor : AppColors.greyColor70,
              fontSize: AppSizes.w(12),
            ),
          ),
        ],
      ),
    );
  }
}
