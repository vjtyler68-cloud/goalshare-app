import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../../../../goals/ui/goal_celebration.dart';
import '../core/hive_setup.dart';
import '../data/daily_todos.dart';
import '../data/todo_item.dart';

class DailyTodoController extends GetxController with WidgetsBindingObserver {
  Box<DailyTodos>? _box;

  /// Small side box holding a per-date "won the day" flag so the full-day
  /// celebration fires exactly once per day (un/re-checking won't re-fire).
  Box<String>? _wonDayBox;
  static const String _wonDayBoxName = 'daily_todos_won_day_v1';

  /// Saved daily-habit templates (habitId -> text). These seed each new day so
  /// recurring tasks never have to be retyped.
  Box<String>? _habitsBox;
  static const String _habitsBoxName = 'daily_habits_v1';
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

  /// Max tasks a user may add per day. Minimal by default — add as few or as
  /// many as you like, up to this cap.
  static const int maxTasks = 8;

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

    if (Hive.isBoxOpen(_wonDayBoxName)) {
      _wonDayBox = Hive.box<String>(_wonDayBoxName);
    } else {
      _wonDayBox = await Hive.openBox<String>(_wonDayBoxName);
    }

    if (Hive.isBoxOpen(_habitsBoxName)) {
      _habitsBox = Hive.box<String>(_habitsBoxName);
    } else {
      _habitsBox = await Hive.openBox<String>(_habitsBoxName);
    }

    // Resilience: if this side box was lost (e.g. a reinstall restored the
    // backed-up daily_todos but not this list), rebuild the templates from any
    // habit tasks still on today's list so they keep repeating.
    if (_habitsBox?.isEmpty ?? true) {
      final today = _box?.get(todayKey());
      if (today != null) {
        for (final it in today.items) {
          if (it.isHabit) _habitsBox?.put(it.habitId!, it.text);
        }
      }
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

  int get remainingSlots => maxTasks - _items.length;
  int get count => _items.length;
  bool get canAddMore => _items.length < maxTasks;

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

  Future<void> addTodo(String text, {bool repeat = false}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    // New tasks belong to today or tomorrow — checking off/editing a past day
    // is fine, but adding to it would undermine the 5-per-day rule.
    if (!canEditActiveDay) {
      Get.snackbar('Read-only', 'Past days are read-only. Switch to today or tomorrow to add tasks.');
      return;
    }
    _loadActiveDay();

    if (!canAddMore) {
      Get.snackbar('Limit reached', 'You can add up to $maxTasks tasks per day.');
      return;
    }

    final now = DateTime.now();
    String? habitId;
    if (repeat) {
      // Save a template so this task seeds every new day.
      habitId = 'h${now.microsecondsSinceEpoch}';
      await _habitsBox?.put(habitId, trimmed);
    }
    final newItem = TodoItem(
      id: repeat ? '$habitId@${_currentKey.value}'
                 : now.microsecondsSinceEpoch.toString(),
      text: trimmed,
      createdAt: now,
      done: false,
      habitId: habitId,
    );

    _items.add(newItem);
    await _persist();
  }

  /// Turn an existing task into a daily habit (auto-repeats each new day) or
  /// back into a one-off. Habits show the repeat badge and count toward the 5.
  Future<void> toggleRepeat(String id) async {
    _loadActiveDay();
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final item = _items[idx];

    if (item.isHabit) {
      // Stop repeating: drop the template, keep today's task as a one-off.
      await _habitsBox?.delete(item.habitId);
      _items[idx] = TodoItem(
        id: item.id,
        text: item.text,
        createdAt: item.createdAt,
        done: item.done,
        doneAt: item.doneAt,
        habitId: null,
      );
      await _persist();
      Get.snackbar('Habit off', '"${item.text}" won\'t repeat anymore.',
          snackPosition: SnackPosition.BOTTOM,
          margin: EdgeInsets.all(12), duration: const Duration(seconds: 2));
    } else {
      // Start repeating: save a template so it seeds every new day.
      final habitId = 'h${DateTime.now().microsecondsSinceEpoch}';
      await _habitsBox?.put(habitId, item.text);
      _items[idx] = TodoItem(
        id: item.id,
        text: item.text,
        createdAt: item.createdAt,
        done: item.done,
        doneAt: item.doneAt,
        habitId: habitId,
      );
      await _persist();
      Get.snackbar('Repeats daily 🔁', '"${item.text}" will show up every day.',
          snackPosition: SnackPosition.BOTTOM,
          margin: EdgeInsets.all(12), duration: const Duration(seconds: 2));
    }
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

    _maybeCelebrateWonDay(value);
  }

  /// Celebrate a fully-conquered day: every task checked off, with at least a
  /// few on the list (so a single-task day doesn't trivially fire it). Only for
  /// today, only when the toggle just marked something done, and only once per
  /// date — the flag is persisted so un/re-checking won't re-fire it.
  void _maybeCelebrateWonDay(bool value) {
    if (!value) return;
    if (dayOffset.value != 0) return;
    if (_items.length < 3) return;
    if (_items.any((e) => !e.done)) return;

    final key = 'won_day_${dayKey(activeDate)}';
    if (_wonDayBox?.get(key) != null) return;

    _wonDayBox?.put(key, DateTime.now().toIso8601String());
    HapticFeedback.heavyImpact();
    GoalCelebration.show(message: 'You won the day! 🏆');
  }

  Future<void> editText(String id, String newText) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final trimmed = newText.trim();
    if (trimmed.isEmpty) return;

    final item = _items[idx];
    _items[idx] = item.copyWith(text: trimmed);
    // Keep the habit template in step so future days use the new wording.
    if (item.isHabit) {
      await _habitsBox?.put(item.habitId!, trimmed);
    }
    await _persist();
  }

  Future<void> deleteTodo(String id) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    _items.removeAt(idx);
    await _persist();
  }

  /// Put a swipe-deleted task back exactly as it was — powers the Undo action.
  /// Re-adds by its original id/timestamps so the list re-sorts it into place.
  Future<void> restoreTodo(TodoItem item) async {
    if (_items.any((e) => e.id == item.id)) return;
    _items.add(item);
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
    final base = existing?.items ?? const <TodoItem>[];

    // Past days are read-only history — show exactly what's stored, never seed.
    if (dayOffset.value < 0) {
      _items.assignAll(base);
      return;
    }

    // Today or a future (planning) day: ALWAYS make sure every recurring daily
    // habit is present, merging any that are missing into whatever is already
    // saved. This is the fix for the bug where pre-creating a day (adding a
    // task to "Tomorrow" before it arrived) left that day WITHOUT the everyday
    // repeats — because it already existed, the old code skipped seeding.
    final merged = _mergeHabits(key, base);
    _items.assignAll(merged);

    // Persist when we created the day or added missing habits, so the list is
    // stable and gets cloud-backed-up.
    if (existing == null || merged.length != base.length) {
      _box?.put(key, DailyTodos(dateKey: key, items: merged));
    }
  }

  /// Ensure every saved daily habit appears on [dateKey]'s list (unchecked),
  /// merging in any that are missing while keeping the tasks already there.
  /// Habits count toward the per-day cap. Passing an empty [current] makes this
  /// behave like a fresh seed.
  List<TodoItem> _mergeHabits(String dateKey, List<TodoItem> current) {
    final box = _habitsBox;
    if (box == null || box.isEmpty) return List<TodoItem>.of(current);
    final present = current.map((e) => e.habitId).whereType<String>().toSet();
    final now = DateTime.now();
    final merged = List<TodoItem>.of(current);
    for (final key in box.keys) {
      if (merged.length >= maxTasks) break;
      final habitId = key.toString();
      if (present.contains(habitId)) continue; // already on the list
      final text = (box.get(key) ?? '').trim();
      if (text.isEmpty) continue;
      merged.add(TodoItem(
        id: '$habitId@$dateKey', // stable + unique per day
        text: text,
        createdAt: now,
        done: false,
        habitId: habitId,
      ));
    }
    return merged;
  }

  Future<void> _persist() async {
    final key = _currentKey.value.isEmpty ? todayKey() : _currentKey.value;
    final data = DailyTodos(dateKey: key, items: _items.toList());
    await _box?.put(key, data);
    _items.refresh();
  }
}
