import 'package:hive/hive.dart';
import 'todo_item.dart';

part 'daily_todos.g.dart';

@HiveType(typeId: 12)
class DailyTodos {
  @HiveField(0)
  final String dateKey; // e.g. "2025-11-02"

  @HiveField(1)
  List<TodoItem> items;

  DailyTodos({
    required this.dateKey,
    List<TodoItem>? items,
  }) : items = items ?? [];

  // ── Cloud backup (JSON) ─────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
        'dateKey': dateKey,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory DailyTodos.fromJson(Map<String, dynamic> j) => DailyTodos(
        dateKey: (j['dateKey'] ?? '').toString(),
        items: ((j['items'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => TodoItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}
