import 'package:hive/hive.dart';
import 'gratitude_entry.dart';

part 'daily_gratitude.g.dart';

@HiveType(typeId: 14)
class DailyGratitude {
  @HiveField(0)
  final String dateKey; // e.g. "2026-07-09"

  @HiveField(1)
  List<GratitudeEntry> entries;

  DailyGratitude({
    required this.dateKey,
    List<GratitudeEntry>? entries,
  }) : entries = entries ?? [];
}
