import 'dart:convert';

import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/features/subscriptions/model/subscription_model.dart';
import 'package:spanx/routes/app_routes.dart';

import '../../../core/network_caller/endpoints.dart';
import '../../../core/network_caller/network_config.dart';

class SubscriptionController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final logger = Logger();

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
        logger.d("get subscription failed -- ${response["message"]}");
      }
    } catch (e) {
      logger.e("Fetching Subscription Error: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  final RxBool isCreateSubscriptionLoading = false.obs;

  Future<void> createSubscriptionPackages(String subscriptionID) async {
    try {
      isCreateSubscriptionLoading.value = true;
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.createSubscriptionPackages,
        jsonEncode({"subscriptionId": subscriptionID}),
        is_auth: true,
      );
      if (response != null && response['success'] == true) {
        AppSnackbar.show(message: "Subscription Added", isSuccess: true);
        fetchSubscriptionPackages();
        Get.offAllNamed(AppRoutes.mainNavBarScreen);
      } else {
        logger.e("create subscription failed -- ${response["message"]}");
      }
    } catch (e) {
      logger.e("Fetching Subscription Error: ${e.toString()}");
    } finally {
      isCreateSubscriptionLoading.value = false;
    }
  }
}
