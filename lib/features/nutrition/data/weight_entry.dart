import 'package:hive/hive.dart';

part 'weight_entry.g.dart';

/// A single body-weight reading on a given [date] (one per day; keyed by
/// the day string so re-logging the same day overwrites).
@HiveType(typeId: 17)
class WeightEntry {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final double weightLbs;

  const WeightEntry({
    required this.id,
    required this.date,
    required this.weightLbs,
  });

  // ── Cloud backup (JSON) ─────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'weightLbs': weightLbs,
      };

  factory WeightEntry.fromJson(Map<String, dynamic> j) => WeightEntry(
        id: (j['id'] ?? '').toString(),
        date: DateTime.tryParse('${j['date'] ?? ''}') ?? DateTime.now(),
        weightLbs: (j['weightLbs'] is num)
            ? (j['weightLbs'] as num).toDouble()
            : double.tryParse('${j['weightLbs'] ?? ''}') ?? 0,
      );
}
