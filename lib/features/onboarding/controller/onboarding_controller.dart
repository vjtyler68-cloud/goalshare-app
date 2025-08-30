import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:spanx/routes/app_routes.dart';

class OnboardingController extends GetxController {
  final RxInt initialPage = 0.obs;

  final PageController pageController = PageController(
    initialPage: 0,
    viewportFraction: 1,
  );

  void changePage(int i){
    initialPage.value = i;
  }

  void nextPage(){
    if (initialPage.value < 1){
      pageController.nextPage(duration: Duration(milliseconds: 10), curve: Curves.easeIn);
    }
    else{
      Get.toNamed(AppRoutes.subscriptionScreen);
    }
  }
}
