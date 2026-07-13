import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../core/hive_setup.dart';
import '../data/daily_todos.dart';
import '../data/todo_item.dart';

class DailyTodoController extends GetxController with WidgetsBindingObserver {
  Box<DailyTodos>? _box;
  final RxList<TodoItem> _items = <TodoItem>[].obs;
  final RxString _currentKey = ''.obs;

  /// Which day the card is showing, as an offset from today:
  ///   -1 = yesterday (late-night finishers can still check items off)
  ///    0 = today
  ///   +1 = tomorrow (plan the next day ahead)
  /// New tasks can be added to today or tomorrow, but not to past days —
  /// that keeps the 5-per-day rule honest.
  final RxInt dayOffset = 0.obs;

  static const int _minOffset = -1;
  static const int _maxOffset = 1;

  /// Back-compat helper: true only while viewing yesterday.
  bool get viewingYesterday => dayOffset.value < 0;

  bool get canGoBack => dayOffset.value > _minOffset;
  bool get canGoForward => dayOffset.value < _maxOffset;

  /// Today and tomorrow accept new tasks; past days are check-off/edit only.
  bool get canEditActiveDay => dayOffset.value >= 0;

  /// Relative name for the active day: Yesterday / Today / Tomorrow.
  String get relativeLabel {
    switch (dayOffset.value) {
      case -1:
        return 'Yesterday';
      case 1:
        return 'Tomorrow';
      default:
        return 'Today';
    }
  }

  // Fires exactly at the next local midnight to flip the list to a clean day
  // even while the app sits open in the foreground.
  Timer? _midnightTimer;

  Future<void> _openBox() async {
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(TodoItemAdapter());
    if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(DailyTodosAdapter());

    if (!Hive.isBoxOpen(kDailyTodosBox)) {
      _box = await Hive.openBox<DailyTodos>(kDailyTodosBox);
    } else {
      _box = Hive.box<DailyTodos>(kDailyTodosBox);
    }

    _loadActiveDay();
  }

  // Schedule a one-shot timer for the next local midnight. On fire, load the
  // fresh (empty) day and re-arm for the following midnight.
  void _scheduleMidnightRollover() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    // +1s cushion so DateTime.now() is safely past midnight when we reload.
    final untilMidnight = nextMidnight.difference(now) + const Duration(seconds: 1);
    _midnightTimer = Timer(untilMidnight, () {
      // A new day started: snap the view back to (the new) today. The list the
      // user may have been finishing is now reachable via "view yesterday",
      // and what was "tomorrow" is now today.
      dayOffset.value = 0;
      _loadActiveDay();
      _scheduleMidnightRollover();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from background is the common way to cross midnight, so
    // re-check the day and re-arm the timer whenever the app resumes.
    // Snap back to today — "yesterday" has shifted meaning if a day passed.
    if (state == AppLifecycleState.resumed) {
      dayOffset.value = 0;
      _loadActiveDay();
      _scheduleMidnightRollover();
    }
  }

  /// Step to the previous day (down to yesterday).
  void goPrevDay() {
    if (!canGoBack) return;
    dayOffset.value--;
    _loadActiveDay();
  }

  /// Step to the next day (up to tomorrow) so the user can plan ahead.
  void goNextDay() {
    if (!canGoForward) return;
    dayOffset.value++;
    _loadActiveDay();
  }

  /// Jump straight back to today.
  void goToToday() {
    if (dayOffset.value == 0) return;
    dayOffset.value = 0;
    _loadActiveDay();
  }

  /// The date currently shown (yesterday, today, or tomorrow).
  DateTime get activeDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day)
        .add(Duration(days: dayOffset.value));
  }

  String formatDate(String? date) {
    if (date == null) return "-";
    final parseDate = DateTime.tryParse(date);
    if (parseDate == null) return "-";
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
    WidgetsBinding.instance.addObserver(this);
    _openBox();
    _scheduleMidnightRollover();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    super.onClose();
  }

  // Call this if you suspect the day changed while app running (e.g., via pull-to-refresh)
  void refreshForToday() {
    _loadActiveDay();
  }

  Future<void> addTodo(String text) async {
    if (text.trim().isEmpty) return;
    // New tasks belong to today or tomorrow — checking off/editing a past day
    // is fine, but adding to it would undermine the 5-per-day rule.
    if (!canEditActiveDay) {
      Get.snackbar('Read-only', 'Past days are read-only. Switch to today or tomorrow to add tasks.');
      return;
    }
    _loadActiveDay();

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
    _loadActiveDay();
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

  void _loadActiveDay() {
    final key = dayKey(activeDate);
    // Already showing this day's list — nothing to do. (Keyed on the date alone
    // so an empty-but-current day doesn't reload, and a day-flip always does.)
    if (_currentKey.value == key) return;

    _currentKey.value = key;
    final existing = _box?.get(key);
    if (existing == null) {
      _items.assignAll([]);
      // Materialise an empty record for TODAY only; just browsing an empty
      // yesterday or tomorrow shouldn't write anything until a task is added.
      if (dayOffset.value == 0) _box?.put(key, DailyTodos(dateKey: key, items: []));
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
