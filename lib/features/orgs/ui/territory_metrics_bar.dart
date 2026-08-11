import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/features/mission/ui/mission_compass.dart';

/// A compact door-knocking counter bar that pins to the bottom of the territory
/// map. Three tap-counters — Doors Knocked, People Talked To, Bills — plus the
/// live magnetic compass, so a rep can tally the street and stay oriented while
/// the Ameren map fills the rest of the screen.
///
/// Tap a tile to +1 (light haptic), long-press to −1. Counts are today's tally,
/// persisted per org + day, so each day starts fresh and survives app restarts.
class TerritoryMetricsBar extends StatefulWidget {
  final String orgId;
  const TerritoryMetricsBar({super.key, required this.orgId});

  @override
  State<TerritoryMetricsBar> createState() => _TerritoryMetricsBarState();
}

class _TerritoryMetricsBarState extends State<TerritoryMetricsBar> {
  static const _kText = Color(0xff1A1010);
  static const _kMuted = Color(0xff9E9090);

  int _doors = 0;
  int _talked = 0;
  int _bills = 0;

  String get _todayKey {
    final now = DateTime.now();
    final d =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return 'territory_metrics_v1_${widget.orgId}_$d';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_todayKey);
      if (raw != null && raw.isNotEmpty) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          _doors = (m['d'] as num?)?.toInt() ?? 0;
          _talked = (m['t'] as num?)?.toInt() ?? 0;
          _bills = (m['b'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
          _todayKey, jsonEncode({'d': _doors, 't': _talked, 'b': _bills}));
    } catch (_) {}
  }

  void _bump(String which, int delta) {
    setState(() {
      switch (which) {
        case 'd':
          _doors = (_doors + delta).clamp(0, 99999);
          break;
        case 't':
          _talked = (_talked + delta).clamp(0, 99999);
          break;
        case 'b':
          _bills = (_bills + delta).clamp(0, 99999);
          break;
      }
    });
    HapticFeedback.lightImpact();
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primaryColor;
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
          padding: EdgeInsets.fromLTRB(8.w, 8.h, 8.w, 8.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                  child: _counter('Doors\nKnocked', _doors, 'd', accent)),
              SizedBox(width: 6.w),
              Expanded(
                  child: _counter('People\nTalked To', _talked, 't', accent)),
              SizedBox(width: 6.w),
              Expanded(child: _counter('Bills', _bills, 'b', accent)),
              SizedBox(width: 8.w),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MissionCompass(diameter: 48),
                  SizedBox(height: 2.h),
                  Text('Compass',
                      style: AppFonts.spaceGrotesk
                          .copyWith(fontSize: 8.5.sp, color: _kMuted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _counter(String label, int value, String which, Color accent) {
    return GestureDetector(
      onTap: () => _bump(which, 1),
      onLongPress: () => _bump(which, -1),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 6.w),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: accent.withOpacity(0.18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$value',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    color: accent,
                    height: 1.0)),
            SizedBox(height: 3.h),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w700,
                    color: _kText,
                    height: 1.1)),
          ],
        ),
      ),
    );
  }
}
