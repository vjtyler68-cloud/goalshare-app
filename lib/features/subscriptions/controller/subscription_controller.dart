import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:spanx/features/subscriptions/model/subscription_model.dart';

import '../../../core/network_caller/endpoints.dart';
import '../../../core/network_caller/network_config.dart';

class SubscriptionController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  final RxBool isLoading = false.obs;

  void selectedPlan(int i) {
    selectedIndex.value = i;
  }

  @override
  void onInit() {
    super.onInit();
    fetchSubscriptionPackages();
  }

  String getPackageString(String package) {
    return switch (package) {
      "FREE" => "FREE",
      "MONTHLY" => "Month",
      "YEARLY" => "Year",
      _ => "None",
    };
  }

  final RxList<SubscriptionScreenModel> subscriptionList =
      RxList<SubscriptionScreenModel>();

  Future<void> fetchSubscriptionPackages() async {
    try {
      isLoading.value = true;
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.getSubscriptionPackages,
        jsonEncode({}),
        is_auth: true,
      );
      if (response != null && response['success'] == true) {
        subscriptionList.assignAll(
          (response['data'] as List)
              .map((e) => SubscriptionScreenModel.fromJson(e))
              .toList(),
        );
      } else {
        log("get subscription failed -- ${response["message"]}");
      }
    } catch (e) {
      log("Fetching Subscription Error: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }
}
