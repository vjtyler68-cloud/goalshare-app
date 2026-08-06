import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../feed/controller/feed_events.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final Color color;
  bool unlocked;
  DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.color,
    this.unlocked = false,
    this.unlockedAt,
  });
}

class AchievementsController extends GetxController {
  // All-time cumulative stats
  final RxInt totalHomesAllTime = 0.obs;
  final RxInt totalPeopleAllTime = 0.obs;
  final RxInt totalSalesAllTime = 0.obs;
  final RxInt currentStreak = 0.obs;
  final RxInt bestStreak = 0.obs;
  final RxInt perfectDays = 0.obs;
  final RxInt totalXP = 0.obs;

  // Universal (non-sales) counters that back the everyday achievements.
  final RxInt mealDaysCount = 0.obs; // distinct days with a meal logged
  final RxInt workoutsTotal = 0.obs; // workouts finished all-time

  final RxList<Achievement> achievements = <Achievement>[].obs;
  final RxList<String> newlyUnlocked = <String>[].obs;

  static const _kHomesAll   = 'ach_homes_all';
  static const _kPeopleAll  = 'ach_people_all';
  static const _kSalesAll   = 'ach_sales_all';
  static const _kStreak     = 'ach_streak';
  static const _kBestStreak = 'ach_best_streak';
  static const _kPerfectDays= 'ach_perfect_days';
  static const _kXP         = 'ach_xp';
  static const _kUnlocked   = 'ach_unlocked_ids';
  static const _kStreakDate  = 'ach_streak_date';
  static const _kMealDays    = 'ach_meal_days';
  static const _kMealDate    = 'ach_meal_date';
  static const _kWorkouts    = 'ach_workouts';

  @override
  void onInit() {
    super.onInit();
    _buildAchievements();
    _load();
  }

  void _buildAchievements() {
    achievements.assignAll([
      // ── Two door-knocking trophies (kept for the sales crowd) ──────────────
      Achievement(id: 'first_door',  title: 'First Door',       description: 'Knock your first home',                        emoji: '🏠', color: const Color(0xff6366F1)),
      Achievement(id: 'century',     title: 'Century Club',     description: '100 total homes knocked all-time',            emoji: '💯', color: const Color(0xff3B82F6)),

      // ── Nutrition ──────────────────────────────────────────────────────────
      Achievement(id: 'first_meal',  title: 'Fresh Start',      description: 'Log your first meal',                          emoji: '🍽️', color: const Color(0xff10B981)),
      Achievement(id: 'meal_10',     title: 'Meal Prepper',     description: 'Log a meal on 10 different days',              emoji: '🥗', color: const Color(0xff22C55E)),
      Achievement(id: 'meal_30',     title: 'Nutrition Nerd',   description: 'Log meals on 30 different days',               emoji: '🍎', color: const Color(0xffEF4444)),

      // ── Movement ───────────────────────────────────────────────────────────
      Achievement(id: 'first_workout', title: 'Broke a Sweat',  description: 'Finish your first workout',                    emoji: '💪', color: const Color(0xffF97316)),
      Achievement(id: 'workout_10',    title: 'On the Move',    description: 'Complete 10 workouts',                         emoji: '🏃', color: const Color(0xff8B5CF6)),

      // ── Consistency (works for everyone) ───────────────────────────────────
      Achievement(id: 'streak_3',    title: 'Getting Going',    description: '3-day activity streak',                        emoji: '🌱', color: const Color(0xff84CC16)),
      Achievement(id: 'streak_7',    title: 'Hot Streak',       description: '7-day activity streak',                        emoji: '⚡', color: const Color(0xffF97316)),
      Achievement(id: 'streak_30',   title: 'Locked In',        description: '30-day activity streak',                       emoji: '🗓️', color: const Color(0xffEC4899)),
      Achievement(id: 'level_5',     title: 'Rising Star',      description: 'Reach level 5',                                emoji: '🌟', color: const Color(0xffF59E0B)),
    ]);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    totalHomesAllTime.value  = prefs.getInt(_kHomesAll)   ?? 0;
    totalPeopleAllTime.value = prefs.getInt(_kPeopleAll)  ?? 0;
    totalSalesAllTime.value  = prefs.getInt(_kSalesAll)   ?? 0;
    currentStreak.value      = prefs.getInt(_kStreak)     ?? 0;
    bestStreak.value         = prefs.getInt(_kBestStreak) ?? 0;
    perfectDays.value        = prefs.getInt(_kPerfectDays)?? 0;
    totalXP.value            = prefs.getInt(_kXP)         ?? 0;
    mealDaysCount.value      = prefs.getInt(_kMealDays)  ?? 0;
    workoutsTotal.value      = prefs.getInt(_kWorkouts)  ?? 0;

    final unlocked = prefs.getStringList(_kUnlocked) ?? [];
    for (final a in achievements) {
      if (unlocked.contains(a.id)) a.unlocked = true;
    }
    achievements.refresh();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kHomesAll,    totalHomesAllTime.value);
    await prefs.setInt(_kPeopleAll,   totalPeopleAllTime.value);
    await prefs.setInt(_kSalesAll,    totalSalesAllTime.value);
    await prefs.setInt(_kStreak,      currentStreak.value);
    await prefs.setInt(_kBestStreak,  bestStreak.value);
    await prefs.setInt(_kPerfectDays, perfectDays.value);
    await prefs.setInt(_kXP,          totalXP.value);
    await prefs.setInt(_kMealDays,    mealDaysCount.value);
    await prefs.setInt(_kWorkouts,    workoutsTotal.value);
    final ids = achievements.where((a) => a.unlocked).map((a) => a.id).toList();
    await prefs.setStringList(_kUnlocked, ids);
  }

  /// Call when the user logs any meal. Counts at most one per calendar day, so
  /// "log a meal on N days" measures consistency, not how much they ate.
  Future<void> recordMealLogged() async {
    final prefs = await SharedPreferences.getInstance();
    final t = DateTime.now();
    final dayStr = '${t.year}-${t.month}-${t.day}';
    if (prefs.getString(_kMealDate) != dayStr) {
      mealDaysCount.value++;
      await prefs.setString(_kMealDate, dayStr);
    }
    _checkAchievements(homes: 0, people: 0, sales: 0, dailyGoal: 0);
    await _save();
  }

  /// Call when the user finishes a workout (run/walk/strength).
  Future<void> recordWorkout() async {
    workoutsTotal.value++;
    _checkAchievements(homes: 0, people: 0, sales: 0, dailyGoal: 0);
    await _save();
  }

  /// Call this at end of day or when a metric changes to update career totals.
  /// [forDateKey] ("y-m-d") is the calendar day the numbers BELONG to — the
  /// mission auto-save banks yesterday's work on the following morning, and
  /// without it the streak marker would land on the wrong day and block that
  /// evening's manual save from counting.
  Future<void> recordDailyActivity({
    required int homes,
    required int people,
    required int sales,
    required int dailyGoal,
    String? forDateKey,
  }) async {
    totalHomesAllTime.value  += homes;
    totalPeopleAllTime.value += people;
    totalSalesAllTime.value  += sales;
    totalXP.value += homes * 10 + people * 20 + sales * 100;

    // Streak logic — stamped with the day the activity happened on.
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final dayStr = forDateKey ?? '${today.year}-${today.month}-${today.day}';
    final lastStr = prefs.getString(_kStreakDate) ?? '';
    if ((homes > 0 || sales > 0) && lastStr != dayStr) {
      currentStreak.value++;
      if (currentStreak.value > bestStreak.value) bestStreak.value = currentStreak.value;
      await prefs.setString(_kStreakDate, dayStr);
      // Broadcast streak milestones to the Friends Activity Feed.
      const milestones = {3, 7, 14, 30, 50, 75, 100, 150, 200, 365};
      if (milestones.contains(currentStreak.value)) {
        FeedEvents.streakMilestone(currentStreak.value);
      }
    }

    if (homes >= dailyGoal && dailyGoal > 0) perfectDays.value++;

    _checkAchievements(homes: homes, people: people, sales: sales, dailyGoal: dailyGoal);
    await _save();
  }

  void _checkAchievements({required int homes, required int people, required int sales, required int dailyGoal}) {
    final checks = <String, bool>{
      // Door-knocking (kept)
      'first_door':    totalHomesAllTime.value >= 1,
      'century':       totalHomesAllTime.value >= 100,
      // Nutrition
      'first_meal':    mealDaysCount.value >= 1,
      'meal_10':       mealDaysCount.value >= 10,
      'meal_30':       mealDaysCount.value >= 30,
      // Movement
      'first_workout': workoutsTotal.value >= 1,
      'workout_10':    workoutsTotal.value >= 10,
      // Consistency (universal)
      'streak_3':      currentStreak.value >= 3,
      'streak_7':      currentStreak.value >= 7,
      'streak_30':     currentStreak.value >= 30,
      'level_5':       level >= 5,
    };

    bool anyNew = false;
    for (final a in achievements) {
      if (!a.unlocked && (checks[a.id] ?? false)) {
        a.unlocked = true;
        a.unlockedAt = DateTime.now();
        newlyUnlocked.add(a.id);
        // Broadcast the unlock to the Friends Activity Feed.
        FeedEvents.achievementUnlocked(a.title, a.emoji);
        anyNew = true;
      }
    }
    if (anyNew) achievements.refresh();
  }

  // Level system
  int get level {
    final xp = totalXP.value;
    if (xp < 500)   return 1;
    if (xp < 1500)  return 2;
    if (xp < 3500)  return 3;
    if (xp < 7000)  return 4;
    if (xp < 12000) return 5;
    if (xp < 20000) return 6;
    if (xp < 30000) return 7;
    if (xp < 50000) return 8;
    return 9;
  }

  String get levelTitle {
    const titles = ['', 'Rookie', 'Hustler', 'Grinder', 'Pro', 'Elite', 'Champion', 'Legend', 'Icon', 'Titan'];
    return titles[level.clamp(1, 9)];
  }

  double get levelProgress {
    final thresholds = [0, 500, 1500, 3500, 7000, 12000, 20000, 30000, 50000, 100000];
    final lvl = level;
    if (lvl >= 9) return 1.0;
    final start = thresholds[lvl - 1];
    final end = thresholds[lvl];
    return ((totalXP.value - start) / (end - start)).clamp(0.0, 1.0);
  }

  int get unlockedCount => achievements.where((a) => a.unlocked).length;
}
