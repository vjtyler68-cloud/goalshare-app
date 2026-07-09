import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../core/hive_setup.dart';
import '../data/daily_todos.dart';
import '../data/todo_item.dart';

class DailyTodoController extends GetxController {
  Box<DailyTodos>? _box;
  final RxList<TodoItem> _items = <TodoItem>[].obs;
  final RxString _currentKey = ''.obs;

  Future<void> _openBox() async {
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(TodoItemAdapter());
    if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(DailyTodosAdapter());

    if (!Hive.isBoxOpen(kDailyTodosBox)) {
      _box = await Hive.openBox<DailyTodos>(kDailyTodosBox);
    } else {
      _box = Hive.box<DailyTodos>(kDailyTodosBox);
    }

    _ensureTodayLoaded();
  }

  String formatDate(String? date) {
    if (date == null) return "-";
    final parseDate = DateTime.parse(date);
    final formatDate = DateFormat('E, MMM d').format(parseDate);
    return formatDate;
  }

  // Public getters
  List<TodoItem> get items {
    // Sort: undone first by createdAt, then done by doneAt/createdAt
    final undone = _items.where((e) => !e.done).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final done = _items.where((e) => e.done).toList()
      ..sort((a, b) {
        final aT = a.doneAt ?? a.createdAt;
        final bT = b.doneAt ?? b.createdAt;
        return aT.compareTo(bT);
      });
    return [...undone, ...done];
  }

  int get remainingSlots => 5 - _items.length;
  int get count => _items.length;
  bool get canAddMore => _items.length < 5;

  @override
  void onInit() {
    super.onInit();
    _openBox();
  }

  // Call this if you suspect the day changed while app running (e.g., via pull-to-refresh)
  void refreshForToday() {
    _ensureTodayLoaded();
  }

  Future<void> addTodo(String text) async {
    if (text.trim().isEmpty) return;
    _ensureTodayLoaded();

    if (!canAddMore) {
      Get.snackbar('Limit reached', 'You can only create 5 todos per day.');
      return;
    }

    final now = DateTime.now();
    final newItem = TodoItem(
      id: now.microsecondsSinceEpoch.toString(),
      text: text.trim(),
      createdAt: now,
      done: false,
    );

    _items.add(newItem);
    await _persist();
  }

  Future<void> toggleDone(String id, bool value) async {
    _ensureTodayLoaded();
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) return;

    final item = _items[idx];
    _items[idx] = item.copyWith(
      done: value,
      doneAt: value ? DateTime.now() : null,
    );
    await _persist();
  }

  Future<void> editText(String id, String newText) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    if (newText.trim().isEmpty) return;

    final item = _items[idx];
    _items[idx] = item.copyWith(text: newText.trim());
    await _persist();
  }

  Future<void> deleteTodo(String id) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    _items.removeAt(idx);
    await _persist();
  }

  // --- internal helpers ---

  void _ensureTodayLoaded() {
    final key = todayKey();
    if (_currentKey.value == key && _items.isNotEmpty) return;

    _currentKey.value = key;
    final existing = _box?.get(key);
    if (existing == null) {
      // Start fresh for today
      _items.assignAll([]);
      _box?.put(key, DailyTodos(dateKey: key, items: []));
    } else {
      _items.assignAll(existing.items);
    }
  }

  Future<void> _persist() async {
    final key = _currentKey.value.isEmpty ? todayKey() : _currentKey.value;
    final data = DailyTodos(dateKey: key, items: _items.toList());
    await _box?.put(key, data);
    _items.refresh();
  }
}
