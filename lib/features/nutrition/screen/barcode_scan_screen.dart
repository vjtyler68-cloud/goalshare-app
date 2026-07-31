import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:url_launcher/url_launcher.dart';


/// Camera barcode scanner. Pops with the first detected barcode string
/// (via `Get.back(result: code)`), or null if the user cancels.
class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

/// Full-screen explanation shown when the camera cannot start — almost always
/// because camera access is blocked for the app in iOS Settings. Gives the
/// user a one-tap way to fix it instead of a silent black screen.
class _CameraBlocked extends StatelessWidget {
  const _CameraBlocked({required this.onRetry, this.details});
  final Future<void> Function() onRetry;

  /// Raw technical reason the camera failed, shown small so a screenshot of
  /// this screen tells us the root cause.
  final String? details;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.no_photography_rounded,
                color: Colors.white70, size: 42.r),
            SizedBox(height: 14.h),
            Text(
              'The camera is blocked for GoalShare.\n'
              'Tap below, turn on Camera access, then come back.',
              textAlign: TextAlign.center,
              style: AppFonts.spaceGrotesk.copyWith(
                  color: Colors.white70, fontSize: 13.5.sp, height: 1.4),
            ),
            SizedBox(height: 18.h),
            ElevatedButton(
              onPressed: () => launchUrl(Uri.parse('app-settings:')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding:
                    EdgeInsets.symmetric(horizontal: 22.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.r)),
              ),
              child: Text('Open Settings',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontWeight: FontWeight.w700, fontSize: 14.sp)),
            ),
            SizedBox(height: 10.h),
            TextButton(
              onPressed: onRetry,
              child: Text('Try again',
                  style: AppFonts.spaceGrotesk.copyWith(
                      color: Colors.white54, fontSize: 13.sp)),
            ),
            if (details != null && details!.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Text(
                details!,
                textAlign: TextAlign.center,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.spaceGrotesk.copyWith(
                    color: Colors.white38, fontSize: 10.sp, height: 1.3),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  // Exactly the QR scanner's proven pattern: autoStart:false + one explicit
  // start() after the first frame. Under this app's custom engine, the widget's
  // built-in auto-start can fire before the camera texture is ready (that was
  // the original flakiness). Crucially there is NO stop()-on-lifecycle here —
  // that was the blank-screen bug (iOS goes 'inactive' during the permission
  // prompt, and stopping then killed the camera as it started).
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    autoStart: false,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
    ],
  );
  bool _handled = false;
  // Set when the camera fails to start (most commonly: camera permission
  // denied at the iOS level). Previously start() failures were silently
  // swallowed, leaving a pure black screen with no explanation.
  bool _startFailed = false;
  // Technical reason for the failure, surfaced on the blocked screen so a
  // screenshot tells us the exact root cause.
  String? _camError;

  @override
  void initState() {
    super.initState();
    // Bring the camera up once the platform view exists.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCamera());
  }

  Future<void> _startCamera() async {
    try {
      await _controller.start();
      if (mounted && _startFailed) {
        setState(() {
          _startFailed = false;
          _camError = null;
        });
      }
      // Watchdog: start() can "succeed" while the camera never actually runs
      // (session conflict, wedged camera daemon, permission revoked at the OS
      // level). Check the controller's real state shortly after.
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (!mounted || _handled) return;
        final v = _controller.value;
        if (!v.isRunning || v.error != null || !v.hasCameraPermission) {
          setState(() {
            _startFailed = true;
            _camError = v.error != null
                ? '${v.error}'
                : (!v.hasCameraPermission
                    ? 'No camera permission (iOS reports access denied)'
                    : 'Camera session did not start (isRunning=false)');
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _startFailed = true;
          _camError = '$e';
        });
      }
    }
  }

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
          if (_startFailed)
            _CameraBlocked(onRetry: _startCamera, details: _camError)
          else
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: EdgeInsets.all(28.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.no_photography_rounded,
                        color: Colors.white70, size: 42.r),
                    SizedBox(height: 14.h),
                    Text(
                      'Camera unavailable. Allow camera access for GoalShare '
                      'in Settings, then reopen the scanner.',
                      textAlign: TextAlign.center,
                      style: AppFonts.spaceGrotesk.copyWith(
                          color: Colors.white70,
                          fontSize: 13.5.sp,
                          height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // dim + cutout frame (hidden while the blocked-camera message shows)
          if (!_startFailed)
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
                  if (!_startFailed)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 12.h),
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
          // DIAGNOSTIC: live camera state, painted on top of everything so any
          // screenshot tells us which layer is failing (session vs rendering).
          Positioned(
            top: MediaQuery.of(context).viewPadding.top + 4,
            left: 0,
            right: 0,
            child: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, v, _) => Text(
                'cam: run=${v.isRunning} perm=${v.hasCameraPermission} '
                'size=${v.size.width.toInt()}x${v.size.height.toInt()} '
                'err=${v.error ?? "-"}',
                textAlign: TextAlign.center,
                style: AppFonts.spaceGrotesk
                    .copyWith(color: Colors.white38, fontSize: 9.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
