import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_icons.dart';
import 'package:spanx/features/analytics_tab/ui/analytics_ui.dart';
import 'package:spanx/features/home/screen/home_screen.dart';
import 'package:spanx/features/profile_tab/ui/profile_tab.dart';

import '../../mission/screen/mission_screen.dart';


class MainNavBarController extends GetxController {
  RxInt selectedIndex = 0.obs;

  void changeIndex(int i) {
    selectedIndex.value = i;
  }

  final List<String> labels = ['Home', 'Mission', 'Analytics', 'Profile'];
  final List<String> icons = [
    AppIcons.home,
    AppIcons.goals,
    AppIcons.analytics,
    AppIcons.person,
  ];

  final List<Widget> pages = [
    HomeScreen(),
    MissionScreen(),
    AnalyticsPage(),
    ProfileTabPage()
  ];
}
