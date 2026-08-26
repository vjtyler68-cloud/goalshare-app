import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/features/achievements/achievements_controller.dart';
import 'package:spanx/features/gratitude_journal/controller/journal_controller.dart';
import 'package:spanx/features/workout/controller/workout_controller.dart';

/// "Your Week in Review" — a Sunday-style recap of the past 7 days (XP, active
/// days, streak, workouts, gratitudes, achievements) with a shareable summary.
/// Gives a felt sense of progress and a reason to come back each week — the
/// point in the week people most often fall off.
class WeeklyRecapScreen extends StatelessWidget {
  const WeeklyRecapScreen({super.key});

  AchievementsController get _ach => Get.isRegistered<AchievementsController>()
      ? Get.find<AchievementsController>()
      : Get.put(AchievementsController(), permanent: true);

  Color get _red => AppColors.primaryColor;

  static const List<String> _dow = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  int _workoutsThisWeek() {
    if (!Get.isRegistered<WorkoutController>()) return 0;
    try {
      return Get.find<WorkoutController>().workoutsThisWeek;
    } catch (_) {
      return 0;
    }
  }

  int _gratitudesThisWeek() {
    if (!Get.isRegistered<JournalController>()) return 0;
    try {
      final cutoff = DateTime.now().subtract(const Duration(days: 7));
      return Get.find<JournalController>()
          .entries
          .where((e) => e.date.isAfter(cutoff))
          .fold(0, (a, e) => a + e.gratitudeItems.length);
    } catch (_) {
      return 0;
    }
  }

  String _headline(int weeklyXp, int activeDays, int streak) {
    if (activeDays >= 6) return 'Elite week. You barely missed a beat. 🏆';
    if (activeDays >= 4) return 'Strong week — consistency is compounding. 🔥';
    if (activeDays >= 2) return 'You showed up. Let\'s stack more next week. 💪';
    if (weeklyXp > 0) return 'A start is a start. Next week, go again. 🌱';
    return 'Fresh week ahead — let\'s make it count. ☀️';
  }

  void _share(int weeklyXp, int activeDays, int streak, int workouts) {
    final buf = StringBuffer()
      ..writeln('My GoalShare week 📈')
      ..writeln('• $weeklyXp XP earned')
      ..writeln('• Active $activeDays/7 days')
      ..writeln('• $streak-day streak 🔥')
      ..writeln('• $workouts workouts')
      ..writeln('Level ${_ach.level} · ${_ach.levelTitle}')
      ..write('#GoalShare');
    SharePlus.instance.share(ShareParams(text: buf.toString()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff17121C),
      body: SafeArea(
        child: Obx(() {
          final weekly = _ach.weeklyXp();
          final days = _ach.last7DaysXp();
          final activeDays = _ach.activeDaysThisWeek();
          final streak = _ach.currentStreak.value;
          final best = _ach.bestStreak.value;
          final achWeek = _ach.achievementsThisWeek();
          final workouts = _workoutsThisWeek();
          final gratitudes = _gratitudesThisWeek();
          final maxXp = days.fold(0, (a, b) => b > a ? b : a);
          final now = DateTime.now();
          final startDate = now.subtract(const Duration(days: 6));

          // Best day of the week (highest XP).
          int bestIdx = 0;
          for (int i = 0; i < days.length; i++) {
            if (days[i] > days[bestIdx]) bestIdx = i;
          }
          final bestDayName = _fullDow(startDate.add(Duration(days: bestIdx)));

          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 30.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: Get.back,
                      child: Icon(Icons.close_rounded,
                          color: Colors.white70, size: 24.r),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () =>
                          _share(weekly, activeDays, streak, workouts),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.ios_share_rounded,
                                color: Colors.white, size: 15.r),
                            SizedBox(width: 6.w),
                            Text('Share',
                                style: AppFonts.spaceGrotesk.copyWith(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                Text('YOUR WEEK IN REVIEW',
                    style: AppFonts.spaceGrotesk.copyWith(
                        color: _red,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2)),
                SizedBox(height: 4.h),
                Text('${_short(startDate)} – ${_short(now)}',
                    style: AppFonts.spaceGrotesk
                        .copyWith(color: Colors.white54, fontSize: 13.sp)),
                SizedBox(height: 20.h),

                // Hero XP number
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(22.r),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_red, AppColors.primaryDarkColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('XP EARNED THIS WEEK',
                          style: AppFonts.spaceGrotesk.copyWith(
                              color: Colors.white70,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2)),
                      SizedBox(height: 6.h),
                      Text('$weekly',
                          style: AppFonts.spaceGrotesk.copyWith(
                              color: Colors.white,
                              fontSize: 52.sp,
                              fontWeight: FontWeight.w900,
                              height: 1)),
                      SizedBox(height: 8.h),
                      Text('Active $activeDays of 7 days',
                          style: AppFonts.spaceGrotesk.copyWith(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700)),
                      SizedBox(height: 18.h),
                      // 7-day bar chart
                      SizedBox(
                        height: 70.h,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            for (int i = 0; i < 7; i++)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        height: (maxXp == 0
                                                ? 3
                                                : (days[i] / maxXp) * 52 + 3)
                                            .h,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(
                                              days[i] == 0 ? 0.2 : 0.9),
                                          borderRadius:
                                              BorderRadius.circular(4.r),
                                        ),
                                      ),
                                      SizedBox(height: 6.h),
                                      Text(_dow[i],
                                          style: AppFonts.spaceGrotesk.copyWith(
                                              color: Colors.white70,
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // Headline
                Text(_headline(weekly, activeDays, streak),
                    style: AppFonts.spaceGrotesk.copyWith(
                        color: Colors.white,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        height: 1.3)),
                SizedBox(height: 18.h),

                // Stat grid
                Row(
                  children: [
                    _stat('🔥', '$streak', 'Day streak', const Color(0xffFF6B35)),
                    SizedBox(width: 12.w),
                    _stat('💪', '$workouts', 'Workouts',
                        const Color(0xff8B5CF6)),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    _stat('🙏', '$gratitudes', 'Gratitudes',
                        const Color(0xff22C55E)),
                    SizedBox(width: 12.w),
                    _stat('🏅', '$achWeek', 'New badges',
                        const Color(0xffF59E0B)),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    _stat('⭐', 'Lvl ${_ach.level}', _ach.levelTitle,
                        const Color(0xff0EA5E9)),
                    SizedBox(width: 12.w),
                    _stat('📅', activeDays == 0 ? '—' : bestDayName, 'Best day',
                        const Color(0xffEC4899)),
                  ],
                ),
                SizedBox(height: 18.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events_rounded,
                          color: const Color(0xffF59E0B), size: 22.r),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text('Best streak ever: $best days',
                            style: AppFonts.spaceGrotesk.copyWith(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _stat(String emoji, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: TextStyle(fontSize: 20.sp)),
            SizedBox(height: 8.h),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.spaceGrotesk.copyWith(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900)),
            SizedBox(height: 2.h),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.spaceGrotesk
                    .copyWith(color: Colors.white54, fontSize: 11.sp)),
          ],
        ),
      ),
    );
  }

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  String _short(DateTime d) => '${_months[d.month - 1]} ${d.day}';

  static const List<String> _dowFull = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  String _fullDow(DateTime d) => _dowFull[d.weekday - 1];
}
