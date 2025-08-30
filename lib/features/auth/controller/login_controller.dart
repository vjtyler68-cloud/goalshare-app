import 'package:flutter/cupertino.dart';
import 'package:get/state_manager.dart';

class LoginController extends GetxController {
  final RxBool isPasswordVisible = false.obs;
  TextEditingController passwordController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  void makePasswordVisible() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }
}
