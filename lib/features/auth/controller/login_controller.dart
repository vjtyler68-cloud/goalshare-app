import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/core/notifications/push_notification_service.dart';
import 'package:spanx/core/user_info/user_info_controller.dart';
import 'package:spanx/core/utils/test_accounts.dart';
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

        if (response['data'] == '' || response['data'] == null) {
          Get.offNamed(
            AppRoutes.applyCodeScreen,
            arguments: {'email': emailController.text},
          );
          return;
        }

        final data = response['data'] as Map<String, dynamic>;
        token.value = data['accessToken'] as String?;
        userID.value = data['id'] as String?;
        final isDeleted = data['isDeleted'] as bool? ?? false;
        final String role = data['role'] as String? ?? '';
        final String accountEmail = (data['email'] as String?) ?? email;

        // NEW response shape:
        final String? subscriptionId = data['subscription'] as String?;
        final String? subscriptionEndDate =
            data['subscriptionEndDate'] as String?;

        if (isDeleted) {
          AppSnackBar.error('Your account has been deleted.');
          return;
        }

        // clear inputs
        emailController.clear();
        passwordController.clear();

        // route
        _routeAfterLogin(
          role: role,
          email: accountEmail,
          subscriptionId: subscriptionId,
          subscriptionEndDate: subscriptionEndDate,
        );
      } else {
        final message = response != null && response['message'] != null
            ? response['message'].toString()
            : 'User info is not correct';
        log('Login failed: $message');
        // Most common tester mistake: signing in before registering — the
        // backend returns "user not found". Give a clear next step instead.
        if (message.toLowerCase().contains('not found')) {
          AppSnackBar.error(
              'No account found for that email. Tap "Create New Account" below to sign up first.');
        } else {
          AppSnackBar.error(message);
        }
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
    // Active if the subscription END DATE is in the future — do NOT require the
    // `subscription` object/id to be non-null. Granted/test-mode subscriptions
    // (and the App Store's own records right after purchase) set only the end
    // date, with the subscription object null; requiring the id here was
    // sending every otherwise-valid user to the paywall — only ADMIN got in.
    return !isSubscriptionExpired(endDateString);
  }

  void _routeAfterLogin({
    required String role,
    required String email,
    required String? subscriptionId,
    required String? subscriptionEndDate,
  }) async {
    if (token.value != null) await localService.setToken(token.value!);
    if (userID.value != null) await localService.setUserId(userID.value!);

    // Now that we have a session + user id, register this device for push
    // notifications (friend requests/accepts + new messages). Best-effort.
    PushNotificationService.instance.registerToken();

    // Load THIS account's profile fresh. UserInfoController is a long-lived
    // singleton, so without an explicit refresh a newly logged-in account keeps
    // showing the previously logged-in user's cached profile (the "logged in as
    // a new account but saw the admin" bug).
    try {
      final userInfo = Get.isRegistered<UserInfoController>()
          ? Get.find<UserInfoController>()
          : Get.put(UserInfoController(), permanent: true);
      await userInfo.refreshUserData();
    } catch (e) {
      log('refresh user info after login failed: $e');
    }

    // Admins and whitelisted test accounts always go straight to the app —
    // no subscription required
    if (role == 'ADMIN' || isTestAccount(email)) {
      AppSnackBar.success('Welcome back!');
      Get.offNamed(AppRoutes.mainNavBarScreen);
      return;
    }

    if (hasActiveSubscription(subscriptionId, subscriptionEndDate)) {
      AppSnackBar.success('Login successful');
      Get.offNamed(AppRoutes.mainNavBarScreen);
    } else {
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
