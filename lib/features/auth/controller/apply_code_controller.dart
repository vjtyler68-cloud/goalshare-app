import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/routes/app_routes.dart';

class ApplyCodeController extends GetxController {
  // pin input controller
  final pinController = TextEditingController();
  final localService = LocalService();

  // verification code
  late var verificationCode = int.parse(pinController.text);

  // previous screen value
  // late final String passedValue ;
  //
  //  @override
  // void onInit() {
  //   super.onInit();
  //   passedValue = Get.arguments;
  //   log("Received argument: $passedValue");
  //
  // }

  // Handle pin completion
  // void onPinCompleted(int pin, String passedEmail) {
  //   verificationCode = pin;
  //   debugPrint('Verification code entered: $pin');
  //   handleOTPVerification(passedEmail);
  // }

  final isLoading = false.obs;

  bool isPinEmpty() {
    if (pinController.text.length != 6) {
      return false;
    }
    return true;
  }

  Future<void> handleOTPVerification(
    String passedEmail,
    String passedFullName,
  ) async {
    isLoading.value = true;

    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.verifyOTP,
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
        final token = response['data']['accessToken'];
        await localService.setToken(token);
        // Get.offNamed(AppRoutes.loginScreen);
        Get.offNamed(AppRoutes.setUpProfileScreen, arguments: passedFullName);
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
