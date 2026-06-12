import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/routes/app_routes.dart';

class ResetCodeController extends GetxController {
  final pinController = TextEditingController();
  final isLoading = false.obs;

  @override
  void onClose() {
    pinController.dispose();
    super.onClose();
  }

  bool isPinComplete() => pinController.text.length == 6;

  // kept for UI compatibility
  bool isPinEmpty() => isPinComplete();

  Future<void> handleOTPVerification(String passedEmail) async {
    if (!isPinComplete()) {
      AppSnackBar.error('Please enter the 6-digit code');
      return;
    }

    isLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.verifyForgotPasswordOTP,
        jsonEncode({'email': passedEmail, 'otp': pinController.text}),
        is_auth: false,
      );

      if (response != null && response['success'] == true) {
        AppSnackBar.success('Code verified!');
        Get.offNamed(AppRoutes.resetPasswordScreen, arguments: passedEmail);
      } else {
        AppSnackBar.error(response?['message'] ?? 'Invalid code. Please try again.');
      }
    } catch (e) {
      log('handleOTPVerification error: $e');
      AppSnackBar.error('Something went wrong. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }
}
