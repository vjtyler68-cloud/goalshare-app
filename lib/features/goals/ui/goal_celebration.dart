import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:spanx/core/const/app_fonts.dart';

const _kText = Color(0xff1A1010);

/// A quick, non-blocking confetti burst shown when a goal is completed.
/// Rendered in the app Overlay behind an [IgnorePointer] so the user can keep
/// tapping, and auto-removes itself after the animation.
class GoalCelebration {
  static void show({String message = 'Goal crushed! 🎉'}) {
    final ctx = Get.overlayContext ?? Get.context;
    if (ctx == null) return;
    final overlay = Overlay.maybeOf(ctx);
    if (overlay == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        child: _CelebrationView(message: message),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 1800), () {
      entry.remove();
    });
  }
}

class _CelebrationView extends StatelessWidget {
  const _CelebrationView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Lottie.asset(
            'assets/jsons/confetti.json',
            fit: BoxFit.cover,
            repeat: false,
          ),
        ),
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.elasticOut,
            builder: (_, t, child) => Transform.scale(
              scale: (0.6 + 0.4 * t).clamp(0.0, 1.0),
              child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                message,
                style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: _kText,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
