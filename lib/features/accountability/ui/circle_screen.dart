import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';

import '../controller/circles_controller.dart';
import '../data/buddies_api.dart';
import '../data/circle_models.dart';

const _kBg = Color(0xffF6F4F2);
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);
const _kGreen = Color(0xff22C55E);

/// The squad view — shared "Circle Streak", Squad Shields, everyone's daily
/// check-in status, and your own daily proof.
class CircleScreen extends StatefulWidget {
  const CircleScreen({super.key});

  @override
  State<CircleScreen> createState() => _CircleScreenState();
}

class _CircleScreenState extends State<CircleScreen> {
  final _picker = ImagePicker();
  bool _busy = false;

  Color get _accent => AppColors.primaryColor;

  Future<void> _checkInFlow() async {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12.h),
              Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(4.r))),
              _tile(Icons.camera_alt_rounded, 'Take a photo',
                  () => _pick(ImageSource.camera)),
              _tile(Icons.photo_library_rounded, 'Choose from library',
                  () => _pick(ImageSource.gallery)),
              _tile(Icons.check_circle_outline, 'Check in without proof', () {
                Get.back();
                _submit(null);
              }),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap) => ListTile(
        leading: Icon(icon, color: _accent),
        title: Text(label,
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 15.sp, fontWeight: FontWeight.w700, color: _kText)),
        onTap: onTap,
      );

  Future<void> _pick(ImageSource source) async {
    Get.back();
    try {
      final img = await _picker.pickImage(source: source, imageQuality: 70);
      if (img == null) return;
      setState(() => _busy = true);
      final url = await BuddiesApi.instance.uploadProofImage(img.path);
      await _submit(url);
    } catch (_) {
      AppSnackBar.error('Could not add that photo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit(String? proofUrl) async {
    setState(() => _busy = true);
    try {
      await CirclesController.to.checkinToday(proofUrl: proofUrl);
      AppSnackBar.success('Checked in with your circle ✅');
    } catch (_) {
      AppSnackBar.error('Check-in failed — try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _confirmShield() {
    Get.defaultDialog(
      title: 'Burn a shield?',
      middleText:
          'This saves yesterday for the whole squad — even if not enough of you checked in. Shields are limited, so use them for real emergencies.',
      textConfirm: 'Burn shield',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: _accent,
      onConfirm: () async {
        Get.back();
        final left = await CirclesController.to.burnShield();
        AppSnackBar.success(left == null
            ? 'Shield used.'
            : 'Shield used — $left left. Streak saved. 🛡');
      },
    );
  }

  void _confirmLeave() {
    Get.defaultDialog(
      title: 'Leave circle?',
      middleText: 'You can rejoin or start a new one later.',
      textConfirm: 'Leave',
      textCancel: 'Stay',
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xffEF4444),
      onConfirm: () {
        Get.back();
        CirclesController.to.leaveCircle();
        Get.back();
      },
    );
  }

  void _viewProof(String url) {
    if (url.isEmpty) return;
    Get.dialog(GestureDetector(
      onTap: Get.back,
      child: Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: InteractiveViewer(
          child: Image.network(url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.broken_image, color: Colors.white38, size: 60.sp)),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back, color: _kText)),
        title: Obx(() => Text(
            CirclesController.to.circle.value?.name ?? 'Your Circle',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.spaceGrotesk
                .copyWith(color: _kText, fontWeight: FontWeight.w800))),
        centerTitle: true,
      ),
      body: Obx(() {
        final c = CirclesController.to.circle.value;
        if (c == null) {
          return Center(
            child: Text('You’re not in a circle.',
                style: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 15.sp, color: _kMuted)),
          );
        }
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 30.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _streakBanner(c),
              SizedBox(height: 14.h),
              _shieldsCard(c),
              SizedBox(height: 14.h),
              _myCheckIn(c),
              SizedBox(height: 14.h),
              _members(c),
              SizedBox(height: 18.h),
              Center(
                child: TextButton(
                  onPressed: _confirmLeave,
                  child: Text('Leave circle',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: _kMuted)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _streakBanner(CircleData c) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent, AppColors.primaryDarkColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        children: [
          Text('🔥', style: TextStyle(fontSize: 34.sp)),
          SizedBox(width: 14.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${c.ourStreak}',
                  style: AppFonts.spaceGrotesk.copyWith(
                      color: Colors.white,
                      fontSize: 30.sp,
                      height: 1.0,
                      fontWeight: FontWeight.w900)),
              Text('${c.ourStreak == 1 ? 'day' : 'days'} · Circle Streak',
                  style: AppFonts.spaceGrotesk.copyWith(
                      color: Colors.white70,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${c.todayCount}/${c.threshold}',
                  style: AppFonts.spaceGrotesk.copyWith(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900)),
              Text('checked in today',
                  style: AppFonts.spaceGrotesk
                      .copyWith(color: Colors.white70, fontSize: 11.sp)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shieldsCard(CircleData c) {
    return _card(
      child: Row(
        children: [
          Icon(Icons.shield_rounded, color: _accent, size: 26.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${c.shields} Squad Shield${c.shields == 1 ? '' : 's'} left',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: _kText)),
                SizedBox(height: 2.h),
                Text('Save the streak on a rough day.',
                    style: AppFonts.spaceGrotesk
                        .copyWith(fontSize: 12.sp, color: _kMuted)),
              ],
            ),
          ),
          if (c.shields > 0)
            GestureDetector(
              onTap: _confirmShield,
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text('Burn',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: _accent)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _myCheckIn(CircleData c) {
    final done = c.iCheckedInToday;
    return _card(
      child: Row(
        children: [
          Icon(done ? Icons.verified_rounded : Icons.today_rounded,
              color: done ? _kGreen : _accent, size: 24.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(done ? "You're checked in today" : 'Check in for today',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
          ),
          if (!done)
            GestureDetector(
              onTap: _busy ? null : _checkInFlow,
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                decoration: BoxDecoration(
                    color: _accent, borderRadius: BorderRadius.circular(24.r)),
                child: Text(_busy ? 'Uploading…' : 'Check in',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _members(CircleData c) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Text('Squad · ${c.memberCount}',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
          ),
          for (final m in c.members) _memberRow(m),
        ],
      ),
    );
  }

  Widget _memberRow(CircleMember m) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _avatar(m.avatar, m.name),
              if (m.checkedInToday)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 16.r,
                    height: 16.r,
                    decoration: BoxDecoration(
                      color: _kGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(Icons.check, color: Colors.white, size: 9.r),
                  ),
                ),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(m.isMe ? '${m.name} (you)' : m.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: _kText)),
          ),
          if (m.proofUrl.isNotEmpty)
            GestureDetector(
              onTap: () => _viewProof(m.proofUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.network(m.proofUrl,
                    width: 38.r,
                    height: 38.r,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
            )
          else
            Text(m.checkedInToday ? '✓' : '—',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: m.checkedInToday ? _kGreen : _kMuted)),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
          ],
        ),
        child: child,
      );

  Widget _avatar(String url, String name) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    Widget fill() => Center(
        child: Text(initial,
            style: AppFonts.spaceGrotesk.copyWith(
                color: _accent, fontSize: 15.sp, fontWeight: FontWeight.w800)));
    return Container(
      width: 42.r,
      height: 42.r,
      decoration: BoxDecoration(
          shape: BoxShape.circle, color: _accent.withOpacity(0.12)),
      child: ClipOval(
        child: url.isNotEmpty
            ? Image.network(url,
                fit: BoxFit.cover, errorBuilder: (_, __, ___) => fill())
            : fill(),
      ),
    );
  }
}
