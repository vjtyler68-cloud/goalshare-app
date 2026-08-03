import 'dart:convert';
import 'dart:developer';

import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';

import 'shared_summary.dart';

/// Best-effort backend client for buddy sharing. Failures are swallowed so the
/// settings screen stays responsive offline; the grants themselves are also
/// mirrored locally.
class SharingApi {
  SharingApi._();
  static final SharingApi instance = SharingApi._();

  /// Push my grant lists + latest summaries. The backend only ever returns a
  /// section to a viewer who is on the matching grant list.
  Future<void> upsertSettings({
    required List<String> nutritionViewerIds,
    required List<String> workoutViewerIds,
    Map<String, dynamic>? nutritionSummary,
    Map<String, dynamic>? workoutSummary,
  }) async {
    try {
      await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.sharingSettings,
        jsonEncode({
          'nutritionViewerIds': nutritionViewerIds,
          'workoutViewerIds': workoutViewerIds,
          'nutritionSummary': nutritionSummary,
          'workoutSummary': workoutSummary,
        }),
        is_auth: true,
      );
    } catch (e) {
      log('SharingApi.upsertSettings: $e');
    }
  }

  /// Fetch the summary sections [userId] has granted the current user (either
  /// may be absent). Returns an empty [SharedStats] on any failure.
  Future<SharedStats> getSummaryFor(String userId) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.sharingSummary(userId),
        jsonEncode({}),
        is_auth: true,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        return SharedStats.fromJson(
            Map<String, dynamic>.from(res['data'] as Map));
      }
    } catch (e) {
      log('SharingApi.getSummaryFor: $e');
    }
    return const SharedStats();
  }
}
