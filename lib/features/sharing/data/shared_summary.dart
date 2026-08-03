import 'dart:convert';

/// A privacy-preserving snapshot of the owner's nutrition day — only what a
/// buddy needs for accountability, never raw meal-by-meal entries.
class NutritionSummary {
  final int calories; // consumed today
  final int calorieBudget; // daily goal
  final int protein; // grams today
  final int carbs;
  final int fat;
  final int? proteinGoal; // grams, when in protein mode
  final String trackingMode; // 'calories' | 'protein'
  final int updatedAtMs;

  const NutritionSummary({
    this.calories = 0,
    this.calorieBudget = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.proteinGoal,
    this.trackingMode = 'calories',
    this.updatedAtMs = 0,
  });

  int get caloriesRemaining => calorieBudget - calories;

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'calorieBudget': calorieBudget,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'proteinGoal': proteinGoal,
        'trackingMode': trackingMode,
        'updatedAtMs': updatedAtMs,
      };

  factory NutritionSummary.fromJson(Map<String, dynamic> j) => NutritionSummary(
        calories: (j['calories'] as num?)?.round() ?? 0,
        calorieBudget: (j['calorieBudget'] as num?)?.round() ?? 0,
        protein: (j['protein'] as num?)?.round() ?? 0,
        carbs: (j['carbs'] as num?)?.round() ?? 0,
        fat: (j['fat'] as num?)?.round() ?? 0,
        proteinGoal: (j['proteinGoal'] as num?)?.round(),
        trackingMode: (j['trackingMode'] ?? 'calories').toString(),
        updatedAtMs: (j['updatedAtMs'] as num?)?.toInt() ?? 0,
      );

  String toJsonString() => jsonEncode(toJson());
  factory NutritionSummary.fromJsonString(String s) =>
      NutritionSummary.fromJson(Map<String, dynamic>.from(jsonDecode(s) as Map));
}

/// A privacy-preserving snapshot of the owner's training — streak + recent
/// activity, never the full workout history.
class WorkoutSummary {
  final int currentStreak; // days
  final int workoutsThisWeek; // sessions + runs in the last 7 days
  final String lastActivity; // e.g. "Morning Run" / "Push Day"
  final int? lastActivityDaysAgo; // 0 = today, null = none
  final int updatedAtMs;

  const WorkoutSummary({
    this.currentStreak = 0,
    this.workoutsThisWeek = 0,
    this.lastActivity = '',
    this.lastActivityDaysAgo,
    this.updatedAtMs = 0,
  });

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'workoutsThisWeek': workoutsThisWeek,
        'lastActivity': lastActivity,
        'lastActivityDaysAgo': lastActivityDaysAgo,
        'updatedAtMs': updatedAtMs,
      };

  factory WorkoutSummary.fromJson(Map<String, dynamic> j) => WorkoutSummary(
        currentStreak: (j['currentStreak'] as num?)?.toInt() ?? 0,
        workoutsThisWeek: (j['workoutsThisWeek'] as num?)?.toInt() ?? 0,
        lastActivity: (j['lastActivity'] ?? '').toString(),
        lastActivityDaysAgo: (j['lastActivityDaysAgo'] as num?)?.toInt(),
        updatedAtMs: (j['updatedAtMs'] as num?)?.toInt() ?? 0,
      );

  String toJsonString() => jsonEncode(toJson());
  factory WorkoutSummary.fromJsonString(String s) =>
      WorkoutSummary.fromJson(Map<String, dynamic>.from(jsonDecode(s) as Map));
}

/// What the viewer receives when they open someone's profile: whichever
/// sections that person has granted them (either may be null = not shared).
class SharedStats {
  final NutritionSummary? nutrition;
  final WorkoutSummary? workout;

  const SharedStats({this.nutrition, this.workout});

  bool get hasAny => nutrition != null || workout != null;

  factory SharedStats.fromJson(Map<String, dynamic> j) => SharedStats(
        nutrition: j['nutrition'] is Map
            ? NutritionSummary.fromJson(
                Map<String, dynamic>.from(j['nutrition'] as Map))
            : null,
        workout: j['workout'] is Map
            ? WorkoutSummary.fromJson(
                Map<String, dynamic>.from(j['workout'] as Map))
            : null,
      );
}
