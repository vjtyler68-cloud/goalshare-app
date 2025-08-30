import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ApplyCodeController extends GetxController {
  // pin input controller
  final pinController = TextEditingController();

  // verification code
  var verificationCode = ''.obs;

  // Handle pin completion
  void onPinCompleted(String pin) {
    verificationCode.value = pin;
    debugPrint('Verification code entered: $pin');
  }
}
