import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/features/motivationalNudges/model/motivational_nudges_model.dart';

class MotivationalNudgesController extends GetxController {
  final RxList<MotivationalNudgesModel> motivationNudgesList =
      <MotivationalNudgesModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMotivationalNudges();
  }

  Future<void> fetchMotivationalNudges() async {
    isLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.motivationalNudges,
        jsonEncode({}),
        is_auth: true,
      );

      if (response != null && response['success'] == true) {
        motivationNudgesList.assignAll(
          (response['data'] as List)
              .map((e) => MotivationalNudgesModel.fromJson(e)),
        );
      }
    } catch (e) {
      log('fetchMotivationalNudges error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteMotivation(String motivationID) async {
    final index =
        motivationNudgesList.indexWhere((e) => e.id == motivationID);
    if (index == -1) return;

    final removed = motivationNudgesList[index];
    motivationNudgesList.removeAt(index);

    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.DELETE,
        '${Urls.deleteMotivationalNudges}/$motivationID',
        jsonEncode({}),
        is_auth: true,
      );

      if (response != null && response['success'] == true) {
        AppSnackBar.success(response['message'] ?? 'Motivation deleted');
      } else {
        motivationNudgesList.insert(index, removed);
        AppSnackBar.error(response?['message'] ?? 'Delete failed');
      }
    } catch (e) {
      log('deleteMotivation error: $e');
      motivationNudgesList.insert(index, removed);
      AppSnackBar.error('Something went wrong. Please try again.');
    }
  }
}
