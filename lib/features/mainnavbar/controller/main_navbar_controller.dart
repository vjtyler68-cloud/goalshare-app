import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_icons.dart';
import 'package:spanx/features/home/screen/home_screen.dart';

import '../../goals/screen/goals_screen.dart';

class MainNavBarController extends GetxController {
  RxInt selectedIndex = 0.obs;

  void changeIndex(int i) {
    selectedIndex.value = i;
  }

  final List<String> labels = ['Home', 'Goals', 'Analytics', 'Profile'];
  final List<String> icons = [
    AppIcons.home,
    AppIcons.goals,
    AppIcons.analytics,
    AppIcons.person,
  ];

  final List<Widget> pages = [
    HomeScreen(),
    GoalsScreen(),
    Center(child: Text('data')),
    Center(child: Text('data')),
  ];
}
