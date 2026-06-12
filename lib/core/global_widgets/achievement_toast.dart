import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/features/achievements/achievements_controller.dart';

/// Wrap around MainNavbarScreen to listen for newly-unlocked achievements.
class AchievementListener extends StatefulWidget {
  final Widget child;
  const AchievementListener({super.key, required this.child});

  @override
  State<AchievementListener> createState() => _AchievementListenerState();
}

class _AchievementListenerState extends State<AchievementListener> {
  late final Worker _worker;

  @override
  void initState() {
    super.initState();
    final ac = Get.put(AchievementsController(), permanent: true);
    _worker = ever(ac.newlyUnlocked, (List<String> ids) {
      if (ids.isNotEmpty) {
        final id = ids.last;
        final a = ac.achievements.firstWhereOrNull((x) => x.id == id);
        if (a != null) _showToast(a);
      }
    });
  }

  void _showToast(Achievement a) {
    // Avoid stacking toasts if one is already visible
    if (Get.isDialogOpen == true) return;
    Get.dialog(
      _AchievementDialog(achievement: a),
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.65),
    );
  }

  @override
  void dispose() {
    _worker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _AchievementDialog extends StatefulWidget {
  final Achievement achievement;
  const _AchievementDialog({required this.achievement});
  @override
  State<_AchievementDialog> createState() => _AchievementDialogState();
}

class _AchievementDialogState extends State<_AchievementDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();

    // Auto-dismiss after 4 s — only if still mounted
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && (Get.isDialogOpen == true)) Get.back();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.achievement;
    return FadeTransition(
      opacity: _fade,
      child: Center(
        child: ScaleTransition(
          scale: _scale,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: Get.back,
              child: Container(
                width: 300.w,
                padding: EdgeInsets.all(28.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28.r),
                  boxShadow: [
                    BoxShadow(
                      color: a.color.withOpacity(0.35),
                      blurRadius: 40,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glow circle with emoji
                    Container(
                      width: 88.r,
                      height: 88.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: a.color.withOpacity(0.15),
                        border: Border.all(color: a.color, width: 3),
                        boxShadow: [BoxShadow(color: a.color.withOpacity(0.35), blurRadius: 24)],
                      ),
                      child: Center(
                        child: Text(a.emoji, style: TextStyle(fontSize: 38.sp)),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // "Unlocked" chip
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: const Color(0xff22C55E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xff22C55E), size: 14),
                          SizedBox(width: 4.w),
                          Text(
                            'Achievement Unlocked!',
                            style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xff22C55E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),

                    Text(
                      a.title,
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xff1A1010),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      a.description,
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 13.sp,
                        color: const Color(0xff9E9090),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24.h),

                    // CTA button
                    GestureDetector(
                      onTap: Get.back,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [a.color, a.color.withOpacity(0.75)],
                          ),
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Center(
                          child: Text(
                            'Awesome! 🎉',
                            style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Tap anywhere to dismiss',
                      style: AppFonts.spaceGrotesk.copyWith(fontSize: 10.sp, color: const Color(0xff9E9090)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
