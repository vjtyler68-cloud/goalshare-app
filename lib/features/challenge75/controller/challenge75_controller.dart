import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/daily_checks/daily_check_service.dart';
import '../../../core/firebase/firebase_service.dart';
import '../../../core/local/local_data.dart';
import '../data/challenge75_crew.dart';
import '../data/challenge75_models.dart';

/// Owns all 75 Challenge state: the config, every logged day, the joined crew
/// code, and the derived stats (current day, streak, completed/remaining).
/// Local-first (SharedPreferences) so it works fully offline; the crew push is
/// a best-effort extra on top.
class Challenge75Controller extends GetxController {
  static Challenge75Controller get to =>
      Get.isRegistered<Challenge75Controller>()
          ? Get.find<Challenge75Controller>()
          : Get.put(Challenge75Controller(), permanent: true);

  static const String _kConfig = 'challenge75_config_v1';
  static const String _kDays = 'challenge75_days_v1';
  static const String _kCrew = 'challenge75_crew_code_v1';

  static const String dailyCheckFeature = 'challenge75';

  final Rxn<Challenge75Config> config = Rxn<Challenge75Config>();
  final RxMap<int, Challenge75Day> days = <int, Challenge75Day>{}.obs;
  final RxString crewCode = ''.obs;
  final RxBool loading = true.obs;

  String _userId = '';
  String _userName = 'Me';

  bool get started => config.value != null;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawConfig = prefs.getString(_kConfig);
      if (rawConfig != null && rawConfig.isNotEmpty) {
        config.value = Challenge75Config.fromJson(
          jsonDecode(rawConfig) as Map<String, dynamic>,
        );
      }
      final rawDays = prefs.getString(_kDays);
      if (rawDays != null && rawDays.isNotEmpty) {
        final list = jsonDecode(rawDays) as List;
        final map = <int, Challenge75Day>{};
        for (final e in list) {
          if (e is Map) {
            final d = Challenge75Day.fromJson(e.cast<String, dynamic>());
            map[d.day] = d;
          }
        }
        days.assignAll(map);
      }
      crewCode.value = prefs.getString(_kCrew) ?? '';
    } catch (e) {
      log('Challenge75Controller load failed: $e');
    }
    await _resolveIdentity();
    loading.value = false;
  }

  Future<void> _resolveIdentity() async {
    try {
      final id = await FirebaseService.instance.currentUserId();
      final name = await LocalService().getName();
      if (id != null && id.isNotEmpty) _userId = id;
      if (name != null && name.trim().isNotEmpty) _userName = name.trim();
    } catch (_) {}
  }

  Future<void> _saveConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final c = config.value;
      if (c == null) {
        await prefs.remove(_kConfig);
      } else {
        await prefs.setString(_kConfig, jsonEncode(c.toJson()));
      }
    } catch (e) {
      log('Challenge75Controller saveConfig failed: $e');
    }
  }

  Future<void> _saveDays() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = days.values.map((d) => d.toJson()).toList();
      await prefs.setString(_kDays, jsonEncode(list));
    } catch (e) {
      log('Challenge75Controller saveDays failed: $e');
    }
  }

  // ── Date helpers (date-only) ────────────────────────────────────────────────
  DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static String ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime dateForDay(int day) {
    final c = config.value;
    if (c == null) return _today();
    return c.startDate.add(Duration(days: day - 1));
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────────
  Future<void> start(Challenge75Config newConfig) async {
    config.value = newConfig;
    days.clear();
    await _saveConfig();
    await _saveDays();
    await pushMyProgress();
  }

  /// Change the rules WITHOUT wiping logged progress (used by "Edit goals").
  Future<void> updateConfig(Challenge75Config newConfig) async {
    config.value = newConfig;
    await _saveConfig();
    await pushMyProgress();
  }

  Future<void> reset() async {
    config.value = null;
    days.clear();
    await _saveConfig();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kDays);
    } catch (_) {}
    await _deletePhotos();
  }

  /// Restart the same variant from today (used when restart-on-miss triggers or
  /// the user chooses to begin again). Keeps the variant/rules, resets the clock
  /// and clears logged days + photos.
  Future<void> restartFromToday() async {
    final c = config.value;
    if (c == null) return;
    await _deletePhotos();
    days.clear();
    config.value = c.copyWith(startDate: _today());
    await _saveConfig();
    await _saveDays();
    await pushMyProgress();
  }

  Future<void> _deletePhotos() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/challenge75_photos');
      if (folder.existsSync()) folder.deleteSync(recursive: true);
    } catch (_) {}
  }

  // ── Day access + save ─────────────────────────────────────────────────────────
  /// The stored entry for [day], or a fresh blank one (not yet persisted).
  Challenge75Day dayFor(int day) {
    final existing = days[day];
    if (existing != null) return existing;
    final c = config.value;
    return Challenge75Day.blank(
      day: day,
      date: c == null ? ymd(_today()) : ymd(dateForDay(day)),
      config: c ??
          Challenge75Config.fromVariant(
            Challenge75Variant.all.last,
            startDate: _today(),
          ),
    );
  }

  Challenge75Day get today => dayFor(currentDayNumber.clamp(1, kChallenge75Length));

  /// Persist a day the editor has changed. Flags it as "edited" when the change
  /// happens on a later calendar day than the day it represents.
  Future<void> saveDay(Challenge75Day day) async {
    final todayYmd = ymd(_today());
    if (day.date.isNotEmpty && day.date.compareTo(todayYmd) < 0) {
      day.edited = true;
      day.editedAt = DateTime.now().toIso8601String();
    }
    days[day.day] = day;
    days.refresh();
    await _saveDays();

    // Green ✓ on the Home grid once TODAY's challenge is fully complete.
    final c = config.value;
    if (c != null &&
        day.day == currentDayNumber &&
        day.isComplete(c) &&
        Get.isRegistered<DailyCheckService>()) {
      DailyCheckService.to.markDoneToday(dailyCheckFeature);
    }
    await pushMyProgress();
  }

  // ── Derived stats ──────────────────────────────────────────────────────────────
  /// Day number for today's date. <1 means the start date is in the future;
  /// >75 means the run is finished.
  int get currentDayNumber {
    final c = config.value;
    if (c == null) return 0;
    return _today().difference(c.startDate).inDays + 1;
  }

  bool get notStartedYet => started && currentDayNumber < 1;
  bool get finished => started && currentDayNumber > kChallenge75Length;

  int get daysUntilStart {
    final c = config.value;
    if (c == null) return 0;
    return c.startDate.difference(_today()).inDays;
  }

  int get daysCompleted {
    final c = config.value;
    if (c == null) return 0;
    var n = 0;
    for (final d in days.values) {
      if (d.isComplete(c)) n++;
    }
    return n;
  }

  int get daysRemaining {
    if (!started) return kChallenge75Length;
    final cur = currentDayNumber;
    if (cur < 1) return kChallenge75Length;
    return (kChallenge75Length - cur).clamp(0, kChallenge75Length);
  }

  /// Consecutive complete days ending at today (or yesterday if today isn't done
  /// yet). A missed past day breaks it.
  int get streak {
    final c = config.value;
    if (c == null) return 0;
    final cur = currentDayNumber;
    if (cur < 1) return 0;
    final last = cur > kChallenge75Length ? kChallenge75Length : cur;
    final todayDay = days[last];
    final todayComplete = todayDay != null && todayDay.isComplete(c);
    var start = last;
    if (last == cur && !todayComplete) start = last - 1;
    var count = 0;
    for (var i = start; i >= 1; i--) {
      final d = days[i];
      if (d != null && d.isComplete(c)) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  /// First PAST day (strictly before today) that was missed. Only meaningful
  /// when the rules restart on a miss. Null when nothing is broken.
  int? get missedDay {
    final c = config.value;
    if (c == null || !c.restartOnMiss) return null;
    final cur = currentDayNumber;
    final lastPast = (cur - 1).clamp(0, kChallenge75Length);
    for (var i = 1; i <= lastPast; i++) {
      final d = days[i];
      if (d == null || !d.isComplete(c)) return i;
    }
    return null;
  }

  /// Day grid state for the calendar.
  Challenge75DayState stateFor(int day) {
    final c = config.value;
    if (c == null) return Challenge75DayState.future;
    final cur = currentDayNumber;
    if (day == cur) return Challenge75DayState.current;
    if (day > cur) return Challenge75DayState.future;
    // Past (or today-already-passed): complete vs missed.
    final d = days[day];
    if (d != null && d.isComplete(c)) return Challenge75DayState.complete;
    return Challenge75DayState.missed;
  }

  // ── Crew / sharing ───────────────────────────────────────────────────────────
  bool get inCrew => crewCode.value.trim().isNotEmpty;

  Future<String?> createCrew(String name) async {
    await _resolveIdentity();
    final code = await Challenge75Crew.instance.createCrew(
      crewName: name,
      userId: _userIdOrFallback,
      userName: _userName,
    );
    if (code != null) {
      crewCode.value = code;
      await _persistCrew();
      await pushMyProgress();
    }
    return code;
  }

  Future<bool> joinCrew(String code) async {
    await _resolveIdentity();
    final ok = await Challenge75Crew.instance.joinCrew(
      code: code,
      userId: _userIdOrFallback,
      userName: _userName,
    );
    if (ok) {
      crewCode.value = code.trim().toUpperCase();
      await _persistCrew();
      await pushMyProgress();
    }
    return ok;
  }

  Future<void> leaveCrew() async {
    final code = crewCode.value;
    if (code.isEmpty) return;
    await Challenge75Crew.instance.leaveCrew(
      code: code,
      userId: _userIdOrFallback,
    );
    crewCode.value = '';
    await _persistCrew();
  }

  Future<void> _persistCrew() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (crewCode.value.isEmpty) {
        await prefs.remove(_kCrew);
      } else {
        await prefs.setString(_kCrew, crewCode.value);
      }
    } catch (_) {}
  }

  /// Publish my current summary to the crew (best-effort / no-op if not shared).
  Future<void> pushMyProgress() async {
    if (!inCrew) return;
    final c = config.value;
    if (c == null) return;
    if (_userId.isEmpty) await _resolveIdentity();
    final cur = currentDayNumber.clamp(0, kChallenge75Length);
    final todayDay = days[cur];
    await Challenge75Crew.instance.pushProgress(
      code: crewCode.value,
      userId: _userIdOrFallback,
      userName: _userName,
      variantId: c.variantId,
      day: cur,
      daysCompleted: daysCompleted,
      streak: streak,
      completionToday: todayDay?.completion(c) ?? 0,
      todayComplete: todayDay != null && todayDay.isComplete(c),
    );
  }

  Stream<List<Challenge75CrewMember>> watchCrew() =>
      Challenge75Crew.instance.watchCrew(crewCode.value);

  bool get sharingAvailable => Challenge75Crew.instance.available;

  String get _userIdOrFallback =>
      _userId.isNotEmpty ? _userId : 'local_${_userName.hashCode}';
}

enum Challenge75DayState { complete, missed, current, future }
