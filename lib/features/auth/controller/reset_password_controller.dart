import 'dart:convert';

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

  Future<void> handleResetPassword(String passedEmail) async {
    if (newPasswordController.text.isEmpty &&
        confirmPasswordController.text.isEmpty) {
      Get.snackbar(
        "Error",
        'Please fill password values',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      Get.snackbar(
        "Error",
        'Password not matched',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (newPasswordController.text.length < 8 ||
        confirmPasswordController.text.length < 8) {
      Get.snackbar(
        "Error",
        'Password should be 8 Digits',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.resetPassword,
        jsonEncode({
          'email': passedEmail,
          'password': newPasswordController.text}
        ),
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
        print('Reset Password failed');
        Get.snackbar(
          "FAILED",
          'Reset Password failed',
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      print('Reset Password error ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}
