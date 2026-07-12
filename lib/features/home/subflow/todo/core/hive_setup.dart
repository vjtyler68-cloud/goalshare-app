import 'package:hive_flutter/hive_flutter.dart';
import '../data/todo_item.dart';
import '../data/daily_todos.dart';

const String kDailyTodosBox = 'daily_todos';

Future<void> initHive() async {
  await Hive.initFlutter();

  // Register adapters once
  if (!Hive.isAdapterRegistered(11)) {
    Hive.registerAdapter(TodoItemAdapter());
  }
  if (!Hive.isAdapterRegistered(12)) {
    Hive.registerAdapter(DailyTodosAdapter());
  }

  // Open the box that stores DailyTodos keyed by date string
  await Hive.openBox<DailyTodos>(kDailyTodosBox);
}

/// Utility: date key like "YYYY-MM-DD" (local) for any date.
String dayKey(DateTime d) {
  final only = DateTime(d.year, d.month, d.day);
  // ISO-like, but just the date part
  return "${only.year.toString().padLeft(4, '0')}-"
      "${only.month.toString().padLeft(2, '0')}-"
      "${only.day.toString().padLeft(2, '0')}";
}

/// Utility: date key like "YYYY-MM-DD" (local)
String todayKey() => dayKey(DateTime.now());

/// Yesterday's date key — used by the "view yesterday" toggle.
String yesterdayKey() =>
    dayKey(DateTime.now().subtract(const Duration(days: 1)));
