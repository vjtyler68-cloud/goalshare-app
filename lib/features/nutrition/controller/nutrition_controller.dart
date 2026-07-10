import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../data/food_item.dart';
import '../data/logged_entry.dart';
import '../data/nutrition_goal.dart';
import '../service/food_api_service.dart';

const String kNutritionEntriesBox = 'nutritionEntriesBox';
const String kFoodCacheBox = 'foodCacheBox';
const String kNutritionGoalsBox = 'nutritionGoalsBox';

const List<String> kMeals = ['breakfast', 'lunch', 'dinner', 'snacks'];
const String kExerciseMeal = 'exercise';
const String _kGoalKey = 'goal';

class NutritionController extends GetxController {
  /// Shared instance — reused if already registered (survives deep links).
  static NutritionController get to => Get.isRegistered<NutritionController>()
      ? Get.find<NutritionController>()
      : Get.put(NutritionController(), permanent: true);

  Box<LoggedEntry>? _entriesBox;
  Box<NutritionGoal>? _goalBox;
  Box<String>? _cacheBox;

  final RxBool isReady = false.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final Rxn<NutritionGoal> goal = Rxn<NutritionGoal>();

  /// All logged entries across all days. Reactive so screens rebuild on change.
  final RxList<LoggedEntry> allEntries = <LoggedEntry>[].obs;

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

      _entriesBox = Hive.isBoxOpen(kNutritionEntriesBox)
          ? Hive.box<LoggedEntry>(kNutritionEntriesBox)
          : await Hive.openBox<LoggedEntry>(kNutritionEntriesBox);
      _goalBox = Hive.isBoxOpen(kNutritionGoalsBox)
          ? Hive.box<NutritionGoal>(kNutritionGoalsBox)
          : await Hive.openBox<NutritionGoal>(kNutritionGoalsBox);
      _cacheBox = Hive.isBoxOpen(kFoodCacheBox)
          ? Hive.box<String>(kFoodCacheBox)
          : await Hive.openBox<String>(kFoodCacheBox);

      api.cacheBox = _cacheBox;
      goal.value = _goalBox?.get(_kGoalKey) ?? const NutritionGoal();
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

  double caloriesForMeal(String meal) =>
      entriesForMeal(meal).fold(0.0, (p, e) => p + e.calories);

  /// Even split of the daily budget across the four meals (suggested target).
  int get suggestedMealTarget => (budget / kMeals.length).round();

  // ── today summary (for the dashboard tile) ───────────────────────────────────
  double get todayFoodCalories => allEntries
      .where((e) => kMeals.contains(e.meal) && _sameDay(e.date, DateTime.now()))
      .fold(0.0, (p, e) => p + e.calories);

  bool get hasLoggedToday => allEntries.any((e) => _sameDay(e.date, DateTime.now()));

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
}
