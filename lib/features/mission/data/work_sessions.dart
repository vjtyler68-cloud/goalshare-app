import 'dart:convert';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One completed "Start Day → End Day" work session.
class WorkSession {
  final String date; // yyyy-MM-dd of the day the session started
  final DateTime start;
  final DateTime end;

  const WorkSession({
    required this.date,
    required this.start,
    required this.end,
  });

  Duration get duration {
    final d = end.difference(start);
    return d.isNegative ? Duration.zero : d;
  }

  Map<String, dynamic> toMap() => {
        'date': date,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      };

  static WorkSession? fromMap(Map<String, dynamic> m) {
    final start = DateTime.tryParse((m['start'] ?? '').toString());
    final end = DateTime.tryParse((m['end'] ?? '').toString());
    if (start == null || end == null) return null;
    final date = (m['date'] ?? '').toString();
    return WorkSession(
      date: date.isEmpty ? DateFormat('yyyy-MM-dd').format(start) : date,
      start: start,
      end: end,
    );
  }
}

/// Local store behind the Mission header's Start Day / End Day pill.
///
/// The *only* source of truth for "am I on the clock" is the persisted start
/// timestamp — elapsed time is always computed as `now - storedStart`, never
/// from an in-memory stopwatch, so closing and reopening the app resumes the
/// running day correctly. SharedPreferences JSON (no codegen), capped at ~400
/// sessions, mirroring [StatsHistoryService].
class WorkSessionsService extends GetxService {
  static WorkSessionsService get to => Get.isRegistered<WorkSessionsService>()
      ? Get.find<WorkSessionsService>()
      : Get.put(WorkSessionsService(), permanent: true);

  static const String _kSessions = 'work_sessions_v1';
  static const String _kActiveStart = 'work_day_start_v1';
  static const int _maxSessions = 400;

  final RxList<WorkSession> sessions = <WorkSession>[].obs;

  /// Start time of the day currently in progress, or null when off the clock.
  final Rxn<DateTime> activeStart = Rxn<DateTime>();

  bool get isRunning => activeStart.value != null;

  static String dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  void onInit() {
    super.onInit();
    ensureLoaded();
  }

  Future<void>? _loading;

  /// Disk load, memoized. [onInit] and [MissionController.syncDay] both reach
  /// for it (and syncDay runs again on every resume), so a raw re-read would
  /// let two passes append the same stale session twice. Mirrors
  /// [StatsHistoryService.ensureLoaded].
  Future<void> ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kSessions);
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List)
            .whereType<Map>()
            .map((m) => WorkSession.fromMap(m.cast<String, dynamic>()))
            .whereType<WorkSession>()
            .toList();
        list.sort((a, b) => a.start.compareTo(b.start));
        sessions.assignAll(list);
      }
      final startRaw = prefs.getString(_kActiveStart);
      activeStart.value =
          startRaw == null || startRaw.isEmpty ? null : DateTime.tryParse(startRaw);
      await closeStaleSession();
    } catch (_) {
      // The timer is additive — never break the mission screen over it.
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _kSessions, jsonEncode(sessions.map((s) => s.toMap()).toList()));
    } catch (_) {}
  }

  Future<void> _setActiveStart(DateTime? value) async {
    activeStart.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value == null) {
        await prefs.remove(_kActiveStart);
      } else {
        await prefs.setString(_kActiveStart, value.toIso8601String());
      }
    } catch (_) {}
  }

  /// Begin today's work session. No-op if one is already running.
  Future<void> startDay() async {
    if (isRunning) return;
    await _setActiveStart(DateTime.now());
  }

  /// Close the running session and file it under the day it started.
  Future<void> endDay() async {
    final start = activeStart.value;
    if (start == null) return;
    await _closeSession(start, DateTime.now());
  }

  /// A session left running overnight (the user forgot to tap End Day) is
  /// closed out at the end of the day it started, so the pill never shows a
  /// runaway multi-day counter.
  Future<void> closeStaleSession() async {
    final start = activeStart.value;
    if (start == null) return;
    final now = DateTime.now();
    if (dateKey(start) == dateKey(now)) return;
    await _closeSession(
        start, DateTime(start.year, start.month, start.day, 23, 59, 59));
  }

  /// Bank a finished session and go off the clock. Both in-memory changes land
  /// synchronously and in one go — persistence is awaited afterwards — so a
  /// concurrent caller can never observe the same active start twice and file
  /// a duplicate session, and the pill never flickers mid-close.
  Future<void> _closeSession(DateTime start, DateTime end) async {
    if (activeStart.value != start) return; // someone else already closed it
    activeStart.value = null;
    final appended = _addSession(start, end);
    await _clearActiveStartOnDisk();
    if (appended) await _persist();
  }

  /// In-memory append. Returns false when the session is a no-op or already
  /// banked (belt-and-braces against a double-bank of the same start).
  bool _addSession(DateTime start, DateTime end) {
    if (!end.isAfter(start)) return false; // ignore zero/negative sessions
    if (sessions.any((s) => s.start == start)) return false;
    sessions.add(WorkSession(date: dateKey(start), start: start, end: end));
    sessions.sort((a, b) => a.start.compareTo(b.start));
    if (sessions.length > _maxSessions) {
      sessions.removeRange(0, sessions.length - _maxSessions);
    }
    return true;
  }

  Future<void> _clearActiveStartOnDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kActiveStart);
    } catch (_) {}
  }

  Duration _completedBetween(DateTime from, DateTime to) {
    var total = Duration.zero;
    for (final s in sessions) {
      if (!s.start.isBefore(from) && s.start.isBefore(to)) {
        total += s.duration;
      }
    }
    return total;
  }

  /// Live elapsed time of the running session, computed from the stored start.
  Duration get _activeElapsed {
    final start = activeStart.value;
    if (start == null) return Duration.zero;
    final d = DateTime.now().difference(start);
    return d.isNegative ? Duration.zero : d;
  }

  /// Everything logged today, including the session still in progress.
  Duration getTodaysWorkDuration() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    return _completedBetween(startOfDay, startOfDay.add(const Duration(days: 1))) +
        _activeElapsed;
  }

  /// Monday-to-now total, including the session still in progress.
  Duration getWeeklyWorkDuration() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return _completedBetween(monday, monday.add(const Duration(days: 7))) +
        _activeElapsed;
  }

  /// "Xh Ym" (or "Xm" under an hour) for the pill and future weekly recap.
  static String formatHm(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }
}
