import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/routes/app_routes.dart';

class LoginController extends GetxController {
  final RxBool isPasswordVisible = false.obs;

  TextEditingController passwordController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  void makePasswordVisible() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  final isLoading = false.obs;
  final NetworkConfig networkConfig = NetworkConfig();

  @override
  void onInit() {
    super.onInit();
  }

  Future<void> handleLogin() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar(
        "Error",
        'Please fill all values',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;
      final response = await networkConfig.ApiRequestHandler(
        RequestMethod.POST,
        Urls.login,
        jsonEncode({
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
        }),
        is_auth: false
      );

      if (response != null && response['success']==true ) {    
        final token = response['data']['token'];  
        final LocalService localService = LocalService();
        localService.setValue<String>(PreferenceKey.token, token); 
        final getToken = await localService.getValue<String>(PreferenceKey.token);      
        log("get token----- $getToken");      
        Get.snackbar(
          'Success',
          'Login successful',
          snackPosition: SnackPosition.TOP,
        );
        log('Login successful ${response['message']}');
        Get.toNamed(AppRoutes.mainNavBarScreen);
        isLoading.value = false;
      } else {
        log('Login failed ${response['message']}');
        Get.snackbar(
          'Error',
          'Login failed. Please try again.',
          snackPosition: SnackPosition.TOP,
        );
      }
    } catch (e) {
      log('Login error ${e.toString()}');
      // Get.snackbar('Error', '$e', snackPosition: SnackPosition.TOP);
    } finally {
      isLoading.value = false;
    }
  }
}
