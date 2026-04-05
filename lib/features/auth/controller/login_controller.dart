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
  final Rxn<String> token = Rxn<String>();
  final Rxn<String> userID = Rxn<String>();

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

  bool isEmailValid(String email) {
    final RegExp emailRegex = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    );
    return emailRegex.hasMatch(email);
  }

  Future<void> handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    // Email validation
    if (email.isEmpty) {
      AppSnackBar.error('Email is required');
      return;
    }

    if (!isEmailValid(email)) {
      AppSnackBar.error('Please enter a valid email address');
      return;
    }

    // Password validation
    if (password.isEmpty) {
      AppSnackBar.error('Password is required');
      return;
    }

    isLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.login,
        jsonEncode({'email': email, 'password': password}),
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
        token.value = data['accessToken'] as String?;
        userID.value = data['id'] as String?;
        final isApproved = data['isApproved'] as bool? ?? false;
        final isDeleted = data['isDeleted'] as bool? ?? false;

        // NEW response shape:
        final String? subscriptionId = data['subscription'] as String?;
        final String? subscriptionEndDate =
            data['subscriptionEndDate'] as String?;

        if (isDeleted) {
          AppSnackBar.error('Your account has been deleted.');
          return; // stop here
        }

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
        AppSnackBar.error(message);
      }
    } catch (e) {
      logger.e('Login error ${e.toString()}');
      AppSnackBar.error('Something went wrong. Please try again.');
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
  }) async {
    if (!isApproved) {
      Get.offNamed(AppRoutes.pendingUser);
      return;
    }

    if (hasActiveSubscription(subscriptionId, subscriptionEndDate)) {
      // persist token + user id so subscription page can still use them if needed
      if (token.value != null) await localService.setToken(token.value!);
      if (userID.value != null) await localService.setUserId(userID.value!);
      AppSnackBar.success('Login successful');
      Get.offNamed(AppRoutes.mainNavBarScreen);
    } else {
      // no sub OR expired → go to subscribe flow
      AppSnackBar.error('Please subscribe to continue');

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
