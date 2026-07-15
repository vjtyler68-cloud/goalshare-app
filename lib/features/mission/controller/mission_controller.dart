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
import 'package:spanx/features/mission/model/get_all_mission_model.dart';

/// A user-defined daily counter (custom stats column, e.g. "Doors Hung").
class CustomMetric {
  final String id;
  final String name;
  final RxInt value;
  CustomMetric({required this.id, required this.name, int value = 0})
      : value = value.obs;
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

class MissionController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    fetchMission();
    _loadDailyMetrics();
  }

  @override
  void onClose() {
    missionTitle.dispose();
    clientTarget.dispose();
    description.dispose();
    for (final t in clientTimers) {
      t.stop();
    }
    super.onClose();
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

  static const _kDate = 'metrics_date';
  static const _kGoal = 'daily_goal';
  static const _kHomes = 'homes_knocked';
  static const _kPeople = 'people_talked';
  static const _kSales = 'sales_made';

  /// User-added metric columns (e.g. "Doors Hung"). Definitions persist across
  /// days; values reset daily exactly like the built-in counters.
  final RxList<CustomMetric> customMetrics = <CustomMetric>[].obs;
  static const _kCustomDefs = 'custom_metric_defs_v1';

  Future<void> _loadDailyMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final savedDate = prefs.getString(_kDate) ?? '';
    final isNewDay = savedDate != today;
    if (isNewDay) {
      // New day — reset counters
      homesKnocked.value = 0;
      peopleTalkedTo.value = 0;
      salesMade.value = 0;
      await prefs.setString(_kDate, today);
      await prefs.setInt(_kHomes, 0);
      await prefs.setInt(_kPeople, 0);
      await prefs.setInt(_kSales, 0);
    } else {
      homesKnocked.value = prefs.getInt(_kHomes) ?? 0;
      peopleTalkedTo.value = prefs.getInt(_kPeople) ?? 0;
      salesMade.value = prefs.getInt(_kSales) ?? 0;
    }
    dailyGoal.value = prefs.getInt(_kGoal) ?? 10;

    // Custom metric definitions + today's values.
    try {
      final defsRaw = prefs.getString(_kCustomDefs);
      if (defsRaw != null && defsRaw.isNotEmpty) {
        final defs = (jsonDecode(defsRaw) as List).whereType<Map>().toList();
        customMetrics.assignAll(defs.map((m) {
          final id = (m['id'] ?? '').toString();
          final value =
              isNewDay ? 0 : (prefs.getInt('custom_metric_val_$id') ?? 0);
          if (isNewDay) prefs.setInt('custom_metric_val_$id', 0);
          return CustomMetric(
              id: id, name: (m['name'] ?? '').toString(), value: value);
        }));
      }
    } catch (_) {
      // Custom metrics are additive — never break the built-in counters.
    }
  }

  Future<void> _saveMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kHomes, homesKnocked.value);
    await prefs.setInt(_kPeople, peopleTalkedTo.value);
    await prefs.setInt(_kSales, salesMade.value);
    await prefs.setInt(_kGoal, dailyGoal.value);
    for (final m in customMetrics) {
      await prefs.setInt('custom_metric_val_${m.id}', m.value.value);
    }
  }

  Future<void> _saveCustomDefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kCustomDefs,
      jsonEncode(customMetrics.map((m) => {'id': m.id, 'name': m.name}).toList()),
    );
  }

  void increment(RxInt field) { field.value++; _saveMetrics(); }
  void decrement(RxInt field) { if (field.value > 0) { field.value--; _saveMetrics(); } }
  void setDailyGoal(int value) { dailyGoal.value = value; _saveMetrics(); }

  /// Direct edit (tap the number, type the real count) — works for the three
  /// built-in counters and custom metric values alike.
  void setMetricValue(RxInt field, int value) {
    field.value = value < 0 ? 0 : value;
    _saveMetrics();
  }

  /// Add a user-defined metric column (max 4 keeps the screen clean).
  bool addCustomMetric(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || customMetrics.length >= 4) return false;
    customMetrics.add(CustomMetric(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmed,
    ));
    _saveCustomDefs();
    _saveMetrics();
    return true;
  }

  void removeCustomMetric(String id) {
    customMetrics.removeWhere((m) => m.id == id);
    _saveCustomDefs();
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
