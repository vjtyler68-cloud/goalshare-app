import 'package:hive/hive.dart';

part 'nutrition_goal.g.dart';

/// The user's daily calorie budget and optional macro targets (grams).
@HiveType(typeId: 16)
class NutritionGoal {
  @HiveField(0)
  final int dailyCalorieBudget;

  @HiveField(1)
  final double? proteinTargetG;

  @HiveField(2)
  final double? carbsTargetG;

  @HiveField(3)
  final double? fatTargetG;

  // ── Weight goal + pacing (set via the Goal Setup flow) ──────────────────────
  @HiveField(4)
  final double? currentWeightLbs;

  @HiveField(5)
  final double? goalWeightLbs;

  @HiveField(6)
  final DateTime? targetDate;

  /// e.g. -1.0 for "lose 1 lb/week", +0.5 for a lean bulk. Negative = deficit.
  @HiveField(7)
  final double? targetWeeklyRateLbs;

  // ── Profile inputs kept so the budget can be recalculated/edited later ──────
  @HiveField(8)
  final int? ageYears;

  @HiveField(9)
  final bool? sexMale;

  @HiveField(10)
  final double? heightCm;

  /// Mifflin-St Jeor activity multiplier (1.2 sedentary … 1.725 very active).
  @HiveField(11)
  final double? activityLevel;

  const NutritionGoal({
    this.dailyCalorieBudget = 2000,
    this.proteinTargetG,
    this.carbsTargetG,
    this.fatTargetG,
    this.currentWeightLbs,
    this.goalWeightLbs,
    this.targetDate,
    this.targetWeeklyRateLbs,
    this.ageYears,
    this.sexMale,
    this.heightCm,
    this.activityLevel,
  });

  /// Whether the personalized Goal Setup flow has been completed.
  bool get isPersonalized => currentWeightLbs != null && goalWeightLbs != null;

  /// Daily calorie budget from Mifflin-St Jeor BMR × activity, offset by the
  /// deficit/surplus needed to hit [weeklyRateLbs] (3500 cal ≈ 1 lb). Pure
  /// arithmetic, clamped to a safe floor/ceiling.
  static int computeBudget({
    required double currentLbs,
    required bool male,
    required int age,
    required double heightCm,
    required double activity,
    required double weeklyRateLbs,
  }) {
    final kg = currentLbs * 0.45359237;
    final bmr = 10 * kg + 6.25 * heightCm - 5 * age + (male ? 5 : -161);
    final tdee = bmr * activity;
    final dailyAdjustment = weeklyRateLbs * 3500 / 7;
    final budget = (tdee + dailyAdjustment).round();
    return budget.clamp(1200, 6000);
  }

  /// Sensible macro defaults derived from the calorie budget when the user
  /// hasn't set explicit targets: 30% protein / 40% carbs / 30% fat.
  double get effectiveProtein => proteinTargetG ?? (dailyCalorieBudget * 0.30 / 4);
  double get effectiveCarbs => carbsTargetG ?? (dailyCalorieBudget * 0.40 / 4);
  double get effectiveFat => fatTargetG ?? (dailyCalorieBudget * 0.30 / 9);

  NutritionGoal copyWith({
    int? dailyCalorieBudget,
    double? proteinTargetG,
    double? carbsTargetG,
    double? fatTargetG,
    double? currentWeightLbs,
    double? goalWeightLbs,
    DateTime? targetDate,
    double? targetWeeklyRateLbs,
    int? ageYears,
    bool? sexMale,
    double? heightCm,
    double? activityLevel,
  }) {
    return NutritionGoal(
      dailyCalorieBudget: dailyCalorieBudget ?? this.dailyCalorieBudget,
      proteinTargetG: proteinTargetG ?? this.proteinTargetG,
      carbsTargetG: carbsTargetG ?? this.carbsTargetG,
      fatTargetG: fatTargetG ?? this.fatTargetG,
      currentWeightLbs: currentWeightLbs ?? this.currentWeightLbs,
      goalWeightLbs: goalWeightLbs ?? this.goalWeightLbs,
      targetDate: targetDate ?? this.targetDate,
      targetWeeklyRateLbs: targetWeeklyRateLbs ?? this.targetWeeklyRateLbs,
      ageYears: ageYears ?? this.ageYears,
      sexMale: sexMale ?? this.sexMale,
      heightCm: heightCm ?? this.heightCm,
      activityLevel: activityLevel ?? this.activityLevel,
    );
  }
}
