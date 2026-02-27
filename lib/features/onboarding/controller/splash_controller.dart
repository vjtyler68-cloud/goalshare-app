import 'dart:developer';

import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/routes/app_routes.dart';

import '../../../core/user_info/user_info_controller.dart';
import '../../motivationalNudges/controller/motivational_nudges_controller.dart';

class SplashScreenController extends GetxController {
  final LocalService localService = LocalService();
  final logger = Logger();

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
    await Future.delayed(const Duration(seconds: 2));
    log('Starting token fetch...');

    final token = await localService.getToken();
    final isFirstTime = await localService.getOnboarding();

    logger.d('Token received: $token');
    logger.d('Onboarding status: $isFirstTime');

    if (isFirstTime == null || isFirstTime == false) {
      log('First time or onboarding not completed');
      Get.offNamed(AppRoutes.onboardingScreen);
    } else if (token == null) {
      log('No token found. Navigating to login.');
      Get.offNamed(AppRoutes.loginScreen);
    } else {
      log('Token found. Navigating to main screen.');

      // Get or create UserInfoController and WAIT for data to load
      final userInfoController = Get.put(UserInfoController());
      await userInfoController.loadAndSetUserInfo();

      // Now check subscription status after data is loaded
      if (isSubscriptionActive()) {
        Get.find<MotivationalNudgesController>();
        Get.offNamed(AppRoutes.mainNavBarScreen);
      } else {
        log('Subscription inactive. Navigating to subscription screen.');
        Get.offNamed(AppRoutes.subscriptionEnd);
      }
    }
  }

  bool isSubscriptionActive() {
    final now = DateTime.now().toUtc();
    final userData = Get.find<UserInfoController>().userData.value;
    final endDate = userData?.subscriptionEnd;
    final startDate = userData?.subscriptionStart;

    log("=== SUBSCRIPTION CHECK ===");
    log("Current Time (UTC): $now");
    log("Subscription Start: $startDate");
    log("Subscription End: $endDate");
    log("User Data Available: ${userData != null}");
    log("Full User Data: ${userData?.toJson()}");
    log("========================");

    if (endDate == null) {
      log("⚠️ No subscription end date found");
      return false;
    }

    final isActive = endDate.toUtc().isAfter(now);
    log("Subscription Active: $isActive");
    return isActive;
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
