import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:spanx/features/motivationalNudges/model/motivational_nudges_model.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/network_caller/endpoints.dart';
import '../../../core/network_caller/network_config.dart';

class MotivationalNudgesController extends GetxController {
  final RxList<MotivationalNudgesModel> motivationNudgesList =
      <MotivationalNudgesModel>[].obs;
  final RxBool isLoading = false.obs;

  // bool hasFetched = false;

  @override
  void onInit() {
    super.onInit();
    fetchMotivationalNudges();
    // if (!hasFetched) {
    //   fetchMotivationalNudges();
    // }
  }

  Future<void> fetchMotivationalNudges() async {
    isLoading.value = true;
    final response = await NetworkConfig.instance.ApiRequestHandler(
      RequestMethod.GET,
      Urls.motivationalNudges,
      jsonEncode({}),
      is_auth: true,
    );

    try {
      if (response != null && response['success'] == true) {
        motivationNudgesList.assignAll(
          (response['data'] as List).map(
            (e) => MotivationalNudgesModel.fromJson(e),
          ),
        );
        // hasFetched = true;
      }

      isLoading.value = false;
    } catch (e) {
      log("Motivational Nudges fetch error: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  // ============ delete ====
  Future<void> deleteMotivation(String motivationID) async {
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.DELETE,
        "${Urls.deleteMotivationalNudges}/$motivationID",
        jsonEncode({}),
        is_auth: true,
      );

      if (response != null && response['success'] == true) {
        log("DELETE SUCCESSFUL------:");
        fetchMotivationalNudges();
        Get.snackbar(
          'Success',
          '${response['message']}',
          colorText: AppColors.blackColor,
          backgroundColor: AppColors.greenColor,
        );
      }
    } catch (e) {
      log("DELETE ERROR: ${e.toString()}");
    }
  }

  // random quote generate



}
