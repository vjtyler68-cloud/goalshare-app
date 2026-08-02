import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';

import '../controller/buddies_controller.dart';

const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// End-of-cycle rating for the current buddy. Stars are required; the note is
/// optional and private (stored for the rater's own review, never shown to the
/// buddy). Submitting is locked to one shot by the controller's guard.
Future<void> showBuddyRatingSheet(String buddyName) {
  return Get.bottomSheet<void>(
    _RatingSheet(buddyName: buddyName),
    isScrollControlled: true,
    barrierColor: Colors.black54,
  );
}

class _RatingSheet extends StatefulWidget {
  final String buddyName;
  const _RatingSheet({required this.buddyName});

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _stars = 0;
  final _note = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_stars == 0 || _submitting) return;
    setState(() => _submitting = true);
    await BuddiesController.to.submitRating(_stars, comment: _note.text.trim());
    if (mounted) Get.back();
    AppSnackBar.success('Thanks for the feedback!');
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primaryColor;
    final name = widget.buddyName.trim().isEmpty
        ? 'your buddy'
        : widget.buddyName.trim();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(22.w, 12.h, 22.w, 18.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(4.r)),
                ),
                SizedBox(height: 18.h),
                Text('How was $name this week?',
                    textAlign: TextAlign.center,
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: _kText)),
                SizedBox(height: 6.h),
                Text('Your rating builds their Buddy reputation.',
                    textAlign: TextAlign.center,
                    style: AppFonts.spaceGrotesk
                        .copyWith(fontSize: 12.5.sp, color: _kMuted)),
                SizedBox(height: 18.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      GestureDetector(
                        onTap: () => setState(() => _stars = i),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6.w),
                          child: Icon(
                            i <= _stars ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 42.r,
                            color: i <= _stars ? const Color(0xffF5B301) : _kMuted,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 18.h),
                TextField(
                  controller: _note,
                  maxLines: 3,
                  maxLength: 240,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 14.sp,
                      color: _kText,
                      fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Private note (optional — only you see this)',
                    hintStyle: AppFonts.spaceGrotesk
                        .copyWith(fontSize: 13.sp, color: _kMuted),
                    filled: true,
                    fillColor: const Color(0xffF6F4F2),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 6.h),
                GestureDetector(
                  onTap: _stars == 0 ? null : _submit,
                  child: Container(
                    height: 52.h,
                    decoration: BoxDecoration(
                      color: _stars == 0 ? _kMuted.withOpacity(0.4) : accent,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    alignment: Alignment.center,
                    child: Text(_submitting ? 'Submitting…' : 'Submit rating',
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
