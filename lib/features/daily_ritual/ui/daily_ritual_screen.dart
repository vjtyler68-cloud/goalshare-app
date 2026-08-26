import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/daily_checks/daily_check_service.dart';
import 'package:spanx/features/achievements/achievements_controller.dart';
import 'package:spanx/features/gratitude_journal/controller/journal_controller.dart';
import 'package:spanx/features/gratitude_journal/data/journal_entry.dart';
import 'package:spanx/features/home/controller/home_controller.dart';
import 'package:spanx/features/home/subflow/todo/controller/daily_todo_controller.dart';

/// The Daily Ritual — one guided, ~3-minute morning flow that walks the user
/// through their motivation stack (Spark → Gratitude → Affirmation → Why → set
/// today's Wins) and ends with a streak + XP payoff. This is the anchor habit:
/// a single reason to open the app every morning, with a clear start and a
/// satisfying finish.
enum _Step { intro, spark, gratitude, affirmation, why, wins, done }

class DailyRitualScreen extends StatefulWidget {
  const DailyRitualScreen({super.key});

  @override
  State<DailyRitualScreen> createState() => _DailyRitualScreenState();
}

class _DailyRitualScreenState extends State<DailyRitualScreen> {
  final PageController _page = PageController();
  final TextEditingController _gratitude = TextEditingController();
  final TextEditingController _win = TextEditingController();
  int _index = 0;
  bool _completed = false;

  static const List<_Step> _steps = [
    _Step.intro,
    _Step.spark,
    _Step.gratitude,
    _Step.affirmation,
    _Step.why,
    _Step.wins,
    _Step.done,
  ];

  HomeController get _home => Get.isRegistered<HomeController>()
      ? Get.find<HomeController>()
      : Get.put(HomeController());
  DailyTodoController get _todo => Get.isRegistered<DailyTodoController>()
      ? Get.find<DailyTodoController>()
      : Get.put(DailyTodoController());
  JournalController get _journal => Get.isRegistered<JournalController>()
      ? Get.find<JournalController>()
      : Get.put(JournalController());
  AchievementsController get _ach => Get.isRegistered<AchievementsController>()
      ? Get.find<AchievementsController>()
      : Get.put(AchievementsController(), permanent: true);

  Color get _red => AppColors.primaryColor;

  @override
  void dispose() {
    _page.dispose();
    _gratitude.dispose();
    _win.dispose();
    super.dispose();
  }

  void _next() {
    _awardFor(_steps[_index]);
    if (_index >= _steps.length - 1) {
      Get.back();
      return;
    }
    final nextStep = _steps[_index + 1];
    if (nextStep == _Step.done) _completeRitual();
    HapticFeedback.selectionClick();
    _page.nextPage(
        duration: const Duration(milliseconds: 320), curve: Curves.easeInOut);
  }

  void _awardFor(_Step step) {
    final checks = DailyCheckService.to;
    switch (step) {
      case _Step.spark:
        checks.markDoneToday(DailyCheckFeature.dailySpark);
        break;
      case _Step.gratitude:
        _saveGratitude();
        break;
      case _Step.affirmation:
        checks.markDoneToday(DailyCheckFeature.affirmations);
        break;
      case _Step.why:
        checks.markDoneToday(DailyCheckFeature.myWhy);
        break;
      default:
        break;
    }
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  void _saveGratitude() {
    final text = _gratitude.text.trim();
    if (text.isEmpty) {
      // Still counts as showing up for the reflection.
      DailyCheckService.to.markDoneToday(DailyCheckFeature.gratitude);
      return;
    }
    try {
      final id = _dateKey(DateTime.now());
      final existing = _journal.entries.firstWhereOrNull((e) => e.id == id);
      if (existing != null) {
        final items = List<String>.from(existing.gratitudeItems)..add(text);
        _journal.save(existing.copyWith(
            gratitudeItems: items, updatedAt: DateTime.now(), edited: true));
      } else {
        _journal.save(JournalEntry(
          id: id,
          date: DateTime.now(),
          gratitudeItems: [text],
          createdAt: DateTime.now(),
        ));
      }
    } catch (_) {
      DailyCheckService.to.markDoneToday(DailyCheckFeature.gratitude);
    }
  }

  void _completeRitual() {
    if (_completed) return;
    _completed = true;
    DailyCheckService.to.markDoneToday(DailyCheckFeature.ritual);
    _ach.awardOncePerDay('ritual', XpValues.ritualBonus);
    HapticFeedback.heavyImpact();
  }

  void _addWin() {
    final t = _win.text.trim();
    if (t.isEmpty) return;
    _todo.addTodo(t);
    _win.clear();
    setState(() {});
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
                    _introPage(),
                    _sparkPage(),
                    _gratitudePage(),
                    _affirmationPage(),
                    _whyPage(),
                    _winsPage(),
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
    final shown = (_index).clamp(0, total);
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 4.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: Get.back,
            child: Icon(Icons.close_rounded, color: Colors.white70, size: 24.r),
          ),
          SizedBox(width: 12.w),
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
          SizedBox(width: 12.w),
          Text(_index >= total ? 'Done' : '${shown + 1}/$total',
              style: AppFonts.spaceGrotesk.copyWith(
                  color: Colors.white70,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    final step = _steps[_index];
    if (step == _Step.done) {
      return Padding(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 20.h),
        child: _cta('Let\'s win today 🚀', () => Get.back()),
      );
    }
    final isWins = step == _Step.wins;
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 20.h),
      child: _cta(isWins ? 'Finish ritual' : 'Continue', _next),
    );
  }

  Widget _cta(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
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
    );
  }

  // ── Pages ────────────────────────────────────────────────────────────────
  Widget _scroll(Widget child) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 24.h),
        child: child,
      );

  Widget _eyebrow(String text, IconData icon) => Row(
        children: [
          Icon(icon, color: Colors.white70, size: 16.r),
          SizedBox(width: 6.w),
          Text(text.toUpperCase(),
              style: AppFonts.spaceGrotesk.copyWith(
                  color: Colors.white70,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5)),
        ],
      );

  Widget _heading(String text) => Text(text,
      style: AppFonts.spaceGrotesk.copyWith(
          color: Colors.white,
          fontSize: 26.sp,
          fontWeight: FontWeight.w900,
          height: 1.2));

  Widget _glass({required Widget child}) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: child,
      );

  Widget _introPage() {
    return _scroll(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20.h),
        Text('☀️', style: TextStyle(fontSize: 64.sp)),
        SizedBox(height: 18.h),
        _heading('Good morning.\nLet\'s start your day right.'),
        SizedBox(height: 14.h),
        Text(
            'Three minutes to get your mind right — a spark, gratitude, your '
            'affirmations, your why, and today\'s wins. Show up here every '
            'morning and watch it compound.',
            style: AppFonts.spaceGrotesk.copyWith(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14.sp,
                height: 1.6)),
        SizedBox(height: 20.h),
        Obx(() => _glass(
              child: Row(
                children: [
                  Icon(Icons.local_fire_department_rounded,
                      color: const Color(0xffFFB74D), size: 26.r),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                        _ach.currentStreak.value == 0
                            ? 'Complete this to start your streak.'
                            : 'You\'re on a ${_ach.currentStreak.value}-day streak. Keep it alive.',
                        style: AppFonts.spaceGrotesk.copyWith(
                            color: Colors.white,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            )),
      ],
    ));
  }

  Widget _sparkPage() {
    final spark = _home.currentSpark;
    return _scroll(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10.h),
        _eyebrow('Daily Spark', Icons.auto_awesome_rounded),
        SizedBox(height: 20.h),
        Text('“',
            style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 72.sp,
                height: 0.7,
                fontWeight: FontWeight.w900)),
        Text(spark.quote,
            style: AppFonts.spaceGrotesk.copyWith(
                color: Colors.white,
                fontSize: 24.sp,
                fontWeight: FontWeight.w800,
                height: 1.35)),
        SizedBox(height: 14.h),
        if (spark.author.trim().isNotEmpty)
          Text('— ${spark.author}',
              style: AppFonts.spaceGrotesk.copyWith(
                  color: Colors.white70,
                  fontSize: 14.sp,
                  fontStyle: FontStyle.italic)),
        SizedBox(height: 24.h),
        Text('Read it. Sit with it for a breath. Then carry it into your day.',
            style: AppFonts.spaceGrotesk.copyWith(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13.sp,
                height: 1.5)),
      ],
    ));
  }

  Widget _gratitudePage() {
    return _scroll(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10.h),
        _eyebrow('Gratitude', Icons.favorite_rounded),
        SizedBox(height: 18.h),
        _heading('What\'s one thing\nyou\'re grateful for?'),
        SizedBox(height: 10.h),
        Text('Gratitude rewires your focus toward what\'s going right.',
            style: AppFonts.spaceGrotesk.copyWith(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13.sp,
                height: 1.5)),
        SizedBox(height: 18.h),
        TextField(
          controller: _gratitude,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          style: AppFonts.spaceGrotesk.copyWith(
              color: Colors.white, fontSize: 16.sp, height: 1.4),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: 'I\'m grateful for…',
            hintStyle: AppFonts.spaceGrotesk
                .copyWith(color: Colors.white54, fontSize: 16.sp),
            filled: true,
            fillColor: Colors.white.withOpacity(0.12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.all(16.r),
          ),
        ),
        SizedBox(height: 10.h),
        Text('Saved to your Gratitude Journal.',
            style: AppFonts.spaceGrotesk
                .copyWith(color: Colors.white54, fontSize: 11.sp)),
      ],
    ));
  }

  Widget _affirmationPage() {
    final list = _home.homeMyAffirmationList;
    return _scroll(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10.h),
        _eyebrow('Affirmations', Icons.bolt_rounded),
        SizedBox(height: 18.h),
        _heading('Speak life over\nyourself.'),
        SizedBox(height: 16.h),
        if (list.isEmpty)
          _glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('I am becoming the person I said I would be.',
                    style: AppFonts.spaceGrotesk.copyWith(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.4)),
                SizedBox(height: 10.h),
                Text('Add your own in the Affirmations tab to see them here.',
                    style: AppFonts.spaceGrotesk
                        .copyWith(color: Colors.white60, fontSize: 12.sp)),
              ],
            ),
          )
        else
          ...list.take(5).map((a) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _glass(
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 20.r),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(a.text ?? '',
                            style: AppFonts.spaceGrotesk.copyWith(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                height: 1.35)),
                      ),
                    ],
                  ),
                ),
              )),
        SizedBox(height: 8.h),
        Text('Say each one out loud. Mean it.',
            style: AppFonts.spaceGrotesk.copyWith(
                color: Colors.white.withOpacity(0.8), fontSize: 13.sp)),
      ],
    ));
  }

  Widget _whyPage() {
    final list = _home.homeMyWhyList;
    return _scroll(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10.h),
        _eyebrow('My Why', Icons.local_fire_department_rounded),
        SizedBox(height: 18.h),
        _heading('Remember why\nyou started.'),
        SizedBox(height: 16.h),
        if (list.isEmpty)
          _glass(
            child: Text(
                'Add your reasons in the My Why tab — the deeper "why" that '
                'keeps you going when motivation runs dry.',
                style: AppFonts.spaceGrotesk.copyWith(
                    color: Colors.white, fontSize: 15.sp, height: 1.5)),
          )
        else
          ...list.take(5).map((w) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _glass(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('“',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 30.sp,
                              height: 0.9,
                              fontWeight: FontWeight.w900)),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(w.text ?? '',
                            style: AppFonts.spaceGrotesk.copyWith(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                                height: 1.35)),
                      ),
                    ],
                  ),
                ),
              )),
      ],
    ));
  }

  Widget _winsPage() {
    return _scroll(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10.h),
        _eyebrow('Win The Day', Icons.flag_rounded),
        SizedBox(height: 18.h),
        _heading('What would make\ntoday a win?'),
        SizedBox(height: 10.h),
        Text('Name a few. Check them off as you go — each one earns XP.',
            style: AppFonts.spaceGrotesk.copyWith(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13.sp,
                height: 1.5)),
        SizedBox(height: 18.h),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _win,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _addWin(),
                style: AppFonts.spaceGrotesk
                    .copyWith(color: Colors.white, fontSize: 15.sp),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: 'Add a win…',
                  hintStyle: AppFonts.spaceGrotesk
                      .copyWith(color: Colors.white54, fontSize: 15.sp),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            GestureDetector(
              onTap: _addWin,
              child: Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r)),
                child: Icon(Icons.add_rounded, color: _red, size: 26.r),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Obx(() {
          final items = _todo.items;
          if (items.isEmpty) {
            return Text('No wins yet — add one or two above.',
                style: AppFonts.spaceGrotesk
                    .copyWith(color: Colors.white54, fontSize: 12.sp));
          }
          return Column(
            children: items
                .map((it) => Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: _glass(
                        child: Row(
                          children: [
                            Icon(
                                it.done
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: Colors.white,
                                size: 20.r),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(it.text,
                                  style: AppFonts.spaceGrotesk.copyWith(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          );
        }),
      ],
    ));
  }

  Widget _donePage() {
    return _scroll(Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 30.h),
        Text('🎉', style: TextStyle(fontSize: 72.sp)),
        SizedBox(height: 20.h),
        Text('Ritual complete!',
            textAlign: TextAlign.center,
            style: AppFonts.spaceGrotesk.copyWith(
                color: Colors.white,
                fontSize: 28.sp,
                fontWeight: FontWeight.w900)),
        SizedBox(height: 12.h),
        Obx(() => Text(
              _ach.currentStreak.value <= 1
                  ? 'You showed up. That\'s how it starts.'
                  : '${_ach.currentStreak.value}-day streak and counting. 🔥',
              textAlign: TextAlign.center,
              style: AppFonts.spaceGrotesk.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 15.sp,
                  height: 1.5),
            )),
        SizedBox(height: 24.h),
        _glass(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt_rounded,
                      color: const Color(0xffFFD54F), size: 22.r),
                  SizedBox(width: 8.w),
                  Text('+${XpValues.ritualBonus} XP ritual bonus',
                      style: AppFonts.spaceGrotesk.copyWith(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              SizedBox(height: 10.h),
              Obx(() => Text('+${_ach.todayXP.value} XP earned today',
                  style: AppFonts.spaceGrotesk.copyWith(
                      color: Colors.white70, fontSize: 13.sp))),
            ],
          ),
        ),
      ],
    ));
  }
}
