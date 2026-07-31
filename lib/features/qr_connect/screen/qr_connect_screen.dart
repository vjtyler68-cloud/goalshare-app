import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_network_image.dart';
import 'package:spanx/features/friends/controller/friends_controller.dart';

import '../../../core/user_info/user_info_controller.dart';
import 'package:spanx/core/const/app_colors.dart';

Color get _kRed => AppColors.primaryColor;
Color get _kRedDk => AppColors.primaryDarkColor;
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// Payload prefix so we only react to GoalShare codes (not random QRs).
const _kQrPrefix = 'goalshare:user:';

String buildUserQrPayload(String id) => '$_kQrPrefix$id';

/// Returns the user id if [raw] is a valid GoalShare user code, else null.
String? parseUserQrPayload(String? raw) {
  if (raw == null) return null;
  final value = raw.trim();
  if (!value.toLowerCase().startsWith(_kQrPrefix)) return null;
  final id = value.substring(_kQrPrefix.length).trim();
  return id.isEmpty ? null : id;
}

class QrConnectScreen extends StatelessWidget {
  QrConnectScreen({super.key});

  final userInfo = Get.find<UserInfoController>();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xffF6F4F2),
        appBar: AppBar(
          backgroundColor: _kRed,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Text(
            'Add People',
            style: AppFonts.spaceGrotesk
                .copyWith(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18.sp),
          ),
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: AppFonts.spaceGrotesk.copyWith(fontWeight: FontWeight.w700, fontSize: 13.sp),
            tabs: const [
              Tab(text: 'My Code'),
              Tab(text: 'Scan'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MyCodeTab(userInfo: userInfo),
            const _ScanTab(),
          ],
        ),
      ),
    );
  }
}

// ── My Code ─────────────────────────────────────────────────────────────────

class _MyCodeTab extends StatelessWidget {
  const _MyCodeTab({required this.userInfo});
  final UserInfoController userInfo;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = userInfo.userData.value;
      final id = user?.id ?? '';

      if (id.isEmpty) {
        return Center(
          child: Text(
            'Loading your code…',
            style: AppFonts.spaceGrotesk.copyWith(color: _kMuted, fontSize: 14.sp),
          ),
        );
      }

      return SingleChildScrollView(
        padding: EdgeInsets.all(24.r),
        child: Column(
          children: [
            SizedBox(height: 12.h),
            Text(
              'Let people scan this code to add you as a friend',
              textAlign: TextAlign.center,
              style: AppFonts.spaceGrotesk.copyWith(color: _kMuted, fontSize: 13.sp),
            ),
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28.r),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6)),
                ],
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 64.r,
                    height: 64.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _kRed, width: 2),
                    ),
                    child: ClipOval(
                      child: (user?.profile != null && user!.profile!.isNotEmpty)
                          ? ResponsiveNetworkImage(
                              imageUrl: user.profile!,
                              shape: ImageShape.circle,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: _kRed.withOpacity(0.1),
                              child: Center(
                                child: Text(
                                  _initials(user?.fullName ?? 'U'),
                                  style: AppFonts.spaceGrotesk.copyWith(
                                      color: _kRed, fontSize: 22.sp, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    user?.fullName ?? '',
                    style: AppFonts.spaceGrotesk
                        .copyWith(color: _kText, fontSize: 18.sp, fontWeight: FontWeight.w800),
                  ),
                  if ((user?.email ?? '').isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      user!.email!,
                      style: AppFonts.spaceGrotesk.copyWith(color: _kMuted, fontSize: 12.sp),
                    ),
                  ],
                  SizedBox(height: 20.h),
                  QrImageView(
                    data: buildUserQrPayload(id),
                    version: QrVersions.auto,
                    size: 220.r,
                    gapless: false,
                    eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: _kRedDk),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: _kText,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'Have a friend open the Scan tab and point their camera here.',
              textAlign: TextAlign.center,
              style: AppFonts.spaceGrotesk.copyWith(color: _kMuted, fontSize: 12.sp, height: 1.4),
            ),
          ],
        ),
      );
    });
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (name.isNotEmpty) return name[0].toUpperCase();
    return 'U';
  }
}

// ── Scan ────────────────────────────────────────────────────────────────────

class _ScanTab extends StatefulWidget {
  const _ScanTab();

  @override
  State<_ScanTab> createState() => _ScanTabState();
}

class _ScanTabState extends State<_ScanTab> {
  // autoStart:false — the camera is started/stopped explicitly based on which
  // tab is visible (see _syncCamera), so it never runs while "My Code" is shown.
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    autoStart: false,
  );
  final userInfo = Get.find<UserInfoController>();

  TabController? _tab;
  bool _handling = false;

  FriendsController get _friendsCtrl {
    if (!Get.isRegistered<FriendsController>()) {
      Get.put(FriendsController());
    }
    return Get.find<FriendsController>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final t = DefaultTabController.of(context);
    if (t != _tab) {
      _tab?.removeListener(_syncCamera);
      _tab = t;
      _tab?.addListener(_syncCamera);
      _syncCamera();
    }
  }

  // Set when the camera fails to start (usually: camera permission denied in
  // iOS Settings). Without this, a failed start() was silently swallowed and
  // the Scan tab showed nothing but black.
  bool _startFailed = false;
  // Technical reason for the failure, surfaced on screen so a screenshot
  // tells us the exact root cause.
  String? _camError;

  /// Run the camera only while the Scan tab is the active tab.
  void _syncCamera() {
    if (!mounted) return;
    final onScanTab = (_tab?.index ?? 0) == 1;
    if (onScanTab && !_handling) {
      _controller.start().then((_) {
        if (mounted && _startFailed) {
          setState(() {
            _startFailed = false;
            _camError = null;
          });
        }
        // Watchdog: start() can "succeed" while the camera never actually
        // runs (session conflict, wedged camera daemon, OS-level permission
        // problem). Check the controller's real state shortly after.
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (!mounted || _handling) return;
          if ((_tab?.index ?? 0) != 1) return;
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
      }).catchError((e) {
        if (mounted) {
          setState(() {
            _startFailed = true;
            _camError = '$e';
          });
        }
      });
    } else {
      _controller.stop();
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final raw = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
    final scannedId = parseUserQrPayload(raw);

    if (scannedId == null) {
      // Not a GoalShare code — ignore silently so unrelated QRs don't spam.
      return;
    }

    _handling = true;
    await _controller.stop();

    final myId = userInfo.userData.value?.id ?? '';
    if (myId.isEmpty) {
      // Our own profile hasn't loaded yet — can't safely self-check or follow.
      Get.snackbar('Just a sec', 'Still loading your profile — try again.');
      _resume();
      return;
    }
    if (scannedId == myId) {
      Get.snackbar('That\'s you', 'You can\'t add yourself.');
      _resume();
      return;
    }

    // Send a friend request to the scanned user (sendRequest shows its own
    // success/error snackbars), then leave the scanner.
    await _friendsCtrl
        .sendRequest(FriendUser(id: scannedId, name: 'this user'));
    if (!mounted) return;
    Get.back();
  }

  Future<void> _resume() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    _handling = false;
    _syncCamera();
  }

  @override
  void dispose() {
    _tab?.removeListener(_syncCamera);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_startFailed)
                Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(28.r),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.no_photography_rounded,
                          color: Colors.white70, size: 42.r),
                      SizedBox(height: 14.h),
                      Text(
                        'The camera is blocked for GoalShare.\n'
                        'Tap below, turn on Camera access, then come back.',
                        textAlign: TextAlign.center,
                        style: AppFonts.spaceGrotesk.copyWith(
                            color: Colors.white70,
                            fontSize: 13.5.sp,
                            height: 1.4),
                      ),
                      SizedBox(height: 18.h),
                      ElevatedButton(
                        onPressed: () =>
                            launchUrl(Uri.parse('app-settings:')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(
                              horizontal: 22.w, vertical: 12.h),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.r)),
                        ),
                        child: Text('Open Settings',
                            style: AppFonts.spaceGrotesk.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.sp)),
                      ),
                      SizedBox(height: 10.h),
                      TextButton(
                        onPressed: _syncCamera,
                        child: Text('Try again',
                            style: AppFonts.spaceGrotesk.copyWith(
                                color: Colors.white54, fontSize: 13.sp)),
                      ),
                      if (_camError != null && _camError!.isNotEmpty) ...[
                        SizedBox(height: 12.h),
                        Text(
                          _camError!,
                          textAlign: TextAlign.center,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.spaceGrotesk.copyWith(
                              color: Colors.white38,
                              fontSize: 10.sp,
                              height: 1.3),
                        ),
                      ],
                    ],
                  ),
                )
              else ...[
                MobileScanner(controller: _controller, onDetect: _onDetect),
                // Framing overlay
                Container(
                  width: 240.r,
                  height: 240.r,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                ),
              ],
              // DIAGNOSTIC: live camera state, painted on top so any
              // screenshot tells us which layer is failing.
              Positioned(
                top: 6,
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
                        .copyWith(color: _kMuted, fontSize: 9.sp),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 28.h),
          child: Column(
            children: [
              Text(
                'Point your camera at someone\'s GoalShare QR code to add them as a friend.',
                textAlign: TextAlign.center,
                style: AppFonts.spaceGrotesk.copyWith(color: _kMuted, fontSize: 13.sp, height: 1.4),
              ),
              SizedBox(height: 14.h),
              TextButton.icon(
                onPressed: () => _controller.toggleTorch(),
                icon: Icon(Icons.flashlight_on_outlined, color: _kRed),
                label: Text(
                  'Toggle flash',
                  style: AppFonts.spaceGrotesk
                      .copyWith(color: _kRed, fontWeight: FontWeight.w700, fontSize: 13.sp),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
