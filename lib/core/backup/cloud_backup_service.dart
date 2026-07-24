import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import '../firebase/firebase_service.dart';

// Hive models + their hand-written adapters (no build_runner).
import '../../features/goals/data/goal.dart';
import '../../features/gratitude_journal/data/journal_entry.dart';
import '../../features/home/subflow/todo/data/daily_todos.dart';
import '../../features/home/subflow/todo/data/todo_item.dart';
import '../../features/nutrition/data/food_combo.dart';
import '../../features/nutrition/data/food_item.dart';
import '../../features/nutrition/data/logged_entry.dart';
import '../../features/nutrition/data/nutrition_goal.dart';
import '../../features/nutrition/data/streak_data.dart';
import '../../features/nutrition/data/weight_entry.dart';

/// Describes one Hive box we back up and restore.
///
/// A box is either:
///  - **typed** — it holds Hive model objects and needs its adapter(s)
///    registered before it can be opened. [open] opens it with the correct
///    generic type; [encode]/[decode] convert to/from JSON via the model's
///    toJson()/fromJson().
///  - **plain string** — it holds JSON strings or plain strings (no adapters).
///    [open] opens it as `Box<String>` and encode/decode pass strings through.
///
/// Every box uses stable string keys (put(key, value)), so restore preserves
/// keys via [Box.putAll].
class _BoxSpec {
  final String name;

  /// Registers any adapters this box needs (guarded by isAdapterRegistered),
  /// then opens (or returns the already-open) box, matching the EXACT generic
  /// type the owning controller uses so the open never conflicts.
  final Future<Box<dynamic>> Function() open;

  /// box contents -> Map<key, jsonable value>
  final Map<String, dynamic> Function(Box<dynamic> box) encode;

  /// decoded Map<key, jsonable value> -> Map<key, value to putAll>
  final Map<dynamic, dynamic> Function(Map<String, dynamic> data) decode;

  const _BoxSpec({
    required this.name,
    required this.open,
    required this.encode,
    required this.decode,
  });
}

/// Cloud backup + restore of ALL device-local user data (goals, nutrition,
/// todos, budget, journal, etc.) so deleting / reinstalling the app never wipes
/// the user's data.
///
/// Design:
///  - Uses the STABLE Railway backend user id (survives reinstall) as the
///    Firestore document owner.
///  - Backup: each box -> `user_backups/{userId}/boxes/{boxName}` as a single
///    JSON string, debounced on change.
///  - Restore: local ALWAYS wins. A box is only restored from cloud when it is
///    still empty locally. No merge, no overwrite.
///  - Never throws to callers: all failures are logged and swallowed so login
///    and startup never break.
class CloudBackupService {
  CloudBackupService._();
  static final CloudBackupService instance = CloudBackupService._();

  /// Firestore 1 MB doc limit — skip a box whose JSON exceeds this safety cap.
  static const int _maxDocBytes = 900000;

  /// Debounce window for auto-backup after a box changes.
  static const Duration _debounce = Duration(seconds: 5);

  /// Hard cap on the whole restore pass so login/startup never hangs.
  static const Duration _restoreTimeout = Duration(seconds: 15);

  bool _started = false;
  final List<StreamSubscription<dynamic>> _subs = [];
  final Map<String, Timer> _debounceTimers = {};

  FirebaseFirestore get _db => FirebaseService.instance.db;

  // ── Box registry ────────────────────────────────────────────────────────────

  List<_BoxSpec> get _specs => [
        // ── Typed boxes (Hive models) ──────────────────────────────────────
        _BoxSpec(
          name: 'goals_box',
          open: () async {
            if (!Hive.isAdapterRegistered(20)) {
              Hive.registerAdapter(GoalAdapter());
            }
            return Hive.isBoxOpen('goals_box')
                ? Hive.box<Goal>('goals_box')
                : await Hive.openBox<Goal>('goals_box');
          },
          encode: (box) => _encodeTyped<Goal>(box, (g) => g.toJson()),
          decode: (data) =>
              _decodeTyped(data, (m) => Goal.fromJson(m)),
        ),
        _BoxSpec(
          name: 'daily_todos',
          open: () async {
            if (!Hive.isAdapterRegistered(11)) {
              Hive.registerAdapter(TodoItemAdapter());
            }
            if (!Hive.isAdapterRegistered(12)) {
              Hive.registerAdapter(DailyTodosAdapter());
            }
            return Hive.isBoxOpen('daily_todos')
                ? Hive.box<DailyTodos>('daily_todos')
                : await Hive.openBox<DailyTodos>('daily_todos');
          },
          encode: (box) => _encodeTyped<DailyTodos>(box, (d) => d.toJson()),
          decode: (data) =>
              _decodeTyped(data, (m) => DailyTodos.fromJson(m)),
        ),
        _BoxSpec(
          name: 'journal_entries',
          open: () async {
            if (!Hive.isAdapterRegistered(13)) {
              Hive.registerAdapter(JournalEntryAdapter());
            }
            return Hive.isBoxOpen('journal_entries')
                ? Hive.box<JournalEntry>('journal_entries')
                : await Hive.openBox<JournalEntry>('journal_entries');
          },
          encode: (box) => _encodeTyped<JournalEntry>(box, (e) => e.toJson()),
          decode: (data) =>
              _decodeTyped(data, (m) => JournalEntry.fromJson(m)),
        ),
        _BoxSpec(
          name: 'nutritionEntriesBox',
          open: () async {
            _registerNutritionAdapters();
            return Hive.isBoxOpen('nutritionEntriesBox')
                ? Hive.box<LoggedEntry>('nutritionEntriesBox')
                : await Hive.openBox<LoggedEntry>('nutritionEntriesBox');
          },
          encode: (box) => _encodeTyped<LoggedEntry>(box, (e) => e.toJson()),
          decode: (data) =>
              _decodeTyped(data, (m) => LoggedEntry.fromJson(m)),
        ),
        _BoxSpec(
          name: 'nutritionGoalsBox',
          open: () async {
            _registerNutritionAdapters();
            return Hive.isBoxOpen('nutritionGoalsBox')
                ? Hive.box<NutritionGoal>('nutritionGoalsBox')
                : await Hive.openBox<NutritionGoal>('nutritionGoalsBox');
          },
          encode: (box) =>
              _encodeTyped<NutritionGoal>(box, (g) => g.toJson()),
          decode: (data) =>
              _decodeTyped(data, (m) => NutritionGoal.fromJson(m)),
        ),
        _BoxSpec(
          name: 'foodCombosBox',
          open: () async {
            _registerNutritionAdapters();
            return Hive.isBoxOpen('foodCombosBox')
                ? Hive.box<FoodCombo>('foodCombosBox')
                : await Hive.openBox<FoodCombo>('foodCombosBox');
          },
          encode: (box) => _encodeTyped<FoodCombo>(box, (c) => c.toJson()),
          decode: (data) =>
              _decodeTyped(data, (m) => FoodCombo.fromJson(m)),
        ),
        _BoxSpec(
          name: 'weightEntriesBox',
          open: () async {
            _registerNutritionAdapters();
            return Hive.isBoxOpen('weightEntriesBox')
                ? Hive.box<WeightEntry>('weightEntriesBox')
                : await Hive.openBox<WeightEntry>('weightEntriesBox');
          },
          encode: (box) => _encodeTyped<WeightEntry>(box, (w) => w.toJson()),
          decode: (data) =>
              _decodeTyped(data, (m) => WeightEntry.fromJson(m)),
        ),
        _BoxSpec(
          name: 'streakDataBox',
          open: () async {
            _registerNutritionAdapters();
            return Hive.isBoxOpen('streakDataBox')
                ? Hive.box<StreakData>('streakDataBox')
                : await Hive.openBox<StreakData>('streakDataBox');
          },
          encode: (box) => _encodeTyped<StreakData>(box, (s) => s.toJson()),
          decode: (data) =>
              _decodeTyped(data, (m) => StreakData.fromJson(m)),
        ),

        // ── Plain-string boxes (JSON strings / plain strings) ──────────────
        _plainStringSpec('budget_v1'),
        _plainStringSpec('leads_v1'),
        _plainStringSpec('priming_streak'),
        _plainStringSpec('daily_feature_checks_v1'),
        _plainStringSpec('bible_marks'),
        _plainStringSpec('quick_access_v1'),
        _plainStringSpec('daily_todos_won_day_v1'),
      ];

  void _registerNutritionAdapters() {
    if (!Hive.isAdapterRegistered(14)) Hive.registerAdapter(FoodItemAdapter());
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(LoggedEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(16)) {
      Hive.registerAdapter(NutritionGoalAdapter());
    }
    if (!Hive.isAdapterRegistered(17)) {
      Hive.registerAdapter(WeightEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(18)) {
      Hive.registerAdapter(FoodComboAdapter());
    }
    if (!Hive.isAdapterRegistered(19)) {
      Hive.registerAdapter(StreakDataAdapter());
    }
  }

  _BoxSpec _plainStringSpec(String name) => _BoxSpec(
        name: name,
        open: () async => Hive.isBoxOpen(name)
            ? Hive.box<String>(name)
            : await Hive.openBox<String>(name),
        encode: (box) {
          final out = <String, dynamic>{};
          for (final k in box.keys) {
            final v = box.get(k);
            out[k.toString()] = v?.toString();
          }
          return out;
        },
        decode: (data) {
          final out = <dynamic, dynamic>{};
          data.forEach((k, v) {
            if (v == null) return;
            out[k] = v.toString();
          });
          return out;
        },
      );

  static Map<String, dynamic> _encodeTyped<T>(
    Box<dynamic> box,
    Map<String, dynamic> Function(T value) toJson,
  ) {
    final out = <String, dynamic>{};
    for (final k in box.keys) {
      final v = box.get(k);
      if (v is T) out[k.toString()] = toJson(v);
    }
    return out;
  }

  static Map<dynamic, dynamic> _decodeTyped(
    Map<String, dynamic> data,
    dynamic Function(Map<String, dynamic> m) fromJson,
  ) {
    final out = <dynamic, dynamic>{};
    data.forEach((k, v) {
      if (v is! Map) return;
      try {
        out[k] = fromJson(Map<String, dynamic>.from(v));
      } catch (e) {
        log('CloudBackup: skip bad entry "$k" — $e');
      }
    });
    return out;
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Restore any box that is still empty locally from its cloud backup.
  /// Local non-empty ALWAYS wins (no merge, no overwrite). Time-boxed so
  /// login/startup never hangs. No-ops when Firebase isn't ready / no userId.
  Future<void> restoreIfNeeded() async {
    if (!FirebaseService.instance.isReady) return;
    final userId = await FirebaseService.instance.currentUserId();
    if (userId == null || userId.isEmpty) return;

    try {
      var completed = false;
      final restore = _restoreAll(userId).then((_) => completed = true);
      await Future.any([
        restore,
        Future<void>.delayed(_restoreTimeout),
      ]);
      if (!completed) {
        // The timeout won. Abandon the still-running pass so it can never
        // write stale cloud data into boxes the user has started using.
        _restoreAbandoned = true;
        log('CloudBackup: restore timed out — remaining boxes abandoned');
      }
    } catch (e) {
      log('CloudBackup: restore pass failed — $e');
    }
  }

  /// Set when a time-boxed restore pass is abandoned; blocks any late writes.
  bool _restoreAbandoned = false;

  Future<void> _restoreAll(String userId) async {
    for (final spec in _specs) {
      try {
        await _restoreBox(userId, spec);
      } catch (e) {
        // A single bad box must never block the rest.
        log('CloudBackup: restore "${spec.name}" failed — $e');
      }
    }
  }

  Future<void> _restoreBox(String userId, _BoxSpec spec) async {
    if (_restoreAbandoned) return;
    final box = await spec.open();

    // Local data wins — only ever restore into an empty box.
    if (box.isNotEmpty) return;

    final doc = await _boxDoc(userId, spec.name).get();
    if (!doc.exists) return;
    final raw = doc.data()?['data'];
    if (raw is! String || raw.isEmpty) return;

    final decoded = jsonDecode(raw);
    if (decoded is! Map) return;
    final data = Map<String, dynamic>.from(decoded);

    final entries = spec.decode(data);
    if (entries.isEmpty) return;

    // Re-check right before writing: the pass may have been abandoned (timeout)
    // or the user may have started writing to this box while we fetched.
    if (_restoreAbandoned || box.isNotEmpty) return;

    await box.putAll(entries);
    log('CloudBackup: restored ${entries.length} entries into "${spec.name}"');
  }

  /// Begins auto-backup: uploads a first snapshot then watches every box and
  /// uploads (debounced) whenever it changes. Idempotent — safe to call twice.
  Future<void> start() async {
    if (_started) return;
    if (!FirebaseService.instance.isReady) return;
    final userId = await FirebaseService.instance.currentUserId();
    if (userId == null || userId.isEmpty) return;

    _started = true;

    for (final spec in _specs) {
      try {
        final box = await spec.open();
        // Initial upload so a box that already has local data (and no cloud
        // copy yet) gets backed up on first run.
        unawaited(backupBox(spec.name));
        final sub = box.watch().listen((_) {
          _debounceTimers[spec.name]?.cancel();
          _debounceTimers[spec.name] = Timer(_debounce, () {
            unawaited(backupBox(spec.name));
          });
        });
        _subs.add(sub);
      } catch (e) {
        log('CloudBackup: watch "${spec.name}" failed — $e');
      }
    }
  }

  /// Serialize one box and upload it to Firestore. Never throws.
  Future<void> backupBox(String name) async {
    try {
      if (!FirebaseService.instance.isReady) return;
      final userId = await FirebaseService.instance.currentUserId();
      if (userId == null || userId.isEmpty) return;

      _BoxSpec? spec;
      for (final s in _specs) {
        if (s.name == name) {
          spec = s;
          break;
        }
      }
      if (spec == null) return;

      final box = await spec.open();
      final map = spec.encode(box);
      final jsonStr = jsonEncode(map);

      final bytes = utf8.encode(jsonStr).length;
      if (bytes > _maxDocBytes) {
        log('CloudBackup: skip "$name" — $bytes bytes exceeds doc limit.');
        return;
      }

      await _boxDoc(userId, name).set({
        'data': jsonStr,
        'count': map.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      log('CloudBackup: backup "$name" failed — $e');
    }
  }

  DocumentReference<Map<String, dynamic>> _boxDoc(
    String userId,
    String boxName,
  ) =>
      _db
          .collection('user_backups')
          .doc(userId)
          .collection('boxes')
          .doc(boxName);
}
