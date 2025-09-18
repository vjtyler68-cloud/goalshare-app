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

    if (initialPage.value < 1) {
      pageController.nextPage(
        duration: Duration(milliseconds: 500),
        curve: Curves.easeIn,
      );
      if (initialPage.value == 1) {
        localService.setValue(PreferenceKey.onboard, true);
      }
    } else {
      Get.toNamed(AppRoutes.subscriptionScreen);
    }
  }




}
