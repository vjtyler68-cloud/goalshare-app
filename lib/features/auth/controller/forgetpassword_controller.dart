import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/routes/app_routes.dart';

class ForgetPasswordController extends GetxController {
  final TextEditingController forgetPasswordEditingController =
      TextEditingController();
  final isLoading = false.obs;

  Future<void> handleForgetPassword() async {
    isLoading.value = true;
      try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.forgotPass,
        jsonEncode({'email': forgetPasswordEditingController.text.trim()}),
        is_auth: false,
      );

      if (response != null && response['success'] == true) {
        Get.snackbar(
          "Success",
          'OTP sent to your email',
          snackPosition: SnackPosition.TOP,
        );
        Get.toNamed(
          AppRoutes.resetCodeScreen,
          arguments: forgetPasswordEditingController.text,
        );
        isLoading.value = false;
      } else {
        print('OTP sent Failed');
        Get.snackbar(
          "FAILED",
          'OTP sent failed',
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      print('otp sent error ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  bool isFieldFilled(){
   if(forgetPasswordEditingController.text.isEmpty){
     return false;
   }
   return true;
  }

}
