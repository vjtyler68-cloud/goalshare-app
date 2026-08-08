import 'package:get/get.dart';

import 'package:spanx/features/nutrition/controller/nutrition_controller.dart';
import 'package:spanx/features/workout/controller/workout_controller.dart';
import 'package:spanx/features/goflow/controller/goflow_controller.dart';
import 'package:spanx/features/goflow/data/goflow_summary.dart';

import '../data/shared_summary.dart';
import '../data/sharing_api.dart';
import '../data/sharing_store.dart';

/// Owns buddy-sharing: which friends I've granted a view of my nutrition and/or
/// workout, and the summaries pushed to the backend for them. Default is fully
/// private — nothing syncs until I grant someone.
class SharingController extends GetxController {
  static SharingController get to => Get.isRegistered<SharingController>()
      ? Get.find<SharingController>()
      : Get.put(SharingController(), permanent: true);

  final SharingStore _store = SharingStore();

  /// friendId → {'nutrition': bool, 'workout': bool}
  final RxMap<String, Map<String, bool>> grants =
      <String, Map<String, bool>>{}.obs;
  final RxBool ready = false.obs;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    await _store.open();
    grants.assignAll(_store.load());
    ready.value = true;
    // Refresh what I already share on launch, but don't spin up the nutrition/
    // workout controllers just for this — only build from ones already live.
    if (_hasAnyGrant) pushIfSharing();
  }

  bool get _hasAnyGrant => grants.values
      .any((g) => g['nutrition'] == true || g['workout'] == true);

  bool isSharing(String friendId, String category) =>
      grants[friendId]?[category] == true;

  List<String> viewersFor(String category) => [
        for (final e in grants.entries)
          if (e.value[category] == true) e.key,
      ];

  /// Grant or revoke one category for one friend, persist, and re-push.
  Future<void> setGrant(String friendId, String category, bool value) async {
    final current = Map<String, bool>.from(
        grants[friendId] ?? {'nutrition': false, 'workout': false});
    current[category] = value;
    if (current['nutrition'] != true && current['workout'] != true) {
      grants.remove(friendId); // fully private → drop the entry
    } else {
      grants[friendId] = current;
    }
    grants.refresh();
    await _store.save(Map<String, Map<String, bool>>.from(grants));
    await pushIfSharing(force: true);
  }

  /// Build my current summaries + viewer lists and push them. When [force] is
  /// false, a section is only built if its controller is already registered
  /// (keeps app launch cheap); the settings screen calls it with force = true.
  Future<void> pushIfSharing({bool force = false}) async {
    final nViewers = viewersFor('nutrition');
    final wViewers = viewersFor('workout');
    final gViewers = viewersFor('goflow');
    final nSummary = nViewers.isEmpty ? null : _buildNutrition(force);
    final wSummary = wViewers.isEmpty ? null : _buildWorkout(force);
    final gSummary = gViewers.isEmpty ? null : _buildGoFlow(force);
    await SharingApi.instance.upsertSettings(
      nutritionViewerIds: nViewers,
      workoutViewerIds: wViewers,
      goflowViewerIds: gViewers,
      nutritionSummary: nSummary?.toJson(),
      workoutSummary: wSummary?.toJson(),
      goflowSummary: gSummary?.toJson(),
    );
  }

  /// GoFlow shares only a stripped summary (phase + optional custom line),
  /// never raw logs. Built only if the module is live (or forced).
  GoFlowSummary? _buildGoFlow(bool force) {
    if (!force && !Get.isRegistered<GoFlowController>()) return null;
    if (!Get.isRegistered<GoFlowController>()) return null;
    return GoFlowController.to.buildSummary();
  }

  NutritionSummary? _buildNutrition(bool force) {
    if (!force && !Get.isRegistered<NutritionController>()) return null;
    final n = NutritionController.to;
    return NutritionSummary(
      calories: n.todayFoodCalories.round(),
      calorieBudget: n.budget,
      protein: n.proteinToday.round(),
      carbs: n.carbsToday.round(),
      fat: n.fatToday.round(),
      proteinGoal: n.proteinGoal,
      trackingMode: n.trackingMode,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  WorkoutSummary? _buildWorkout(bool force) {
    if (!force && !Get.isRegistered<WorkoutController>()) return null;
    final w = WorkoutController.to;
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    var count = 0;
    DateTime? last;
    var lastLabel = '';
    for (final s in w.history) {
      final d = DateTime.fromMillisecondsSinceEpoch(s.startedAtMs);
      if (d.isAfter(weekAgo)) count++;
      if (last == null || d.isAfter(last)) {
        last = d;
        lastLabel = 'Workout';
      }
    }
    for (final r in w.runs) {
      final d = r.startedAt;
      if (d.isAfter(weekAgo)) count++;
      if (last == null || d.isAfter(last)) {
        last = d;
        lastLabel = r.timeOfDayTitle;
      }
    }
    int? daysAgo;
    if (last != null) {
      daysAgo = DateTime(now.year, now.month, now.day)
          .difference(DateTime(last.year, last.month, last.day))
          .inDays;
    }
    return WorkoutSummary(
      currentStreak: w.streak.value.current,
      workoutsThisWeek: count,
      lastActivity: lastLabel,
      lastActivityDaysAgo: daysAgo,
      updatedAtMs: now.millisecondsSinceEpoch,
    );
  }

  /// Viewer side: what does [userId] share with me? (Either section may be null.)
  Future<SharedStats> statsFor(String userId) =>
      SharingApi.instance.getSummaryFor(userId);
}
