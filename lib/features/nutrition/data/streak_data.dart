import 'package:hive/hive.dart';

part 'streak_data.g.dart';

/// Tracks consecutive-day logging streaks — the zero-cost retention driver.
@HiveType(typeId: 19)
class StreakData {
  @HiveField(0)
  final int currentStreak;

  @HiveField(1)
  final int longestStreak;

  @HiveField(2)
  final DateTime? lastLoggedDate;

  const StreakData({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastLoggedDate,
  });

  StreakData copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastLoggedDate,
  }) {
    return StreakData(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastLoggedDate: lastLoggedDate ?? this.lastLoggedDate,
    );
  }
}
