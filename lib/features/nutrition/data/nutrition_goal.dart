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

  const NutritionGoal({
    this.dailyCalorieBudget = 2000,
    this.proteinTargetG,
    this.carbsTargetG,
    this.fatTargetG,
  });

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
  }) {
    return NutritionGoal(
      dailyCalorieBudget: dailyCalorieBudget ?? this.dailyCalorieBudget,
      proteinTargetG: proteinTargetG ?? this.proteinTargetG,
      carbsTargetG: carbsTargetG ?? this.carbsTargetG,
      fatTargetG: fatTargetG ?? this.fatTargetG,
    );
  }
}
