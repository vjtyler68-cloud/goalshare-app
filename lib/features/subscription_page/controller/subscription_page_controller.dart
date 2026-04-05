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

      log("📊 SubscriptionPage API Response: $response");

      if (response != null && response['success'] == true) {
        final data = response['data'];
        log("📊 Response Data: $data");
        log("📊 Response Data Type: ${data.runtimeType}");
        log("📊 Response Data Keys: ${(data as Map?)?.keys.toList()}");

        // Check if user has subscription data
        if (data is Map && data.isNotEmpty) {
          log("📊 Data is Map and not empty. All keys: ${data.keys.toList()}");

          // Check if subscription is nested inside a 'subscription' object
          Map<String, dynamic> subscriptionMap = {};
          if (data.containsKey('subscription') && data['subscription'] is Map) {
            log("📊 Found nested 'subscription' object. Using that instead.");
            subscriptionMap = Map<String, dynamic>.from(data['subscription']);
          } else {
            subscriptionMap = Map<String, dynamic>.from(data);
          }

          // Check if user has an active subscription
          final hasPlan = data['hasPlan'] ?? false;
          log("📊 hasPlan: $hasPlan");

          if (hasPlan && subscriptionMap.isNotEmpty) {
            // Support multiple possible key name variations
            final startDateKey = _findKey(subscriptionMap, [
              'subscriptionStart',
              'startDate',
              'start_date',
              'subscriptionStartDate',
            ]);
            final endDateKey = _findKey(subscriptionMap, [
              'subscriptionEnd',
              'endDate',
              'end_date',
              'subscriptionEndDate',
            ]);

            log("📊 StartDateKey found: $startDateKey");
            log("📊 EndDateKey found: $endDateKey");

            if (startDateKey != null && endDateKey != null) {
              // User has an active/inactive subscription
              final startDateValue = subscriptionMap[startDateKey];
              final endDateValue = subscriptionMap[endDateKey];
              final idValue =
                  data['subscriptionId'] ??
                  subscriptionMap['subscriptionId'] ??
                  data['id'] ??
                  'com.goal.monthly';

              log(
                "📊 Subscription values - ID: $idValue, Start: $startDateValue, End: $endDateValue",
              );

              final subscriptionData = {
                'id': idValue,
                'startDate': startDateValue,
                'endDate': endDateValue,
                'title':
                    data['title'] ??
                    subscriptionMap['title'] ??
                    data['planName'] ??
                    'Premium Plan',
                'type': data['type'] ?? subscriptionMap['type'] ?? 'monthly',
                'remainingDays': subscriptionMap['remainingDays'],
              };

              subsModel.value = SubscriptionPageModel.fromJson(
                subscriptionData,
              );
              log(
                "✅ Subscription found and parsed: ID = ${subsModel.value?.id}",
              );
              log(
                "✅ Final Model - ID: ${subsModel.value?.id}, StartDate: ${subsModel.value?.startDate}, EndDate: ${subsModel.value?.endDate}",
              );
            } else {
              // No subscription found
              subsModel.value = SubscriptionPageModel.empty();
              log(
                "⚠️ No subscription date fields found. Available keys: ${subscriptionMap.keys.toList()}",
              );
            }
          } else {
            // No subscription found
            subsModel.value = SubscriptionPageModel.empty();
            log("⚠️ hasPlan is false or subscription map is empty");
          }
        } else {
          // No subscription found
          subsModel.value = SubscriptionPageModel.empty();
          log("⚠️ No subscription data found in response");
        }
      } else {
        log("❌ API failed: ${response?["message"]}");
        subsModel.value = SubscriptionPageModel.empty();
      }
    } catch (e, st) {
      log("❌ Subscription Error: $e\n$st");
      subsModel.value = SubscriptionPageModel.empty();
    } finally {
      isSubLoading.value = false;
    }
  }

  // ========= helper method ==============
  String? _findKey(Map data, List<String> possibleKeys) {
    for (String key in possibleKeys) {
      if (data.containsKey(key)) {
        return key;
      }
    }
    return null;
  }

  // ========= date format ==============
  String formatDate(String isoDateString) {
    final DateTime dateTime = DateTime.parse(isoDateString);
    final DateFormat formatter = DateFormat('dd/MM/yyyy, hh:mm a');
    return formatter.format(dateTime);
  }

  int remainingDays() {
    final DateTime time = DateTime.now();
    final diff = subsModel.value?.endDate?.difference(time);
    return diff?.inDays ?? 0;
  }
}
