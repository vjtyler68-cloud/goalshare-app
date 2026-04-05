import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class PurchaseProcessingDialog {
  PurchaseProcessingDialog._();

  static bool _isOpen = false;

  static Future<void> show({
    String message = 'Processing your purchase...',
    String lottieAssetPath = 'assets/jsons/confetti.json',
  }) async {
    if (_isOpen || Get.isDialogOpen == true) return;
    _isOpen = true;

    await Get.dialog(
      PopScope(
        canPop: false,
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: Colors.black54)),
              Center(
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 160,
                        height: 160,
                        child: Lottie.asset(lottieAssetPath),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    // If it was closed externally, reset flag.
    _isOpen = false;
  }

  static void hide() {
    if (!_isOpen) return;
    if (Get.isDialogOpen == true) {
      Get.back();
    }
    _isOpen = false;
  }
}
