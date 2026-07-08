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
    super.onInit();
    // Ensure the observable page index stays in sync with the PageController.
    // This guards against any stale state if the controller is kept alive across
    // hot-restarts in development.
    initialPage.value = 0;
    log('OnboardingController ready — ${_totalPages} page(s)');
  }

  int get _totalPages => 2; // matches OnboardingModel.onboardingList.length

  void changePage(int i) {
    initialPage.value = i;
  }

  void nextPage() {
    log("Onboarding page index: ${initialPage.value}");

    final isLastPage = initialPage.value >= _totalPages - 1;

    if (!isLastPage) {
      pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // User has finished all onboarding slides — mark complete then go to login.
      localService.setOnboarding(true);
      log('Onboarding completed and saved');
      Get.offAllNamed(AppRoutes.loginScreen);
    }
  }





}
