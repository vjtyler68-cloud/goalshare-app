import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/features/analytics_tab/model/report_analysis_model.dart' hide RecentActivity, GoalTrend, CategoryDistribution;
import '../model/analytics_model.dart';

class AnalyticsController extends GetxController {

  // ================== API ===============================
  // Whole model
  final Rxn<AnalyticsModel> analyticsModel = Rxn<AnalyticsModel>();

  // Separate useful fields for easier access (optional)
  final RxInt totalClients = 0.obs;
  final RxInt salesPercent = 0.obs;
  final RxInt totalTimeSpent = 0.obs;

  final RxList<RecentActivity> recentActivities = <RecentActivity>[].obs;
  final RxList<GoalTrend> goalTrends = <GoalTrend>[].obs;
  final RxList<CategoryDistribution> categoryDistributions = <CategoryDistribution>[].obs;

  final RxInt target = 0.obs;
  final RxInt completed = 0.obs;

  Future<void> fetchReportAnalysis() async {
    final response = await NetworkConfig.instance.ApiRequestHandler(
      RequestMethod.GET,
      Urls.getUserReportAnalytics,
      jsonEncode({}),
      is_auth: true,
    );

    if (response != null && response['success'] == true) {
      final data = response['data'];
      final AnalyticsModel model = AnalyticsModel.fromJson(data);

      analyticsModel.value = model;

      /// Optionally map useful sub-parts for UI access

      // Progress
      totalClients.value = model.progress?.totalClients ?? 0;
      salesPercent.value = model.progress?.salesPercent ?? 0;
      totalTimeSpent.value = model.progress?.totalTimeSpent ?? 0;

      // Goal Trend
      goalTrends.assignAll(model.goalTrend ?? []);

      // Category Distribution
      categoryDistributions.assignAll(model.categoryDistribution ?? []);

      // Recent Activities
      recentActivities.assignAll(model.recentActivity ?? []);

      // Performance (specific week key - 2025-W40)
      final perf = model.performance?.the2025W40;
      if (perf != null) {
        target.value = perf.target ?? 0;
        completed.value = perf.completed ?? 0;
      }
    }
  }
  // =======================================================

  // Observable variables
  final RxBool isLoading = false.obs;
  final Rx<AnalyticsData?> analyticsData = Rx<AnalyticsData?>(null);

  // Chart animation controllers
  final RxDouble animationValue = 0.0.obs;

  // Selected time period
  final RxString selectedTimePeriod = 'This Month'.obs;
  final List<String> timePeriods = [
    'This Week',
    'This Month',
    'This Quarter',
    'This Year',
  ];

  @override
  void onInit() {
    super.onInit();
    loadAnalyticsData();
    _startAnimation();
    // fetchReportAnalysis();
  }

  void _startAnimation() {
    // Animate charts with a smooth transition
    Future.delayed(const Duration(milliseconds: 300), () {
      animationValue.value = 1.0;
    });
  }

  void loadAnalyticsData() {
    isLoading.value = true;

    // Simulate API call delay
    Future.delayed(const Duration(milliseconds: 800), () {
      analyticsData.value = AnalyticsDummyData.generateDummyData();
      isLoading.value = false;
    });
  }

  void refreshData() {
    animationValue.value = 0.0;
    loadAnalyticsData();
    _startAnimation();
  }

  void onTimePeriodChanged(String period) {
    selectedTimePeriod.value = period;
    refreshData();
  }

  void onBackPressed() {
    Get.back();
  }

  // Helper methods for chart colors
  Color getProgressColor(String category) {
    switch (category) {
      case 'Completed':
        return const Color(0xFFFF6B6B);
      case 'In Progress':
        return const Color(0xFF4ECDC4);
      case 'Pending':
        return const Color(0xFF45B7D1);
      case 'On Hold':
        return const Color(0xFFFFA726);
      default:
        return Colors.grey;
    }
  }

  // Calculate progress percentage
  double get overallProgress {
    if (analyticsData.value == null) return 0.0;

    final completed = analyticsData.value!.progressDistribution
        .firstWhere(
          (item) => item.category == 'Completed',
          orElse: () => ProgressDistributionData('', 0, ''),
        )
        .percentage;

    return completed;
  }

  // Get formatted currency
  String getFormattedCurrency(double amount) {
    if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '\$${amount.toStringAsFixed(0)}';
  }

  // Get trend direction
  bool isUpTrend() {
    if (analyticsData.value == null ||
        analyticsData.value!.salesTrend.length < 2) {
      return true;
    }

    final lastTwo = analyticsData.value!.salesTrend.toList();
    return lastTwo[1].value > lastTwo[0].value;
  }

  // Calculate goal completion percentage
  double get goalCompletionPercentage {
    if (analyticsData.value == null) return 0.0;

    double totalCompleted = 0;
    double totalGoals = 0;

    for (var item in analyticsData.value!.goalTrend) {
      totalCompleted += item.completed;
      totalGoals += item.completed + item.pending;
    }

    return totalGoals > 0 ? (totalCompleted / totalGoals) * 100 : 0.0;
  }
}
