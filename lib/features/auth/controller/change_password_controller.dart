import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/routes/app_routes.dart';

class ChangePasswordController extends GetxController {
  final RxBool isNewPasswordVisible = false.obs;
  final RxBool isOldPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;

  final newPasswordController = TextEditingController();
  final oldPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final isLoading = false.obs;

  @override
  void onClose() {
    newPasswordController.dispose();
    oldPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void makeNewPasswordVisible() =>
      isNewPasswordVisible.value = !isNewPasswordVisible.value;
  void makeOldPasswordVisible() =>
      isOldPasswordVisible.value = !isOldPasswordVisible.value;
  void makeConfirmPasswordVisible() =>
      isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;

  bool isPasswordFilled() =>
      oldPasswordController.text.isNotEmpty &&
      newPasswordController.text.isNotEmpty &&
      confirmPasswordController.text.isNotEmpty;

  bool isPasswordMatchingOkay() =>
      oldPasswordController.text != newPasswordController.text &&
      newPasswordController.text == confirmPasswordController.text;

  bool isPassLengthOkay() => newPasswordController.text.length >= 8;

  Future<void> handleChangePassword(
      String oldPassword, String newPassword) async {
    if (!isPasswordFilled()) {
      AppSnackBar.error('Please fill in all password fields');
      return;
    }
    if (!isPassLengthOkay()) {
      AppSnackBar.error('New password must be at least 8 characters');
      return;
    }
    if (!isPasswordMatchingOkay()) {
      AppSnackBar.error(
          'New password must differ from old and match confirmation');
      return;
    }

    isLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.changePassword,
        jsonEncode({'oldPassword': oldPassword, 'newPassword': newPassword}),
        is_auth: true,
      );

      if (response != null && response['success'] == true) {
        AppSnackBar.success('Password changed successfully');
        await LocalService().clearUserData();
        Get.offAllNamed(AppRoutes.loginScreen);
      } else {
        AppSnackBar.error(
            response?['message'] ?? 'Failed to change password. Please try again.');
      }
    } catch (e) {
      log('handleChangePassword error: $e');
      AppSnackBar.error('Something went wrong. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }
}
