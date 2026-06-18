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

  // Ensures we navigate away from the splash exactly once, no matter which path
  // (session restore, onboarding, fallback, or the hard timeout) gets there first.
  bool _navigated = false;
  void _goOnce(String route) {
    if (_navigated) return;
    _navigated = true;
    Get.offNamed(route);
  }

  @override
  void onInit() {
    super.onInit();
    _navigateToNextPage();
  }

  void _navigateToNextPage() async {
    await Future.delayed(const Duration(seconds: 2));

    // First-time users see onboarding; they sign in / sign up from there.
    final isFirstTime = await localService.getOnboarding();
    if (isFirstTime == null || isFirstTime == false) {
      await localService.setOnboarding(true);
      _goOnce(AppRoutes.onboardingScreen);
      return;
    }

    // Returning users: restore their session from the saved token. Never let a
    // slow/unreachable backend freeze the splash — if session restore doesn't
    // finish within 6s, stop waiting and go to the login screen. (A down backend
    // DB can take ~30s to fail; we must not block on that.)
    try {
      await _restoreSession().timeout(const Duration(seconds: 6));
    } catch (e) {
      log('Splash: session restore slow/failed ($e) — going to login');
      _goOnce(AppRoutes.loginScreen);
    }
  }

  Future<void> _restoreSession() async {
    final token = await localService.getToken();
    if (token == null) {
      _goOnce(AppRoutes.loginScreen);
      return;
    }

    final userInfoController = Get.put(UserInfoController());
    await userInfoController.loadAndSetUserInfo();

    if (isSubscriptionActive()) {
      Get.find<MotivationalNudgesController>();
      _goOnce(AppRoutes.mainNavBarScreen);
    } else {
      _goOnce(AppRoutes.subscriptionEnd);
    }
  }

  bool isSubscriptionActive() {
    final now = DateTime.now().toUtc();
    final userData = Get.find<UserInfoController>().userData.value;
    final role = userData?.role ?? '';
    final endDate = userData?.subscriptionEnd;

    if (role.toUpperCase() == 'ADMIN') return true;
    if (endDate == null) return false;
    return endDate.toUtc().isAfter(now);
  }
}
