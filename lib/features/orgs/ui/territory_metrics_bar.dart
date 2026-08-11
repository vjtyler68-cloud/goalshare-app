import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/features/mission/ui/mission_compass.dart';

import '../controller/territory_metrics_controller.dart';

/// A compact door-knocking counter bar that pins to the bottom of the territory
/// map. Three tap-counters — Doors Knocked, People Talked To, Bills — plus the
/// live magnetic compass, so a rep can tally the street and stay oriented while
/// the Ameren map fills the rest of the screen.
///
/// Tap a tile to +1 (light haptic), long-press to −1. The counts live in
/// [TerritoryMetricsController] (today's tally, persisted, day-scoped) so they
/// also roll up to the sales org's metrics — not a separate island.
class TerritoryMetricsBar extends StatelessWidget {
  final String orgId;
  const TerritoryMetricsBar({super.key, required this.orgId});

  static const _kText = Color(0xff1A1010);
  static const _kMuted = Color(0xff9E9090);

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primaryColor;
    final c = TerritoryMetricsController.to;
    void bump(String which, int delta) {
      c.bump(which, delta);
      HapticFeedback.lightImpact();
    }

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
                child: _counter('Doors\nKnocked', c.doors, 'd', accent, bump),
              ),
              SizedBox(width: 5.w),
              Expanded(
                child:
                    _counter('People\nTalked To', c.talked, 't', accent, bump),
              ),
              SizedBox(width: 5.w),
              Expanded(child: _counter('Bills', c.bills, 'b', accent, bump)),
              SizedBox(width: 7.w),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MissionCompass(diameter: 42),
                  SizedBox(height: 1.h),
                  Text('Compass',
                      style: AppFonts.spaceGrotesk
                          .copyWith(fontSize: 8.sp, color: _kMuted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _counter(String label, RxInt value, String which, Color accent,
      void Function(String, int) bump) {
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
          Text(label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 8.5.sp,
                  fontWeight: FontWeight.w700,
                  color: _kText,
                  height: 1.1)),
          SizedBox(height: 3.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _pm(Icons.remove_rounded, accent, () => bump(which, -1)),
              Expanded(
                child: Obx(() => Text('${value.value}',
                    textAlign: TextAlign.center,
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: accent,
                        height: 1.0))),
              ),
              _pm(Icons.add_rounded, accent, () => bump(which, 1)),
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
