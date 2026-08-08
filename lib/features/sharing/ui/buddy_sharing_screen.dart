import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/features/friends/controller/friends_controller.dart';

import '../controller/sharing_controller.dart';

const _kBg = Color(0xffF6F4F2);
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// Where you decide who — if anyone — can see your nutrition or workout summary.
/// Everything starts private; a section is shared with a friend only when you
/// switch it on for that specific person.
class BuddySharingScreen extends StatefulWidget {
  const BuddySharingScreen({super.key});

  @override
  State<BuddySharingScreen> createState() => _BuddySharingScreenState();
}

class _BuddySharingScreenState extends State<BuddySharingScreen> {
  Color get _accent => AppColors.primaryColor;

  @override
  void initState() {
    super.initState();
    // Opening this screen is a good moment to refresh the summaries granted
    // buddies will see (the user's data is typically fresh in-app by now).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SharingController.to.pushIfSharing(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back, color: _kText)),
        title: Text('Buddy Sharing',
            style: AppFonts.spaceGrotesk
                .copyWith(color: _kText, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 30.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _intro(),
            SizedBox(height: 18.h),
            Text('Your friends',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
            SizedBox(height: 4.h),
            Text('Switch on what each person can see. Off = private.',
                style: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 12.5.sp, color: _kMuted)),
            SizedBox(height: 12.h),
            _friends(),
          ],
        ),
      ),
    );
  }

  Widget _intro() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _accent.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: _accent, size: 22.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
                'Your nutrition and workouts are private by default. Only the friends you switch on below can see your summary — and only that summary, never your raw logs.',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 12.5.sp, height: 1.4, color: _kText)),
          ),
        ],
      ),
    );
  }

  Widget _friends() {
    return Obx(() {
      final friends = FriendsController.to.friends;
      if (friends.isEmpty) {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            children: [
              Icon(Icons.group_add_outlined, size: 34.r, color: _kMuted),
              SizedBox(height: 8.h),
              Text('No friends yet',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: _kText)),
              SizedBox(height: 4.h),
              Text('Add friends from the People tab to share with them.',
                  textAlign: TextAlign.center,
                  style: AppFonts.spaceGrotesk
                      .copyWith(fontSize: 12.5.sp, color: _kMuted)),
            ],
          ),
        );
      }
      return Column(
        children: [for (final f in friends) _friendRow(f.id, f.name, f.username, f.profile)],
      );
    });
  }

  Widget _friendRow(String id, String name, String? username, String? avatar) {
    final display = name.isNotEmpty ? name : (username ?? 'Friend');
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _avatar(avatar ?? '', display),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(display,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: _kText)),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Obx(() {
            final c = SharingController.to;
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _toggle('Nutrition', Icons.restaurant_rounded,
                          c.isSharing(id, 'nutrition'),
                          () => c.setGrant(id, 'nutrition',
                              !c.isSharing(id, 'nutrition'))),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _toggle('Workout', Icons.fitness_center_rounded,
                          c.isSharing(id, 'workout'),
                          () => c.setGrant(
                              id, 'workout', !c.isSharing(id, 'workout'))),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                // GoFlow shares only a phase label + optional status line —
                // never raw cycle logs.
                _toggle('GoFlow', Icons.spa_rounded, c.isSharing(id, 'goflow'),
                    () => c.setGrant(id, 'goflow', !c.isSharing(id, 'goflow'))),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _toggle(String label, IconData icon, bool on, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44.h,
        decoration: BoxDecoration(
          color: on ? _accent : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
              color: on ? _accent : const Color(0xffE6E0DE), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(on ? icon : icon,
                size: 16.r, color: on ? Colors.white : _kMuted),
            SizedBox(width: 6.w),
            Text(label,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: on ? Colors.white : _kText)),
            SizedBox(width: 6.w),
            Icon(on ? Icons.check_circle : Icons.circle_outlined,
                size: 15.r, color: on ? Colors.white : _kMuted),
          ],
        ),
      ),
    );
  }

  Widget _avatar(String url, String name) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: 42.r,
      height: 42.r,
      decoration:
          BoxDecoration(shape: BoxShape.circle, color: _accent.withOpacity(0.12)),
      child: ClipOval(
        child: url.isNotEmpty
            ? Image.network(url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initFill(initial))
            : _initFill(initial),
      ),
    );
  }

  Widget _initFill(String initial) => Center(
        child: Text(initial,
            style: AppFonts.spaceGrotesk.copyWith(
                color: _accent, fontSize: 16.sp, fontWeight: FontWeight.w800)),
      );
}
