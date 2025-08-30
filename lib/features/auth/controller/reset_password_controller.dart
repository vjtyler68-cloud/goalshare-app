import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ResetPasswordController extends GetxController {
  final RxBool isNewPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;

  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  void makeNewPasswordVisible() {
    isNewPasswordVisible.value = !isNewPasswordVisible.value;
  }

  void makeConfirmPasswordVisible() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }
}
