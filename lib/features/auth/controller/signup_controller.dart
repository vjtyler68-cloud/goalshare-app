import 'dart:convert';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/core/notifications/push_notification_service.dart';
import 'package:spanx/routes/app_routes.dart';

class SignupController extends GetxController {
  final LocalService localService = LocalService();

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
        // The backend's OTP email delivery is unreliable, but accounts can
        // log in without verifying their email. Auto-login so the user is
        // never stranded on an OTP screen waiting for a code that may never
        // arrive. Fall back to the OTP screen only if login is refused.
        final loggedIn = await _autoLoginAfterSignup(email, password, fullName);
        if (!loggedIn) {
          clearFields();
          Get.toNamed(
            AppRoutes.applyCodeScreen,
            arguments: {'email': email, 'fullName': fullName},
          );
        }
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

  /// Logs the freshly registered user straight in (the backend issues tokens
  /// to unverified accounts). Returns true when the user was logged in and
  /// routed onward; false means the caller should fall back to OTP entry.
  Future<bool> _autoLoginAfterSignup(
    String email,
    String password,
    String fullName,
  ) async {
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.login,
        jsonEncode({'email': email, 'password': password}),
        is_auth: false,
      );

      if (response == null || response['success'] != true) return false;
      final data = response['data'];
      if (data is! Map<String, dynamic>) return false;

      final token = data['accessToken'] as String?;
      if (token == null || token.isEmpty) return false;

      await localService.setToken(token);
      final id = data['id'] as String?;
      if (id != null && id.isNotEmpty) await localService.setUserId(id);

      // Register this device for push now that a brand-new account has a
      // session + id. Without this, a freshly-signed-up user's first session
      // never registers an FCM token (init() ran at launch when userId was
      // still null), so pushes wouldn't reach them until the next app launch.
      PushNotificationService.instance.registerToken();

      clearFields();
      AppSnackBar.success('Account created — welcome!');
      Get.offNamed(AppRoutes.setUpProfileScreen, arguments: fullName);
      return true;
    } catch (e) {
      log('auto-login after signup failed: $e');
      return false;
    }
  }

  void clearFields() {
    fullNameTextController.clear();
    emailTextController.clear();
    passwordTextController.clear();
    confirmPasswordTextController.clear();
  }
}
