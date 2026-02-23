import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import 'package:logger/logger.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/routes/app_routes.dart';

class LoginController extends GetxController {
  final logger = Logger();
  final RxBool isPasswordVisible = false.obs;

  TextEditingController passwordController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  // final userInfoController = Get.put(UserInfoController());
  final LocalService localService = LocalService();

  void makePasswordVisible() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  final RxBool isLoading = false.obs;

  // @override
  // void onInit() {
  //   super.onInit();
  // }

  Future<void> handleLogin() async {
    isLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.login,
        jsonEncode({
          'email': emailController.text.trim(),
          'password': passwordController.text,
        }),
        is_auth: false,
      );

      if (response != null && response['success'] == true) {
        logger.t('Login Successful');

        if (response['success'] == true && response['data'] == '') {
          Get.offNamed(
            AppRoutes.applyCodeScreen,
            arguments: {'email': emailController.text},
          );
        }

        final data = response['data'] as Map<String, dynamic>;
        final token = data['accessToken'] as String?;
        final userID = data['id'] as String?;
        final isApproved = data['isApproved'] as bool? ?? false;
        final isDeleted = data['isDeleted'] as bool? ?? false;

        // NEW response shape:
        final String? subscriptionId = data['subscription'] as String?;
        final String? subscriptionEndDate =
            data['subscriptionEndDate'] as String?;

        if (isDeleted) {
          AppSnackbar.show(
            message: 'Your account has been deleted.',
            isSuccess: false,
          );
          return; // stop here
        }

        // persist token + user id so subscription page can still use them if needed
        if (token != null) await localService.setToken(token);
        if (userID != null) await localService.setUserId(userID);

        // clear inputs
        emailController.clear();
        passwordController.clear();

        // route
        _routeAfterLogin(
          isApproved: isApproved,
          subscriptionId: subscriptionId,
          subscriptionEndDate: subscriptionEndDate,
        );
      } else {
        final message = response != null && response['message'] != null
            ? response['message']
            : 'User info is not correct';
        log('Login failed: $message');
        AppSnackbar.show(message: message, isSuccess: false);
      }
    } catch (e) {
      logger.e('Login error ${e.toString()}');
      AppSnackbar.show(
        message: 'Something went wrong. Please try again.',
        isSuccess: false,
      );
    } finally {
      isLoading.value = false;
    }
  }

  bool isUserSubscribed(Map<String, dynamic>? subscription) {
    return subscription != null;
  }

  bool isSubscriptionExpired(String? endDateString) {
    if (endDateString == null || endDateString.isEmpty)
      return true; // missing = expired
    try {
      final endDate = DateTime.parse(endDateString).toLocal();
      return DateTime.now().isAfter(endDate);
    } catch (_) {
      return true; // parse fail = treat as expired
    }
  }

  bool hasActiveSubscription(String? subscriptionId, String? endDateString) {
    if (subscriptionId == null) return false;
    if (isSubscriptionExpired(endDateString)) return false;
    return true;
  }

  void _routeAfterLogin({
    required bool isApproved,
    required String? subscriptionId,
    required String? subscriptionEndDate,
  }) {
    if (!isApproved) {
      Get.offNamed(AppRoutes.pendingUser);
      return;
    }

    if (hasActiveSubscription(subscriptionId, subscriptionEndDate)) {
      AppSnackbar.show(message: 'Login successful', isSuccess: true);
      Get.offNamed(AppRoutes.mainNavBarScreen);
    } else {
      // no sub OR expired → go to subscribe flow
      AppSnackbar.show(
        message: 'Please subscribe to continue',
        isSuccess: false,
      );
      Get.offNamed(AppRoutes.subscriptionScreen);
    }
  }

  bool isInfoCompleted() {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      return false;
    }
    return true;
  }
}
