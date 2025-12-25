import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/routes/app_routes.dart';

class OnboardingController extends GetxController {
  final RxInt initialPage = 0.obs;
  final LocalService localService = LocalService();

  final PageController pageController = PageController(
    initialPage: 0,
    viewportFraction: 1,
  );

@override
  void onInit() {
    // TODO: implement onInit
    super.onInit();

  }
  void changePage(int i) {
    initialPage.value = i;
  }

  void nextPage() {
    log("Check page index---------- ${initialPage.value}");

    if (initialPage.value < 1) {
      pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      localService.setOnboarding(true);
      log('Onboarding completed and saved');
    } else {
      // Set onboarding as completed

      // Navigate to login or home
      Get.offAllNamed(AppRoutes.loginScreen);
    }
  }





}
