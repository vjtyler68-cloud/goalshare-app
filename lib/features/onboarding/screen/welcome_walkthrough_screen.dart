import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/features/achievements/achievements_controller.dart';
import 'package:spanx/features/goals/controller/goals_controller.dart';
import 'package:spanx/features/home/controller/home_controller.dart';

/// The new-user walkthrough — a short guided setup shown once, right after a
/// new account first lands in the app. It welcomes them, captures their "why"
/// and first goals, gives a 30-second tour of how GoalShare works, and hands
/// them their first XP so the reward loop clicks on day one.
enum _Step { welcome, why, goals, tour, done }

class WelcomeWalkthroughScreen extends StatefulWidget {
  const WelcomeWalkthroughScreen({super.key});

  @override
  State<WelcomeWalkthroughScreen> createState() =>
      _WelcomeWalkthroughScreenState();
}

class _WelcomeWalkthroughScreenState extends State<WelcomeWalkthroughScreen> {
  final PageController _page = PageController();
  final TextEditingController _why = TextEditingController();
  final TextEditingController _goal = TextEditingController();
  final List<String> _addedGoals = [];
  int _index = 0;
  bool _finished = false;

  static const List<_Step> _steps = [
    _Step.welcome,
    _Step.why,
    _Step.goals,
    _Step.tour,
    _Step.done,
  ];

  final LocalService _local = LocalService();
  Color get _red => AppColors.primaryColor;

  HomeController get _home => Get.isRegistered<HomeController>()
      ? Get.find<HomeController>()
      : Get.put(HomeController());
  GoalsController get _goals => Get.isRegistered<GoalsController>()
      ? Get.find<GoalsController>()
      : Get.put(GoalsController());
  AchievementsController get _ach => Get.isRegistered<AchievementsController>()
      ? Get.find<AchievementsController>()
      : Get.put(AchievementsController(), permanent: true);

  @override
  void dispose() {
    _page.dispose();
    _why.dispose();
    _goal.dispose();
    super.dispose();
  }

  Future<void> _markDone() async {
    try {
      await _local.setWalkthroughDone(true);
      await _local.setPendingWalkthrough(false);
    } catch (_) {}
  }

  Future<void> _skip() async {
    await _markDone();
    Get.back();
  }

  void _next() {
    if (_index >= _steps.length - 1) {
      _complete();
      return;
    }
    if (_steps[_index + 1] == _Step.done) _completeSaves();
    HapticFeedback.selectionClick();
    _page.nextPage(
        duration: const Duration(milliseconds: 320), curve: Curves.easeInOut);
  }

  /// Persist the why + award the welcome XP as we cross into the final step.
  Future<void> _completeSaves() async {
    if (_finished) return;
    _finished = true;
    // Save their "why" to My Why (backend-synced), without popping this screen.
    final why = _why.text.trim();
    if (why.isNotEmpty) {
      try {
        _home.myWhyAffirmation.text = why;
        await _home.createHomeMyWhy(closeSheet: false);
      } catch (_) {}
    }
    try {
      await _ach.awardOncePerDay('welcome', 50); // first XP on day one
    } catch (_) {}
    HapticFeedback.heavyImpact();
  }

  Future<void> _complete() async {
    await _markDone();
    Get.back();
  }

  void _addGoal() {
    final t = _goal.text.trim();
    if (t.isEmpty) return;
    if (_addedGoals.length >= 5) return;
    try {
      _goals.addGoal(title: t, timeframe: 'Weekly', target: 1, emoji: '🎯');
    } catch (_) {}
    setState(() {
      _addedGoals.add(t);
      _goal.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_red, AppColors.primaryDarkColor, const Color(0xff2A1020)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _topBar(),
              Expanded(
                child: PageView(
                  controller: _page,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _index = i),
                  children: [
                    _welcomePage(),
                    _whyPage(),
                    _goalsPage(),
                    _tourPage(),
                    _donePage(),
                  ],
                ),
              ),
              _bottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    final total = _steps.length - 1; // exclude the done page from the count
    final shown = _index.clamp(0, total);
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: LinearProgressIndicator(
                value: _index >= total ? 1 : shown / total,
                minHeight: 6.h,
                backgroundColor: Colors.white.withOpacity(0.18),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ),
          SizedBox(width: 14.w),
          if (_steps[_index] != _Step.done)
            GestureDetector(
              onTap: _skip,
              child: Text('Skip',
                  style: AppFonts.spaceGrotesk.copyWith(
                      color: Colors.white70,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    final step = _steps[_index];
    final label = switch (step) {
      _Step.done => 'Let\'s win 🚀',
      _Step.goals => _addedGoals.isEmpty ? 'Skip for now' : 'Continue',
      _Step.tour => 'Got it',
      _ => 'Continue',
    };
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 20.h),
      child: GestureDetector(
        onTap: _next,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Center(
            child: Text(label,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: _red)),
          ),
        ),
      ),
    );
  }

  // ── shared bits ────────────────────────────────────────────────────────────
  Widget _scroll(Widget child) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
        child: child,
      );

  Widget _eyebrow(String text) => Text(text.toUpperCase(),
      style: AppFonts.spaceGrotesk.copyWith(
          color: Colors.white70,
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5));

  Widget _heading(String text) => Text(text,
      style: AppFonts.spaceGrotesk.copyWith(
          color: Colors.white,
          fontSize: 26.sp,
          fontWeight: FontWeight.w900,
          height: 1.15));

  Widget _glass({required Widget child}) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: child,
      );

  InputDecoration _fieldDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            AppFonts.spaceGrotesk.copyWith(color: Colors.white54, fontSize: 15.sp),
        filled: true,
        fillColor: Colors.white.withOpacity(0.12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      );

  // ── pages ──────────────────────────────────────────────────────────────────
  Widget _welcomePage() {
    return _scroll(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24.h),
        Text('👋', style: TextStyle(fontSize: 60.sp)),
        SizedBox(height: 18.h),
        _heading('Welcome to GoalShare.\nBecome who you said\nyou\'d be.'),
        SizedBox(height: 14.h),
        Text(
            'One place for your whole disciplined life — faith, fitness, food, '
            'money, and your team. Let\'s spend 60 seconds getting you set up.',
            style: AppFonts.spaceGrotesk.copyWith(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14.sp,
                height: 1.6)),
        SizedBox(height: 22.h),
        _glass(
          child: Row(
            children: [
              Text('🎁', style: TextStyle(fontSize: 26.sp)),
              SizedBox(width: 12.w),
              Expanded(
                child: Text('Finish this quick setup and earn your first 50 XP.',
                    style: AppFonts.spaceGrotesk.copyWith(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ],
    ));
  }

  Widget _whyPage() {
    return _scroll(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10.h),
        _eyebrow('Your Why'),
        SizedBox(height: 16.h),
        _heading('Why are you here?'),
        SizedBox(height: 10.h),
        Text('Your deeper reason — the thing that keeps you going when '
            'motivation runs dry. We\'ll keep it in your My Why.',
            style: AppFonts.spaceGrotesk.copyWith(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13.sp,
                height: 1.5)),
        SizedBox(height: 18.h),
        TextField(
          controller: _why,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          cursorColor: Colors.white,
          style: AppFonts.spaceGrotesk.copyWith(
              color: Colors.white, fontSize: 16.sp, height: 1.4),
          decoration: _fieldDeco('I want to…'),
        ),
        SizedBox(height: 10.h),
        Text('You can skip and add this later.',
            style: AppFonts.spaceGrotesk
                .copyWith(color: Colors.white54, fontSize: 11.sp)),
      ],
    ));
  }

  Widget _goalsPage() {
    return _scroll(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10.h),
        _eyebrow('Your Goals'),
        SizedBox(height: 16.h),
        _heading('What do you want\nto accomplish?'),
        SizedBox(height: 10.h),
        Text('Name a few. They land in your Goals tab — track them and check '
            'them off as you go.',
            style: AppFonts.spaceGrotesk.copyWith(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13.sp,
                height: 1.5)),
        SizedBox(height: 18.h),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _goal,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _addGoal(),
                cursorColor: Colors.white,
                style: AppFonts.spaceGrotesk
                    .copyWith(color: Colors.white, fontSize: 15.sp),
                decoration: _fieldDeco('Add a goal…'),
              ),
            ),
            SizedBox(width: 10.w),
            GestureDetector(
              onTap: _addGoal,
              child: Container(
                width: 50.r,
                height: 50.r,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r)),
                child: Icon(Icons.add_rounded, color: _red, size: 26.r),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        if (_addedGoals.isEmpty)
          Text('No goals yet — add one or two above.',
              style: AppFonts.spaceGrotesk
                  .copyWith(color: Colors.white54, fontSize: 12.sp))
        else
          ..._addedGoals.asMap().entries.map((e) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: _glass(
                  child: Row(
                    children: [
                      Text('🎯', style: TextStyle(fontSize: 18.sp)),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(e.value,
                            style: AppFonts.spaceGrotesk.copyWith(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              )),
      ],
    ));
  }

  Widget _tourCard(String emoji, String title, String body) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: _glass(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: TextStyle(fontSize: 26.sp)),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppFonts.spaceGrotesk.copyWith(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: 3.h),
                  Text(body,
                      style: AppFonts.spaceGrotesk.copyWith(
                          color: Colors.white.withOpacity(0.88),
                          fontSize: 12.5.sp,
                          height: 1.45)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tourPage() {
    return _scroll(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10.h),
        _eyebrow('How it works'),
        SizedBox(height: 14.h),
        _heading('The daily loop.'),
        SizedBox(height: 16.h),
        _tourCard('☀️', 'Start with the Daily Ritual',
            'Three minutes each morning to set your mind and today\'s wins.'),
        _tourCard('🔥', 'Build your streak',
            'Show up every day to grow your streak. Miss one? A streak freeze has your back.'),
        _tourCard('⚡', 'Earn XP, level up',
            'Workouts, meals, tasks, Bible, and more all earn XP toward your next level.'),
        _tourCard('🧩', 'Everything in one place',
            'Fitness, faith, food, money, and your team — tap Quick Access on Home to explore.'),
      ],
    ));
  }

  Widget _donePage() {
    return _scroll(Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 34.h),
        Text('🎉', style: TextStyle(fontSize: 72.sp)),
        SizedBox(height: 20.h),
        Text('You\'re all set!',
            textAlign: TextAlign.center,
            style: AppFonts.spaceGrotesk.copyWith(
                color: Colors.white,
                fontSize: 28.sp,
                fontWeight: FontWeight.w900)),
        SizedBox(height: 12.h),
        Text(
            _addedGoals.isEmpty
                ? 'Your daily loop is ready. Let\'s build your streak.'
                : '${_addedGoals.length} goal${_addedGoals.length == 1 ? '' : 's'} set. Now let\'s build your streak.',
            textAlign: TextAlign.center,
            style: AppFonts.spaceGrotesk.copyWith(
                color: Colors.white.withOpacity(0.9),
                fontSize: 15.sp,
                height: 1.5)),
        SizedBox(height: 24.h),
        _glass(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bolt_rounded,
                  color: const Color(0xffFFD54F), size: 22.r),
              SizedBox(width: 8.w),
              Text('+50 XP welcome bonus',
                  style: AppFonts.spaceGrotesk.copyWith(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ],
    ));
  }
}
