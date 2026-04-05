import 'dart:convert';

import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logger/logger.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/core/services/iap/premium_service.dart';
import 'package:spanx/core/user_info/user_info_controller.dart';
import 'package:spanx/features/subscriptions/model/subscription_model.dart';
import 'package:spanx/routes/app_routes.dart';

import '../../../core/network_caller/endpoints.dart';
import '../../../core/network_caller/network_config.dart';

class SubscriptionController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final logger = Logger();

  // IAP Integration
  final _premiumService = PremiumService.instance;
  final RxList<ProductDetails> iapProducts = <ProductDetails>[].obs;
  final RxBool useIAP = false.obs;
  final RxString selectedProductId = ''.obs;

  // Subscription Status
  final RxBool isSubscribed = false.obs;
  final Rxn<DateTime> subscriptionEndDate = Rxn<DateTime>();

  void selectedPlan(int i) {
    selectedIndex.value = i;
  }

  @override
  void onInit() {
    super.onInit();
    fetchSubscriptionPackages();
    _initializeIAP();
    checkUserSubscription();
  }

  String getPackageString(String package) {
    return switch (package) {
      "FREE" => "FREE",
      "MONTHLY" => "Month",
      "YEARLY" => "Year",
      _ => "None",
    };
  }

  final RxList<SubscriptionModel> subscriptionList =
      RxList<SubscriptionModel>();

  /// Initialize IAP and load products from Play Store
  Future<void> _initializeIAP() async {
    try {
      logger.i('🔄 Starting IAP initialization...');

      // Get user ID from UserInfoController
      final userInfoController = Get.find<UserInfoController>();
      final userId = userInfoController.userData.value?.id ?? '';

      logger.i('User ID from UserInfoController: $userId');

      final iapAvailable = await _premiumService.init(
        onStatusFromServer:
            ({required bool isPremium, required String? expiryTime}) async {
              logger.i(
                'Premium status updated - isPremium: $isPremium, expiryTime: $expiryTime',
              );
              if (isPremium) {
                AppSnackBar.show(
                  message: "Premium activated!",
                  isSuccessful: true,
                );
                await fetchSubscriptionPackages();
                Get.offAllNamed(AppRoutes.mainNavBarScreen);
              }
            },
        backendVerifyUrl: Urls.createSubscriptionPackages,
        packageName: 'com.goal.share',
        userId: userId,
        productIdList: const ['com.goal.monthly', 'com.goal.yearly'],
      );

      logger.i('IAP Available: $iapAvailable');
      logger.i('Products Loaded: ${_premiumService.products.length}');

      if (iapAvailable && _premiumService.products.isNotEmpty) {
        iapProducts.value = _premiumService.products;
        useIAP.value = true;
        logger.i('✓ Loaded ${iapProducts.length} IAP products');
        for (var product in iapProducts) {
          logger.i(
            '  Product: ${product.id} - ${product.title} (${product.price})',
          );
        }
      } else {
        logger.w('⚠️ IAP not available or no products found');
        logger.w('   Product IDs: [monthly, yearly]');
        logger.w('   Check Google Play Console configuration');
        useIAP.value = false;
      }
    } catch (e, st) {
      logger.e('❌ Error initializing IAP: $e\n$st');
      useIAP.value = false;
    }
  }

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
              .map((e) => SubscriptionModel.fromJson(e))
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

  /// Buy subscription via IAP
  Future<void> buySubscriptionIAP(String productId) async {
    try {
      isCreateSubscriptionLoading.value = true;
      selectedProductId.value = productId;

      final product = _premiumService.getProductById(productId);
      if (product == null) {
        AppSnackBar.show(message: "Product not found", isSuccessful: false);
        return;
      }

      await _premiumService.buyPremium();
    } catch (e) {
      logger.e('Error buying subscription: $e');
      AppSnackBar.show(
        message: "Purchase failed: ${e.toString()}",
        isSuccessful: false,
      );
    } finally {
      isCreateSubscriptionLoading.value = false;
    }
  }

  /// Check if user is already subscribed
  Future<void> checkUserSubscription() async {
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.getUserSubscription,
        jsonEncode({}),
        is_auth: true,
      );

      if (response != null && response['success'] == true) {
        final data = response['data'];

        if (data != null) {
          // Check if subscription end date is in the future
          final endDateStr = data['subscriptionEndDate'];
          if (endDateStr != null) {
            final endDate = DateTime.parse(endDateStr);
            subscriptionEndDate.value = endDate;

            final now = DateTime.now();
            isSubscribed.value = endDate.isAfter(now);

            logger.i('User subscription status:');
            logger.i('  - Is Subscribed: ${isSubscribed.value}');
            logger.i('  - End Date: $endDate');
            logger.i('  - Current Time: $now');
          }
        }
      }
    } catch (e) {
      logger.e("Error checking subscription: $e");
    }
  }

  /// Create subscription via API (fallback)
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
        AppSnackBar.show(message: "Subscription Added", isSuccessful: true);
        await checkUserSubscription();
        await fetchSubscriptionPackages();
        Get.offAllNamed(AppRoutes.mainNavBarScreen);
      } else {
        logger.e("create subscription failed -- ${response["message"]}");
        AppSnackBar.show(
          message: response?["message"] ?? "Failed to create subscription",
          isSuccessful: false,
        );
      }
    } catch (e) {
      logger.e("Creating Subscription Error: ${e.toString()}");
      AppSnackBar.show(message: "Error: ${e.toString()}", isSuccessful: false);
    } finally {
      isCreateSubscriptionLoading.value = false;
    }
  }

  /// Get IAP products formatted for UI
  List<Map<String, dynamic>> getDisplayPlans() {
    return iapProducts.map((product) {
      return {
        'id': product.id,
        'title': product.title,
        'description': product.description,
        'price': product.price,
        'priceAmount': product.rawPrice,
      };
    }).toList();
  }

  @override
  void onClose() {
    _premiumService.dispose();
    super.onClose();
  }
}
