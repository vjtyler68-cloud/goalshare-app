import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/features/analytics_tab/model/report_analysis_model.dart';

class ReportAnalysisController extends GetxController {
  final Rxn<SummaryAllTime> reportSummary = Rxn<SummaryAllTime>();
  final Rxn<GoalTrend> reportMissionTrend = Rxn<GoalTrend>();
  final Rxn<Month> reportMonth = Rxn<Month>(); // ✅
  final RxList<CategoryDistribution> categoryDistribution = RxList<CategoryDistribution>(); // ✅
  final RxList<RecentActivity> recentActivity = RxList<RecentActivity>(); // optional

  @override
  void onInit() {
    super.onInit();
    fetchReportAnalytics();
  }

  Future<void> fetchReportAnalytics() async {
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.getUserReportAnalytics,
        jsonEncode({}),
        is_auth: true,
      );

      if (response != null && response['success'] == true) {
        final data = response['data'];

        // ✅ Fix: parse from correct keys
        reportSummary.value = SummaryAllTime.fromJson(data['summaryAllTime']);
        reportMissionTrend.value = GoalTrend.fromJson(data['goalTrend']); // 🔄 was wrong before
        reportMonth.value = Month.fromJson(data['month']); // ✅

        // ✅ Parse categoryDistribution
        categoryDistribution.assignAll(
          (data['categoryDistribution'] as List?)
              ?.map((e) => CategoryDistribution.fromJson(e as Map<String, dynamic>))
              .toList() ??
              [],
        );

        // Optional: recentActivity
        recentActivity.assignAll(
          (data['recentActivity'] as List?)
              ?.map((e) => RecentActivity.fromJson(e as Map<String, dynamic>))
              .toList() ??
              [],
        );
      }
    } catch (e) {
      log('Fetch Report Analysis Error: ${e.toString()}');
    }
  }
}