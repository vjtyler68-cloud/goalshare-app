import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';

import '../controller/buddies_controller.dart';
import '../data/checkin_models.dart';

const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);
const _kHit = Color(0xff16A34A);
const _kMiss = Color(0xffEF4444);

/// Shared daily status thread — tell your buddy about your day and whether you
/// hit your goals, and see their updates too. Both sides post; both sides read.
class BuddyStatusCard extends StatefulWidget {
  const BuddyStatusCard({super.key});

  @override
  State<BuddyStatusCard> createState() => _BuddyStatusCardState();
}

class _BuddyStatusCardState extends State<BuddyStatusCard> {
  final TextEditingController _text = TextEditingController();

  // null = didn't say, true = hit goals, false = missed.
  bool? _hit;
  bool _busy = false;

  Color get _accent => AppColors.primaryColor;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final t = _text.text.trim();
    if (t.isEmpty) {
      AppSnackBar.error('Write a quick update first.');
      return;
    }
    setState(() => _busy = true);
    final ok = await BuddiesController.to.postStatus(t, hitGoals: _hit);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      _text.clear();
      setState(() => _hit = null);
    } else {
      AppSnackBar.error('Could not share that update.');
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Icon(Icons.today_rounded, color: _accent, size: 18.r),
              SizedBox(width: 8.w),
              Text('Daily status',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: _kText)),
            ],
          ),
          SizedBox(height: 4.h),
          Text('Tell your buddy how your day went.',
              style: AppFonts.spaceGrotesk
                  .copyWith(fontSize: 12.sp, color: _kMuted)),
          SizedBox(height: 12.h),

          // ── Composer ────────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xffF7F5F4),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xffEDE9E7)),
            ),
            child: TextField(
              controller: _text,
              minLines: 1,
              maxLines: 4,
              maxLength: 400,
              style: AppFonts.spaceGrotesk
                  .copyWith(fontSize: 13.5.sp, color: _kText),
              decoration: InputDecoration(
                border: InputBorder.none,
                counterText: '',
                hintText: "What did you get done today?",
                hintStyle: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 13.sp, color: _kMuted),
              ),
            ),
          ),
          SizedBox(height: 10.h),

          // ── Did you hit your goals? ─────────────────────────────────────────
          Row(
            children: [
              Text('Hit your goals?',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: _kText)),
              SizedBox(width: 10.w),
              _choice('Yes', true, _kHit, Icons.check_circle_rounded),
              SizedBox(width: 8.w),
              _choice('Not yet', false, _kMiss, Icons.trending_up_rounded),
            ],
          ),
          SizedBox(height: 12.h),

          // ── Share button ────────────────────────────────────────────────────
          GestureDetector(
            onTap: _busy ? null : _post,
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: _busy ? _accent.withOpacity(0.6) : _accent,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(_busy ? 'Sharing…' : 'Share update',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
          ),

          // ── Thread (mine + buddy's) ─────────────────────────────────────────
          Obx(() {
            final items = BuddiesController.to.statusUpdates;
            if (items.isEmpty) {
              return Padding(
                padding: EdgeInsets.only(top: 14.h),
                child: Text('No updates yet — be the first to check in.',
                    style: AppFonts.spaceGrotesk
                        .copyWith(fontSize: 12.5.sp, color: _kMuted)),
              );
            }
            return Column(
              children: [
                SizedBox(height: 14.h),
                Divider(color: const Color(0xffEDE9E7), height: 1),
                SizedBox(height: 10.h),
                for (final u in items) _entry(u),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _choice(String label, bool value, Color color, IconData icon) {
    final selected = _hit == value;
    return GestureDetector(
      // Tapping the selected one again clears it (back to "didn't say").
      onTap: () => setState(() => _hit = selected ? null : value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : const Color(0xffF1EEEC),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
              color: selected ? color : Colors.transparent, width: 1.4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15.r, color: selected ? color : _kMuted),
            SizedBox(width: 5.w),
            Text(label,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: selected ? color : _kMuted)),
          ],
        ),
      ),
    );
  }

  Widget _entry(BuddyStatusUpdate u) {
    final mine = u.mine;
    final who = mine ? 'You' : (u.senderName.isNotEmpty ? u.senderName : 'Buddy');
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: mine ? _accent.withOpacity(0.06) : const Color(0xffF7F5F4),
        borderRadius: BorderRadius.circular(12.r),
        border: Border(
          left: BorderSide(
              color: mine ? _accent : const Color(0xffD9D3D0), width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(who,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w800,
                      color: mine ? _accent : _kText)),
              SizedBox(width: 8.w),
              if (u.saysHit) _goalChip('Hit goals', _kHit, Icons.check_circle),
              if (u.saysMissed)
                _goalChip('Working on it', _kMiss, Icons.trending_up),
              const Spacer(),
              Text(u.whenLabel,
                  style: AppFonts.spaceGrotesk
                      .copyWith(fontSize: 11.sp, color: _kMuted)),
            ],
          ),
          if (u.text.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(u.text,
                style: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 13.sp, color: _kText, height: 1.35)),
          ],
        ],
      ),
    );
  }

  Widget _goalChip(String label, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.r, color: color),
          SizedBox(width: 4.w),
          Text(label,
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}
