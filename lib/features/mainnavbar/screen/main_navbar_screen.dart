import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/achievement_toast.dart';
import 'package:spanx/features/mainnavbar/controller/main_navbar_controller.dart';

import '../../../core/alertdialogs/create_new_mission.dart';

const _kRed   = Color(0xffE84040);
const _kRedDk = Color(0xff9B1414);

class MainNavbarScreen extends GetView<MainNavBarController> {
  const MainNavbarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AchievementListener(
      child: Scaffold(
        backgroundColor: const Color(0xffF6F4F2),
        body: Stack(
          children: [
            // Page content
            Obx(() => controller.pages[controller.selectedIndex.value]),

            // Bottom nav bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BottomNavBar(controller: controller),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final MainNavBarController controller;
  const _BottomNavBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64.h,
          child: Obx(() {
            final sel = controller.selectedIndex.value;
            return Row(
              children: [
                // Home
                _NavItem(
                  index: 0,
                  selected: sel,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: 'Home',
                  controller: controller,
                ),
                // Mission
                _NavItem(
                  index: 1,
                  selected: sel,
                  icon: Icons.flag_outlined,
                  activeIcon: Icons.flag_rounded,
                  label: 'Mission',
                  controller: controller,
                ),

                // FAB centre
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      CreateNewMission.show();
                      controller.toggleFabTapped();
                    },
                    child: Center(
                      child: Container(
                        width: 52.r,
                        height: 52.r,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kRed, _kRedDk],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _kRed.withOpacity(0.45),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ),

                // Goals
                _NavItem(
                  index: 2,
                  selected: sel,
                  icon: Icons.track_changes_outlined,
                  activeIcon: Icons.track_changes_rounded,
                  label: 'Goals',
                  controller: controller,
                ),
                // Messages
                _NavItem(
                  index: 3,
                  selected: sel,
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  label: 'Messages',
                  controller: controller,
                ),
                // Profile
                _NavItem(
                  index: 4,
                  selected: sel,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  controller: controller,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int selected;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final MainNavBarController controller;

  const _NavItem({
    required this.index,
    required this.selected,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeIndex(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? _kRed : const Color(0xffB0AAAA),
                size: 22,
              ),
            ),
            SizedBox(height: 2.h),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 9.sp,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? _kRed : const Color(0xffB0AAAA),
              ),
              child: Text(label),
            ),
            SizedBox(height: 2.h),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 16 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: _kRed,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
