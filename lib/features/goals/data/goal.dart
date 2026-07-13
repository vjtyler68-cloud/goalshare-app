import 'package:hive/hive.dart';

part 'goal.g.dart';

// Sentinel so copyWith can distinguish "leave completedAt unchanged" from
// "explicitly set completedAt to null" (needed when a goal is un-completed).
const Object _undefined = Object();

/// A single user goal, stored locally in Hive (device-only, always saves — no
/// backend round-trip to fail). [target] is how many reps/units complete the
/// goal; [progress] is how far along. A goal is done when progress >= target.
@HiveType(typeId: 20)
class Goal {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;

  /// One of: Daily / Weekly / Monthly / Yearly.
  @HiveField(2)
  final String timeframe;

  @HiveField(3)
  final int target;
  @HiveField(4)
  final int progress;
  @HiveField(5)
  final DateTime createdAt;
  @HiveField(6)
  final DateTime? completedAt;

  /// A fun emoji shown on the card. Defaults to a target.
  @HiveField(7)
  final String emoji;

  const Goal({
    required this.id,
    required this.title,
    required this.timeframe,
    required this.target,
    required this.progress,
    required this.createdAt,
    this.completedAt,
    this.emoji = '🎯',
  });

  bool get isCompleted => progress >= target;

  double get fraction =>
      target <= 0 ? 1.0 : (progress / target).clamp(0.0, 1.0);

  int get remaining => (target - progress) < 0 ? 0 : target - progress;

  Goal copyWith({
    String? title,
    String? timeframe,
    int? target,
    int? progress,
    String? emoji,
    Object? completedAt = _undefined,
  }) {
    return Goal(
      id: id,
      title: title ?? this.title,
      timeframe: timeframe ?? this.timeframe,
      target: target ?? this.target,
      progress: progress ?? this.progress,
      createdAt: createdAt,
      completedAt: identical(completedAt, _undefined)
          ? this.completedAt
          : completedAt as DateTime?,
      emoji: emoji ?? this.emoji,
    );
  }
}
