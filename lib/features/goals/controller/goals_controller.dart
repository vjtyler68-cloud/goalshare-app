import 'dart:developer';

import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../data/goal.dart';

/// Local-first goals store. Everything lives in a Hive box on the device, so
/// creating and updating a goal always succeeds instantly (no backend call to
/// fail). Reads/writes are gated on [isReady].
class GoalsController extends GetxController {
  static const String kGoalsBox = 'goals_box';

  /// Timeframes in display order. Used for the create sheet chips and grouping.
  static const List<String> timeframes = ['Daily', 'Weekly', 'Monthly', 'Yearly'];

  static String bucketLabel(String tf) {
    switch (tf) {
      case 'Daily':
        return 'Today';
      case 'Weekly':
        return 'This Week';
      case 'Monthly':
        return 'This Month';
      case 'Yearly':
        return 'This Year';
      default:
        return tf;
    }
  }

  Box<Goal>? _box;
  final RxList<Goal> goals = <Goal>[].obs;
  final RxBool isReady = false.obs;

  // Kept so writes triggered before init finishes (e.g. the FAB opening the
  // create sheet on first launch) can await readiness instead of silently
  // no-op'ing.
  Future<void>? _initFuture;

  @override
  void onInit() {
    super.onInit();
    _initFuture = _init();
  }

  Future<void> _ensureReady() => _initFuture ??= _init();

  Future<void> _init() async {
    try {
      if (!Hive.isAdapterRegistered(20)) {
        Hive.registerAdapter(GoalAdapter());
      }
      _box = Hive.isBoxOpen(kGoalsBox)
          ? Hive.box<Goal>(kGoalsBox)
          : await Hive.openBox<Goal>(kGoalsBox);
      goals.assignAll(_box!.values.toList());
      await rolloverRepeats();
      _sort();
      isReady.value = true;
    } catch (e) {
      log('GoalsController init error: $e');
    }
  }

  // ── Aggregates (drive the header stats) ──────────────────────────────────
  int get activeCount => goals.where((g) => !g.isCompleted).length;
  int get completedCount => goals.where((g) => g.isCompleted).length;
  int get totalCount => goals.length;

  /// Average completion across all goals, 0..1.
  double get overallProgress {
    if (goals.isEmpty) return 0;
    final sum = goals.fold<double>(0, (a, g) => a + g.fraction);
    return sum / goals.length;
  }

  /// Goals for a timeframe, undone first (created order), then completed.
  List<Goal> byTimeframe(String tf) {
    final list = goals.where((g) => g.timeframe == tf).toList();
    list.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      return a.createdAt.compareTo(b.createdAt);
    });
    return list;
  }

  // ── Mutations ────────────────────────────────────────────────────────────
  Future<void> addGoal({
    required String title,
    required String timeframe,
    required int target,
    String emoji = '🎯',
    bool repeats = false,
  }) async {
    await _ensureReady();
    if (_box == null) return;
    if (title.trim().isEmpty) return;
    final now = DateTime.now();
    final goal = Goal(
      id: now.microsecondsSinceEpoch.toString(),
      title: title.trim(),
      timeframe: timeframe,
      target: target < 1 ? 1 : target,
      progress: 0,
      createdAt: now,
      emoji: emoji,
      repeats: repeats,
      lastReset: now, // anchors the first period so it won't reset today
    );
    await _box!.put(goal.id, goal);
    goals.add(goal);
    _sort();
    goals.refresh();
  }

  Future<void> editGoal(
    String id, {
    required String title,
    required String timeframe,
    required int target,
    required String emoji,
    required bool repeats,
  }) async {
    await _ensureReady();
    final idx = goals.indexWhere((g) => g.id == id);
    if (idx == -1) return;
    final current = goals[idx];
    final safeTarget = target < 1 ? 1 : target;
    final updated = current.copyWith(
      title: title.trim().isEmpty ? current.title : title.trim(),
      timeframe: timeframe,
      target: safeTarget,
      emoji: emoji,
      repeats: repeats,
      // Re-derive completion against the new target.
      completedAt: current.progress >= safeTarget
          ? (current.completedAt ?? DateTime.now())
          : null,
      // Turning repeat ON anchors a fresh period so it doesn't instantly roll
      // over; otherwise leave the existing anchor.
      lastReset:
          (repeats && !current.repeats) ? DateTime.now() : current.lastReset,
    );
    goals[idx] = updated;
    await _box?.put(updated.id, updated);
    _sort();
    goals.refresh();
  }

  /// Bumps progress by one. Returns true if this tap *completed* the goal
  /// (so the UI can celebrate).
  Future<bool> increment(String id) async {
    final idx = goals.indexWhere((g) => g.id == id);
    if (idx == -1) return false;
    final g = goals[idx];
    if (g.isCompleted) return false;
    final next = g.progress + 1;
    final justCompleted = next >= g.target;
    final updated = g.copyWith(
      progress: next,
      completedAt: justCompleted ? DateTime.now() : null,
    );
    goals[idx] = updated;
    await _box?.put(updated.id, updated);
    _sort();
    goals.refresh();
    return justCompleted;
  }

  Future<void> decrement(String id) async {
    final idx = goals.indexWhere((g) => g.id == id);
    if (idx == -1) return;
    final g = goals[idx];
    final next = g.progress - 1 < 0 ? 0 : g.progress - 1;
    final updated = g.copyWith(
      progress: next,
      completedAt: next >= g.target ? g.completedAt : null,
    );
    goals[idx] = updated;
    await _box?.put(updated.id, updated);
    _sort();
    goals.refresh();
  }

  /// One-tap complete / reset. Returns true if the goal just became complete.
  Future<bool> toggleComplete(String id) async {
    final idx = goals.indexWhere((g) => g.id == id);
    if (idx == -1) return false;
    final g = goals[idx];
    final becameComplete = !g.isCompleted;
    final updated = becameComplete
        ? g.copyWith(progress: g.target, completedAt: DateTime.now())
        : g.copyWith(progress: 0, completedAt: null);
    goals[idx] = updated;
    await _box?.put(updated.id, updated);
    _sort();
    goals.refresh();
    return becameComplete;
  }

  Future<void> deleteGoal(String id) async {
    goals.removeWhere((g) => g.id == id);
    await _box?.delete(id);
    goals.refresh();
  }

  // ── Repeating goals ──────────────────────────────────────────────────────
  /// A key that changes whenever a new period begins for [timeframe]. Two dates
  /// in the same period share a key; a rollover produces a different one.
  String _periodKey(String timeframe, DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    switch (timeframe) {
      case 'Weekly':
        final monday = day.subtract(Duration(days: day.weekday - 1));
        return 'W${monday.year}-${monday.month}-${monday.day}';
      case 'Monthly':
        return 'M${d.year}-${d.month}';
      case 'Yearly':
        return 'Y${d.year}';
      default: // Daily
        return 'D${day.year}-${day.month}-${day.day}';
    }
  }

  /// Reset any repeating goal whose period has rolled over since it was last
  /// active — so a daily routine item comes back FRESH each day instead of
  /// staying completed forever. Called on launch; safe to call again (e.g. when
  /// the Goals tab is reopened after midnight).
  Future<void> rolloverRepeats() async {
    final now = DateTime.now();
    var changed = false;
    for (var i = 0; i < goals.length; i++) {
      final g = goals[i];
      if (!g.repeats) continue;
      final marker = g.lastReset ?? g.createdAt;
      if (_periodKey(g.timeframe, marker) == _periodKey(g.timeframe, now)) {
        continue; // still the same period — nothing to do
      }
      final reset = g.copyWith(progress: 0, completedAt: null, lastReset: now);
      goals[i] = reset;
      await _box?.put(reset.id, reset);
      changed = true;
    }
    if (changed) {
      _sort();
      goals.refresh();
    }
  }

  void _sort() {
    goals.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      return a.createdAt.compareTo(b.createdAt);
    });
  }
}
