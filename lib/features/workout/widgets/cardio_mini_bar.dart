import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/services/no_internet/controller.dart';
import '../controller/cardio_controller.dart';
import '../controller/workout_controller.dart';
import '../data/cardio_run.dart';
import '../data/workout_theme.dart';
import '../screen/cardio_tracking_screen.dart';

/// A global "run in progress" pill that floats above EVERY screen while a
/// run/walk is being tracked. Start a run, walk off to the Bible (or budget,
/// nutrition, anything) and it stays put — live time + distance ticking, one
/// tap to drop back into the map. Hidden while you're on the tracker itself,
/// and gone the instant you finish or discard.
///
/// Lives in the app-root overlay (see [main]) so it rides on top of every
/// pushed route, not just the tabs.
class CardioMiniBar extends StatelessWidget {
  const CardioMiniBar({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CardioController>()) return const SizedBox.shrink();
    final c = CardioController.to;

    return Obx(() {
      final show = c.tracking.value && !c.viewing.value;
      // If the offline strip is up, sit just beneath it so the two never
      // stack on top of each other.
      final offline = Get.isRegistered<ConnectivityController>() &&
          !Get.find<ConnectivityController>().isConnected.value;

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutBack,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => SizeTransition(
          sizeFactor: anim,
          axisAlignment: -1,
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: !show
            ? const SizedBox.shrink()
            : Align(
                alignment: Alignment.topCenter,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: (offline ? 34 : 6).h,
                      left: 10.w,
                      right: 10.w,
                    ),
                    child: _pill(c),
                  ),
                ),
              ),
      );
    });
  }

  Widget _pill(CardioController c) {
    final miles = WorkoutController.to.useMiles;
    final dist = (miles
            ? c.distanceMeters.value / 1609.34
            : c.distanceMeters.value / 1000.0)
        .toStringAsFixed(2);
    final paused = c.paused.value;
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () => Get.to(() => CardioTrackingScreen(kind: c.kind.value)),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: WT.surface,
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(
                color: (paused ? WT.amber : WT.flame).withOpacity(0.6),
                width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 9.w,
                height: 9.w,
                decoration: BoxDecoration(
                  color: paused ? WT.amber : WT.flame,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 10.w),
              Text('${c.emoji} ${c.label}',
                  style: TextStyle(
                      color: WT.textHi,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.sp)),
              SizedBox(width: 12.w),
              Text(formatDuration(c.elapsedSec.value),
                  style: TextStyle(
                      color: WT.volt,
                      fontWeight: FontWeight.w900,
                      fontSize: 14.sp,
                      fontFeatures: const [FontFeature.tabularFigures()])),
              SizedBox(width: 10.w),
              Flexible(
                child: Text('· $dist ${miles ? 'mi' : 'km'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: WT.textMid,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp)),
              ),
              const Spacer(),
              Text(paused ? 'PAUSED' : 'Tap to return',
                  style: TextStyle(
                      color: paused ? WT.amber : WT.flame,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5.sp)),
              Icon(Icons.chevron_right_rounded,
                  color: paused ? WT.amber : WT.flame, size: 18.sp),
            ],
          ),
        ),
      ),
    );
  }
}
