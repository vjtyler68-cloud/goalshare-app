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

  /// When true, this goal auto-RESETS at the start of each new period (its
  /// [timeframe] cadence — a Daily goal resets every day, Weekly every week,
  /// etc.), so a routine habit comes back fresh instead of staying done forever.
  @HiveField(8)
  final bool repeats;

  /// The moment this goal was last rolled into its current period. The
  /// controller uses it to decide when a repeating goal is due to reset.
  /// Null → fall back to [createdAt].
  @HiveField(9)
  final DateTime? lastReset;

  const Goal({
    required this.id,
    required this.title,
    required this.timeframe,
    required this.target,
    required this.progress,
    required this.createdAt,
    this.completedAt,
    this.emoji = '🎯',
    this.repeats = false,
    this.lastReset,
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
    bool? repeats,
    Object? completedAt = _undefined,
    Object? lastReset = _undefined,
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
      repeats: repeats ?? this.repeats,
      lastReset: identical(lastReset, _undefined)
          ? this.lastReset
          : lastReset as DateTime?,
    );
  }

  // ── Cloud backup (JSON) ─────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'timeframe': timeframe,
        'target': target,
        'progress': progress,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'emoji': emoji,
        'repeats': repeats,
        'lastReset': lastReset?.toIso8601String(),
      };

  factory Goal.fromJson(Map<String, dynamic> j) => Goal(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        timeframe: (j['timeframe'] ?? 'Daily').toString(),
        target: (j['target'] is num)
            ? (j['target'] as num).toInt()
            : int.tryParse('${j['target'] ?? ''}') ?? 0,
        progress: (j['progress'] is num)
            ? (j['progress'] as num).toInt()
            : int.tryParse('${j['progress'] ?? ''}') ?? 0,
        createdAt:
            DateTime.tryParse('${j['createdAt'] ?? ''}') ?? DateTime.now(),
        completedAt: j['completedAt'] == null
            ? null
            : DateTime.tryParse('${j['completedAt']}'),
        emoji: (j['emoji'] ?? '🎯').toString(),
        repeats: j['repeats'] == true,
        lastReset: j['lastReset'] == null
            ? null
            : DateTime.tryParse('${j['lastReset']}'),
      );
}
