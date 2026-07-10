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
}
