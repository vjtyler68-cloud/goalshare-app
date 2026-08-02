import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/features/friends/controller/friends_controller.dart';

import '../controller/buddies_controller.dart';
import 'accountability_match_screen.dart';
import 'buddy_questionnaire_screen.dart';

const _kBg = Color(0xffF6F4F2);
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// The Buddies home. Shows the right thing for the user's state:
/// onboarding intro → find-a-buddy (friend pick + weekly opt-in) → matched.
class BuddiesHubScreen extends StatelessWidget {
  const BuddiesHubScreen({super.key});

  Color get _accent => AppColors.primaryColor;

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
        title: Text('Accountability Buddies',
            style: AppFonts.spaceGrotesk.copyWith(
                color: _kText, fontWeight: FontWeight.w800, fontSize: 17.sp)),
        centerTitle: true,
        actions: [
          Obx(() {
            final c = BuddiesController.to;
            if (!c.hasProfile) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'Edit profile',
              onPressed: () => Get.to(() => const BuddyQuestionnaireScreen()),
              icon: Icon(Icons.tune_rounded, color: _accent),
            );
          }),
        ],
      ),
      body: Obx(() {
        final c = BuddiesController.to;
        if (!c.ready.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (c.needsOnboarding) return _intro();
        if (c.isMatched) return _matchedSummary(c);
        return _findBuddy(c);
      }),
    );
  }

  // ── Onboarding intro ────────────────────────────────────────────────────────
  Widget _intro() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(22.w, 10.h, 22.w, 30.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(22.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accent, AppColors.primaryDarkColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🤝', style: TextStyle(fontSize: 42.sp)),
                SizedBox(height: 10.h),
                Text('Find your accountability buddy',
                    style: AppFonts.spaceGrotesk.copyWith(
                        color: Colors.white,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        height: 1.2)),
                SizedBox(height: 8.h),
                Text(
                    'Team up for a week, check in, ask great questions, and push each other to show up. Answer a few questions and we\'ll help you match.',
                    style: AppFonts.spaceGrotesk.copyWith(
                        color: Colors.white70,
                        fontSize: 13.5.sp,
                        height: 1.4)),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          _howItWorks(),
          SizedBox(height: 22.h),
          _bigButton('Set up my buddy profile',
              () => Get.to(() => const BuddyQuestionnaireScreen())),
        ],
      ),
    );
  }

  Widget _howItWorks() {
    Widget row(IconData i, String t, String s) => Padding(
          padding: EdgeInsets.only(bottom: 14.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38.r,
                height: 38.r,
                decoration: BoxDecoration(
                    color: _accent.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(i, color: _accent, size: 20.r),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t,
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 14.5.sp,
                            fontWeight: FontWeight.w800,
                            color: _kText)),
                    SizedBox(height: 2.h),
                    Text(s,
                        style: AppFonts.spaceGrotesk
                            .copyWith(fontSize: 12.5.sp, color: _kMuted)),
                  ],
                ),
              ),
            ],
          ),
        );
    return Column(
      children: [
        row(Icons.person_search_rounded, 'Get matched',
            'Pick a friend, or opt into weekly matching with a compatible buddy.'),
        row(Icons.forum_rounded, 'Check in daily',
            'A fresh supportive question each day keeps it real, not robotic.'),
        row(Icons.star_rounded, 'Rate the cycle',
            'After 7 days, rate each other. Build your Reliable Buddy reputation.'),
      ],
    );
  }

  // ── Matched summary ─────────────────────────────────────────────────────────
  Widget _matchedSummary(BuddiesController c) {
    final m = c.currentMatch.value!;
    final uid = c.myUserId;
    final days = m.daysRemaining();
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 30.h),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => Get.to(() => const AccountabilityMatchScreen()),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(18.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18.r),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 10),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 54.r,
                    height: 54.r,
                    decoration: BoxDecoration(
                        color: _accent.withOpacity(0.12),
                        shape: BoxShape.circle),
                    child: Icon(Icons.handshake_rounded,
                        color: _accent, size: 26.r),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('This week\'s buddy',
                            style: AppFonts.spaceGrotesk.copyWith(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w700,
                                color: _kMuted)),
                        SizedBox(height: 2.h),
                        Text(m.buddyNameFor(uid).isEmpty
                            ? 'Your buddy'
                            : m.buddyNameFor(uid),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.spaceGrotesk.copyWith(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w800,
                                color: _kText)),
                        SizedBox(height: 2.h),
                        Text(
                            m.status == 'completed' || m.isOver
                                ? 'Cycle complete — tap to rate'
                                : (days == 0
                                    ? 'Last day — tap to check in'
                                    : '$days ${days == 1 ? 'day' : 'days'} left — tap to open'),
                            style: AppFonts.spaceGrotesk.copyWith(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w600,
                                color: _accent)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 15, color: Color(0xffB0AAAA)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Find a buddy ────────────────────────────────────────────────────────────
  Widget _findBuddy(BuddiesController c) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 30.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly random opt-in
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.casino_rounded, color: _accent, size: 20.r),
                    SizedBox(width: 8.w),
                    Text('Get matched this week',
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            color: _kText)),
                    const Spacer(),
                    Obx(() => Switch.adaptive(
                          value: BuddiesController.to.isOptedIn,
                          activeColor: _accent,
                          onChanged: (v) => c.setOptIn(v),
                        )),
                  ],
                ),
                SizedBox(height: 4.h),
                Obx(() => Text(
                      BuddiesController.to.isOptedIn
                          ? 'You\'re in the pool. New buddies are matched every Monday.'
                          : 'Opt in and we\'ll pair you with a compatible buddy every Monday.',
                      style: AppFonts.spaceGrotesk
                          .copyWith(fontSize: 12.5.sp, color: _kMuted),
                    )),
              ],
            ),
          ),
          SizedBox(height: 22.h),
          Text('Or start now with a friend',
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 15.sp, fontWeight: FontWeight.w800, color: _kText)),
          SizedBox(height: 4.h),
          Text('Pair up instantly for a 7-day cycle.',
              style: AppFonts.spaceGrotesk
                  .copyWith(fontSize: 12.5.sp, color: _kMuted)),
          SizedBox(height: 12.h),
          _friendsList(c),
          SizedBox(height: 20.h),
          Center(
            child: TextButton.icon(
              onPressed: () async {
                await c.debugCreateTestBuddy();
                Get.to(() => const AccountabilityMatchScreen());
              },
              icon: Icon(Icons.play_circle_outline, size: 18.r, color: _kMuted),
              label: Text('See how it works (sample buddy)',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: _kMuted)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _friendsList(BuddiesController c) {
    final friends = FriendsController.to.friends;
    if (friends.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(18.r),
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
            Text(
                'Add friends from the People tab, or opt into weekly matching above.',
                textAlign: TextAlign.center,
                style: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 12.5.sp, color: _kMuted)),
          ],
        ),
      );
    }
    return Column(
      children: [
        for (final f in friends)
          Container(
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.03), blurRadius: 6),
              ],
            ),
            child: Row(
              children: [
                _miniAvatar(f.profile ?? '', f.name),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(f.name.isEmpty ? (f.username ?? 'Friend') : f.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: _kText)),
                ),
                GestureDetector(
                  onTap: () => _chooseFriend(c, f.id, f.name, f.profile ?? ''),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text('Choose',
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _chooseFriend(
      BuddiesController c, String id, String name, String avatar) async {
    final match = await c.createMatchWithBuddy(
      buddyId: id,
      buddyName: name,
      buddyAvatar: avatar,
    );
    if (match != null) {
      AppSnackBar.success('You\'re paired with ${name.isEmpty ? 'your buddy' : name}!');
      Get.to(() => const AccountabilityMatchScreen());
    }
  }

  Widget _miniAvatar(String url, String name) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: 40.r,
      height: 40.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _accent.withOpacity(0.12),
      ),
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

  Widget _bigButton(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 54.h,
          decoration: BoxDecoration(
              color: _accent, borderRadius: BorderRadius.circular(16.r)),
          alignment: Alignment.center,
          child: Text(label,
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white)),
        ),
      );
}
