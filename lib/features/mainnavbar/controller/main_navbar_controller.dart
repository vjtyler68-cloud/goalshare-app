import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spanx/core/const/app_icons.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/routes/app_routes.dart';
import 'package:spanx/features/achievements/achievements_controller.dart';
import 'package:spanx/features/chat_tab/ui/chat_message.dart';
import 'package:spanx/features/goals/screen/goals_screen.dart';
import 'package:spanx/features/home/controller/quick_access_controller.dart';
import 'package:spanx/features/home/screen/home_screen.dart';
import 'package:spanx/features/profile_tab/ui/profile_tab.dart';

import '../../mission/screen/mission_screen.dart';

class MainNavBarController extends GetxController {
  RxInt selectedIndex = 0.obs;
  final RxBool isFabTapped = false.obs;

  @override
  void onInit() {
    super.onInit();
    if (!Get.isRegistered<AchievementsController>()) {
      Get.put(AchievementsController(), permanent: true);
    }
    _maybeShowWalkthrough();
    _maybeResumeCanvass();
  }

  /// If the app was killed while the user was in Sales Ranch (iOS reclaiming
  /// memory — common after popping out to Apple Maps for directions), reopening
  /// drops them right back into Sales Ranch instead of the home dashboard, so a
  /// canvassing session isn't interrupted. Only when it was recent (last 6h);
  /// leaving on purpose clears the flag. Walkthrough users never have the flag.
  Future<void> _maybeResumeCanvass() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool('canvass_resume') ?? false)) return;
      final at = prefs.getInt('canvass_resume_at') ?? 0;
      final recent =
          DateTime.now().millisecondsSinceEpoch - at < 6 * 60 * 60 * 1000;
      if (!recent) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.currentRoute == AppRoutes.mainNavBarScreen) {
          Get.toNamed(AppRoutes.canvassScreen);
        }
      });
    } catch (_) {}
  }

  /// Show the new-user walkthrough once, the first time a freshly-signed-up
  /// account reaches the main app. Consumes the pending flag so it never
  /// repeats, and never fires for existing users logging back in.
  Future<void> _maybeShowWalkthrough() async {
    try {
      final local = LocalService();
      final pending = await local.getPendingWalkthrough();
      if (!pending) return;
      if (await local.getWalkthroughDone()) {
        await local.setPendingWalkthrough(false);
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.currentRoute == AppRoutes.mainNavBarScreen) {
          Get.toNamed(AppRoutes.welcomeWalkthroughScreen);
        }
      });
    } catch (_) {
      // Never let the walkthrough check interfere with a normal launch.
    }
  }

  void toggleFabTapped() {
    isFabTapped.value = !isFabTapped.value;
  }

  void changeIndex(int i) {
    // Leaving the Home tab always ends dashboard edit mode, so nobody returns
    // to a grid whose cards silently ignore taps.
    if (i != 0 && Get.isRegistered<QuickAccessController>()) {
      Get.find<QuickAccessController>().exitEditMode();
    }
    selectedIndex.value = i;
  }

  final List<String> labels = ['Home', 'Mission', 'Goals', 'Messages', 'Profile'];
  final List<String> icons = [
    AppIcons.home,
    AppIcons.goals,
    AppIcons.goals,
    AppIcons.person,
    AppIcons.person,
  ];

  final List<Widget> pages = [
    HomeScreen(),
    MissionScreen(),
    GoalsScreen(),
    MessagesPage(),
    ProfileTabPage(),
  ];
}
