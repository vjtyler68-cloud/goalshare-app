import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void onInit() {
    super.onInit();
    _buildAchievements();
    _load();
  }

  void _buildAchievements() {
    achievements.assignAll([
      Achievement(id: 'first_door',  title: 'First Door',       description: 'Knock your first home',                        emoji: '🏠', color: const Color(0xff6366F1)),
      Achievement(id: 'fire_10',     title: 'Fire Starter',     description: 'Knock 10 homes in one day',                    emoji: '🔥', color: const Color(0xffE84040)),
      Achievement(id: 'convo_10',    title: 'Smooth Talker',    description: 'Talk to 10 people in a day',                   emoji: '💬', color: const Color(0xff10B981)),
      Achievement(id: 'first_sale',  title: 'First Sale!',      description: 'Make your very first sale',                    emoji: '💰', color: const Color(0xffF59E0B)),
      Achievement(id: 'sales_5day',  title: 'Closer',           description: '5 sales in a single day',                     emoji: '🎯', color: const Color(0xff8B5CF6)),
      Achievement(id: 'streak_7',    title: 'Hot Streak',       description: '7 day activity streak',                       emoji: '⚡', color: const Color(0xffF97316)),
      Achievement(id: 'perfect_day', title: 'Perfect Day',      description: 'Hit your daily homes goal',                   emoji: '🌟', color: const Color(0xffF59E0B)),
      Achievement(id: 'century',     title: 'Century Club',     description: '100 total homes knocked all-time',             emoji: '💯', color: const Color(0xff3B82F6)),
      Achievement(id: 'sales_50',    title: 'Sales Machine',    description: '50 total sales all-time',                     emoji: '🚀', color: const Color(0xffEC4899)),
      Achievement(id: 'convert_20',  title: 'Sharpshooter',     description: '20%+ conversion rate in a day (10+ doors)',   emoji: '🎖', color: const Color(0xff14B8A6)),
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
    final ids = achievements.where((a) => a.unlocked).map((a) => a.id).toList();
    await prefs.setStringList(_kUnlocked, ids);
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
    }

    if (homes >= dailyGoal && dailyGoal > 0) perfectDays.value++;

    _checkAchievements(homes: homes, people: people, sales: sales, dailyGoal: dailyGoal);
    await _save();
  }

  void _checkAchievements({required int homes, required int people, required int sales, required int dailyGoal}) {
    final checks = <String, bool>{
      'first_door':  totalHomesAllTime.value >= 1,
      'fire_10':     homes >= 10,
      'convo_10':    people >= 10,
      'first_sale':  totalSalesAllTime.value >= 1,
      'sales_5day':  sales >= 5,
      'streak_7':    currentStreak.value >= 7,
      'perfect_day': dailyGoal > 0 && homes >= dailyGoal,
      'century':     totalHomesAllTime.value >= 100,
      'sales_50':    totalSalesAllTime.value >= 50,
      'convert_20':  homes >= 10 && people > 0 && (sales / people) >= 0.20,
    };

    bool anyNew = false;
    for (final a in achievements) {
      if (!a.unlocked && (checks[a.id] ?? false)) {
        a.unlocked = true;
        a.unlockedAt = DateTime.now();
        newlyUnlocked.add(a.id);
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
