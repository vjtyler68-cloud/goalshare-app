import 'package:hive/hive.dart';

part 'gratitude_entry.g.dart';

@HiveType(typeId: 13)
class GratitudeEntry {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String text;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  DateTime? updatedAt;

  GratitudeEntry({
    required this.id,
    required this.text,
    required this.createdAt,
    this.updatedAt,
  });

  GratitudeEntry copyWith({
    String? id,
    String? text,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GratitudeEntry(
      id: id ?? this.id,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
