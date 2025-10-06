import 'dart:developer';

import 'package:get/get.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/routes/app_routes.dart';

import '../../../core/user_info/user_info_controller.dart';
import '../../mission/controller/mission_controller.dart';
import '../../motivationalNudges/controller/motivational_nudges_controller.dart';

class SplashScreenController extends GetxController {
  final LocalService localService = LocalService();

  @override
  void onInit() {
    super.onInit();
    _navigateToNextPage();
    
    // checkLoginStatus();
  }

  // void checkLoginStatus() async{
  //   final token = await localService.getValue(PreferenceKey.token);
  //   if(token != null){
  //       Get.toNamed(AppRoutes.mainNavBarScreen);
  //   }else{
  //     Get.toNamed(AppRoutes.onboardingScreen);
  //   }

  // }

  void _navigateToNextPage() async {
    await Future.delayed(Duration(seconds: 2));
    log('Starting token fetch...');

    final token = await localService.getToken();
    final isFirstTime = await localService.getOnboarding();

    log('Token received: $token');
    log('Onboarding status: $isFirstTime');

    if (isFirstTime == null || isFirstTime == false) {
      log('First time or onboarding not completed');
      Get.offNamed(AppRoutes.onboardingScreen);
    } else if (token == null) {
      log('No token found. Navigating to login.');
      Get.offNamed(AppRoutes.loginScreen);
    } else {
      log('Token found. Navigating to main screen.');
      Get.offNamed(AppRoutes.mainNavBarScreen);
      Get.put(UserInfoController());
      Get.put(MotivationalNudgesController());
    }
  }



  // void _navigateToNextPage() async {
  //   await Future.delayed(Duration(seconds: 2));
  //   final token = await localService.getValue(PreferenceKey.token);
  //   log('token searching start-----------');
  //   if (token == null) {
  //     Get.toNamed(AppRoutes.loginScreen);
  //   } else {
  //     Get.toNamed(AppRoutes.mainNavBarScreen);
  //   }
  // }

  @override
  void dispose() {
    super.dispose();
  }
}
