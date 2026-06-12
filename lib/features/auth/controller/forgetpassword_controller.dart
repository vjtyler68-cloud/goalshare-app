import 'dart:convert';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/routes/app_routes.dart';

class ForgetPasswordController extends GetxController {
  final forgetPasswordEditingController = TextEditingController();
  final isLoading = false.obs;

  @override
  void onClose() {
    forgetPasswordEditingController.dispose();
    super.onClose();
  }

  bool isFieldFilled() => forgetPasswordEditingController.text.trim().isNotEmpty;

  Future<void> handleForgetPassword() async {
    final email = forgetPasswordEditingController.text.trim();
    if (email.isEmpty) {
      AppSnackBar.error('Please enter your email address');
      return;
    }

    isLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.forgotPass,
        jsonEncode({'email': email}),
        is_auth: false,
      );

      if (response != null && response['success'] == true) {
        AppSnackBar.success('OTP sent to your email');
        Get.toNamed(AppRoutes.resetCodeScreen, arguments: email);
      } else {
        AppSnackBar.error(response?['message'] ?? 'Failed to send OTP. Please try again.');
      }
    } catch (e) {
      log('handleForgetPassword error: $e');
      AppSnackBar.error('Something went wrong. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }
}
