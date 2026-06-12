import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/routes/app_routes.dart';

class ApplyCodeController extends GetxController {
  final pinController = TextEditingController();
  final localService = LocalService();
  final isLoading = false.obs;

  @override
  void onClose() {
    pinController.dispose();
    super.onClose();
  }

  bool isPinComplete() => pinController.text.length == 6;

  // kept for UI compatibility
  bool isPinEmpty() => isPinComplete();

  Future<void> handleOTPVerification(
    String passedEmail,
    String passedFullName,
  ) async {
    if (!isPinComplete()) {
      AppSnackBar.error('Please enter the 6-digit code');
      return;
    }

    isLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.verifyOTP,
        jsonEncode({'email': passedEmail, 'otp': pinController.text}),
        is_auth: false,
      );

      if (response != null && response['success'] == true) {
        AppSnackBar.success('Email verified!');
        final token = response['data']['accessToken'];
        await localService.setToken(token);
        Get.offNamed(AppRoutes.setUpProfileScreen, arguments: passedFullName);
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
