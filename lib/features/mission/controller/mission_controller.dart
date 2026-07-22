import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spanx/core/alertdialogs/task_created_successful.dart';
import 'package:spanx/core/const/enums.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/features/achievements/achievements_controller.dart';
import 'package:spanx/features/mission/data/metric_icons.dart';
import 'package:spanx/features/mission/data/stats_history.dart';
import 'package:spanx/features/mission/data/work_sessions.dart';
import 'package:spanx/features/mission/model/get_all_mission_model.dart';

/// A user-defined daily counter (custom stats column, e.g. "Doors Hung").
/// [iconKey] indexes [kMetricIcons]; metrics saved before icons existed load
/// with [kDefaultMetricIconKey] instead of crashing.
class CustomMetric {
  final String id;
  String name;
  String iconKey;
  final RxInt value;
  CustomMetric({
    required this.id,
    required this.name,
    this.iconKey = kDefaultMetricIconKey,
    int value = 0,
  }) : value = value.obs;

  IconData get icon => metricIconFor(iconKey);
}

class ClientTimerEntry {
  final String id;
  String name;
  int elapsedSeconds;
  bool isRunning;
  DateTime? _startedAt;
  Timer? _ticker;

  ClientTimerEntry({required this.id, required this.name, this.elapsedSeconds = 0, this.isRunning = false});

  void start(VoidCallback onTick) {
    if (isRunning) return;
    isRunning = true;
    _startedAt = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => onTick());
  }

  void stop() {
    if (!isRunning) return;
    isRunning = false;
    _ticker?.cancel();
    _ticker = null;
  }

  String get formatted {
    final h = (elapsedSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((elapsedSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class MissionController extends GetxController with WidgetsBindingObserver {
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    // Register the services up front so the first build never has to Get.put
    // them from inside an Obx.
    WorkSessionsService.to;
    StatsHistoryService.to;
    fetchMission();
    syncDay();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Crossing midnight while backgrounded is the usual way a day gets lost,
    // so re-run the whole day check on every resume (not just at first launch).
    if (state == AppLifecycleState.resumed) syncDay();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _workTicker?.cancel();
    missionTitle.dispose();
    clientTarget.dispose();
    description.dispose();
    for (final t in clientTimers) {
      t.stop();
    }
    super.onClose();
  }

  /// Full day check: auto-save a finished day, roll the counters over, then
  /// reload today's numbers and the work-session timer. Safe to call as often
  /// as we like — [rolloverIfNeeded] and [saveDayToCareerStats] both guard on
  /// the date, so repeat opens on the same day change nothing.
  Future<void> syncDay() async {
    await rolloverIfNeeded();
    await _loadDailyMetrics();
    await _syncSavedFlag();
    await _loadWorkSession();
  }

  /// Keeps [isTodaySaved] honest, including for users upgrading from a build
  /// that saved days without writing the saved-date marker.
  Future<void> _syncSavedFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _dateKey(DateTime.now());
      var saved = prefs.getString(_kStatsSavedDate) ?? '';
      if (saved != today) {
        await StatsHistoryService.to.ensureLoaded();
        if (StatsHistoryService.to.hasDay(today)) {
          saved = today;
          await prefs.setString(_kStatsSavedDate, today);
        }
      }
      lastSavedStatsDate.value = saved;
    } catch (e) {
      log('_syncSavedFlag error: $e');
    }
  }

  // ── API / mission state ──────────────────────────────────────────────────
  final RxBool isLoading = false.obs;
  final RxBool isDeleteLoading = false.obs;
  final RxString selectedDate = ''.obs;
  var selectedCategory = 'Daily'.obs;
  var selectedPriority = 'High'.obs;

  final missionTitle = TextEditingController();
  final clientTarget = TextEditingController();
  final description = TextEditingController();

  final List<String> categoryList = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
  final List<String> priorityList = ['High', 'Medium', 'Low'];

  final RxList<GetAllMissionModel> getAllMissionList = <GetAllMissionModel>[].obs;

  final RxInt totalClient = 0.obs;
  final RxInt totalReachedClient = 0.obs;
  final RxInt totalSalesPercentage = 0.obs;
  final RxString totalTimeSpent = '0 Sec'.obs;

  void selectCategory(String value) => selectedCategory.value = value;
  void selectPriority(String value) => selectedPriority.value = value;

  // ── Daily metrics (persisted locally) ───────────────────────────────────
  final RxInt dailyGoal = 10.obs;
  final RxInt homesKnocked = 0.obs;
  final RxInt peopleTalkedTo = 0.obs;
  final RxInt salesMade = 0.obs;

  /// Which metric the Daily Goal tracks: 'homes' | 'people' | 'sales' | a custom
  /// metric id. Defaults to 'homes' so existing users see no change.
  final RxString goalMetric = 'homes'.obs;

  static const _kDate = 'metrics_date';
  static const _kGoal = 'daily_goal';
  static const _kGoalMetric = 'daily_goal_metric';
  static const _kHomes = 'homes_knocked';
  static const _kPeople = 'people_talked';
  static const _kSales = 'sales_made';

  // Editable display (label + icon) for the three built-in metrics. GoalShare
  // isn't only for door-to-door reps — a realtor, recruiter, or gym owner can
  // rename these to whatever they track. Only the DISPLAY changes; the values
  // still drive Daily Goal progress and career stats.
  final RxString homesLabel = 'Homes Knocked'.obs;
  final RxString homesIcon = 'home'.obs;
  final RxString peopleLabel = 'People Talked To'.obs;
  final RxString peopleIcon = 'people'.obs;
  final RxString salesLabel = 'Sales Made'.obs;
  final RxString salesIcon = 'dollar'.obs;
  static const _kBuiltinDefs = 'builtin_metric_defs_v1';

  String builtinLabelFor(String which) => which == 'homes'
      ? homesLabel.value
      : which == 'people'
          ? peopleLabel.value
          : salesLabel.value;

  String builtinIconFor(String which) => which == 'homes'
      ? homesIcon.value
      : which == 'people'
          ? peopleIcon.value
          : salesIcon.value;

  // Resolved icons for the three built-ins, so every screen (Mission cards,
  // End-of-Day, Analytics, Profile) shows the SAME icon the user picked.
  // Reading `.value` here keeps callers reactive when used inside an Obx.
  IconData get homesIconData => metricIconFor(homesIcon.value);
  IconData get peopleIconData => metricIconFor(peopleIcon.value);
  IconData get salesIconData => metricIconFor(salesIcon.value);

  /// User-added metric columns (e.g. "Doors Hung"). Definitions persist across
  /// days; values reset daily exactly like the built-in counters.
  final RxList<CustomMetric> customMetrics = <CustomMetric>[].obs;
  static const _kCustomDefs = 'custom_metric_defs_v1';

  // ── Day rollover / auto-save ─────────────────────────────────────────────
  /// The day the numbers currently on disk belong to.
  static const _kLastMissionDate = 'last_mission_date_v1';

  /// The last day that was committed to career stats. This is the *only*
  /// double-save guard: one entry per date, ever.
  static const _kStatsSavedDate = 'stats_saved_date_v1';

  /// Mirrors [_kStatsSavedDate] so the End of Day button can react to it.
  final RxString lastSavedStatsDate = ''.obs;

  bool get isTodaySaved => lastSavedStatsDate.value == _dateKey(DateTime.now());

  Future<void>? _rolloverFuture;

  static String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  /// Reads the custom metric values sitting on disk (i.e. the previous day's,
  /// before any reset) keyed by metric *name*, matching [DayStat.custom].
  Map<String, int> _customValuesFromPrefs(SharedPreferences prefs) {
    final out = <String, int>{};
    try {
      final raw = prefs.getString(_kCustomDefs);
      if (raw == null || raw.isEmpty) return out;
      for (final m in (jsonDecode(raw) as List).whereType<Map>()) {
        final id = (m['id'] ?? '').toString();
        final name = (m['name'] ?? '').toString();
        if (name.isEmpty) continue;
        out[name] = prefs.getInt('custom_metric_val_$id') ?? 0;
      }
    } catch (_) {}
    return out;
  }

  /// If the stored numbers belong to an earlier day, save THAT day to career
  /// stats (using the values from that day, not today's blank slate), then
  /// clear the counters for today. Idempotent: strictly guarded on the date,
  /// so opening the app ten times today does nothing after the first pass.
  ///
  /// Re-entrant callers *await the in-flight run* rather than dropping their
  /// call: `syncDay()` is fired unawaited from both `onInit` and a resume, and
  /// whoever loses that race must not run [_loadDailyMetrics] before the
  /// rollover has finished banking the day.
  Future<void> rolloverIfNeeded() => _rolloverFuture ??=
      _runRollover().whenComplete(() => _rolloverFuture = null);

  Future<void> _runRollover() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _dateKey(DateTime.now());
      lastSavedStatsDate.value = prefs.getString(_kStatsSavedDate) ?? '';

      // Fall back to the pre-existing metrics_date so upgrading users don't
      // get a bogus "first day" rollover.
      final last = prefs.getString(_kLastMissionDate) ??
          prefs.getString(_kDate) ??
          '';

      if (last.isEmpty) {
        await prefs.setString(_kLastMissionDate, today);
        await prefs.setString(_kDate, today);
        return;
      }
      if (last == today) return; // already on today — nothing to roll over

      // Commit the finished day from the numbers stored for it.
      await saveDayToCareerStats(
        forDate: last,
        homes: prefs.getInt(_kHomes) ?? 0,
        people: prefs.getInt(_kPeople) ?? 0,
        sales: prefs.getInt(_kSales) ?? 0,
        goal: prefs.getInt(_kGoal) ?? 10,
        custom: _customValuesFromPrefs(prefs),
      );

      // Then start the new day clean.
      await prefs.setInt(_kHomes, 0);
      await prefs.setInt(_kPeople, 0);
      await prefs.setInt(_kSales, 0);
      try {
        final raw = prefs.getString(_kCustomDefs);
        if (raw != null && raw.isNotEmpty) {
          for (final m in (jsonDecode(raw) as List).whereType<Map>()) {
            await prefs.setInt(
                'custom_metric_val_${(m['id'] ?? '').toString()}', 0);
          }
        }
      } catch (_) {}

      await prefs.setString(_kDate, today);
      await prefs.setString(_kLastMissionDate, today);
    } catch (e) {
      log('rolloverIfNeeded error: $e');
    }
  }

  /// Single shared "End of Day" commit — used by both the automatic rollover
  /// and the manual button. Returns true only when a day was actually written.
  ///
  /// Skips entirely when the date has already been saved (no inflated career
  /// totals, no duplicate history row) and when the day is completely empty
  /// (an untouched day is not worth a zero row in the weekly breakdown).
  Future<bool> saveDayToCareerStats({
    String? forDate,
    int? homes,
    int? people,
    int? sales,
    int? goal,
    Map<String, int>? custom,
  }) async {
    final date = forDate ?? _dateKey(DateTime.now());
    final prefs = await SharedPreferences.getInstance();

    if ((prefs.getString(_kStatsSavedDate) ?? '') == date) {
      lastSavedStatsDate.value = date;
      return false;
    }

    // A date already in history was committed at some point — re-committing
    // would inflate the all-time career totals. This also covers users
    // upgrading from a build that had no saved-date marker at all.
    await StatsHistoryService.to.ensureLoaded();
    if (StatsHistoryService.to.hasDay(date)) {
      await prefs.setString(_kStatsSavedDate, date);
      lastSavedStatsDate.value = date;
      return false;
    }

    final h = homes ?? homesKnocked.value;
    final p = people ?? peopleTalkedTo.value;
    final s = sales ?? salesMade.value;
    final g = goal ?? dailyGoal.value;
    final cm = custom ??
        {for (final m in customMetrics) m.name: m.value.value};

    if (h == 0 && p == 0 && s == 0 && cm.values.every((v) => v == 0)) {
      return false;
    }

    try {
      final ac = Get.isRegistered<AchievementsController>()
          ? Get.find<AchievementsController>()
          : Get.put(AchievementsController(), permanent: true);
      await ac.recordDailyActivity(
          homes: h, people: p, sales: s, dailyGoal: g, forDateKey: date);
    } catch (e) {
      log('saveDayToCareerStats achievements error: $e');
    }

    // Per-day history powers the Weekly Breakdown; same-date saves replace.
    await StatsHistoryService.to.recordDay(
      DayStat(date: date, homes: h, people: p, sales: s, custom: cm),
    );

    await prefs.setString(_kStatsSavedDate, date);
    lastSavedStatsDate.value = date;
    return true;
  }

  Future<void> _loadDailyMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateKey(DateTime.now());
    lastSavedStatsDate.value = prefs.getString(_kStatsSavedDate) ?? '';
    final savedDate = prefs.getString(_kDate) ?? '';
    final isNewDay = savedDate != today;
    _dayStale = isNewDay;
    if (isNewDay) {
      // New day — blank the *display* only. rolloverIfNeeded() owns both date
      // markers and the on-disk reset; if it failed (or hasn't run yet) the
      // stored numbers are still the unbanked previous day, and clearing them
      // here would destroy them for good with no retry on the next open.
      homesKnocked.value = 0;
      peopleTalkedTo.value = 0;
      salesMade.value = 0;
    } else {
      homesKnocked.value = prefs.getInt(_kHomes) ?? 0;
      peopleTalkedTo.value = prefs.getInt(_kPeople) ?? 0;
      salesMade.value = prefs.getInt(_kSales) ?? 0;
    }
    dailyGoal.value = prefs.getInt(_kGoal) ?? 10;
    goalMetric.value = prefs.getString(_kGoalMetric) ?? 'homes';

    // Built-in metric labels/icons (persist across days, never reset).
    _loadBuiltinDefs(prefs);

    // Custom metric definitions + today's values.
    try {
      final defsRaw = prefs.getString(_kCustomDefs);
      if (defsRaw != null && defsRaw.isNotEmpty) {
        final defs = (jsonDecode(defsRaw) as List).whereType<Map>().toList();
        customMetrics.assignAll(defs.map((m) {
          final id = (m['id'] ?? '').toString();
          // Same rule as the built-ins: blank the display on a new day, but
          // leave the stored value alone so an un-run rollover can still bank
          // it. rolloverIfNeeded() does the on-disk reset.
          final value =
              isNewDay ? 0 : (prefs.getInt('custom_metric_val_$id') ?? 0);
          return CustomMetric(
            id: id,
            name: (m['name'] ?? '').toString(),
            // Metrics saved before icons existed have no 'icon' key.
            iconKey: (m['icon'] ?? kDefaultMetricIconKey).toString(),
            value: value,
          );
        }));
      }
    } catch (_) {
      // Custom metrics are additive — never break the built-in counters.
    }
  }

  /// True when the numbers on disk still belong to an earlier day — i.e. the
  /// rollover has not managed to bank them yet.
  bool _dayStale = false;

  Future<void> _saveMetrics() async {
    // Never overwrite an unbanked previous day. If the rollover errored (or
    // simply hasn't run), retry it once here so the old numbers get committed
    // before today's land on top of them.
    if (_dayStale) {
      _dayStale = false;
      await rolloverIfNeeded();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kHomes, homesKnocked.value);
    await prefs.setInt(_kPeople, peopleTalkedTo.value);
    await prefs.setInt(_kSales, salesMade.value);
    await prefs.setInt(_kGoal, dailyGoal.value);
    await prefs.setString(_kGoalMetric, goalMetric.value);
    for (final m in customMetrics) {
      await prefs.setInt('custom_metric_val_${m.id}', m.value.value);
    }
  }

  Future<void> _saveCustomDefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kCustomDefs,
      jsonEncode(customMetrics
          .map((m) => {'id': m.id, 'name': m.name, 'icon': m.iconKey})
          .toList()),
    );
  }

  void increment(RxInt field) { field.value++; _saveMetrics(); }
  void decrement(RxInt field) { if (field.value > 0) { field.value--; _saveMetrics(); } }
  void setDailyGoal(int value) { dailyGoal.value = value; _saveMetrics(); }
  void setGoalMetric(String key) { goalMetric.value = key; _saveMetrics(); }

  /// The live value + label of whichever metric the Daily Goal tracks, so the
  /// progress bar and caption work for anyone — not just door-knockers.
  int get goalCurrentValue {
    switch (goalMetric.value) {
      case 'homes':
        return homesKnocked.value;
      case 'people':
        return peopleTalkedTo.value;
      case 'sales':
        return salesMade.value;
      default:
        return _goalCustomMetric?.value.value ?? homesKnocked.value;
    }
  }

  String get goalMetricLabel {
    switch (goalMetric.value) {
      case 'homes':
        return homesLabel.value;
      case 'people':
        return peopleLabel.value;
      case 'sales':
        return salesLabel.value;
      default:
        return _goalCustomMetric?.name ?? homesLabel.value;
    }
  }

  CustomMetric? get _goalCustomMetric {
    for (final m in customMetrics) {
      if (m.id == goalMetric.value) return m;
    }
    return null;
  }

  /// (key, label) options for the Daily Goal metric picker: the 3 built-ins
  /// (with their current custom names) plus any user-added stats.
  List<({String key, String label})> get goalMetricOptions => [
        (key: 'homes', label: homesLabel.value),
        (key: 'people', label: peopleLabel.value),
        (key: 'sales', label: salesLabel.value),
        for (final m in customMetrics) (key: m.id, label: m.name),
      ];

  /// Direct edit (tap the number, type the real count) — works for the three
  /// built-in counters and custom metric values alike.
  void setMetricValue(RxInt field, int value) {
    field.value = value < 0 ? 0 : value;
    _saveMetrics();
  }

  /// Add a user-defined metric column (max 4 keeps the screen clean).
  bool addCustomMetric(String name, {String iconKey = kDefaultMetricIconKey}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || customMetrics.length >= 4) return false;
    customMetrics.add(CustomMetric(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmed,
      iconKey: kMetricIcons.containsKey(iconKey) ? iconKey : kDefaultMetricIconKey,
    ));
    _saveCustomDefs();
    _saveMetrics();
    return true;
  }

  /// Rename / re-icon an existing custom metric (long-press the card).
  /// The running value is untouched.
  bool editCustomMetric(String id, {String? name, String? iconKey}) {
    final m = customMetrics.firstWhereOrNull((e) => e.id == id);
    if (m == null) return false;
    final trimmed = name?.trim();
    if (trimmed != null && trimmed.isEmpty) return false;
    if (trimmed != null) m.name = trimmed;
    if (iconKey != null && kMetricIcons.containsKey(iconKey)) m.iconKey = iconKey;
    customMetrics.refresh();
    _saveCustomDefs();
    return true;
  }

  void removeCustomMetric(String id) {
    customMetrics.removeWhere((m) => m.id == id);
    _saveCustomDefs();
  }

  /// Rename / re-icon a built-in metric. [which] is 'homes' | 'people' |
  /// 'sales'. The running value and its role in goals/career stats are
  /// untouched — only the label + icon shown on the card change.
  bool editBuiltinMetric(String which, {String? name, String? iconKey}) {
    final trimmed = name?.trim();
    if (trimmed != null && trimmed.isEmpty) return false;
    final key =
        (iconKey != null && kMetricIcons.containsKey(iconKey)) ? iconKey : null;
    switch (which) {
      case 'homes':
        if (trimmed != null) homesLabel.value = trimmed;
        if (key != null) homesIcon.value = key;
        break;
      case 'people':
        if (trimmed != null) peopleLabel.value = trimmed;
        if (key != null) peopleIcon.value = key;
        break;
      case 'sales':
        if (trimmed != null) salesLabel.value = trimmed;
        if (key != null) salesIcon.value = key;
        break;
      default:
        return false;
    }
    _saveBuiltinDefs();
    return true;
  }

  Future<void> _saveBuiltinDefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kBuiltinDefs,
      jsonEncode({
        'homes': {'label': homesLabel.value, 'icon': homesIcon.value},
        'people': {'label': peopleLabel.value, 'icon': peopleIcon.value},
        'sales': {'label': salesLabel.value, 'icon': salesIcon.value},
      }),
    );
  }

  void _loadBuiltinDefs(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(_kBuiltinDefs);
      if (raw == null || raw.isEmpty) return;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      void apply(String k, RxString label, RxString icon) {
        final e = m[k];
        if (e is Map) {
          final l = (e['label'] ?? '').toString();
          final ic = (e['icon'] ?? '').toString();
          if (l.isNotEmpty) label.value = l;
          if (kMetricIcons.containsKey(ic)) icon.value = ic;
        }
      }

      apply('homes', homesLabel, homesIcon);
      apply('people', peopleLabel, peopleIcon);
      apply('sales', salesLabel, salesIcon);
    } catch (_) {
      // Labels are cosmetic — never break the counters over a bad blob.
    }
  }

  // ── Work day session (Start Day / End Day) ───────────────────────────────
  WorkSessionsService get _work => WorkSessionsService.to;

  /// Repaint pulse for the live "Xh Ym" label. The elapsed value itself is
  /// always derived from the persisted start timestamp, never from this — so
  /// closing and reopening the app resumes the running day exactly.
  final RxInt workTick = 0.obs;
  Timer? _workTicker;

  bool get isWorkDayRunning => _work.isRunning;

  /// When today's session started, or null when off the clock.
  DateTime? get dayStartTime => _work.activeStart.value;

  Duration get currentSessionElapsed {
    final start = _work.activeStart.value;
    if (start == null) return Duration.zero;
    final d = DateTime.now().difference(start);
    return d.isNegative ? Duration.zero : d;
  }

  String get currentSessionLabel =>
      WorkSessionsService.formatHm(currentSessionElapsed);

  /// Totals for the header pill today and for a future weekly recap.
  Duration getTodaysWorkDuration() => _work.getTodaysWorkDuration();
  Duration getWeeklyWorkDuration() => _work.getWeeklyWorkDuration();

  Future<void> _loadWorkSession() async {
    await _work.ensureLoaded();
    workTick.value++;
    _syncWorkTicker();
  }

  void _syncWorkTicker() {
    _workTicker?.cancel();
    _workTicker = null;
    if (!_work.isRunning) return;
    // Minute-granular label, so a 30s pulse is plenty.
    _workTicker = Timer.periodic(const Duration(seconds: 30), (_) async {
      final start = _work.activeStart.value;
      if (start != null &&
          WorkSessionsService.dateKey(start) !=
              WorkSessionsService.dateKey(DateTime.now())) {
        // Sat open past midnight — bank it and reset the pill.
        await _work.closeStaleSession();
        _syncWorkTicker();
      }
      workTick.value++;
    });
  }

  /// Start Day ⇄ End Day.
  Future<void> toggleWorkDay() async {
    if (_work.isRunning) {
      await _work.endDay();
    } else {
      await _work.startDay();
    }
    workTick.value++;
    _syncWorkTicker();
  }

  // ── Client timers ────────────────────────────────────────────────────────
  final RxList<ClientTimerEntry> clientTimers = <ClientTimerEntry>[].obs;
  int _timerIdCounter = 0;

  void addClientTimer(String name) {
    clientTimers.add(ClientTimerEntry(id: '${_timerIdCounter++}', name: name.trim().isEmpty ? 'Client ${_timerIdCounter}' : name.trim()));
    clientTimers.refresh();
  }

  void toggleTimer(String id) {
    final idx = clientTimers.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final t = clientTimers[idx];
    if (t.isRunning) {
      t.stop();
    } else {
      t.start(() {
        t.elapsedSeconds++;
        clientTimers.refresh();
      });
    }
    clientTimers.refresh();
  }

  void resetTimer(String id) {
    final t = clientTimers.firstWhereOrNull((t) => t.id == id);
    if (t == null) return;
    t.stop();
    t.elapsedSeconds = 0;
    clientTimers.refresh();
  }

  void removeClientTimer(String id) {
    final t = clientTimers.firstWhereOrNull((t) => t.id == id);
    t?.stop();
    clientTimers.removeWhere((t) => t.id == id);
  }

  // ── Mission CRUD ─────────────────────────────────────────────────────────
  Future<void> pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final dateAtNoon = DateTime(picked.year, picked.month, picked.day, 12);
      selectedDate.value = dateAtNoon.toIso8601String();
    }
  }

  String formattedClientTime(int? sec) {
    if (sec == null || sec <= 0) return '00 : 00';
    final hours = (sec ~/ 3600).toString().padLeft(2, '0');
    final mins = ((sec % 3600) ~/ 60).toString().padLeft(2, '0');
    return '$hours : $mins';
  }

  String formatDate(String isoDateString) {
    final dateTime = DateTime.tryParse(isoDateString);
    if (dateTime == null) return isoDateString;
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  GoalPriority parsePriority(dynamic input) {
    switch (input?.toString().trim()) {
      case 'High': return GoalPriority.HIGH;
      case 'Medium': return GoalPriority.MEDIUM;
      default: return GoalPriority.LOW;
    }
  }

  int get totalClients => getAllMissionList.fold(0, (sum, m) => sum + (m.clientTarget ?? 0));
  RxInt get totalSales => totalReachedClient;

  void _recalculateProgress() {
    totalClient.value = getAllMissionList.fold(0, (sum, m) => sum + (m.clientTarget ?? 0));
    totalReachedClient.value = getAllMissionList.fold(0, (sum, m) => sum + (m.totalReached ?? 0));
    totalSalesPercentage.value = totalClient.value > 0
        ? ((totalReachedClient.value / totalClient.value) * 100).toInt()
        : 0;
    _formatTotalTimeSpent();
  }

  void _formatTotalTimeSpent() {
    final totalSeconds = getAllMissionList.fold(0, (sum, m) => sum + (m.reachedClientsTime ?? 0));
    if (totalSeconds < 60) {
      totalTimeSpent.value = '$totalSeconds Sec';
    } else if (totalSeconds < 3600) {
      totalTimeSpent.value = '${totalSeconds ~/ 60} Min';
    } else {
      totalTimeSpent.value = '${totalSeconds ~/ 3600} Hr';
    }
  }

  Future<void> fetchProgressInfo() async => _recalculateProgress();

  Future<void> createMission() async {
    if (missionTitle.text.trim().isEmpty) { AppSnackBar.error('Please enter a mission title'); return; }
    if (clientTarget.text.trim().isEmpty) { AppSnackBar.error('Please enter a client target'); return; }
    if (selectedDate.value.isEmpty) { AppSnackBar.error('Please select a due date'); return; }

    isLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST, Urls.createMission,
        jsonEncode({
          'title': missionTitle.text.trim(),
          'clientTarget': int.tryParse(clientTarget.text) ?? 0,
          'description': description.text.trim(),
          'category': selectedCategory.value,
          'priority': selectedPriority.value,
          'dueDate': selectedDate.value,
        }),
        is_auth: true,
      );
      if (response != null && response['success'] == true) {
        clearField();
        await fetchMission();
        Get.back();
        TaskCreatedSuccessful.show(onContinue: () {});
      } else {
        log('createMission failed: $response');
        AppSnackBar.error(response?['message'] ?? 'Failed to create mission');
      }
    } catch (e) {
      log('createMission error: $e');
      AppSnackBar.error('Something went wrong. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchMission() async {
    isLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET, Urls.getMission, jsonEncode({}), is_auth: true,
      );
      if (response != null && response['success'] == true) {
        getAllMissionList.assignAll(
          (response['data']?['goals'] as List? ?? []).map((e) => GetAllMissionModel.fromJson(e)),
        );
        _recalculateProgress();
      }
    } catch (e) {
      log('fetchMission error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteMotivation(String missionID) async {
    isDeleteLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.DELETE, '${Urls.deleteMission}/$missionID', jsonEncode({}), is_auth: true,
      );
      if (response != null && response['success'] == true) {
        await fetchMission();
        AppSnackBar.success(response['message'] ?? 'Mission deleted');
      } else {
        AppSnackBar.error(response?['message'] ?? 'Failed to delete mission');
      }
    } catch (e) {
      log('deleteMotivation error: $e');
      AppSnackBar.error('Something went wrong. Please try again.');
    } finally {
      isDeleteLoading.value = false;
    }
  }

  void clearField() {
    missionTitle.clear();
    clientTarget.clear();
    description.clear();
    selectedDate.value = '';
  }
}
