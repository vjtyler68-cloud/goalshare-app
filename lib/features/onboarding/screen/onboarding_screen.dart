import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_images.dart';
import 'package:spanx/core/const/app_size.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';
import 'package:spanx/features/onboarding/controller/onboarding_controller.dart';
import 'package:spanx/features/onboarding/model/onboarding_model.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    OnboardingController onboardingController = Get.put(OnboardingController());
    return Obx(() {
        return BackgroundScreen(
          bgImg: onboardingController.initialPage.value == 0
              ? AppImages.onboarding1
              : AppImages.onboarding2,
          child: SafeArea(
            child: PageView.builder(
              physics: NeverScrollableScrollPhysics(),
              controller: onboardingController.pageController,
              onPageChanged: onboardingController.changePage,
              itemCount: OnboardingModel.onboardingList.length,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.w(20),
                  vertical: AppSizes.h(30),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // slogan
                    Text(
                      OnboardingModel.onboardingList[index].slogan,
                      style: AppFonts.playfair.copyWith(
                        fontSize: AppSizes.sp(38),
                        fontWeight: FontWeight.bold,
                        color: AppColors.blackColor,
                        height: AppSizes.h(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSizes.h(15)),

                    // sub slogan
                    Text(
                      OnboardingModel.onboardingList[index].subSlogan,
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: AppSizes.sp(14),
                        fontWeight: FontWeight.bold,
                        color: AppColors.greyColor,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: AppSizes.h(30)),

                    // button
                    SizedBox(
                      width: double.infinity,
                      child: CustomButtonWidget(
                        onTap: onboardingController.nextPage,
                        row2: Text(
                          ">>",
                          style: AppFonts.spaceGrotesk.copyWith(
                            color: AppColors.whiteColor,
                            fontSize: AppSizes.sp(16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        buttonText: 'Next',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }
}
