import 'package:flutter/material.dart';
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
      body: Stack(
        alignment: AlignmentGeometry.center,
        children: [
          Obx(() => controller.pages[controller.selectedIndex.value]),
          Positioned(
            bottom: AppSizes.h(30),

            child: SizedBox(
              // decoration: BoxDecoration(
              //   image: DecorationImage(image: AssetImage(AppImages.bg_profiles), fit: BoxFit.fill)
              // ),
              width: AppSizes.w(370),
              height: AppSizes.h(80),
              child: Container(
                // height: AppSizes.h(120),
                decoration: BoxDecoration(
                  color: Color(0xffF2D1C3E5).withAlpha(90),
                  border: Border.all(color: AppColors.whiteColor),
                  borderRadius: BorderRadius.circular(AppSizes.w(40)),
                  image: DecorationImage(
                    image: AssetImage(AppImages.bg_profiles),
                    fit: BoxFit.fill,
                  ),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                ),
                padding: EdgeInsets.symmetric(horizontal: AppSizes.h(25)),
                child: Obx(() {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(controller.labels.length, (index) {
                      // Insert spacing for center FAB
                      if (index == 1) {
                        return Row(
                          children: [
                            _buildNavItem(index, controller),
                            SizedBox(width: AppSizes.w(30)), // space for FAB
                          ],
                        );
                      }
                      return _buildNavItem(index, controller);
                    }),
                  );
                }),
              ),
            ),
          ),
        ],
      ),

      // =============================================
      // backgroundColor: Colors.transparent,
      // body: Obx(() => controller.pages[controller.selectedIndex.value]),
      /*  floatingActionButton: SizedBox(
        child: FloatingActionButton(
          onPressed: () {
            // Add your logic here (e.g., open create screen)
          },
          shape: CircleBorder(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: AppSizes.w(120),
            height: AppSizes.h(120),
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
      ), */
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      /*  bottomNavigationBar:
      SizedBox(
        height: AppSizes.h(140),
        child: BottomAppBar(
          shape: CircularNotchedRectangle(),
          notchMargin: 8,
          elevation: 10,
          // color: Colors.transparent,
          child: Container(
            // height: AppSizes.h(120),
            decoration: BoxDecoration(
              color: Color(0xffF2D1C3E5).withAlpha(90),
              borderRadius: BorderRadius.circular(AppSizes.w(40)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            padding: EdgeInsets.symmetric(horizontal: AppSizes.h(25)),
            child: Obx(() {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(controller.labels.length, (index) {
                  // Insert spacing for center FAB
                  if (index == 1) {
                    return Row(
                      children: [
                        _buildNavItem(index, controller),
                        SizedBox(width: AppSizes.w(30)), // space for FAB
                      ],
                    );
                  }
                  return _buildNavItem(index, controller);
                }),
              );
            }),
          ),
        ),
      ), */
    );
  }

  Widget _buildNavItem(int index, MainNavBarController controller) {
    bool isSelected = controller.selectedIndex.value == index;
    return GestureDetector(
      onTap: () => controller.changeIndex(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            controller.icons[index],
            height: AppSizes.h(25),
            color: isSelected ? Colors.orange : Colors.grey,
          ),
          SizedBox(height: AppSizes.w(5)),
          Text(
            controller.labels[index],
            style: AppFonts.spaceGrotesk.copyWith(
              color: isSelected
                  ? AppColors.primaryColor
                  : AppColors.greyColor70,
            ),
            // style: TextStyle(
            //   color: isSelected ? Colors.orange : Colors.grey,
            //   fontSize: 12,
            // ),
          ),
        ],
      ),
    );
  }
}
