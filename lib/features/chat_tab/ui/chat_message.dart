import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/const/app_fonts.dart';
import 'package:spanx/core/const/app_colors.dart';

Color get _kRed => AppColors.primaryColor;
Color get _kRedDk => AppColors.primaryDarkColor;
const _kBg    = Color(0xffF6F4F2);
const _kText  = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// Messages is not shipping in the first release, so this tab shows a polished
/// "Coming Soon" placeholder instead of the (Firebase-dependent) chat UI, which
/// otherwise rendered as a blank gray screen when Firebase isn't configured.
/// The full chat implementation is preserved in git history / other files and
/// can be re-enabled by restoring the previous MessagesPage.
class MessagesPage extends StatelessWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_kRed, _kRedDk],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 22.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Connect',
                        style: AppFonts.spaceGrotesk.copyWith(color: Colors.white70, fontSize: 12.sp)),
                    Text('Messages',
                        style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ),

          // ── Coming Soon body ──────────────────────────────────────────────
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96.r, height: 96.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _kRed.withOpacity(0.08),
                      ),
                      child: Icon(Icons.forum_outlined, color: _kRed, size: 44.r),
                    ),
                    SizedBox(height: 24.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [_kRed, _kRedDk]),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        'COMING SOON',
                        style: AppFonts.spaceGrotesk.copyWith(
                          color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w800, letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'Messages are on the way',
                      textAlign: TextAlign.center,
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 20.sp, fontWeight: FontWeight.w800, color: _kText,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'Soon you\'ll be able to chat with friends, share wins, and cheer each other on toward your goals. Stay tuned!',
                      textAlign: TextAlign.center,
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 13.sp, color: _kMuted, height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
