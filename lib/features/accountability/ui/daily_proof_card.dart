import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';

import '../controller/buddies_controller.dart';
import '../data/buddies_api.dart';
import '../data/checkin_models.dart';

const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);
const _kGreen = Color(0xff22C55E);

/// Daily Proof — you check in with a photo/screenshot instead of a checkbox, and
/// your buddy taps Verified / Doesn't count. Both drive the shared "Our Streak".
class DailyProofCard extends StatefulWidget {
  const DailyProofCard({super.key});

  @override
  State<DailyProofCard> createState() => _DailyProofCardState();
}

class _DailyProofCardState extends State<DailyProofCard> {
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
              SizedBox(height: 6.h),
              _sheetTile(Icons.camera_alt_rounded, 'Take a photo',
                  () => _pickAndCheckIn(ImageSource.camera)),
              _sheetTile(Icons.photo_library_rounded, 'Choose from library',
                  () => _pickAndCheckIn(ImageSource.gallery)),
              _sheetTile(Icons.check_circle_outline, 'Check in without proof',
                  () {
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

  Widget _sheetTile(IconData icon, String label, VoidCallback onTap) => ListTile(
        leading: Icon(icon, color: _accent),
        title: Text(label,
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 15.sp, fontWeight: FontWeight.w700, color: _kText)),
        onTap: onTap,
      );

  Future<void> _pickAndCheckIn(ImageSource source) async {
    Get.back();
    try {
      final img = await _picker.pickImage(source: source, imageQuality: 70);
      if (img == null) return;
      setState(() => _busy = true);
      final url = await BuddiesApi.instance.uploadProofImage(img.path);
      await _submit(url);
    } catch (_) {
      AppSnackBar.error('Could not add that photo — try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit(String? proofUrl) async {
    setState(() => _busy = true);
    try {
      await BuddiesController.to.checkInToday(proofUrl: proofUrl);
      AppSnackBar.success('Checked in for today ✅');
    } catch (_) {
      AppSnackBar.error('Check-in failed — try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _viewProof(String url) {
    if (url.isEmpty) return;
    Get.dialog(
      GestureDetector(
        onTap: Get.back,
        child: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: InteractiveViewer(
            child: Image.network(url, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(Icons.broken_image,
                    color: Colors.white38, size: 60.sp)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = BuddiesController.to;
      final uid = c.myUserId;
      final buddyName = c.currentMatch.value?.buddyNameFor(uid) ?? 'Your buddy';
      final buddyFirst = buddyName.trim().split(' ').first;
      final today = c.today;
      final mine = today?.mine;
      final buddy = today?.buddy;

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified_user_outlined, color: _accent, size: 18.r),
                SizedBox(width: 8.w),
                Text("Today's Proof",
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: _kText)),
              ],
            ),
            SizedBox(height: 12.h),
            // ── My side ──────────────────────────────────────────────────────
            _mineRow(mine),
            Divider(height: 22.h, color: const Color(0xffEFEAE8)),
            // ── Buddy side ───────────────────────────────────────────────────
            _buddyRow(buddy, buddyFirst),
          ],
        ),
      );
    });
  }

  Widget _mineRow(DailyProof? mine) {
    if (mine == null) {
      return Row(
        children: [
          Expanded(
            child: Text('You haven\'t checked in yet today.',
                style: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 13.sp, color: _kMuted)),
          ),
          GestureDetector(
            onTap: _busy ? null : _checkInFlow,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 11.h),
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
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _thumb(mine.proofUrl),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You checked in',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: _kText)),
              SizedBox(height: 3.h),
              _statusPill(mine),
              if (!mine.hasProof) ...[
                SizedBox(height: 8.h),
                GestureDetector(
                  onTap: _busy ? null : _checkInFlow,
                  child: Text('+ Add proof photo',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w700,
                          color: _accent)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buddyRow(DailyProof? buddy, String buddyFirst) {
    if (buddy == null) {
      return Row(
        children: [
          Icon(Icons.hourglass_empty_rounded, size: 18.r, color: _kMuted),
          SizedBox(width: 8.w),
          Expanded(
            child: Text('Waiting on $buddyFirst to check in today.',
                style: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 13.sp, color: _kMuted)),
          ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _thumb(buddy.proofUrl),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$buddyFirst checked in',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: _kText)),
              SizedBox(height: 6.h),
              if (buddy.isPending)
                Row(
                  children: [
                    _verifyBtn('Verified', Icons.check_rounded, _kGreen,
                        () => _review(buddy.id, true)),
                    SizedBox(width: 8.w),
                    _verifyBtn("Doesn't count", Icons.close_rounded,
                        const Color(0xffEF4444), () => _review(buddy.id, false)),
                  ],
                )
              else
                _statusPill(buddy),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _review(String checkinId, bool verified) async {
    await BuddiesController.to.verifyBuddyProof(checkinId, verified);
    AppSnackBar.success(verified ? 'Marked verified ✅' : 'Marked as doesn\'t count');
  }

  Widget _statusPill(DailyProof p) {
    late Color color;
    late String label;
    if (p.isVerified) {
      color = _kGreen;
      label = 'Verified ✓';
    } else if (p.isRejected) {
      color = const Color(0xffEF4444);
      label = "Doesn't count";
    } else {
      color = const Color(0xffF59E0B);
      label = 'Awaiting review';
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20.r)),
      child: Text(label,
          style: AppFonts.spaceGrotesk.copyWith(
              fontSize: 11.5.sp, fontWeight: FontWeight.w800, color: color)),
    );
  }

  Widget _verifyBtn(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15.r, color: color),
            SizedBox(width: 5.w),
            Text(label,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 12.sp, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _thumb(String url) {
    if (url.isEmpty) {
      return Container(
        width: 54.r,
        height: 54.r,
        decoration: BoxDecoration(
          color: const Color(0xffF1EEEC),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(Icons.check_circle, color: _accent, size: 22.r),
      );
    }
    return GestureDetector(
      onTap: () => _viewProof(url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: Image.network(
          url,
          width: 54.r,
          height: 54.r,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 54.r,
            height: 54.r,
            color: const Color(0xffF1EEEC),
            child: Icon(Icons.image_not_supported_outlined,
                color: _kMuted, size: 20.r),
          ),
        ),
      ),
    );
  }
}
