import 'package:hive/hive.dart';

part 'todo_item.g.dart';

@HiveType(typeId: 11)
class TodoItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String text;

  @HiveField(2)
  bool done;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime? doneAt;

  TodoItem({
    required this.id,
    required this.text,
    required this.createdAt,
    this.done = false,
    this.doneAt,
  });

  TodoItem copyWith({
    String? id,
    String? text,
    bool? done,
    DateTime? createdAt,
    DateTime? doneAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      done: done ?? this.done,
      doneAt: doneAt,
    );
  }
}
