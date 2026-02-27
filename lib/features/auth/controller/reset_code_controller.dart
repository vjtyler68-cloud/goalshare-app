import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/network_caller/endpoints.dart';
import '../../../core/network_caller/network_config.dart';
import '../../../routes/app_routes.dart';

class ResetCodeController extends GetxController {
  // pin input controller
  final pinController = TextEditingController();

  final isLoading = false.obs;

  bool isPinEmpty() {
    if (pinController.text.length != 6) {
      return false;
    }
    return true;
  }

  Future<void> handleOTPVerification(String passedEmail) async {
    isLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.verifyForgotPasswordOTP,
        jsonEncode({'email': passedEmail, 'otp': pinController.text}),
        is_auth: false,
      );

      if (response != null && response['success'] == true) {
        Get.snackbar(
          "Success",
          'OTP Verified',
          backgroundColor: AppColors.greenColor,
          snackPosition: SnackPosition.TOP,
        );
        Get.offNamed(AppRoutes.resetPasswordScreen, arguments: passedEmail);
      } else {
        log('OTP not matched');
        Get.snackbar(
          "FAILED",
          '${response['message'] ?? 'Invalid OTP'}',
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      log('OTP error ${e.toString()}');
      Get.snackbar(
        "Error",
        'Something went wrong. Please try again.',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
