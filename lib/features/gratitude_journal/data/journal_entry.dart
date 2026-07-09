import 'package:hive/hive.dart';

part 'journal_entry.g.dart';

/// One journal entry per calendar day.
/// [id] is the dateKey "YYYY-MM-DD" so there is exactly one entry per day.
@HiveType(typeId: 13)
class JournalEntry {
  @HiveField(0)
  final String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  List<String> gratitudeItems;

  @HiveField(3)
  String dayText;

  @HiveField(4)
  int starRating; // 0 = unset, 1..5

  @HiveField(5)
  String? mood; // great / good / okay / hard / rough

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime? updatedAt;

  @HiveField(8)
  bool edited;

  JournalEntry({
    required this.id,
    required this.date,
    required this.gratitudeItems,
    this.dayText = '',
    this.starRating = 0,
    this.mood,
    required this.createdAt,
    this.updatedAt,
    this.edited = false,
  });

  JournalEntry copyWith({
    String? id,
    DateTime? date,
    List<String>? gratitudeItems,
    String? dayText,
    int? starRating,
    String? mood,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? edited,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      gratitudeItems: gratitudeItems ?? this.gratitudeItems,
      dayText: dayText ?? this.dayText,
      starRating: starRating ?? this.starRating,
      mood: mood ?? this.mood,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      edited: edited ?? this.edited,
    );
  }
}
