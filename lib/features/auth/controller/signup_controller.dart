import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';

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

  Future<void> signUpUser() async {
    final response = await NetworkConfig.instance.ApiRequestHandler(
      RequestMethod.POST,
      Urls.signUp,
      jsonEncode({
        'fullName' : fullNameTextController.text.trim(),
        'email' : emailTextController.text.trim(),
        'password' : passwordTextController.text.trim(),
        'isAgreeWithTerms' : isTermsAgree.value,
        'city' : '',
        'address' : '',
      }),
      is_auth: false,
    );

    try{

    }
        catch (e){}finally{
      isLoading.value = false;

    }
  }
}
