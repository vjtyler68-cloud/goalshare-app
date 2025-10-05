import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/routes/app_routes.dart';

import '../../../core/network_caller/network_config.dart';

class ResetPasswordController extends GetxController {
  final RxBool isNewPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;

  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  void makeNewPasswordVisible() {
    isNewPasswordVisible.value = !isNewPasswordVisible.value;
  }

  void makeConfirmPasswordVisible() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  final isLoading = false.obs;

  // final NetworkConfig networkConfig = NetworkConfig();

  bool isPasswordFilled() {
    if (newPasswordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      return false;
    }
    return true;
  }

  bool isPasswordDifferent() {
    if (newPasswordController.text == confirmPasswordController.text) {
      return true;
    }
    return false;
  }

  bool isPassLengthOkay() {
    if (newPasswordController.text.length < 8 &&
        confirmPasswordController.text.length < 8) {
      return false;
    }
    return true;
  }

  Future<void> handleResetPassword(String passedEmail) async {
    isLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.resetPassword,
        jsonEncode({
          'email': passedEmail,
          'password': newPasswordController.text,
        }),
        is_auth: false
      );
      if (response != null && response['success'] == true) {
        Get.snackbar(
          "Success",
          'Reset Password successful',
          snackPosition: SnackPosition.TOP,
        );
        Get.offAllNamed(AppRoutes.loginScreen);
        isLoading.value = false;
      } else {
        log('Reset Password failed');
        Get.snackbar(
          "FAILED",
          'Reset Password failed',
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      log('Reset Password error ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}
