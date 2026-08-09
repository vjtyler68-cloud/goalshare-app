import 'dart:ui';

import 'package:get/get.dart';

import '../../../core/daily_checks/daily_check_service.dart';
import '../../sharing/controller/sharing_controller.dart';
import '../data/goflow_accent.dart';
import '../data/goflow_models.dart';
import '../data/goflow_pregnancy.dart';
import '../data/goflow_store.dart';
import '../data/goflow_summary.dart';
import '../service/goflow_service.dart';

/// Owns GoFlow's on-device state: the day logs, the settings (cycle math,
/// theming, sharing), and the derived cycle status. Everything is local; the
/// only thing that ever leaves the device is the stripped [GoFlowSummary] a
/// user explicitly shares with a specific friend (via Buddy Sharing).
class GoFlowController extends GetxController {
  static GoFlowController get to => Get.isRegistered<GoFlowController>()
      ? Get.find<GoFlowController>()
      : Get.put(GoFlowController(), permanent: true);

  final GoFlowStore _store = GoFlowStore();

  final RxList<GoFlowEntry> entries = <GoFlowEntry>[].obs;
  final Rx<GoFlowSettings> settings = const GoFlowSettings().obs;
  final RxBool ready = false.obs;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    await _store.open();
    entries.assignAll(_store.loadEntries());
    settings.value = _store.loadSettings();
    ready.value = true;
  }

  // ── Derived ────────────────────────────────────────────────────────────────

  /// The cycle picture for today (recomputed on read; entries/settings are the
  /// reactive sources).
  GoFlowStatus get status =>
      GoFlowService.status(entries.toList(), settings.value);

  GoFlowStatus statusOn(DateTime day) =>
      GoFlowService.status(entries.toList(), settings.value, on: day);

  Color get accentColor => GoFlowAccent.resolve(settings.value.accentId);

  GoFlowEntry? entryFor(DateTime day) {
    final key = GoFlowEntry.keyFor(day);
    for (final e in entries) {
      if (e.key == key) return e;
    }
    return null;
  }

  // ── Writes ───────────────────────────────────────────────────────────────

  /// Idempotent daily save: overwrites the day's entry, or removes it entirely
  /// if the user cleared every field.
  Future<void> saveEntry(GoFlowEntry entry) async {
    final key = entry.key;
    if (entry.isEmpty) {
      await _store.deleteEntry(entry.date);
      entries.removeWhere((e) => e.key == key);
    } else {
      await _store.putEntry(entry);
      final idx = entries.indexWhere((e) => e.key == key);
      if (idx == -1) {
        entries.add(entry);
      } else {
        entries[idx] = entry;
      }
      entries.sort((a, b) => a.date.compareTo(b.date));
      entries.refresh();
      _markDailyCheckIfToday(entry);
    }
    _refreshSharing();
  }

  void _markDailyCheckIfToday(GoFlowEntry entry) {
    final now = DateTime.now();
    if (GoFlowEntry.keyFor(now) == entry.key) {
      DailyCheckService.to.markDoneToday(DailyCheckFeature.goflow);
    }
  }

  Future<void> _update(GoFlowSettings next) async {
    settings.value = next;
    settings.refresh();
    await _store.saveSettings(next);
    _refreshSharing();
  }

  Future<void> setCycleLength(int days) =>
      _update(settings.value.copyWith(avgCycleLength: days.clamp(15, 60)));

  Future<void> setPeriodLength(int days) =>
      _update(settings.value.copyWith(avgPeriodLength: days.clamp(1, 14)));

  Future<void> setLastPeriodStart(DateTime? day) => _update(day == null
      ? settings.value.copyWith(clearLastPeriodStart: true)
      : settings.value.copyWith(lastPeriodStart: day));

  Future<void> setModuleEnabled(bool on) =>
      _update(settings.value.copyWith(moduleEnabled: on));

  Future<void> setSharedWithFriends(bool on) =>
      _update(settings.value.copyWith(sharedWithFriends: on));

  Future<void> setCustomStatus(String? msg) => _update((msg == null ||
          msg.trim().isEmpty)
      ? settings.value.copyWith(clearCustomStatus: true)
      : settings.value.copyWith(customStatusMessage: msg.trim()));

  Future<void> setAccent(String? accentId) => _update(accentId == null
      ? settings.value.copyWith(clearAccent: true)
      : settings.value.copyWith(accentId: accentId));

  // ── Role / onboarding / partner ─────────────────────────────────────────────

  GoFlowRole get role => settings.value.role;
  bool get isPartner => role == GoFlowRole.partner;
  bool get onboarded => settings.value.onboarded;

  Future<void> setRole(GoFlowRole role) =>
      _update(settings.value.copyWith(role: role));

  Future<void> completeOnboarding() =>
      _update(settings.value.copyWith(onboarded: true));

  Future<void> setPartner(String? id, String? name) => _update(
      (id == null || id.isEmpty)
          ? settings.value.copyWith(clearPartner: true)
          : settings.value.copyWith(partnerId: id, partnerName: name));

  /// Finish the self-tracker questionnaire in one write (avoids several
  /// rebuilds).
  Future<void> setPerimenopauseMode(bool on) =>
      _update(settings.value.copyWith(perimenopauseMode: on));

  bool get perimenopauseMode => settings.value.perimenopauseMode;

  // ── Pregnancy mode ──────────────────────────────────────────────────────────

  bool get isPregnant =>
      settings.value.pregnancyMode && settings.value.pregnancyLmp != null;

  /// Start pregnancy mode from the last menstrual period date (gestational
  /// anchor).
  Future<void> startPregnancy(DateTime lmp) =>
      _update(settings.value.copyWith(pregnancyMode: true, pregnancyLmp: lmp));

  Future<void> endPregnancy() => _update(
      settings.value.copyWith(pregnancyMode: false, clearPregnancyLmp: true));

  Future<void> completeSelfOnboarding({
    required DateTime lastPeriodStart,
    required int cycleLength,
    required int periodLength,
  }) =>
      _update(settings.value.copyWith(
        role: GoFlowRole.self,
        lastPeriodStart: lastPeriodStart,
        avgCycleLength: cycleLength.clamp(15, 60),
        avgPeriodLength: periodLength.clamp(1, 14),
        onboarded: true,
      ));

  // ── Sharing ────────────────────────────────────────────────────────────────

  /// The stripped, shareable snapshot: current phase + optional custom status
  /// line. Never includes raw logs.
  GoFlowSummary buildSummary() {
    final now = DateTime.now();
    if (isPregnant) {
      final wk = GoFlowPregnancy.statusFrom(settings.value.pregnancyLmp!).week;
      return GoFlowSummary(
        customStatus: settings.value.customStatusMessage,
        pregnancyWeek: wk,
        updatedAtMs: now.millisecondsSinceEpoch,
      );
    }
    final s = status;
    return GoFlowSummary(
      phase: s.phase?.id,
      customStatus: settings.value.customStatusMessage,
      daysUntilPeriod: s.confidence == GoFlowConfidence.none
          ? null
          : s.daysUntilNext,
      fertileNow:
          s.confidence != GoFlowConfidence.none && s.isFertileOn(now),
      updatedAtMs: now.millisecondsSinceEpoch,
    );
  }

  /// Re-push the shared summary if this user shares GoFlow with anyone.
  void _refreshSharing() {
    if (!Get.isRegistered<SharingController>()) return;
    final sc = SharingController.to;
    if (sc.viewersFor('goflow').isNotEmpty) {
      sc.pushIfSharing(force: true);
    }
  }
}
