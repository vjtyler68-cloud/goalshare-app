import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/routes/app_routes.dart';

import '../../../core/user_info/user_info_controller.dart';
import '../../motivationalNudges/controller/motivational_nudges_controller.dart';

class SplashScreenController extends GetxController {
  final LocalService localService = LocalService();
  final logger = Logger();

  // Ensures we navigate away from the splash exactly once, no matter which path
  // (auto-login success, fallback, or the hard timeout) gets there first.
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

    final isFirstTime = await localService.getOnboarding();

    // Always mark onboarding complete so admin auto-login works on fresh installs
    if (isFirstTime == null || isFirstTime == false) {
      await localService.setOnboarding(true);
    }

    // BULLETPROOF: never let a slow/unreachable backend freeze the splash.
    // Try auto-login, but if it doesn't finish within 6s, stop waiting and go
    // straight to the login screen. (The backend DB can take ~30s to fail when
    // it's down — we must not block on that.)
    try {
      await _autoLoginAdmin().timeout(const Duration(seconds: 6));
    } catch (e) {
      log('Splash: auto-login slow/failed ($e) — going to login');
      _goOnce(AppRoutes.loginScreen);
    }
  }

  Future<void> _autoLoginAdmin() async {
    log('Auto-login as admin...');
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.login,
        jsonEncode({'email': 'admin@gmail.com', 'password': '123456'}),
        is_auth: false,
      );

      if (response != null && response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        final token = data['accessToken'] as String?;
        final userId = data['id'] as String?;

        if (token != null) await localService.setToken(token);
        if (userId != null) await localService.setUserId(userId);

        log('Admin auto-login success — navigating to home');
        Get.find<MotivationalNudgesController>();
        _goOnce(AppRoutes.mainNavBarScreen);
      } else {
        log('Auto-login failed — falling back to saved token check');
        await _checkSavedToken();
      }
    } catch (e) {
      log('Auto-login error: $e — falling back to saved token');
      await _checkSavedToken();
    }
  }

  Future<void> _checkSavedToken() async {
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

  @override
  void dispose() {
    super.dispose();
  }
}
