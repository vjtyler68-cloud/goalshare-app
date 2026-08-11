import 'dart:developer';

import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/features/workout/controller/workout_controller.dart';
import 'package:spanx/core/utils/test_accounts.dart';
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
    // We do NOT mark the flag here — OnboardingController sets it only after
    // the user taps through every slide. This way a force-quit mid-onboarding
    // sends them back to the start instead of silently skipping to login.
    final isFirstTime = await localService.getOnboarding();
    if (isFirstTime == null || isFirstTime == false) {
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
      // Offline-first: before giving up, try the locally cached profile so a
      // rep with no signal still gets into the app with their valid session.
      log('Splash: session restore slow/failed ($e) — trying offline cache');
      try {
        final userInfoController = Get.put(UserInfoController());
        final restored = await userInfoController.restoreFromCache();
        if (restored && isSubscriptionActive()) {
          Get.find<MotivationalNudgesController>();
          _goOnce(AppRoutes.mainNavBarScreen);
          return;
        }
      } catch (_) {}
      _goOnce(AppRoutes.loginScreen);
    }
  }

  Future<void> _restoreSession() async {
    final token = await localService.getToken();
    if (token == null) {
      _goOnce(AppRoutes.loginScreen);
      return;
    }

    // Slide the session forward on every launch so an active user's token never
    // reaches its 21-day expiry. Fire-and-forget: it must not slow the splash or
    // block session restore (it never logs the user out on its own).
    NetworkConfig.instance.renewSession();

    final userInfoController = Get.put(UserInfoController());
    await userInfoController.loadAndSetUserInfo();

    if (isSubscriptionActive()) {
      Get.find<MotivationalNudgesController>();
      _goOnce(AppRoutes.mainNavBarScreen);
      // Drop the user straight back into an in-progress workout they were in, so
      // switching apps mid-session doesn't dump them on Home. Fire-and-forget so
      // it never blocks/slows the splash.
      _maybeResumeActiveWorkout();
    } else {
      _goOnce(AppRoutes.subscriptionEnd);
    }
  }

  /// If a workout is still in progress and was started recently, re-open it on
  /// launch. The session itself is always preserved (autosaved); this just puts
  /// the rep back where they were instead of on Home. A stale session (hours old)
  /// is left alone — they can still resume it from the MY WORKOUT banner.
  Future<void> _maybeResumeActiveWorkout() async {
    try {
      final c = WorkoutController.to; // permanent singleton, safe to touch
      // Wait briefly for the persisted active session to load (async bootstrap).
      for (int i = 0; i < 30 && !c.isReady; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      final s = c.active.value;
      if (s == null || !s.isActive) return;
      final ageMin =
          (DateTime.now().millisecondsSinceEpoch - s.startedAtMs) / 60000.0;
      if (ageMin <= 180 && Get.currentRoute == AppRoutes.mainNavBarScreen) {
        Get.toNamed(AppRoutes.activeWorkoutScreen);
      }
    } catch (_) {
      // Never let resume logic interfere with a normal launch.
    }
  }

  bool isSubscriptionActive() {
    final now = DateTime.now().toUtc();
    final userData = Get.find<UserInfoController>().userData.value;
    final role = userData?.role ?? '';
    final endDate = userData?.subscriptionEnd;

    if (role.toUpperCase() == 'ADMIN') return true;
    if (isTestAccount(userData?.email)) return true;
    if (endDate == null) return false;
    return endDate.toUtc().isAfter(now);
  }
}
