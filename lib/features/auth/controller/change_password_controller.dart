import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/routes/app_routes.dart';

import '../../../core/network_caller/network_config.dart';

class ChangePasswordController extends GetxController {
  final RxBool isNewPasswordVisible = false.obs;
  final RxBool isOldPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;

  TextEditingController newPasswordController = TextEditingController();
  TextEditingController oldPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  void makeNewPasswordVisible() {
    isNewPasswordVisible.value = !isNewPasswordVisible.value;
  }

  void makeOldPasswordVisible() {
    isOldPasswordVisible.value = !isOldPasswordVisible.value;
  }

  void makeConfirmPasswordVisible() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  final isLoading = false.obs;

  // final NetworkConfig networkConfig = NetworkConfig();

  bool isPasswordFilled() {
    if (oldPasswordController.text.isEmpty ||
        newPasswordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      return false;
    }
    return true;
  }

  bool isPasswordMatchingOkay() {
    if ((oldPasswordController.text != newPasswordController.text) &&
        (newPasswordController.text == confirmPasswordController.text)) {
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

  Future<void> handleChangePassword(String oldPassword, String newPassword) async {
    isLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.changePassword,
        jsonEncode({
          "oldPassword": oldPassword,
          "newPassword": newPassword
        }),
        is_auth: true,
      );
      if (response != null && response['success'] == true) {
        Get.snackbar(
          "Success",
          'Change Password successful',
          snackPosition: SnackPosition.TOP,
        );
        Get.offAllNamed(AppRoutes.loginScreen);
        final local = LocalService();
        local.clearUserData();
        isLoading.value = false;
      } else {
        log('Change Password failed');
        Get.snackbar(
          "FAILED",
          'Change Password failed',
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      log('Change Password error ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}
