import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/routes/app_routes.dart';

class ResetPasswordController extends GetxController {
  final RxBool isNewPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;

  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final isLoading = false.obs;

  @override
  void onClose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void makeNewPasswordVisible() =>
      isNewPasswordVisible.value = !isNewPasswordVisible.value;
  void makeConfirmPasswordVisible() =>
      isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;

  bool isPasswordFilled() =>
      newPasswordController.text.isNotEmpty &&
      confirmPasswordController.text.isNotEmpty;

  bool isPasswordMatching() =>
      newPasswordController.text == confirmPasswordController.text;

  // kept for UI compatibility
  bool isPasswordDifferent() => isPasswordMatching();

  bool isPassLengthOkay() => newPasswordController.text.length >= 8;

  Future<void> handleResetPassword(String passedEmail) async {
    if (!isPasswordFilled()) {
      AppSnackBar.error('Please enter and confirm your new password');
      return;
    }
    if (!isPassLengthOkay()) {
      AppSnackBar.error('Password must be at least 8 characters');
      return;
    }
    if (!isPasswordMatching()) {
      AppSnackBar.error('Passwords do not match');
      return;
    }

    isLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.resetPassword,
        jsonEncode({
          'email': passedEmail,
          'password': newPasswordController.text,
        }),
        is_auth: false,
      );

      if (response != null && response['success'] == true) {
        AppSnackBar.success('Password reset successfully');
        Get.offAllNamed(AppRoutes.loginScreen);
      } else {
        AppSnackBar.error(response?['message'] ?? 'Reset failed. Please try again.');
      }
    } catch (e) {
      log('handleResetPassword error: $e');
      AppSnackBar.error('Something went wrong. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }
}
