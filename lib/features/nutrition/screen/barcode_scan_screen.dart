import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:spanx/core/const/app_fonts.dart';

const _kRed = Color(0xffE84040);

/// Camera barcode scanner. Pops with the first detected barcode string
/// (via `Get.back(result: code)`), or null if the user cancels.
class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
    ],
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final codes = capture.barcodes;
    if (codes.isEmpty) return;
    final value = codes.first.rawValue;
    if (value == null || value.isEmpty) return;
    _handled = true;
    Get.back(result: value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // dim + cutout frame
          Center(
            child: Container(
              width: 250.r,
              height: 250.r,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: Get.back,
                        child: Container(
                          width: 40.r,
                          height: 40.r,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.4)),
                          child: Icon(Icons.close_rounded,
                              color: Colors.white, size: 22.r),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _controller.toggleTorch(),
                        child: Container(
                          width: 40.r,
                          height: 40.r,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.4)),
                          child: Icon(Icons.flash_on_rounded,
                              color: Colors.white, size: 22.r),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(14.r)),
                    child: Text(
                      'Line up the barcode inside the frame',
                      style: AppFonts.spaceGrotesk.copyWith(
                          color: Colors.white,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
