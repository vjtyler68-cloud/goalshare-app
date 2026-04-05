import 'dart:convert';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/routes/app_routes.dart';

class SignupController extends GetxController {
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

  bool isEmailValid(String email) {
    final RegExp emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    // return true;
    return emailRegex.hasMatch(email);
  }

  // late final Map<String, dynamic> registerBody = {
  //   'fullName': fullNameTextController.text.trim(),
  //   'email': emailTextController.text.trim(),
  //   'password': passwordTextController.text.trim(),
  //   'isAgreeWithTerms': isTermsAgree.value,
  // };

  Future<void> signUpUser() async {
    final fullName = fullNameTextController.text.trim();
    final email = emailTextController.text.trim();
    final password = passwordTextController.text;
    final confirmPassword = confirmPasswordTextController.text;

    // Full Name validation
    if (fullName.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Full name is required',
        backgroundColor: AppColors.redColor,
      );
      return;
    }

    // Email validation
    if (email.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Email is required',
        backgroundColor: AppColors.redColor,
      );
      return;
    }

    if (!isEmailValid(email)) {
      Get.snackbar(
        'Validation Error',
        'Please enter a valid email address',
        backgroundColor: AppColors.redColor,
      );
      return;
    }

    // Password validation
    if (password.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Password is required',
        backgroundColor: AppColors.redColor,
      );
      return;
    }

    if (!isPasswordValid(password)) {
      Get.snackbar(
        'Validation Error',
        'Password must be at least 6 characters long',
        backgroundColor: AppColors.redColor,
      );
      return;
    }

    // Confirm password validation
    if (confirmPassword.isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Please confirm your password',
        backgroundColor: AppColors.redColor,
      );
      return;
    }

    if (!isPasswordMatched()) {
      Get.snackbar(
        'Validation Error',
        'Passwords do not match',
        backgroundColor: AppColors.redColor,
      );
      return;
    }

    // Terms agreement validation
    if (!isTermsAgree.value) {
      Get.snackbar(
        'Validation Error',
        'Please agree to terms and conditions',
        backgroundColor: AppColors.redColor,
      );
      return;
    }

    isLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.signUp,
        jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
          'isAgreeWithTerms': isTermsAgree.value,
        }),
        is_auth: false,
      );

      if (response != null && response['success'] == true) {
        Get.toNamed(
          AppRoutes.applyCodeScreen,
          arguments: {
            'email': emailTextController.text.trim(),
            'fullName': fullNameTextController.text.trim(),
          },
        );
        clearFields();
      } else {
        Get.snackbar(
          'Failed',
          '${response['message']}',
          backgroundColor: AppColors.redColor,
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

  bool isPasswordValid(String password) {
    return password.length >= 6;
  }

  void clearFields() {
    fullNameTextController.clear();
    emailTextController.clear();
    passwordTextController.clear();
    confirmPasswordTextController.clear();
  }
}
