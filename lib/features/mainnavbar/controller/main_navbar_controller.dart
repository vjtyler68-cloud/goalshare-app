import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_icons.dart';
import 'package:spanx/features/achievements/achievements_controller.dart';
import 'package:spanx/features/chat_tab/ui/chat_message.dart';
import 'package:spanx/features/goals/screen/goals_screen.dart';
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
  }

  void toggleFabTapped() {
    isFabTapped.value = !isFabTapped.value;
  }

  void changeIndex(int i) {
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
