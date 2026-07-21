import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/daily_checks/daily_check_service.dart';
import '../../../core/health/health_service.dart';
import '../data/food_combo.dart';
import '../data/food_item.dart';
import '../data/logged_entry.dart';
import '../data/nutrition_goal.dart';
import '../data/streak_data.dart';
import '../data/weight_entry.dart';
import '../service/food_api_service.dart';

const String kNutritionEntriesBox = 'nutritionEntriesBox';
const String kFoodCacheBox = 'foodCacheBox';
const String kNutritionGoalsBox = 'nutritionGoalsBox';
const String kFoodCombosBox = 'foodCombosBox';
const String kWeightEntriesBox = 'weightEntriesBox';
const String kStreakDataBox = 'streakDataBox';

const List<String> kMeals = ['breakfast', 'lunch', 'dinner', 'snacks'];
const String kExerciseMeal = 'exercise';
const String _kGoalKey = 'goal';
const String _kStreakKey = 'streak';

/// Remembers whether the add-food screen was last used in Basic or Detailed
/// mode, so the choice survives a restart.
const String _kDetailedEntryPrefKey = 'nutrition_detailed_entry';

class NutritionController extends GetxController {
  /// Shared instance — reused if already registered (survives deep links).
  static NutritionController get to => Get.isRegistered<NutritionController>()
      ? Get.find<NutritionController>()
      : Get.put(NutritionController(), permanent: true);

  Box<LoggedEntry>? _entriesBox;
  Box<NutritionGoal>? _goalBox;
  Box<String>? _cacheBox;
  Box<FoodCombo>? _combosBox;
  Box<WeightEntry>? _weightBox;
  Box<StreakData>? _streakBox;

  final RxBool isReady = false.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final Rxn<NutritionGoal> goal = Rxn<NutritionGoal>();
  final Rx<StreakData> streak = const StreakData().obs;

  /// Add-food screen: false = Basic (protein/carbs/fat), true = Detailed
  /// (adds fiber/sugar/sodium). Persisted in SharedPreferences.
  final RxBool detailedEntry = false.obs;

  /// All logged entries across all days. Reactive so screens rebuild on change.
  final RxList<LoggedEntry> allEntries = <LoggedEntry>[].obs;

  /// User-saved combos and weight readings. Reactive.
  final RxList<FoodCombo> combos = <FoodCombo>[].obs;
  final RxList<WeightEntry> weights = <WeightEntry>[].obs;

  final FoodApiService api = FoodApiService();

  // ── lifecycle ───────────────────────────────────────────────────────────────
  @override
  void onInit() {
    super.onInit();
    _open();
  }

  Future<void> _open() async {
    try {
      if (!Hive.isAdapterRegistered(14)) Hive.registerAdapter(FoodItemAdapter());
      if (!Hive.isAdapterRegistered(15)) {
        Hive.registerAdapter(LoggedEntryAdapter());
      }
      if (!Hive.isAdapterRegistered(16)) {
        Hive.registerAdapter(NutritionGoalAdapter());
      }
      if (!Hive.isAdapterRegistered(17)) {
        Hive.registerAdapter(WeightEntryAdapter());
      }
      if (!Hive.isAdapterRegistered(18)) {
        Hive.registerAdapter(FoodComboAdapter());
      }
      if (!Hive.isAdapterRegistered(19)) {
        Hive.registerAdapter(StreakDataAdapter());
      }

      _entriesBox = Hive.isBoxOpen(kNutritionEntriesBox)
          ? Hive.box<LoggedEntry>(kNutritionEntriesBox)
          : await Hive.openBox<LoggedEntry>(kNutritionEntriesBox);
      _goalBox = Hive.isBoxOpen(kNutritionGoalsBox)
          ? Hive.box<NutritionGoal>(kNutritionGoalsBox)
          : await Hive.openBox<NutritionGoal>(kNutritionGoalsBox);
      _cacheBox = Hive.isBoxOpen(kFoodCacheBox)
          ? Hive.box<String>(kFoodCacheBox)
          : await Hive.openBox<String>(kFoodCacheBox);
      _combosBox = Hive.isBoxOpen(kFoodCombosBox)
          ? Hive.box<FoodCombo>(kFoodCombosBox)
          : await Hive.openBox<FoodCombo>(kFoodCombosBox);
      _weightBox = Hive.isBoxOpen(kWeightEntriesBox)
          ? Hive.box<WeightEntry>(kWeightEntriesBox)
          : await Hive.openBox<WeightEntry>(kWeightEntriesBox);
      _streakBox = Hive.isBoxOpen(kStreakDataBox)
          ? Hive.box<StreakData>(kStreakDataBox)
          : await Hive.openBox<StreakData>(kStreakDataBox);

      api.cacheBox = _cacheBox;
      goal.value = _goalBox?.get(_kGoalKey) ?? const NutritionGoal();
      streak.value = _streakBox?.get(_kStreakKey) ?? const StreakData();
      await _loadDetailedEntryPref();
      _refresh();
    } catch (_) {
      // Non-fatal — feature starts empty this session.
      goal.value ??= const NutritionGoal();
    } finally {
      isReady.value = true;
    }
  }

  void _refresh() {
    final all = _entriesBox?.values.toList() ?? <LoggedEntry>[];
    all.sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    allEntries.assignAll(all);

    final cs = _combosBox?.values.toList() ?? <FoodCombo>[];
    cs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    combos.assignAll(cs);

    final ws = _weightBox?.values.toList() ?? <WeightEntry>[];
    ws.sort((a, b) => a.date.compareTo(b.date)); // oldest → newest for charts
    weights.assignAll(ws);

    _recomputeStreak();
  }

  // ── streak (consecutive days with ≥1 logged entry) ────────────────────────────
  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Rebuilt from the logged-entry set on every refresh, so it stays correct
  /// through deletes and past-day edits. `longestStreak` never regresses.
  void _recomputeStreak() {
    final days = <DateTime>{for (final e in allEntries) _dayOnly(e.date)};
    if (days.isEmpty) {
      _persistStreak(const StreakData());
      return;
    }
    final sorted = days.toList()..sort();

    // Longest run present in the current data (fully recomputed, not sticky).
    int longest = 1, run = 1;
    for (int i = 1; i < sorted.length; i++) {
      run = sorted[i].difference(sorted[i - 1]).inDays == 1 ? run + 1 : 1;
      if (run > longest) longest = run;
    }

    // Current streak ends at the most recent logged day, but only counts as
    // "live" if that day is today or yesterday (a one-day grace window).
    final today = _dayOnly(DateTime.now());
    final last = sorted.last;
    int current = 0;
    if (today.difference(last).inDays <= 1) {
      current = 1;
      for (int i = sorted.length - 1; i > 0; i--) {
        if (sorted[i].difference(sorted[i - 1]).inDays == 1) {
          current++;
        } else {
          break;
        }
      }
    }

    _persistStreak(StreakData(
      currentStreak: current,
      longestStreak: longest,
      lastLoggedDate: last,
    ));
  }

  void _persistStreak(StreakData s) {
    streak.value = s;
    _streakBox?.put(_kStreakKey, s);
  }

  // ── date helpers ──────────────────────────────────────────────────────────��─
  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void goToPreviousDay() =>
      selectedDate.value = selectedDate.value.subtract(const Duration(days: 1));

  void goToNextDay() {
    final next = selectedDate.value.add(const Duration(days: 1));
    // Don't allow navigating into the future.
    if (next.isAfter(DateTime.now()) && !_sameDay(next, DateTime.now())) return;
    selectedDate.value = next;
  }

  bool get isViewingToday => _sameDay(selectedDate.value, DateTime.now());

  // ── queries (selected date) ──────────────────────────────────────────────────
  List<LoggedEntry> entriesForMeal(String meal) => allEntries
      .where((e) => e.meal == meal && _sameDay(e.date, selectedDate.value))
      .toList()
    ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));

  List<LoggedEntry> get _foodEntriesToday => allEntries
      .where((e) =>
          kMeals.contains(e.meal) && _sameDay(e.date, selectedDate.value))
      .toList();

  List<LoggedEntry> get _exerciseEntriesToday => allEntries
      .where((e) =>
          e.meal == kExerciseMeal && _sameDay(e.date, selectedDate.value))
      .toList();

  List<LoggedEntry> get exerciseEntries => _exerciseEntriesToday
    ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));

  double get foodCalories =>
      _foodEntriesToday.fold(0.0, (p, e) => p + e.calories);
  double get exerciseCalories =>
      _exerciseEntriesToday.fold(0.0, (p, e) => p + e.calories);
  double get netCalories => foodCalories - exerciseCalories;

  int get budget => goal.value?.dailyCalorieBudget ?? 2000;
  double get remaining => budget - foodCalories + exerciseCalories;

  double get proteinToday => _foodEntriesToday.fold(0.0, (p, e) => p + e.protein);
  double get carbsToday => _foodEntriesToday.fold(0.0, (p, e) => p + e.carbs);
  double get fatToday => _foodEntriesToday.fold(0.0, (p, e) => p + e.fat);

  // Detailed nutrition totals (fiber/sugar/sodium) come from [dailyTotals] —
  // one aggregation path, no per-field getters to drift out of sync.

  // ── tracking mode (calories vs protein) ─────────────────────────────────────
  String get trackingMode => goal.value?.trackingMode ?? kTrackCalories;
  bool get isProteinMode => trackingMode == kTrackProtein;

  /// Bodyweight-derived protein target (0.8 g per lb of the latest weigh-in).
  /// Null when nothing has ever been logged — the UI prompts for a weigh-in.
  int? get defaultProteinGoal {
    final lbs = latestWeight?.weightLbs;
    if (lbs == null || lbs <= 0) return null;
    return NutritionGoal.defaultProteinGoal(lbs);
  }

  /// The protein target in effect: the user's override, else the bodyweight
  /// default. Null means "we can't compute one yet".
  int? get proteinGoal {
    final override = goal.value?.proteinGoalGrams;
    if (override != null && override > 0) return override.round();
    return defaultProteinGoal;
  }

  /// True when protein mode is on but there's no weigh-in to derive a goal
  /// from and no manual override — the dashboard shows a Log Weight prompt.
  bool get needsWeightForProteinGoal => isProteinMode && proteinGoal == null;

  double get proteinRemaining => (proteinGoal ?? 0) - proteinToday;

  Future<bool> setTrackingMode(String mode) {
    final next = mode == kTrackProtein ? kTrackProtein : kTrackCalories;
    return saveGoal(
        (goal.value ?? const NutritionGoal()).copyWith(trackingMode: next));
  }

  /// Pass null to drop the override and fall back to the bodyweight default.
  Future<bool> setProteinGoal(double? grams) {
    final base = goal.value ?? const NutritionGoal();
    final valid = grams != null && grams > 0;
    return saveGoal(base.copyWith(
      proteinGoalGrams: valid ? grams : null,
      clearProteinGoalGrams: !valid,
    ));
  }

  // ── Basic / Detailed entry preference ───────────────────────────────────────
  Future<void> _loadDetailedEntryPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      detailedEntry.value = prefs.getBool(_kDetailedEntryPrefKey) ?? false;
    } catch (_) {
      // Non-fatal — defaults to Basic for this session.
    }
  }

  Future<void> setDetailedEntry(bool value) async {
    detailedEntry.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kDetailedEntryPrefKey, value);
    } catch (_) {
      // Non-fatal — the in-memory toggle still applies this session.
    }
  }

  double caloriesForMeal(String meal) =>
      entriesForMeal(meal).fold(0.0, (p, e) => p + e.calories);

  /// Even split of the daily budget across the four meals (suggested target).
  int get suggestedMealTarget => (budget / kMeals.length).round();

  // ── today summary (for the dashboard tile) ───────────────────────────────────
  double get todayFoodCalories => allEntries
      .where((e) => kMeals.contains(e.meal) && _sameDay(e.date, DateTime.now()))
      .fold(0.0, (p, e) => p + e.calories);

  bool get hasLoggedToday => allEntries.any((e) => _sameDay(e.date, DateTime.now()));

  // ── running totals (daily / weekly summary views) ────────────────────────────
  /// Totals for the selected day — the same numbers the dashboard shows.
  NutritionTotals get dailyTotals => NutritionTotals.of(_foodEntriesToday);

  /// Rolling 7-day window ending on (and including) the selected day.
  NutritionTotals get weeklyTotals {
    final end = _dayOnly(selectedDate.value);
    final start = end.subtract(const Duration(days: 6));
    final window = allEntries.where((e) {
      if (!kMeals.contains(e.meal)) return false;
      final d = _dayOnly(e.date);
      return !d.isBefore(start) && !d.isAfter(end);
    });
    return NutritionTotals.of(window);
  }

  /// Distinct days inside the weekly window that have at least one food entry —
  /// the divisor for a "daily average" that isn't dragged down by empty days.
  int get weeklyLoggedDays {
    final end = _dayOnly(selectedDate.value);
    final start = end.subtract(const Duration(days: 6));
    return <DateTime>{
      for (final e in allEntries)
        if (kMeals.contains(e.meal) &&
            !_dayOnly(e.date).isBefore(start) &&
            !_dayOnly(e.date).isAfter(end))
          _dayOnly(e.date)
    }.length;
  }

  // ── My Foods & Recent (across all days) ───────────────────────────────────────
  /// Distinct foods the user has logged before, most-recently-used first.
  List<FoodItem> get myFoods {
    final seen = <String>{};
    final out = <FoodItem>[];
    for (final e in allEntries) {
      // allEntries is already newest-first
      final key = e.foodItem.name.toLowerCase();
      if (seen.add(key)) out.add(e.foodItem);
    }
    return out;
  }

  /// Last 20 logged items regardless of meal, most recent first.
  List<LoggedEntry> get recentEntries => allEntries.take(20).toList();

  // ── mutations ────────────────────────────────────────────────────────────────
  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${allEntries.length}';

  Future<bool> addFood({
    required FoodItem food,
    required String meal,
    required double quantity,
    DateTime? date,
  }) async {
    if (_entriesBox == null) return false;
    final d = date ?? selectedDate.value;
    final entry = LoggedEntry(
      id: _newId(),
      date: DateTime(d.year, d.month, d.day, 12),
      meal: meal,
      foodItem: food,
      quantity: quantity,
      loggedAt: DateTime.now(),
    );
    await _entriesBox!.put(entry.id, entry);
    _refresh();
    // Logging anything today lights the home-screen green check.
    final today = DateTime.now();
    if (d.year == today.year && d.month == today.month && d.day == today.day) {
      DailyCheckService.to.markDoneToday(DailyCheckFeature.nutrition);
    }
    return true;
  }

  Future<bool> addExercise({required String name, required double calories}) async {
    if (_entriesBox == null || calories <= 0) return false;
    final food = FoodItem(
      id: 'exercise_${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim().isEmpty ? 'Exercise' : name.trim(),
      servingSize: '1 session',
      calories: calories,
      source: 'manual',
    );
    return addFood(food: food, meal: kExerciseMeal, quantity: 1);
  }

  /// Pull today's activity (iPhone + Apple Watch) from Apple Health and log it
  /// as a single de-duplicated exercise entry. Returns a user-facing message to
  /// surface in a snackbar. Safe to call while HealthKit is gated off (returns a
  /// "coming soon" message without touching HealthKit).
  Future<String> syncAppleHealthExercise() async {
    final health = HealthService.instance;
    if (!health.isEnabled) {
      return 'Apple Health sync is coming soon.';
    }
    final granted = await health.requestPermissions();
    if (!granted) return 'Health access wasn\'t granted.';

    final result = await health.readToday();
    if (result == null || result.calories <= 0) {
      return 'No Apple Health activity found today.';
    }

    // Replace any prior Apple Health entry for today (also the legacy
    // 'apple_watch' source) so re-syncing updates the total instead of stacking
    // duplicate entries.
    final prior = _exerciseEntriesToday
        .where((e) =>
            e.foodItem.source == 'apple_health' ||
            e.foodItem.source == 'apple_watch')
        .toList();
    for (final e in prior) {
      await _entriesBox?.delete(e.id);
    }

    final cals = result.calories;
    final food = FoodItem(
      id: 'exercise_apple_health_${DateTime.now().microsecondsSinceEpoch}',
      name: 'Apple Health Activity',
      servingSize: 'today',
      calories: cals,
      source: 'apple_health',
    );
    final ok = await addFood(food: food, meal: kExerciseMeal, quantity: 1);
    if (!ok) return 'Couldn\'t save the synced activity.';

    final stepsText =
        result.steps > 0 ? ' · ${_formatSteps(result.steps)} steps' : '';
    return 'Synced ${cals.round()} cal$stepsText from Apple Health';
  }

  String _formatSteps(int steps) {
    // Simple thousands separator (e.g. 6240 -> "6,240").
    final s = steps.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Future<bool> updateEntry(LoggedEntry entry) async {
    if (_entriesBox == null) return false;
    await _entriesBox!.put(entry.id, entry);
    _refresh();
    return true;
  }

  Future<bool> deleteEntry(String id) async {
    if (_entriesBox == null) return false;
    await _entriesBox!.delete(id);
    _refresh();
    return true;
  }

  Future<bool> saveGoal(NutritionGoal g) async {
    goal.value = g;
    if (_goalBox == null) return false;
    await _goalBox!.put(_kGoalKey, g);
    return true;
  }

  /// Personalized budget from the Goal Setup flow (Mifflin-St Jeor). Persists
  /// the profile inputs too so the goal can be re-edited/recalculated later.
  Future<bool> saveGoalSetup({
    required double currentLbs,
    required double goalLbs,
    required bool male,
    required int age,
    required double heightCm,
    required double activity,
    required double weeklyRateLbs,
    DateTime? targetDate,
  }) async {
    final budget = NutritionGoal.computeBudget(
      currentLbs: currentLbs,
      male: male,
      age: age,
      heightCm: heightCm,
      activity: activity,
      weeklyRateLbs: weeklyRateLbs,
    );
    final g = (goal.value ?? const NutritionGoal()).copyWith(
      dailyCalorieBudget: budget,
      currentWeightLbs: currentLbs,
      goalWeightLbs: goalLbs,
      targetWeeklyRateLbs: weeklyRateLbs,
      targetDate: targetDate,
      ageYears: age,
      sexMale: male,
      heightCm: heightCm,
      activityLevel: activity,
    );
    final ok = await saveGoal(g);
    // Seed the weight chart with the starting weight if none logged yet.
    if (ok && weights.isEmpty) await addWeight(currentLbs);
    return ok;
  }

  // ── repeat yesterday / repeat a meal ──────────────────────────────────────────
  DateTime get _priorDay => selectedDate.value.subtract(const Duration(days: 1));

  /// Entries on [day]. With [meal] null, returns every meal + exercise; with a
  /// meal name, only that meal's items.
  List<LoggedEntry> entriesOnDay(DateTime day, {String? meal}) =>
      allEntries.where((e) {
        if (!_sameDay(e.date, day)) return false;
        return meal == null ? true : e.meal == meal;
      }).toList()
        ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));

  /// Items logged the day before the currently selected day.
  List<LoggedEntry> yesterdayEntries({String? meal}) =>
      entriesOnDay(_priorDay, meal: meal);

  bool get hasYesterdayEntries => yesterdayEntries().isNotEmpty;

  bool hasYesterdayMeal(String meal) => yesterdayEntries(meal: meal).isNotEmpty;

  /// Copies every item from the prior day onto the selected day. Returns count.
  Future<int> repeatDay() async {
    int n = 0;
    for (final e in yesterdayEntries()) {
      if (await addFood(food: e.foodItem, meal: e.meal, quantity: e.quantity)) {
        n++;
      }
    }
    return n;
  }

  /// Copies just one meal from the prior day onto the selected day.
  Future<int> repeatMeal(String meal) async {
    int n = 0;
    for (final e in yesterdayEntries(meal: meal)) {
      if (await addFood(food: e.foodItem, meal: meal, quantity: e.quantity)) {
        n++;
      }
    }
    return n;
  }

  // ── combos ────────────────────────────────────────────────────────────────────
  Future<bool> saveCombo(String name, List<FoodItem> items) async {
    if (_combosBox == null || items.isEmpty) return false;
    final combo = FoodCombo(
      id: 'combo_${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim().isEmpty ? 'My combo' : name.trim(),
      items: items,
      createdAt: DateTime.now(),
    );
    await _combosBox!.put(combo.id, combo);
    _refresh();
    return true;
  }

  Future<bool> deleteCombo(String id) async {
    if (_combosBox == null) return false;
    await _combosBox!.delete(id);
    _refresh();
    return true;
  }

  /// Logs every item in a combo to [meal] in one shot. Returns count added.
  Future<int> logCombo(FoodCombo combo, String meal) async {
    int n = 0;
    for (final f in combo.items) {
      if (await addFood(food: f, meal: meal, quantity: 1)) n++;
    }
    return n;
  }

  // ── weight tracking ───────────────────────────────────────────────────────────
  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// One reading per day (same-day re-log overwrites).
  Future<bool> addWeight(double lbs, {DateTime? date}) async {
    if (_weightBox == null || lbs <= 0) return false;
    final d = date ?? DateTime.now();
    final key = _dayKey(d);
    await _weightBox!.put(
      key,
      WeightEntry(id: key, date: DateTime(d.year, d.month, d.day, 12), weightLbs: lbs),
    );
    _refresh();
    return true;
  }

  Future<bool> deleteWeight(String id) async {
    if (_weightBox == null) return false;
    await _weightBox!.delete(id);
    _refresh();
    return true;
  }

  WeightEntry? get latestWeight => weights.isEmpty ? null : weights.last;
}

/// Summed nutrition across a set of logged entries, used by the daily and
/// weekly summary views. Sodium is milligrams; everything else is grams
/// (calories excepted).
class NutritionTotals {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodiumMg;

  const NutritionTotals({
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.sugar = 0,
    this.sodiumMg = 0,
  });

  factory NutritionTotals.of(Iterable<LoggedEntry> entries) {
    double cal = 0, pro = 0, carb = 0, fat = 0, fib = 0, sug = 0, sod = 0;
    for (final e in entries) {
      cal += e.calories;
      pro += e.protein;
      carb += e.carbs;
      fat += e.fat;
      fib += e.fiber;
      sug += e.sugar;
      sod += e.sodiumMg;
    }
    return NutritionTotals(
      calories: cal,
      protein: pro,
      carbs: carb,
      fat: fat,
      fiber: fib,
      sugar: sug,
      sodiumMg: sod,
    );
  }

  /// Per-day averages over [days] logged days (guards a zero divisor).
  NutritionTotals perDay(int days) {
    if (days <= 0) return const NutritionTotals();
    return NutritionTotals(
      calories: calories / days,
      protein: protein / days,
      carbs: carbs / days,
      fat: fat / days,
      fiber: fiber / days,
      sugar: sugar / days,
      sodiumMg: sodiumMg / days,
    );
  }
}
