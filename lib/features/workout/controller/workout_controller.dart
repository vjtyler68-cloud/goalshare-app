import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/notifications/notification_service.dart';
import '../data/cardio_run.dart';
import '../data/exercise_library.dart';
import '../data/workout_models.dart';
import '../data/workout_store.dart';

/// The single source of truth for MY WORKOUT.
///
/// Owns the active session, the streak engine, PR detection, the rest timer and
/// all analytics. Every mutation to the active session is immediately persisted
/// (`_persistActive`) so an OS process-kill mid-set loses nothing — reopening
/// re-hydrates the exact state.
class WorkoutController extends GetxController {
  // Lazily register if a screen is ever reached without the route binding, so
  // `.to` can never throw "controller not found" (which renders as a gray screen).
  static WorkoutController get to => Get.isRegistered<WorkoutController>()
      ? Get.find<WorkoutController>()
      : Get.put(WorkoutController(), permanent: true);

  final WorkoutStore _store = WorkoutStore();
  final _rng = Random();

  // ---- reactive state ----
  final Rxn<WorkoutSession> active = Rxn<WorkoutSession>();
  final Rx<StreakState> streak = StreakState().obs;
  final RxList<WorkoutSession> history = <WorkoutSession>[].obs;
  final RxList<WorkoutGoal> goals = <WorkoutGoal>[].obs;
  final RxList<Exercise> customExercises = <Exercise>[].obs;
  final RxList<CardioRun> runs = <CardioRun>[].obs;

  // rest timer
  final RxInt restRemaining = 0.obs; // 0 = idle
  final RxInt restTotal = 0.obs;
  Timer? _restTimer;
  int defaultRest = 90;

  // celebration signals (screens listen and animate)
  final RxnString celebration = RxnString(); // 'pr' | 'milestone' | 'finish'
  final RxInt milestoneValue = 0.obs;

  // units
  final RxString unit = 'lbs'.obs;
  static const String _kUnitPref = 'workout_unit';

  bool _ready = false;
  bool get isReady => _ready;

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _store.open();
    try {
      final prefs = await SharedPreferences.getInstance();
      unit.value = prefs.getString(_kUnitPref) ?? 'lbs';
    } catch (_) {}
    streak.value = _store.getStreak();
    history.assignAll(_store.allSessions());
    goals.assignAll(_store.getGoals());
    customExercises.assignAll(_store.getCustomExercises());
    runs.assignAll(_store.allRuns());
    active.value = _store.getActive(); // crash recovery
    _refreshGoalProgress();
    _ready = true;
  }

  // -------------------------------------------------------------- exercises
  /// Built-in catalogue + user-created, deduped by id.
  List<Exercise> get allExercises {
    final map = <String, Exercise>{};
    for (final e in ExerciseLibrary.all) {
      map[e.id] = e;
    }
    for (final e in customExercises) {
      map[e.id] = e;
    }
    return map.values.toList();
  }

  Exercise? exerciseById(String id) {
    for (final e in allExercises) {
      if (e.id == id) return e;
    }
    return null;
  }

  List<Exercise> searchExercises(String q) {
    final query = q.trim().toLowerCase();
    final base = allExercises;
    if (query.isEmpty) return base;
    final starts = <Exercise>[];
    final contains = <Exercise>[];
    for (final e in base) {
      final n = e.name.toLowerCase();
      if (n.startsWith(query)) {
        starts.add(e);
      } else if (n.contains(query)) {
        contains.add(e);
      }
    }
    return [...starts, ...contains];
  }

  Future<Exercise> createCustomExercise(String name, MuscleGroup muscle,
      {bool bodyweight = false, bool timed = false}) async {
    final ex = Exercise(
      id: 'custom_${_uid()}',
      name: name.trim(),
      primary: muscle,
      bodyweight: bodyweight,
      timed: timed,
      custom: true,
    );
    customExercises.add(ex);
    await _store.setCustomExercises(customExercises);
    return ex;
  }

  // --------------------------------------------------------- start a workout
  bool get hasActive => active.value != null;

  void startEmpty() {
    active.value = WorkoutSession(
      id: _uid(),
      name: 'Freestyle',
      emoji: '💪',
      startedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    _persistActive();
  }

  void startFromTemplate(WorkoutTemplate tpl) {
    final logs = <ExerciseLog>[];
    for (final te in tpl.exercises) {
      final ex = exerciseById(te.exerciseId);
      if (ex == null) continue;
      logs.add(_buildLog(ex, targetSets: te.sets));
    }
    active.value = WorkoutSession(
      id: _uid(),
      name: tpl.name,
      emoji: tpl.emoji,
      startedAtMs: DateTime.now().millisecondsSinceEpoch,
      exercises: logs,
    );
    _persistActive();
  }

  /// One-tap "repeat my last workout" — same exercises, previous numbers
  /// pre-filled but unchecked.
  void repeatLast() {
    final last = history.isNotEmpty ? history.first : null;
    if (last == null) {
      startEmpty();
      return;
    }
    final logs = <ExerciseLog>[];
    for (final el in last.exercises) {
      final ex = exerciseById(el.exerciseId);
      logs.add(_buildLog(
        ex ??
            Exercise(id: el.exerciseId, name: el.name, primary: el.muscle),
        targetSets: max(1, el.sets.where((s) => s.type.countsAsWork).length),
      ));
    }
    active.value = WorkoutSession(
      id: _uid(),
      name: last.name,
      emoji: last.emoji,
      startedAtMs: DateTime.now().millisecondsSinceEpoch,
      exercises: logs,
    );
    _persistActive();
  }

  void addExerciseToActive(Exercise ex) {
    final s = active.value;
    if (s == null) return;
    s.exercises.add(_buildLog(ex, targetSets: 1));
    active.refresh();
    _persistActive();
  }

  /// Build an ExerciseLog with N empty sets, each PRE-FILLED from the last time
  /// this exercise was trained (weight + reps land straight in the inputs).
  ExerciseLog _buildLog(Exercise ex, {required int targetSets}) {
    final prev = previousPerformance(ex.id);
    final sets = <SetEntry>[];
    for (var i = 0; i < max(1, targetSets); i++) {
      final p = i < prev.length ? prev[i] : (prev.isNotEmpty ? prev.last : null);
      sets.add(SetEntry(
        id: _uid(),
        weight: p?.weight,
        reps: p?.reps,
        type: SetType.working,
      ));
    }
    return ExerciseLog(
      id: _uid(),
      exerciseId: ex.id,
      name: ex.name,
      muscle: ex.primary,
      bodyweight: ex.bodyweight,
      timed: ex.timed,
      sets: sets,
    );
  }

  // ------------------------------------------------------------- set editing
  void addSet(ExerciseLog log) {
    final last = log.sets.isNotEmpty ? log.sets.last : null;
    log.sets.add(SetEntry(
      id: _uid(),
      weight: last?.weight,
      reps: last?.reps,
      rpe: last?.rpe,
      type: last?.type == SetType.warmup ? SetType.working : (last?.type ?? SetType.working),
    ));
    active.refresh();
    _persistActive();
  }

  void updateSet(ExerciseLog log, SetEntry set,
      {double? weight, int? reps, double? rpe, SetType? type}) {
    if (weight != null) set.weight = weight;
    if (reps != null) set.reps = reps;
    if (rpe != null) set.rpe = rpe;
    if (type != null) set.type = type;
    active.refresh();
    _persistActive();
  }

  void removeSet(ExerciseLog log, SetEntry set) {
    log.sets.remove(set);
    active.refresh();
    _persistActive();
  }

  void removeExercise(ExerciseLog log) {
    active.value?.exercises.remove(log);
    active.refresh();
    _persistActive();
  }

  /// The big one-tap checkmark. Marks done, detects a PR, kicks the rest timer,
  /// buzzes, and autosaves — all in one tap.
  void toggleSetDone(ExerciseLog log, SetEntry set) {
    set.done = !set.done;
    if (set.done) {
      HapticFeedback.mediumImpact();
      _maybeFlagPr(log, set);
      if (set.type.countsAsWork || set.type == SetType.warmup) {
        startRest(set.type == SetType.warmup ? 45 : defaultRest);
      }
    } else {
      set.isPr = false;
    }
    active.refresh();
    _persistActive();
  }

  void _maybeFlagPr(ExerciseLog log, SetEntry set) {
    if (!set.type.countsAsWork) return;
    if (set.weight == null || set.reps == null || set.reps! <= 0) return;
    final best = historicalBestE1rm(log.exerciseId);
    if (set.e1rm > best && set.e1rm > 0) {
      set.isPr = true;
      HapticFeedback.heavyImpact();
      celebration.value = 'pr';
    }
  }

  // --------------------------------------------------------------- finishing
  void finishWorkout() {
    final s = active.value;
    if (s == null) return;
    // Trim empty sets so a half-tapped row doesn't pollute stats.
    for (final el in s.exercises) {
      el.sets.removeWhere((set) => !set.done && set.weight == null && set.reps == null);
    }
    s.exercises.removeWhere((el) => el.sets.isEmpty);
    s.endedAtMs = DateTime.now().millisecondsSinceEpoch;

    _store.saveSession(s);
    history.insert(0, s);
    _applyStreakForToday();
    _refreshGoalProgress();

    stopRest();
    active.value = null;
    _store.setActive(null);
    celebration.value = 'finish';
  }

  void discardWorkout() {
    stopRest();
    active.value = null;
    _store.setActive(null);
  }

  // ------------------------------------------------------------ cardio runs
  /// Save a finished run/walk — persists it, counts it toward the streak, and
  /// refreshes goals (a run is a workout too).
  Future<void> saveRun(CardioRun run) async {
    run.endedAtMs ??= DateTime.now().millisecondsSinceEpoch;
    await _store.saveRun(run);
    runs.insert(0, run);
    _applyStreakForToday();
    _refreshGoalProgress();
    celebration.value = 'finish';
  }

  Future<void> deleteRun(String id) async {
    await _store.deleteRun(id);
    runs.removeWhere((r) => r.id == id);
    runs.refresh();
  }

  double get runMetersThisWeek {
    final cutoff = DateTime.now()
        .subtract(const Duration(days: 7))
        .millisecondsSinceEpoch;
    return runs
        .where((r) => r.startedAtMs >= cutoff)
        .fold(0.0, (a, r) => a + r.distanceMeters);
  }

  /// Distance unit follows the weight-unit toggle (lbs → miles, kg → km).
  bool get useMiles => unit.value == 'lbs';

  // ---------------------------------------------------------- streak engine
  void _applyStreakForToday() {
    final st = streak.value;
    final today = _dayKey(DateTime.now());
    if (st.lastDayKey == today) {
      // already counted today — streak unchanged, just bump total
    } else {
      final yday = _dayKey(DateTime.now().subtract(const Duration(days: 1)));
      if (st.lastDayKey == yday) {
        st.current += 1;
      } else {
        st.current = 1; // streak broken or first ever
      }
      st.lastDayKey = today;
      if (st.current > st.longest) st.longest = st.current;
      // milestone celebration
      const milestones = [3, 7, 14, 30, 50, 100, 365];
      if (milestones.contains(st.current)) {
        milestoneValue.value = st.current;
        celebration.value = 'milestone';
      }
    }
    st.totalWorkouts += 1;
    streak.refresh();
    _store.setStreak(st);
  }

  /// Streak is "alive" if the last workout was today or yesterday.
  bool get streakAlive {
    final last = streak.value.lastDayKey;
    if (last == null) return false;
    final today = _dayKey(DateTime.now());
    final yday = _dayKey(DateTime.now().subtract(const Duration(days: 1)));
    return last == today || last == yday;
  }

  bool get trainedToday => streak.value.lastDayKey == _dayKey(DateTime.now());

  // --------------------------------------------------------- rest timer
  void startRest(int seconds) {
    _restTimer?.cancel();
    restTotal.value = seconds;
    restRemaining.value = seconds;
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (restRemaining.value <= 1) {
        t.cancel();
        restRemaining.value = 0;
        HapticFeedback.heavyImpact();
        _notifyRestOver();
      } else {
        restRemaining.value -= 1;
        if (restRemaining.value == 3) HapticFeedback.selectionClick();
      }
    });
  }

  void addRest(int seconds) {
    if (restRemaining.value <= 0) return;
    restRemaining.value += seconds;
    restTotal.value += seconds;
  }

  void skipRest() {
    _restTimer?.cancel();
    restRemaining.value = 0;
  }

  void stopRest() {
    _restTimer?.cancel();
    restRemaining.value = 0;
    restTotal.value = 0;
  }

  void _notifyRestOver() {
    try {
      NotificationService.instance
          .showPush(title: 'Rest over 💪', body: 'Time for your next set — let\'s go!');
    } catch (_) {}
  }

  // ---------------------------------------------------- previous / PR lookup
  /// Working sets from the most recent COMPLETED session that trained [exId].
  List<SetEntry> previousPerformance(String exId) {
    for (final s in history) {
      for (final el in s.exercises) {
        if (el.exerciseId == exId) {
          final work = el.sets.where((x) => x.type.countsAsWork && x.done).toList();
          if (work.isNotEmpty) return work;
        }
      }
    }
    return <SetEntry>[];
  }

  /// Best estimated 1RM ever recorded for an exercise (completed history only).
  double historicalBestE1rm(String exId) {
    double best = 0;
    for (final s in history) {
      for (final el in s.exercises) {
        if (el.exerciseId != exId) continue;
        for (final set in el.sets) {
          if (set.done && set.type.countsAsWork && set.e1rm > best) best = set.e1rm;
        }
      }
    }
    return best;
  }

  // ----------------------------------------------------------- analytics
  /// Total tonnage over the last [days] days.
  double volumeInLastDays(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    double v = 0;
    for (final s in history) {
      if (s.startedAtMs >= cutoff) v += s.totalVolume;
    }
    return v;
  }

  int get workoutsThisWeek {
    final cutoff = DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
    return history.where((s) => s.startedAtMs >= cutoff).length;
  }

  int get totalPrs => history.fold(0, (a, s) => a + s.prCount);

  /// Volume per muscle group over the last 7 days — powers the heatmap.
  Map<MuscleGroup, double> muscleVolumeThisWeek() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
    final map = <MuscleGroup, double>{};
    for (final s in history) {
      if (s.startedAtMs < cutoff) continue;
      for (final el in s.exercises) {
        map[el.muscle] = (map[el.muscle] ?? 0) + el.volume;
      }
    }
    return map;
  }

  /// (dateMs, e1rm) points for an exercise within a time window ('1W','1M','3M','1Y','ALL').
  List<MapEntry<int, double>> strengthSeries(String exId, String range) {
    int? cutoff;
    switch (range) {
      case '1W':
        cutoff = DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
        break;
      case '1M':
        cutoff = DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch;
        break;
      case '3M':
        cutoff = DateTime.now().subtract(const Duration(days: 90)).millisecondsSinceEpoch;
        break;
      case '1Y':
        cutoff = DateTime.now().subtract(const Duration(days: 365)).millisecondsSinceEpoch;
        break;
      default:
        cutoff = null;
    }
    final pts = <MapEntry<int, double>>[];
    for (final s in history) {
      if (cutoff != null && s.startedAtMs < cutoff) continue;
      double best = 0;
      for (final el in s.exercises) {
        if (el.exerciseId != exId) continue;
        final b = el.bestE1rm;
        if (b > best) best = b;
      }
      if (best > 0) pts.add(MapEntry(s.startedAtMs, best));
    }
    pts.sort((a, b) => a.key.compareTo(b.key));
    return pts;
  }

  // -------------------------------------------------------------- Goalshare
  Future<void> addGoal(WorkoutGoal g) async {
    goals.add(g);
    _refreshGoalProgress();
    await _store.setGoals(goals);
  }

  Future<void> updateGoal(WorkoutGoal g) async {
    final i = goals.indexWhere((x) => x.id == g.id);
    if (i >= 0) goals[i] = g;
    _refreshGoalProgress();
    await _store.setGoals(goals);
  }

  Future<void> deleteGoal(String id) async {
    goals.removeWhere((g) => g.id == id);
    await _store.setGoals(goals);
    goals.refresh();
  }

  /// Auto-drive streak / volume / 1RM goals from live data so a user's
  /// Goalshare card is always current without manual entry.
  void _refreshGoalProgress() {
    bool changed = false;
    for (final g in goals) {
      double next = g.current;
      switch (g.type) {
        case GoalType.streak:
          next = streak.value.current.toDouble();
          break;
        case GoalType.volume:
          next = volumeInLastDays(7);
          break;
        case GoalType.lift1rm:
          if (g.exerciseId != null) next = historicalBestE1rm(g.exerciseId!);
          break;
        default:
          next = g.current; // bodyweight / reps / custom = manual
      }
      if (next != g.current) {
        g.current = next;
        changed = true;
      }
      if (g.achieved && g.achievedAtMs == null) {
        g.achievedAtMs = DateTime.now().millisecondsSinceEpoch;
        changed = true;
      }
    }
    if (changed) {
      goals.refresh();
      _store.setGoals(goals);
    }
  }

  // ---------------------------------------------------------------- units
  Future<void> toggleUnit() async {
    unit.value = unit.value == 'lbs' ? 'kg' : 'lbs';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kUnitPref, unit.value);
    } catch (_) {}
  }

  void clearCelebration() => celebration.value = null;

  // ----------------------------------------------------------------- utils
  void _persistActive() {
    if (active.value != null) _store.setActive(active.value);
  }

  String _uid() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${_rng.nextInt(1 << 20).toRadixString(36)}';

  String _dayKey(DateTime d) {
    final only = DateTime(d.year, d.month, d.day);
    return '${only.year.toString().padLeft(4, '0')}-'
        '${only.month.toString().padLeft(2, '0')}-'
        '${only.day.toString().padLeft(2, '0')}';
  }

  @override
  void onClose() {
    _restTimer?.cancel();
    super.onClose();
  }
}
