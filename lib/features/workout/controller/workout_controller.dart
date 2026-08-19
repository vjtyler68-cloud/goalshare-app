import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/daily_checks/daily_check_service.dart';
import '../../../core/health/health_service.dart';
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

  // MUST be reactive (RxBool): the dashboard's Obx shows a loader while this is
  // false, and if that builder reads no Rx at all, GetX throws "improper use of
  // GetX" — which renders as a blank GRAY screen in release builds on the very
  // first open. An RxBool both prevents that crash and auto-swaps the loader
  // for the dashboard the moment loading finishes.
  final RxBool _ready = false.obs;
  bool get isReady => _ready.value;

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
    active.value = _store.getActive(); // crash recovery (same-day resume)
    // Daily reset: a workout left in progress from a PREVIOUS day is cleared so
    // every day starts on a clean, blank slate (you can always start fresh).
    final leftover = active.value;
    if (leftover != null &&
        _dayKey(leftover.startedAt) != _dayKey(DateTime.now())) {
      active.value = null;
      _store.setActive(null);
    }
    _refreshGoalProgress();
    _ready.value = true;
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

  /// Log a workout that already happened on a PAST day — for when the user
  /// trained but couldn't record it live (phone dead / left at home). Opens a
  /// fresh, empty session stamped to the chosen date; finishing it files the
  /// workout on that day and recomputes the streak so the history stays honest.
  void startPastWorkout(DateTime date) {
    // Anchor at local noon of the chosen day so day-key math is unambiguous.
    final at = DateTime(date.year, date.month, date.day, 12);
    active.value = WorkoutSession(
      id: _uid(),
      name: 'Workout · ${_shortDate(at)}',
      emoji: '🗓️',
      startedAtMs: at.millisecondsSinceEpoch,
    );
    _persistActive();
  }

  /// True while the in-progress session is stamped to a day other than today
  /// (i.e. a back-dated "log a past workout" session). Screens show a date
  /// banner for it.
  bool get isBackdatedActive {
    final s = active.value;
    return s != null && _dayKey(s.startedAt) != _dayKey(DateTime.now());
  }

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  String _shortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';

  // ---------------------------------------------- rotating day routines
  /// The variant index that will be used NEXT time this day is started —
  /// alternates from whatever was done last (A ⇄ B).
  int nextVariantIndex(WorkoutDayRoutine day) {
    final last = _store.getDayVariants()[day.id] ?? -1;
    return (last + 1) % day.variantCount;
  }

  /// 'A' / 'B' label for the variant coming up next — shown on the day card.
  String nextVariantLabel(WorkoutDayRoutine day) =>
      day.variantLabel(nextVariantIndex(day));

  /// The most recent COMPLETED session for a day (by its name, e.g. "Push
  /// Day · A") — powers the "last time" reference on the picker.
  WorkoutSession? lastSessionForDay(WorkoutDayRoutine day) {
    for (final s in history) {
      if (s.name == day.name || s.name.startsWith('${day.name} ·')) return s;
    }
    return null;
  }

  /// Start a rotating day: auto-picks the variant you did NOT do last time and
  /// begins it as a FRESH slate (empty inputs; last time shows as the target).
  void startDay(WorkoutDayRoutine day) {
    final idx = nextVariantIndex(day);
    final tpl = day.variants[idx];
    final logs = <ExerciseLog>[];
    for (final te in tpl.exercises) {
      final ex = exerciseById(te.exerciseId);
      if (ex == null) continue;
      logs.add(_buildLog(ex, targetSets: te.sets, prefill: false));
    }
    active.value = WorkoutSession(
      id: _uid(),
      name: '${day.name} · ${day.variantLabel(idx)}',
      emoji: day.emoji,
      startedAtMs: DateTime.now().millisecondsSinceEpoch,
      exercises: logs,
    );
    _persistActive();
    _store.setDayVariant(day.id, idx);
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

  /// Build an ExerciseLog with N sets. When [prefill] is true the inputs are
  /// pre-loaded from last time (used by "repeat last"); when false the slate is
  /// FRESH (empty inputs) — the row still shows last time in the "prev" column
  /// as the number to beat.
  ExerciseLog _buildLog(Exercise ex,
      {required int targetSets, bool prefill = true}) {
    final prev = prefill ? previousPerformance(ex.id) : const <SetEntry>[];
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

  /// PR check with no haptics / celebration — used when auto-completing entered
  /// sets at finish (we don't want a burst of buzzes and 'pr' popups then).
  void _flagPrSilent(ExerciseLog log, SetEntry set) {
    if (!set.type.countsAsWork) return;
    if (set.weight == null || set.reps == null || set.reps! <= 0) return;
    final best = historicalBestE1rm(log.exerciseId);
    if (set.e1rm > best && set.e1rm > 0) set.isPr = true;
  }

  // --------------------------------------------------------------- finishing
  void finishWorkout() {
    final s = active.value;
    if (s == null) return;
    for (final el in s.exercises) {
      // Auto-complete any set the user filled in but didn't tap the checkmark
      // on — an entered weight/reps (or a timed set) means the work was done, so
      // it should count toward sets / volume / PRs instead of silently reading 0.
      for (final set in el.sets) {
        final hasData =
            set.weight != null || set.reps != null || set.durationSec != null;
        if (!set.done && hasData) {
          set.done = true;
          _flagPrSilent(el, set);
        }
      }
      // Trim only truly empty rows (no data at all) so they don't pollute stats.
      el.sets.removeWhere((set) =>
          !set.done &&
          set.weight == null &&
          set.reps == null &&
          set.durationSec == null);
    }
    s.exercises.removeWhere((el) => el.sets.isEmpty);

    // A back-dated "log a past workout" session is filed on its own day; a live
    // one ends now.
    final isPast = _dayKey(s.startedAt) != _dayKey(DateTime.now());
    s.endedAtMs = isPast
        ? s.startedAtMs + 45 * 60 * 1000 // nominal 45-min past session
        : DateTime.now().millisecondsSinceEpoch;

    _store.saveSession(s);
    history.insert(0, s);
    // Keep history newest-first even when this one lands back in the past.
    if (isPast) history.sort((a, b) => b.startedAtMs.compareTo(a.startedAtMs));
    // Mirror into Apple Health as a strength workout (dormant until HealthKit is
    // enabled — safe no-op otherwise). Fire-and-forget so the UI never waits.
    HealthService.instance.saveStrengthSession(
      start: DateTime.fromMillisecondsSinceEpoch(s.startedAtMs),
      end: DateTime.fromMillisecondsSinceEpoch(
          s.endedAtMs ?? DateTime.now().millisecondsSinceEpoch),
    );
    // A back-dated entry can't use the forward-only "today" engine — rebuild
    // the streak from the full history so the inserted day counts correctly.
    if (isPast) {
      _recomputeStreak();
    } else {
      _applyStreakForToday();
    }
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
    // Mirror into Apple Health as a run/walk Workout so it shows in Health and
    // counts toward the Apple Watch rings (dormant until HealthKit is enabled).
    HealthService.instance.saveRun(
      kind: run.kind,
      start: DateTime.fromMillisecondsSinceEpoch(run.startedAtMs),
      end: DateTime.fromMillisecondsSinceEpoch(
          run.endedAtMs ?? DateTime.now().millisecondsSinceEpoch),
      distanceMeters: run.distanceMeters,
    );
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
    // A finished workout — strength OR run/walk — earns the green "done today"
    // check on the Home grid, exactly like Bible, Gratitude, Nutrition, etc.
    DailyCheckService.to.markDoneToday(DailyCheckFeature.workout);
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

  /// Rebuild the streak from the FULL history of workouts + runs. The normal
  /// engine only ever moves forward from "today", so a back-dated workout needs
  /// a full recompute to slot into the right place. Day math runs on UTC
  /// ordinals so it stays correct across daylight-saving shifts.
  void _recomputeStreak() {
    final days = <String>{};
    for (final w in history) {
      days.add(_dayKey(w.startedAt));
    }
    for (final r in runs) {
      days.add(_dayKey(DateTime.fromMillisecondsSinceEpoch(r.startedAtMs)));
    }

    final st = streak.value;
    st.totalWorkouts = history.length + runs.length;

    if (days.isEmpty) {
      st.current = 0;
      st.lastDayKey = null;
      streak.refresh();
      _store.setStreak(st);
      return;
    }

    String keyOf(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    DateTime u(String k) {
      final p = k.split('-');
      return DateTime.utc(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
    }

    final sorted = days.toList()..sort();

    // Longest consecutive-day run across all recorded days.
    int longest = 1, run = 1;
    for (var i = 1; i < sorted.length; i++) {
      run = u(sorted[i]).difference(u(sorted[i - 1])).inDays == 1 ? run + 1 : 1;
      if (run > longest) longest = run;
    }
    if (longest > st.longest) st.longest = longest;

    // Current streak: count back from today (or yesterday if not trained today).
    final todayKey = _dayKey(DateTime.now());
    final ydayKey = _dayKey(DateTime.now().subtract(const Duration(days: 1)));
    DateTime? cursor = days.contains(todayKey)
        ? u(todayKey)
        : (days.contains(ydayKey) ? u(ydayKey) : null);
    int current = 0;
    while (cursor != null && days.contains(keyOf(cursor))) {
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    st.current = current;
    st.lastDayKey = sorted.last;

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

  /// Per-session bests for [exId] over time (oldest → newest) — powers the
  /// strength-progress chart. Each point = that session's heaviest working set,
  /// best estimated 1RM, and top reps.
  List<({DateTime date, double topWeight, double bestE1rm, int topReps})>
      exerciseProgress(String exId) {
    final out =
        <({DateTime date, double topWeight, double bestE1rm, int topReps})>[];
    for (final s in history) {
      double topW = 0, bestE = 0;
      int topR = 0;
      for (final el in s.exercises) {
        if (el.exerciseId != exId) continue;
        for (final set in el.sets) {
          if (!set.done || !set.type.countsAsWork) continue;
          if ((set.weight ?? 0) > topW) topW = set.weight ?? 0;
          if (set.e1rm > bestE) bestE = set.e1rm;
          if ((set.reps ?? 0) > topR) topR = set.reps ?? 0;
        }
      }
      if (topW > 0 || bestE > 0) {
        out.add((
          date: s.startedAt,
          topWeight: topW,
          bestE1rm: bestE,
          topReps: topR
        ));
      }
    }
    out.sort((a, b) => a.date.compareTo(b.date));
    return out;
  }

  /// Distinct exercises ever trained (id + name), alphabetical — for the
  /// progress picker.
  List<({String id, String name})> get trainedExercises {
    final map = <String, String>{};
    for (final s in history) {
      for (final el in s.exercises) {
        if (el.sets.any((x) => x.done)) map[el.exerciseId] = el.name;
      }
    }
    final list = [for (final e in map.entries) (id: e.key, name: e.value)];
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
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
