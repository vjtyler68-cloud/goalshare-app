import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/features/analytics_tab/model/report_analysis_model.dart';

class ReportAnalysisController extends GetxController {
  final Rxn<SummaryAllTime> reportSummary = Rxn<SummaryAllTime>();

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
      if(response != null && response['success']==true){
        reportSummary.value = SummaryAllTime.fromJson(response['data']['summaryAllTime']);
      }
    } catch (e) {
      log('Fetch Report Analysis Error: ${e.toString()}');
    } finally {}
  }
}
