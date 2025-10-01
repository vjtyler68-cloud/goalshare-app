import 'dart:convert';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/core/user_info/user_info_controller.dart';
import 'package:spanx/routes/app_routes.dart';

class SignupController extends GetxController {
  final userInfoController = Get.put(UserInfoController());

  TextEditingController fullNameTextController = TextEditingController();
  TextEditingController emailTextController = TextEditingController();
  TextEditingController passwordTextController = TextEditingController();
  TextEditingController confirmPasswordTextController = TextEditingController();

  final RxBool isPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;
  final RxBool isTermsAgree = false.obs;
  final RxBool isLoading = false.obs;

  void toggleTermsAgree() {
    isTermsAgree.value = !isTermsAgree.value;
  }

  void makePasswordVisible() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void makeConfirmPasswordVisible() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  // late final Map<String, dynamic> registerBody = {
  //   'fullName': fullNameTextController.text.trim(),
  //   'email': emailTextController.text.trim(),
  //   'password': passwordTextController.text.trim(),
  //   'isAgreeWithTerms': isTermsAgree.value,
  // };

  Future<void> signUpUser() async {
    isLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.signUp,
        jsonEncode({
          'fullName': fullNameTextController.text.trim(),
          'email': emailTextController.text.trim(),
          'password': passwordTextController.text.trim(),
          'isAgreeWithTerms': isTermsAgree.value,
        }),
        is_auth: false,
      );
      if (response != null && response['success'] == true) {
        userInfoController.fullName.value = fullNameTextController.text.trim();
        userInfoController.email.value = emailTextController.text.trim();
        Get.toNamed(AppRoutes.applyCodeScreen, arguments: emailTextController.text.trim());
        clearFields();
      } else {
        Get.snackbar(
          'Failed',
          '${response['message']}',
          backgroundColor: AppColors.maroonColor,
        );
      }
    } catch (e) {
      log('Signup Error: ${e.toString()}');
      log(fullNameTextController.text);
      log(emailTextController.text);
      log("${isTermsAgree.value}");
    } finally {
      isLoading.value = false;
    }
  }

  bool isInfoCompleted() {
    if (fullNameTextController.text.isEmpty ||
        emailTextController.text.isEmpty ||
        passwordTextController.text.isEmpty ||
        confirmPasswordTextController.text.isEmpty) {
      return false;
    }

    return true;
  }

  bool isPasswordMatched() {
    if (passwordTextController.text != confirmPasswordTextController.text) {
      return false;
    }
    return true;
  }

  void clearFields(){
    fullNameTextController.clear();
    emailTextController.clear();
    passwordTextController.clear();
    confirmPasswordTextController.clear();
  }
}
