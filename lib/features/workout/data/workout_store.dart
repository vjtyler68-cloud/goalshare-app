import 'dart:convert';
import 'dart:developer';

import 'package:hive_flutter/hive_flutter.dart';

import 'cardio_run.dart';
import 'workout_models.dart';

/// On-device persistence for MY WORKOUT.
///
/// Two `Box<String>` boxes (same graceful-degrade pattern as [BudgetStore]):
///  • `workout_sessions_v1` — completed sessions, keyed by session id.
///  • `workout_meta_v1`     — singletons: the ACTIVE session (crash recovery),
///    streak state, Goalshare goals, and user-created exercises.
///
/// Everything is JSON — no Hive adapters — so a storage hiccup degrades to an
/// in-memory no-op instead of throwing, and the whole thing is trivially
/// cloud-backup-able later.
class WorkoutStore {
  static const String _sessionsBox = 'workout_sessions_v1';
  static const String _metaBox = 'workout_meta_v1';
  static const String _cardioBox = 'workout_cardio_v1';

  // meta keys
  static const String _kActive = 'active_session';
  static const String _kStreak = 'streak';
  static const String _kGoals = 'goals';
  static const String _kCustomExercises = 'custom_exercises';

  Box<String>? _sessions;
  Box<String>? _meta;
  Box<String>? _cardio;
  bool _ready = false;
  bool get isReady => _ready;

  Future<void> open() async {
    try {
      await Hive.initFlutter(); // safe no-op if main() already did it
      _sessions = Hive.isBoxOpen(_sessionsBox)
          ? Hive.box<String>(_sessionsBox)
          : await Hive.openBox<String>(_sessionsBox);
      _meta = Hive.isBoxOpen(_metaBox)
          ? Hive.box<String>(_metaBox)
          : await Hive.openBox<String>(_metaBox);
      _cardio = Hive.isBoxOpen(_cardioBox)
          ? Hive.box<String>(_cardioBox)
          : await Hive.openBox<String>(_cardioBox);
      _ready = true;
    } catch (e) {
      log('WorkoutStore: failed to open boxes — $e');
      _ready = false;
    }
  }

  // ------------------------------------------------------------- cardio runs
  /// All GPS runs/walks, newest-first.
  List<CardioRun> allRuns() {
    if (!_ready || _cardio == null) return <CardioRun>[];
    final out = <CardioRun>[];
    for (final raw in _cardio!.values) {
      try {
        out.add(CardioRun.fromJsonString(raw));
      } catch (e) {
        log('WorkoutStore: unreadable run — $e');
      }
    }
    out.sort((a, b) => b.startedAtMs.compareTo(a.startedAtMs));
    return out;
  }

  Future<void> saveRun(CardioRun r) async {
    if (!_ready || _cardio == null) return;
    try {
      await _cardio!.put(r.id, r.toJsonString());
    } catch (e) {
      log('WorkoutStore: saveRun failed — $e');
    }
  }

  Future<void> deleteRun(String id) async {
    if (!_ready || _cardio == null) return;
    try {
      await _cardio!.delete(id);
    } catch (_) {}
  }

  // ---------------------------------------------------------------- sessions
  /// All completed sessions, newest-first.
  List<WorkoutSession> allSessions() {
    if (!_ready || _sessions == null) return <WorkoutSession>[];
    final out = <WorkoutSession>[];
    for (final raw in _sessions!.values) {
      try {
        out.add(WorkoutSession.fromJsonString(raw));
      } catch (e) {
        log('WorkoutStore: unreadable session — $e');
      }
    }
    out.sort((a, b) => b.startedAtMs.compareTo(a.startedAtMs));
    return out;
  }

  Future<void> saveSession(WorkoutSession s) async {
    if (!_ready || _sessions == null) return;
    try {
      await _sessions!.put(s.id, s.toJsonString());
    } catch (e) {
      log('WorkoutStore: saveSession failed — $e');
    }
  }

  Future<void> deleteSession(String id) async {
    if (!_ready || _sessions == null) return;
    try {
      await _sessions!.delete(id);
    } catch (_) {}
  }

  // ------------------------------------------------------- active (recovery)
  /// The in-progress session, re-serialised after every set for crash recovery.
  WorkoutSession? getActive() {
    final raw = _meta?.get(_kActive);
    if (raw == null || raw.isEmpty) return null;
    try {
      return WorkoutSession.fromJsonString(raw);
    } catch (e) {
      log('WorkoutStore: active session corrupt — $e');
      return null;
    }
  }

  Future<void> setActive(WorkoutSession? s) async {
    if (!_ready || _meta == null) return;
    try {
      if (s == null) {
        await _meta!.delete(_kActive);
      } else {
        await _meta!.put(_kActive, s.toJsonString());
      }
    } catch (e) {
      log('WorkoutStore: setActive failed — $e');
    }
  }

  // ------------------------------------------------------------------ streak
  StreakState getStreak() {
    final raw = _meta?.get(_kStreak);
    if (raw == null) return StreakState();
    try {
      return StreakState.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      return StreakState();
    }
  }

  Future<void> setStreak(StreakState s) async {
    if (!_ready || _meta == null) return;
    try {
      await _meta!.put(_kStreak, jsonEncode(s.toJson()));
    } catch (_) {}
  }

  // ------------------------------------------------------------------- goals
  List<WorkoutGoal> getGoals() {
    final raw = _meta?.get(_kGoals);
    if (raw == null) return <WorkoutGoal>[];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((e) => WorkoutGoal.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return <WorkoutGoal>[];
    }
  }

  Future<void> setGoals(List<WorkoutGoal> goals) async {
    if (!_ready || _meta == null) return;
    try {
      await _meta!.put(_kGoals, jsonEncode(goals.map((g) => g.toJson()).toList()));
    } catch (_) {}
  }

  // -------------------------------------------------------- custom exercises
  List<Exercise> getCustomExercises() {
    final raw = _meta?.get(_kCustomExercises);
    if (raw == null) return <Exercise>[];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((e) => Exercise.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return <Exercise>[];
    }
  }

  Future<void> setCustomExercises(List<Exercise> ex) async {
    if (!_ready || _meta == null) return;
    try {
      await _meta!
          .put(_kCustomExercises, jsonEncode(ex.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }
}
