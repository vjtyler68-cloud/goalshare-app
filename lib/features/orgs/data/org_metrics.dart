import 'package:get/get.dart';

import 'package:spanx/core/daily_checks/daily_check_service.dart';
import 'package:spanx/features/accountability/controller/buddies_controller.dart';
import 'package:spanx/features/goals/controller/goals_controller.dart';
import 'package:spanx/features/gratitude_journal/controller/journal_controller.dart';
import 'package:spanx/features/leads/controller/leads_controller.dart';
import 'package:spanx/features/nutrition/controller/nutrition_controller.dart';
import 'package:spanx/features/vision_board/controller/vision_controller.dart';

import '../controller/territory_metrics_controller.dart';
import 'org_models.dart';
import 'org_visibility.dart';

/// Builds the member's engagement summary — ONLY the fields the whitelist allows
/// for their org type. Reads whatever feature controllers are live; a feature
/// that isn't loaded simply contributes nothing (never blocks). Never reads raw
/// logs — only counts / booleans / streaks.
class OrgMetrics {
  OrgMetrics._();

  static Map<String, dynamic> build(OrgType orgType) {
    final all = _computeAll();
    final allowed = OrgVisibility.allowedKeys(orgType).toSet();
    final out = <String, dynamic>{};
    all.forEach((k, v) {
      if (allowed.contains(k) && v != null) out[k] = v;
    });
    return out;
  }

  static Map<String, dynamic> _computeAll() {
    final m = <String, dynamic>{};

    // RPM = goals.
    if (Get.isRegistered<GoalsController>()) {
      final g = Get.find<GoalsController>();
      m['rpm.goal_set'] = g.activeCount > 0;
      m['rpm.goal_completed'] = g.completedCount;
      m['rpm.quota_progress'] = (g.overallProgress * 100).round();
    }

    // Gratitude.
    if (Get.isRegistered<JournalController>()) {
      final j = Get.find<JournalController>();
      m['gratitude.streak_count'] = j.currentStreak;
      m['gratitude.entries_logged_count'] = j.totalEntries;
    }

    // Daily Spark viewed today.
    if (Get.isRegistered<DailyCheckService>()) {
      m['daily_spark.viewed_today'] =
          DailyCheckService.to.isDoneToday(DailyCheckFeature.dailySpark);
    }

    // Vision board created (boolean only — never image content).
    if (Get.isRegistered<VisionBoardController>()) {
      m['vision_board.created'] =
          Get.find<VisionBoardController>().visionBoardItems.isNotEmpty;
    }

    // Leads (sales).
    if (Get.isRegistered<LeadsController>()) {
      final leads = Get.find<LeadsController>().leads;
      final total = leads.length;
      final won = leads.where((l) => l.status == 'Won').length;
      final active = leads
          .where((l) => l.status != 'Won' && l.status != 'Lost')
          .length;
      m['leads.count'] = total;
      m['leads.conversion_rate'] =
          total > 0 ? ((won / total) * 100).round() : 0;
      m['leads.pipeline_stage'] = active;
    }

    // Nutrition (gym) — counts/booleans only, never meal contents.
    if (Get.isRegistered<NutritionController>()) {
      final n = Get.find<NutritionController>();
      m['nutrition.logged_today'] = n.hasLoggedToday;
      final goal = n.proteinGoal;
      m['nutrition.protein_target_met'] =
          n.isProteinMode && goal != null && n.proteinToday >= goal;
    }

    // Accountability buddy check-in streak.
    if (Get.isRegistered<BuddiesController>()) {
      m['accountability_buddies.checkin_streak'] =
          Get.find<BuddiesController>().ourStreak.value;
    }

    // Territory door-knocking activity (sales) — today's counts. Read via the
    // controller (registered in bindings) so a rep's tally rolls up to the org
    // even if they haven't opened the map this session.
    if (Get.isRegistered<TerritoryMetricsController>()) {
      final t = TerritoryMetricsController.to;
      m['territory.doors_today'] = t.doors.value;
      m['territory.talked_today'] = t.talked.value;
      m['territory.bills_today'] = t.bills.value;
    }

    return m;
  }
}
