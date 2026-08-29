import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/features/mission/controller/mission_controller.dart';
import 'package:spanx/features/mission/ui/mission_compass.dart';

/// A compact activity-counter bar pinned to the bottom of the territory map.
///
/// It edits the SAME three built-in metrics as the Metrics tab's "Today's
/// Metrics" (via [MissionController]: Homes Knocked / People Talked To / the
/// third built-in), so tapping here and tapping there stay perfectly in sync —
/// one source of truth, one daily rollover, one career-stats pipeline. Labels
/// mirror whatever the user renamed the cards to. The live compass rides along.
class TerritoryMetricsBar extends StatelessWidget {
  const TerritoryMetricsBar({super.key});

  static const _kText = Color(0xff1A1010);

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primaryColor;
    final c = Get.isRegistered<MissionController>()
        ? Get.find<MissionController>()
        : Get.put(MissionController(), permanent: true);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
            top: BorderSide(color: Colors.black.withOpacity(0.06), width: 1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(8.w, 5.h, 8.w, 5.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _counter(c.homesLabel, c.homesKnocked,
                    () => c.decrement(c.homesKnocked),
                    () => c.increment(c.homesKnocked), accent),
              ),
              SizedBox(width: 5.w),
              Expanded(
                child: _counter(c.peopleLabel, c.peopleTalkedTo,
                    () => c.decrement(c.peopleTalkedTo),
                    () => c.increment(c.peopleTalkedTo), accent),
              ),
              SizedBox(width: 5.w),
              Expanded(
                child: _counter(c.salesLabel, c.salesMade,
                    () => c.decrement(c.salesMade),
                    () => c.increment(c.salesMade), accent),
              ),
              SizedBox(width: 7.w),
              // Live field compass — magnetometer-driven, so it works with no
              // signal at all; shows an accurate heading + calibration cue.
              const MissionCompass(
                diameter: 42,
                showReadout: true,
                ensureLocation: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _counter(RxString label, RxInt value, VoidCallback onMinus,
      VoidCallback onPlus, Color accent) {
    void minus() {
      onMinus();
      HapticFeedback.lightImpact();
    }

    void plus() {
      onPlus();
      HapticFeedback.lightImpact();
    }

    return Container(
      padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 4.w),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.07),
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(color: accent.withOpacity(0.18)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 12.h,
            width: double.infinity,
            child: Obx(
              () => FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label.value,
                  maxLines: 1,
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: _kText,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 3.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _pm(Icons.remove_rounded, accent, minus),
              Expanded(
                child: Obx(() => Text('${value.value}',
                    textAlign: TextAlign.center,
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: accent,
                        height: 1.0))),
              ),
              _pm(Icons.add_rounded, accent, plus),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pm(IconData icon, Color accent, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 22.r,
        height: 22.r,
        decoration: BoxDecoration(
          color: accent.withOpacity(0.14),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15.r, color: accent),
      ),
    );
  }
}
