import 'dart:convert';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/routes/app_routes.dart';

class SignupController extends GetxController {
  final fullNameTextController = TextEditingController();
  final emailTextController = TextEditingController();
  final passwordTextController = TextEditingController();
  final confirmPasswordTextController = TextEditingController();

  final RxBool isPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;
  final RxBool isTermsAgree = false.obs;
  final RxBool isLoading = false.obs;

  @override
  void onClose() {
    fullNameTextController.dispose();
    emailTextController.dispose();
    passwordTextController.dispose();
    confirmPasswordTextController.dispose();
    super.onClose();
  }

  void toggleTermsAgree() => isTermsAgree.value = !isTermsAgree.value;
  void makePasswordVisible() => isPasswordVisible.value = !isPasswordVisible.value;
  void makeConfirmPasswordVisible() =>
      isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;

  bool isEmailValid(String email) =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

  bool isPasswordValid(String password) => password.length >= 6;

  bool isPasswordMatched() =>
      passwordTextController.text == confirmPasswordTextController.text;

  bool isInfoCompleted() =>
      fullNameTextController.text.isNotEmpty &&
      emailTextController.text.isNotEmpty &&
      passwordTextController.text.isNotEmpty &&
      confirmPasswordTextController.text.isNotEmpty;

  Future<void> signUpUser() async {
    final fullName = fullNameTextController.text.trim();
    final email = emailTextController.text.trim();
    final password = passwordTextController.text;
    final confirmPassword = confirmPasswordTextController.text;

    if (fullName.isEmpty) {
      AppSnackBar.error('Full name is required');
      return;
    }
    if (email.isEmpty) {
      AppSnackBar.error('Email is required');
      return;
    }
    if (!isEmailValid(email)) {
      AppSnackBar.error('Please enter a valid email address');
      return;
    }
    if (password.isEmpty) {
      AppSnackBar.error('Password is required');
      return;
    }
    if (!isPasswordValid(password)) {
      AppSnackBar.error('Password must be at least 6 characters');
      return;
    }
    if (confirmPassword.isEmpty) {
      AppSnackBar.error('Please confirm your password');
      return;
    }
    if (!isPasswordMatched()) {
      AppSnackBar.error('Passwords do not match');
      return;
    }
    if (!isTermsAgree.value) {
      AppSnackBar.error('Please agree to terms and conditions');
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
        clearFields();
        Get.toNamed(
          AppRoutes.applyCodeScreen,
          arguments: {'email': email, 'fullName': fullName},
        );
      } else {
        AppSnackBar.error(response?['message'] ?? 'Sign up failed. Please try again.');
      }
    } catch (e) {
      log('signUpUser error: $e');
      AppSnackBar.error('Something went wrong. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }

  void clearFields() {
    fullNameTextController.clear();
    emailTextController.clear();
    passwordTextController.clear();
    confirmPasswordTextController.clear();
  }
}
