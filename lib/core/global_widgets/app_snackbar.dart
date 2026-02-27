import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppSnackbar {
  static void show({
    required String message,
    required bool isSuccess,
  }) {
    // Make sure context exists
    if (Get.context == null) return;

    // Close any existing snackbar safely
    if (Get.isOverlaysOpen) {
      Get.back();
    }

    Get.showSnackbar(
      GetSnackBar(
        title: isSuccess ? 'Success' : 'Failed',
        message: message,
        icon: Icon(
          isSuccess
              ? Icons.check_circle_outline
              : Icons.warning_amber_outlined,
          color: Colors.white,
        ),
        snackPosition: SnackPosition.TOP,
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,

        // Safe dismiss button
        mainButton: TextButton(
          onPressed: () {
            if (Get.isOverlaysOpen) {
              Get.back();
            }
          },
          child: const Text(
            'Dismiss',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}