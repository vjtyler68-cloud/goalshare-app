import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/features/subscription_page/model/subscription_page_model.dart';

class SubscriptionPageController extends GetxController {
  final RxBool isSubLoading = false.obs;
  Rxn<SubscriptionPageModel> subsModel = Rxn<SubscriptionPageModel>();

  @override
  void onInit() {
    super.onInit();
    fetchSubscriptionInfo();
  }

  // ========= api ==============
  Future<void> fetchSubscriptionInfo() async {
    isSubLoading.value = true;

    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.getUserSubscription,
        jsonEncode({}),
        is_auth: true,
      );
      if (response != null && response['success'] == true) {
        subsModel.value = SubscriptionPageModel.fromJson(
          response['data']['subscription'],
        );
      }else{
        log("get subscription failed -- ${response["message"]}");
      }
    } catch (e) {
      log("Subscription Error: ${e.toString()}");
    } finally {
      isSubLoading.value = false;
    }
  }

  // ========= date format ==============
  String formatDate(String isoDateString) {
    final DateTime dateTime = DateTime.parse(isoDateString);
    final DateFormat formatter = DateFormat('dd MMMM yyyy');
    return formatter.format(dateTime);
  }
}
