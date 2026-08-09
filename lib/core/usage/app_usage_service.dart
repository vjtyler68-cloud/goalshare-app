import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One foreground session in the app (opened → backgrounded).
class AppSession {
  final DateTime start;
  final DateTime end;
  const AppSession({required this.start, required this.end});

  Duration get duration {
    final d = end.difference(start);
    return d.isNegative ? Duration.zero : d;
  }

  Map<String, dynamic> toMap() =>
      {'start': start.toIso8601String(), 'end': end.toIso8601String()};

  static AppSession? fromMap(Map<String, dynamic> m) {
    final s = DateTime.tryParse((m['start'] ?? '').toString());
    final e = DateTime.tryParse((m['end'] ?? '').toString());
    if (s == null || e == null) return null;
    return AppSession(start: s, end: e);
  }
}

/// Automatically logs how long the app is used: it timestamps every foreground
/// session (open → background) and totals time-in-app per day. Distinct from the
/// manual Start Day / End Day work clock — this one needs no user action.
///
/// Local only (SharedPreferences JSON, capped), and the running session's start
/// is persisted so a force-quit still banks the session on next launch.
class AppUsageService extends GetxService with WidgetsBindingObserver {
  static AppUsageService get to => Get.isRegistered<AppUsageService>()
      ? Get.find<AppUsageService>()
      : Get.put(AppUsageService(), permanent: true);

  static const String _kSessions = 'app_usage_sessions_v1';
  static const String _kActiveStart = 'app_usage_active_start_v1';
  static const int _maxSessions = 600;

  final RxList<AppSession> sessions = <AppSession>[].obs;

  /// Start of the session currently in progress (null only briefly during a
  /// close). Persisted so an unexpected termination still banks the session.
  final Rxn<DateTime> activeStart = Rxn<DateTime>();

  static String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kSessions);
      if (raw != null && raw.isNotEmpty) {
        final list = (jsonDecode(raw) as List)
            .whereType<Map>()
            .map((m) => AppSession.fromMap(m.cast<String, dynamic>()))
            .whereType<AppSession>()
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));
        sessions.assignAll(list);
      }
      // Bank any session left open by a previous run before starting a new one.
      final prevRaw = prefs.getString(_kActiveStart);
      final prev = (prevRaw == null || prevRaw.isEmpty)
          ? null
          : DateTime.tryParse(prevRaw);
      if (prev != null) {
        // Close it at the last known day boundary if it straddled midnight,
        // otherwise at "now" (best estimate of when they left).
        final end = _dateKey(prev) == _dateKey(DateTime.now())
            ? DateTime.now()
            : DateTime(prev.year, prev.month, prev.day, 23, 59, 59);
        _bank(prev, end);
      }
    } catch (_) {
      // Usage tracking is additive — never let it break launch.
    }
    // This launch is a fresh session.
    await _setActiveStart(DateTime.now());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (activeStart.value == null) _setActiveStart(DateTime.now());
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _closeActive();
        break;
    }
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

  Future<void> _closeActive() async {
    final start = activeStart.value;
    if (start == null) return;
    activeStart.value = null;
    final banked = _bank(start, DateTime.now());
    await _setActiveStart(null);
    if (banked) await _persist();
  }

  bool _bank(DateTime start, DateTime end) {
    if (!end.isAfter(start)) return false;
    if (sessions.any((s) => s.start == start)) return false;
    sessions.add(AppSession(start: start, end: end));
    sessions.sort((a, b) => a.start.compareTo(b.start));
    if (sessions.length > _maxSessions) {
      sessions.removeRange(0, sessions.length - _maxSessions);
    }
    return true;
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _kSessions, jsonEncode(sessions.map((s) => s.toMap()).toList()));
    } catch (_) {}
  }

  // ── Reads (reactive inside Obx via sessions / activeStart) ──────────────────

  List<AppSession> _sessionsOn(DateTime day) => sessions
      .where((s) => _dateKey(s.start) == _dateKey(day))
      .toList();

  /// Total time in the app today, including the session in progress.
  Duration usageToday() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    var total = Duration.zero;
    for (final s in _sessionsOn(now)) {
      total += s.duration;
    }
    final active = activeStart.value;
    if (active != null) {
      final from = active.isAfter(startOfDay) ? active : startOfDay;
      final d = now.difference(from);
      if (!d.isNegative) total += d;
    }
    return total;
  }

  /// When the app was first opened today (earliest session start, or the live
  /// session's start). Null if nothing today.
  DateTime? firstOpenedToday() {
    final today = _sessionsOn(DateTime.now());
    DateTime? first = today.isEmpty ? null : today.first.start;
    final active = activeStart.value;
    if (active != null &&
        _dateKey(active) == _dateKey(DateTime.now()) &&
        (first == null || active.isBefore(first))) {
      first = active;
    }
    return first;
  }

  /// Most recent activity today — the live session's "now" while running, else
  /// the last session end.
  DateTime? lastActiveToday() {
    if (activeStart.value != null) return DateTime.now();
    final today = _sessionsOn(DateTime.now());
    return today.isEmpty ? null : today.last.end;
  }

  int sessionCountToday() {
    final n = _sessionsOn(DateTime.now()).length;
    return activeStart.value != null ? n + 1 : n;
  }

  static String formatHm(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m';
    return '${d.inSeconds}s';
  }
}
