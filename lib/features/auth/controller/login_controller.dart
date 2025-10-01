import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/core/user_info/user_info_controller.dart';
import 'package:spanx/routes/app_routes.dart';

import '../../../core/const/app_colors.dart';

class LoginController extends GetxController {
  final RxBool isPasswordVisible = false.obs;

  TextEditingController passwordController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  // final userInfoController = Get.put(UserInfoController());
  final LocalService localService  =  LocalService();

  void makePasswordVisible() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  final RxBool isLoading = false.obs;

  // @override
  // void onInit() {
  //   super.onInit();
  // }

  Future<void> handleLogin() async {
    isLoading.value = true;
        try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.login,
        jsonEncode({
          'email': emailController.text.trim(),
          'password': passwordController.text.trim(),
        }),
        is_auth: false
      );
      if (response != null && response['success']==true) {
        log("login start -------");
        final token = response['data']['accessToken'];
        await localService.setToken(token);
        final gt = await localService.getToken();
        log("GET TOKEN: ${gt.toString()}");
        Get.snackbar(
          'Success',
          'Login successful',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.greenColor
        );
        log('Login successful ${response['message']}');
        Get.offNamed(AppRoutes.mainNavBarScreen);
        isLoading.value = false;

      } else if(response['success']==false) {
        log('Login failed ${response['message']}');
        Get.snackbar(
          'Login failed.',
          'Please try again.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.greenColor
        );
      }
    } catch (e) {
      log('Login error ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  bool isInfoCompleted() {
    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty ) {
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    super.dispose();
    emailController.clear();
    passwordController.clear();
  }
}
