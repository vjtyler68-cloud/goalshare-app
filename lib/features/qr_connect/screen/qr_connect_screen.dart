import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_network_image.dart';
import 'package:spanx/features/follwing_followers/controller/follower_controller.dart';

import '../../../core/user_info/user_info_controller.dart';

const _kRed = Color(0xffE84040);
const _kRedDk = Color(0xff9B1414);
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
              'Let people scan this code to follow you',
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
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: _kRedDk),
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

  FollowingsFollowersController get _followCtrl {
    if (!Get.isRegistered<FollowingsFollowersController>()) {
      Get.put(FollowingsFollowersController());
    }
    return Get.find<FollowingsFollowersController>();
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

  /// Run the camera only while the Scan tab is the active tab.
  void _syncCamera() {
    if (!mounted) return;
    final onScanTab = (_tab?.index ?? 0) == 1;
    if (onScanTab && !_handling) {
      _controller.start();
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
      Get.snackbar('That\'s you', 'You can\'t follow your own code.');
      _resume();
      return;
    }

    final ok = await _followCtrl.followUser(scannedId);
    if (!mounted) return;
    if (ok) {
      Get.back();
    } else {
      // Keep the user in the scanner so they can retry.
      _resume();
    }
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
          ),
        ),
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 28.h),
          child: Column(
            children: [
              Text(
                'Point your camera at someone\'s GoalShare QR code to follow them.',
                textAlign: TextAlign.center,
                style: AppFonts.spaceGrotesk.copyWith(color: _kMuted, fontSize: 13.sp, height: 1.4),
              ),
              SizedBox(height: 14.h),
              TextButton.icon(
                onPressed: () => _controller.toggleTorch(),
                icon: const Icon(Icons.flashlight_on_outlined, color: _kRed),
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
