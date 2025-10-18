import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/core/user_info/user_info_controller.dart';
import 'package:spanx/routes/app_routes.dart';

import '../../../core/const/app_colors.dart';

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

        final token = response['data']['accessToken'];
        final userID = response['data']['id'];
        final isApproved = response['data']['isApproved'] as bool;
        final isDeleted = response['data']['isDeleted'] as bool;
        if (isDeleted) {
          AppSnackbar.show(
            message: 'Your account has been deleted.',
            isSuccess: false,
          );
          return;
        }
        final subscription =
            response['data']['subscription'] as Map<String, dynamic>?;

        logger.w("Approval: $isApproved | Deleted: $isDeleted");
        logger.d("Subscription: $subscription");

        isUserApproved(isApproved, token, userID, subscription);

        emailController.clear();
        passwordController.clear();

        isLoading.value = false;
      } else {
        final message = response != null && response['message'] != null
            ? response['message']
            : 'User info is not correct';
        log('Login failed: $message');
        AppSnackbar.show(message: message, isSuccess: false);
      }
    } catch (e) {
      logger.e('Login error ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  bool isUserSubscribed(Map<String, dynamic>? subscription) {
    return subscription != null;
  }

  void isUserApproved(
    bool isApproved,
    String token,
    String uID,
    Map<String, dynamic>? subscription,
  ) async {
    if (!isApproved) {
      Get.offNamed(AppRoutes.pendingUser);
      return;
    }

    if (subscription != null) {
      AppSnackbar.show(message: 'Login successful', isSuccess: true);
      await localService.setToken(token);
      await localService.setUserId(uID);

      logger.d("TOKEN: ${await localService.getToken()}");
      logger.d("USER ID: ${await localService.getUID()}");

      Get.offNamed(AppRoutes.mainNavBarScreen);
    } else {
      // AppSnackbar.show(
      //   message: 'Please subscribe to continue',
      //   isSuccess: false,
      // );
      await localService.setToken(token);
      await localService.setUserId(uID);

      logger.d("TOKEN: ${await localService.getToken()}");
      logger.d("USER ID: ${await localService.getUID()}");
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
