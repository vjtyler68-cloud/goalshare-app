import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/routes/app_routes.dart';

class ApplyCodeController extends GetxController {
  // pin input controller
  final pinController = TextEditingController();

  // verification code
  late var verificationCode = int.parse(pinController.text);

  // previous screen value
  // late final String passedValue ;
  //
  //  @override
  // void onInit() {
  //   super.onInit();
  //   passedValue = Get.arguments;
  //   print("Received argument: $passedValue");
  //
  // }

  // Handle pin completion
  void onPinCompleted(int pin) {
    verificationCode = pin;
    debugPrint('Verification code entered: $pin');
  }

  final isLoading = false.obs;

  Future<void> handleOTPVerification(String passedEmail) async {
    if (pinController.text.isEmpty) {
      Get.snackbar(
        "Error",
        'Please fill email values',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.verifyOTP,
        jsonEncode({'email': passedEmail, 'otp': verificationCode}),
        is_auth: false,
      );

      if (response != null && response['success'] == true) {
        Get.snackbar(
          "Success",
          'OTP Verified',
          snackPosition: SnackPosition.TOP,
        );
        Get.offNamed(AppRoutes.resetPasswordScreen, arguments: passedEmail);
        isLoading.value = false;
      } else {
        print('OTP not matched');
        Get.snackbar(
          "FAILED",
          'OTP not matched',
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      print('OTP error ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}
