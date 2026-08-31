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

/// Central XP amounts so the whole app rewards the same actions consistently.
/// Per-item actions (a workout, a meal, a checked-off task) stack on top of the
/// once-a-day feature bonuses.
class XpValues {
  XpValues._();
  static const int workout = 50;      // per finished workout (strength or run)
  static const int meal = 10;         // per meal logged
  static const int winTask = 10;      // per Win-the-Day task checked off
  static const int ritualBonus = 40;  // completing the full Daily Ritual

  /// Once-per-day feature bonuses, keyed by DailyCheckFeature id (+ affirmations
  /// / my_why which mark done when their screens are opened).
  static const Map<String, int> daily = {
    'priming': 20,
    'vision': 10,
    'bible': 15,
    'nutrition': 15,
    'budget': 10,
    'gratitude': 15,
    'workout': 20,
    'goflow': 5,
    'daily_spark': 5,
    'affirmations': 5,
    'my_why': 5,
  };
}

class AchievementsController extends GetxController with WidgetsBindingObserver {
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

  // ── Gamification (XP economy + app-wide streak) ───────────────────────────
  /// "Streak freezes" — each one covers a single missed day so one slip doesn't
  /// wipe a long streak (Duolingo-style). Earned at streak milestones.
  final RxInt streakFreezes = 1.obs; // everyone starts with one, on the house
  /// Up to this many freezes are EARNABLE PER WEEK purely through XP activity,
  /// so freezes are reliably obtainable (not just rare streak milestones).
  static const int maxWeeklyFreezes = 2;
  /// XP that earns each weekly freeze — 1st at 250, 2nd at 500 (a couple of solid
  /// active days). Earned through normal XP; it does NOT spend/lower your XP.
  static const int xpPerWeeklyFreeze = 250;
  /// Overall holding cap — raised from 3 so the weekly earns have room to land.
  static const int maxFreezes = 5;
  /// XP earned in the current week (Mon–Sun) — drives the weekly freeze earns.
  /// (Distinct from the `weeklyXp()` recap method, which is a rolling 7-day sum.)
  final RxInt freezeWeekXp = 0.obs;
  /// Freezes earned via XP so far THIS week (0..maxWeeklyFreezes).
  final RxInt weeklyFreezesEarned = 0.obs;
  String _freezeWeek = ''; // Monday key of the week weeklyXp belongs to
  /// Fires with the new total the moment an XP-earned freeze lands (UI celebrates).
  final RxnInt freezeEarnedSignal = RxnInt();
  /// XP earned TODAY (drives the home ring + weekly recap). Resets at midnight.
  final RxInt todayXP = 0.obs;
  /// Fires with the new level the moment the user levels up (UI shows a burst).
  final RxnInt levelUpSignal = RxnInt();
  /// Fires with the streak count when a milestone is hit.
  final RxnInt streakMilestoneSignal = RxnInt();
  /// Fires with the number of days a freeze just saved (UI shows a notice).
  final RxnInt streakSavedSignal = RxnInt();

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
  static const _kFreezes     = 'ach_freezes';
  static const _kWeeklyXp     = 'ach_weekly_xp';
  static const _kWeeklyFreezes= 'ach_weekly_freezes';
  static const _kFreezeWeek   = 'ach_freeze_week';
  static const _kTodayXP     = 'ach_today_xp';
  static const _kTodayXPDate = 'ach_today_xp_date';
  static const _kClaimDate   = 'ach_claim_date';
  static const _kDailyClaims = 'ach_daily_claims';
  static const _kTaskClaims  = 'ach_task_claims';
  static const _kXpByDay     = 'ach_xp_by_day';

  // Rolling per-day XP (last ~21 days) — powers the Weekly Recap chart + totals.
  final Map<String, int> _xpByDay = <String, int>{};

  // Per-day claim tracking so once-a-day sources / per-task rewards can't be
  // farmed by toggling. Reset when the calendar day changes.
  String _claimDate = '';
  final Set<String> _dailyClaims = <String>{};
  final Set<String> _taskClaims = <String>{};
  String _todayXpDate = '';

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _buildAchievements();
    _loadThenReconcile();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Returning to the app is the moment a broken streak should be reconciled
    // and a new day's XP counter reset.
    if (state == AppLifecycleState.resumed) reconcileOnOpen();
  }

  Future<void> _loadThenReconcile() async {
    await _load();
    await reconcileOnOpen();
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
    _lastActive              = prefs.getString(_kStreakDate) ?? '';
    perfectDays.value        = prefs.getInt(_kPerfectDays)?? 0;
    totalXP.value            = prefs.getInt(_kXP)         ?? 0;
    mealDaysCount.value      = prefs.getInt(_kMealDays)  ?? 0;
    workoutsTotal.value      = prefs.getInt(_kWorkouts)  ?? 0;
    streakFreezes.value      = prefs.getInt(_kFreezes)   ?? 1;

    // Weekly XP window for the XP-earned freezes — reset if it's a new week.
    _freezeWeek = prefs.getString(_kFreezeWeek) ?? '';
    final thisWeek = _weekKey(DateTime.now());
    if (_freezeWeek == thisWeek) {
      freezeWeekXp.value = prefs.getInt(_kWeeklyXp) ?? 0;
      weeklyFreezesEarned.value = prefs.getInt(_kWeeklyFreezes) ?? 0;
    } else {
      _freezeWeek = thisWeek;
      freezeWeekXp.value = 0;
      weeklyFreezesEarned.value = 0;
    }

    // Today's XP counter — only meaningful if it belongs to today.
    _todayXpDate = prefs.getString(_kTodayXPDate) ?? '';
    todayXP.value = (_todayXpDate == _key(DateTime.now()))
        ? (prefs.getInt(_kTodayXP) ?? 0)
        : 0;

    // Per-day claims (once-a-day sources + per-task rewards).
    _claimDate = prefs.getString(_kClaimDate) ?? '';
    _dailyClaims
      ..clear()
      ..addAll(prefs.getStringList(_kDailyClaims) ?? const []);
    _taskClaims
      ..clear()
      ..addAll(prefs.getStringList(_kTaskClaims) ?? const []);
    if (_claimDate != _key(DateTime.now())) {
      _dailyClaims.clear();
      _taskClaims.clear();
    }

    _xpByDay.clear();
    for (final s in (prefs.getStringList(_kXpByDay) ?? const [])) {
      final i = s.lastIndexOf(':');
      if (i <= 0) continue;
      final v = int.tryParse(s.substring(i + 1));
      if (v != null) _xpByDay[s.substring(0, i)] = v;
    }

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
    await prefs.setString(_kStreakDate, _lastActive);
    await prefs.setInt(_kPerfectDays, perfectDays.value);
    await prefs.setInt(_kXP,          totalXP.value);
    await prefs.setInt(_kMealDays,    mealDaysCount.value);
    await prefs.setInt(_kWorkouts,    workoutsTotal.value);
    await prefs.setInt(_kFreezes,     streakFreezes.value);
    await prefs.setInt(_kWeeklyXp,    freezeWeekXp.value);
    await prefs.setInt(_kWeeklyFreezes, weeklyFreezesEarned.value);
    await prefs.setString(_kFreezeWeek, _freezeWeek);
    await prefs.setInt(_kTodayXP,     todayXP.value);
    await prefs.setString(_kTodayXPDate, _todayXpDate);
    await prefs.setString(_kClaimDate, _claimDate);
    await prefs.setStringList(_kDailyClaims, _dailyClaims.toList());
    await prefs.setStringList(_kTaskClaims, _taskClaims.toList());
    await prefs.setStringList(
        _kXpByDay, _xpByDay.entries.map((e) => '${e.key}:${e.value}').toList());
    final ids = achievements.where((a) => a.unlocked).map((a) => a.id).toList();
    await prefs.setStringList(_kUnlocked, ids);
  }

  // ── Date helpers (tolerant of old unpadded keys like "2026-8-9") ──────────
  String _key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  DateTime? _parse(String s) {
    final p = s.split('-');
    if (p.length != 3) return null;
    final y = int.tryParse(p[0]), m = int.tryParse(p[1]), d = int.tryParse(p[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  int _daysBetween(DateTime a, DateTime b) =>
      DateTime(b.year, b.month, b.day)
          .difference(DateTime(a.year, a.month, a.day))
          .inDays;

  // ── App-wide streak + freezes ──────────────────────────────────────────────
  /// True while the streak is still "alive" (active today or yesterday).
  bool get streakAlive {
    final last = _parse(_lastActive);
    if (last == null) return false;
    return _daysBetween(last, DateTime.now()) <= 1;
  }

  /// Whether the user has already been active (earned XP) today.
  bool get activeToday {
    final last = _parse(_lastActive);
    return last != null && _daysBetween(last, DateTime.now()) == 0;
  }

  String _lastActive = '';

  /// Reconcile the streak when the app opens / resumes: cover any missed days
  /// with freezes if possible, otherwise reset. Keeps the displayed streak
  /// honest and applies loss-aversion gently.
  Future<void> reconcileOnOpen() async {
    // Roll the "today XP" counter over at midnight.
    final todayKey = _key(DateTime.now());
    if (_todayXpDate != todayKey) {
      _todayXpDate = todayKey;
      todayXP.value = 0;
    }
    // Roll the weekly freeze window if a new week started (no grant on 0 XP).
    _accrueWeeklyFreezes(0);
    if (_claimDate != todayKey) {
      _claimDate = todayKey;
      _dailyClaims.clear();
      _taskClaims.clear();
    }

    final last = _parse(_lastActive);
    if (last == null) {
      await _save();
      return;
    }
    final gap = _daysBetween(last, DateTime.now());
    if (gap <= 1) {
      await _save();
      return; // active today or yesterday — streak intact
    }
    final missed = gap - 1;
    if (currentStreak.value > 0 && streakFreezes.value >= missed) {
      // Freezes cover the gap — keep the streak, backdate to yesterday so
      // today's activity continues it.
      streakFreezes.value -= missed;
      _lastActive = _key(DateTime.now().subtract(const Duration(days: 1)));
      streakSavedSignal.value = missed;
    } else {
      currentStreak.value = 0; // streak broken
      _lastActive = '';
    }
    await _save();
  }

  /// Mark the user active for [forDate] (default today) and advance the streak.
  /// Single source of truth for the app-wide activity streak — every XP award
  /// routes through here, so the streak means "you showed up."
  Future<void> markActiveToday({DateTime? forDate}) async {
    final day = forDate ?? DateTime.now();
    final dayKey = _key(day);
    final last = _parse(_lastActive);
    if (last != null && _daysBetween(last, day) == 0) return; // already counted

    if (last == null) {
      currentStreak.value = 1;
    } else {
      final gap = _daysBetween(last, day);
      if (gap == 1) {
        currentStreak.value++;
      } else if (gap < 0) {
        // A backdated mark older than the last active day — don't disturb.
        return;
      } else {
        currentStreak.value = 1; // gap >= 2 slipped past reconcile — restart
      }
    }
    _lastActive = dayKey;
    if (currentStreak.value > bestStreak.value) {
      bestStreak.value = currentStreak.value;
    }
    _grantFreezeOnMilestone();

    const milestones = {3, 7, 14, 30, 50, 75, 100, 150, 200, 365};
    if (milestones.contains(currentStreak.value)) {
      FeedEvents.streakMilestone(currentStreak.value);
      streakMilestoneSignal.value = currentStreak.value;
    }
    _checkAchievements(homes: 0, people: 0, sales: 0, dailyGoal: 0);
    await _save();
  }

  void _grantFreezeOnMilestone() {
    const freezeAt = {7, 14, 30, 60, 100, 200, 365};
    if (freezeAt.contains(currentStreak.value) &&
        streakFreezes.value < maxFreezes) {
      streakFreezes.value++;
    }
  }

  /// Monday-key of the week [d] falls in — the bucket for weekly freeze earns.
  String _weekKey(DateTime d) {
    final monday = DateTime(d.year, d.month, d.day)
        .subtract(Duration(days: d.weekday - 1));
    return _key(monday);
  }

  /// Roll the weekly window if the week changed, add [amount] to it, and grant
  /// XP-earned freezes as thresholds (250, 500) are crossed — up to
  /// [maxWeeklyFreezes] a week and the overall [maxFreezes] holding cap. This is
  /// how freezes are reliably OBTAINABLE through normal XP activity; it does not
  /// spend or reduce XP. Caller persists via _save().
  void _accrueWeeklyFreezes(int amount) {
    final thisWeek = _weekKey(DateTime.now());
    if (_freezeWeek != thisWeek) {
      _freezeWeek = thisWeek;
      freezeWeekXp.value = 0;
      weeklyFreezesEarned.value = 0;
    }
    if (amount > 0) freezeWeekXp.value += amount;
    while (weeklyFreezesEarned.value < maxWeeklyFreezes &&
        freezeWeekXp.value >= xpPerWeeklyFreeze * (weeklyFreezesEarned.value + 1) &&
        streakFreezes.value < maxFreezes) {
      streakFreezes.value++;
      weeklyFreezesEarned.value++;
      freezeEarnedSignal.value = streakFreezes.value;
    }
  }

  /// XP still needed for the next weekly freeze (0 when this week's 2 are earned).
  int get xpToNextWeeklyFreeze {
    if (weeklyFreezesEarned.value >= maxWeeklyFreezes) return 0;
    final need = xpPerWeeklyFreeze * (weeklyFreezesEarned.value + 1);
    final left = need - freezeWeekXp.value;
    return left < 0 ? 0 : left;
  }

  /// Progress (0–1) toward the next weekly freeze, for a progress bar.
  double get weeklyFreezeProgress {
    if (weeklyFreezesEarned.value >= maxWeeklyFreezes) return 1;
    final base = xpPerWeeklyFreeze * weeklyFreezesEarned.value;
    const span = xpPerWeeklyFreeze;
    return ((freezeWeekXp.value - base) / span).clamp(0.0, 1.0);
  }

  bool get weeklyFreezesMaxed =>
      weeklyFreezesEarned.value >= maxWeeklyFreezes;

  // ── XP economy ─────────────────────────────────────────────────────────────
  /// Award XP. By default it also counts as activity (keeps the streak alive)
  /// and detects level-ups. Set [activity] false for cosmetic/back-credit.
  Future<void> addXp(int amount, {bool activity = true}) async {
    if (amount <= 0) return;
    final before = level;
    totalXP.value += amount;
    _bumpTodayXp(amount);
    _accrueWeeklyFreezes(amount); // earn up to 2 streak freezes/week via XP
    if (activity) {
      await markActiveToday(); // persists everything
    } else {
      _checkAchievements(homes: 0, people: 0, sales: 0, dailyGoal: 0);
      await _save();
    }
    if (level > before) levelUpSignal.value = level;
  }

  void _bumpTodayXp(int amount) {
    final todayKey = _key(DateTime.now());
    if (_todayXpDate != todayKey) {
      _todayXpDate = todayKey;
      todayXP.value = 0;
    }
    todayXP.value += amount;
    _xpByDay[todayKey] = todayXP.value;
    // Keep only the last 21 days so prefs never grow unbounded.
    if (_xpByDay.length > 21) {
      final cutoff = DateTime.now().subtract(const Duration(days: 21));
      _xpByDay.removeWhere((k, _) {
        final d = _parse(k);
        return d == null || d.isBefore(DateTime(cutoff.year, cutoff.month, cutoff.day));
      });
    }
  }

  // ── Weekly Recap helpers ───────────────────────────────────────────────────
  int xpForDay(DateTime d) => _xpByDay[_key(d)] ?? 0;

  /// XP for each of the last 7 days, oldest → newest (index 6 = today).
  List<int> last7DaysXp() {
    final now = DateTime.now();
    return [for (int i = 6; i >= 0; i--) xpForDay(now.subtract(Duration(days: i)))];
  }

  int weeklyXp() => last7DaysXp().fold(0, (a, b) => a + b);
  int activeDaysThisWeek() => last7DaysXp().where((x) => x > 0).length;

  /// Achievements whose unlock happened within the last 7 days.
  int achievementsThisWeek() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return achievements
        .where((a) =>
            a.unlocked && a.unlockedAt != null && a.unlockedAt!.isAfter(cutoff))
        .length;
  }

  void _ensureClaimDate() {
    final todayKey = _key(DateTime.now());
    if (_claimDate != todayKey) {
      _claimDate = todayKey;
      _dailyClaims.clear();
      _taskClaims.clear();
    }
  }

  /// Award XP for a once-a-day source (bible read, affirmations viewed, …).
  /// No-ops (returns false) if already claimed today.
  Future<bool> awardOncePerDay(String source, int amount) async {
    _ensureClaimDate();
    if (_dailyClaims.contains(source)) return false;
    _dailyClaims.add(source);
    await addXp(amount);
    return true;
  }

  /// Award XP for one Win-the-Day task (by id) exactly once, so checking /
  /// unchecking can't farm XP.
  Future<bool> awardTask(String taskId, int amount) async {
    _ensureClaimDate();
    if (_taskClaims.contains(taskId)) return false;
    _taskClaims.add(taskId);
    await addXp(amount);
    return true;
  }

  /// Award the once-a-day bonus for a DailyCheckFeature (called the first time
  /// it's marked done today). Amount comes from [XpValues.daily].
  Future<void> awardDailyFeature(String feature) async {
    final amount = XpValues.daily[feature];
    if (amount == null) return;
    await awardOncePerDay('feat_$feature', amount);
  }

  /// Level needed to reach the next tier and XP remaining to get there.
  int get xpIntoLevel {
    final thresholds = [0, 500, 1500, 3500, 7000, 12000, 20000, 30000, 50000];
    final lvl = level;
    if (lvl >= 9) return totalXP.value - 50000;
    return totalXP.value - thresholds[lvl - 1];
  }

  int get xpForNextLevel {
    final thresholds = [0, 500, 1500, 3500, 7000, 12000, 20000, 30000, 50000, 100000];
    final lvl = level;
    if (lvl >= 9) return 0;
    return thresholds[lvl] - thresholds[lvl - 1];
  }

  void clearLevelUpSignal() => levelUpSignal.value = null;
  void clearStreakSignals() {
    streakMilestoneSignal.value = null;
    streakSavedSignal.value = null;
  }

  /// Call when the user logs any meal. Counts at most one per calendar day for
  /// the achievement, but awards XP per meal (logging more = more reward).
  Future<void> recordMealLogged() async {
    final prefs = await SharedPreferences.getInstance();
    final t = DateTime.now();
    final dayStr = _key(t);
    if (prefs.getString(_kMealDate) != dayStr) {
      mealDaysCount.value++;
      await prefs.setString(_kMealDate, dayStr);
    }
    _checkAchievements(homes: 0, people: 0, sales: 0, dailyGoal: 0);
    await addXp(XpValues.meal); // per-meal XP (also saves + keeps streak alive)
  }

  /// Call when the user finishes a workout (run/walk/strength).
  Future<void> recordWorkout() async {
    workoutsTotal.value++;
    _checkAchievements(homes: 0, people: 0, sales: 0, dailyGoal: 0);
    await addXp(XpValues.workout); // per-workout XP (also saves + keeps streak)
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
    _bumpTodayXp(homes * 10 + people * 20 + sales * 100);

    // Streak — a door-knocking / sales day counts, routed through the shared
    // app-wide streak engine so it stays unified with everyday activity.
    final today = DateTime.now();
    final activityDay =
        forDateKey != null ? (_parse(forDateKey) ?? today) : today;
    if (homes > 0 || sales > 0) {
      await markActiveToday(forDate: activityDay); // updates streak + saves
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
