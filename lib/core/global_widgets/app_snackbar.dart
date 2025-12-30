import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppSnackbar {
  static void show({required String message, required bool isSuccess}) {
    if (Get.overlayContext == null) {
      // overlay not ready yet -> delay and try once
      Future.delayed(const Duration(milliseconds: 150), () {
        if (Get.overlayContext != null) {
          show(message: message, isSuccess: isSuccess);
        }
      });
      return;
    }

    Get.snackbar(
      isSuccess ? 'Success' : 'Failed',
      message,
      icon: Icon(
        isSuccess ? Icons.check_circle_outline : Icons.warning_amber_outlined,
        color: Colors.white,
      ),
      snackPosition: SnackPosition.TOP,
      backgroundColor: isSuccess ? Colors.green : Colors.red,
      colorText: Colors.white,
      borderRadius: 10,
      margin: const EdgeInsets.all(10),
      duration: const Duration(seconds: 2),
      isDismissible: true,
      mainButton: TextButton(
        onPressed: Get.closeCurrentSnackbar,
        style: TextButton.styleFrom(foregroundColor: Colors.white),
        child: const Text(
          'Dismiss',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
