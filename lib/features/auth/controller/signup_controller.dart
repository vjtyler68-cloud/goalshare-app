import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class SignupController extends GetxController{

  TextEditingController fullNameTextController = TextEditingController();
  TextEditingController emailTextController = TextEditingController();
  TextEditingController passwordTextController = TextEditingController();
  TextEditingController confirmPasswordTextController = TextEditingController();

  final RxBool isPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;

  void makePasswordVisible() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void makeConfirmPasswordVisible() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

}