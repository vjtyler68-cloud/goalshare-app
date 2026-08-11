import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controller/goalendar_controller.dart';
import '../data/goalendar_models.dart';
import 'goalendar_theme.dart';

class GoalendarSettingsScreen extends StatelessWidget {
  const GoalendarSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = GoalendarController.to;
    return Scaffold(
      backgroundColor: GCal.bg,
      appBar: AppBar(
        backgroundColor: GCal.bg,
        elevation: 0,
        leading: IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back, color: GCal.text)),
        title: Text('Calendar settings', style: GCal.h1),
        centerTitle: true,
      ),
      body: Obx(() {
        final s = c.settings.value;
        return ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            _section('DEFAULT VIEW'),
            _card(Row(
              children: [
                _seg('Month', s.defaultView == 'month', () {
                  s.defaultView = 'month';
                  c.saveSettings(s);
                }),
                SizedBox(width: 8.w),
                _seg('Agenda', s.defaultView == 'agenda', () {
                  s.defaultView = 'agenda';
                  c.saveSettings(s);
                }),
              ],
            )),
            SizedBox(height: 16.h),
            _section('WEEK STARTS ON'),
            _card(Row(
              children: [
                _seg('Sunday', s.weekStartDay == 0, () {
                  s.weekStartDay = 0;
                  c.saveSettings(s);
                }),
                SizedBox(width: 8.w),
                _seg('Monday', s.weekStartDay == 1, () {
                  s.weekStartDay = 1;
                  c.saveSettings(s);
                }),
              ],
            )),
            SizedBox(height: 16.h),
            _section('OPTIONS'),
            _card(_toggle('Show suggested actions', s.showSuggestedActions, (v) {
              s.showSuggestedActions = v;
              c.saveSettings(s);
            })),
            SizedBox(height: 16.h),
            _section('CATEGORY COLORS'),
            _card(Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children: GoalCategory.values
                  .map((cat) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 16.r,
                            height: 16.r,
                            decoration: BoxDecoration(
                                color: cat.color, shape: BoxShape.circle),
                          ),
                          SizedBox(width: 6.w),
                          Text(cat.label,
                              style: GCal.body.copyWith(fontSize: 12.5.sp)),
                        ],
                      ))
                  .toList(),
            )),
            SizedBox(height: 16.h),
            _section('IPHONE CALENDAR'),
            _card(Row(
              children: [
                Icon(Icons.sync_rounded, color: GCal.violet, size: 20.r),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sync with iPhone Calendar', style: GCal.body),
                      SizedBox(height: 2.h),
                      Text(
                          s.deviceSyncEnabled
                              ? 'On — your events sync both ways'
                              : 'See your whole schedule & get native reminders',
                          style: GCal.body
                              .copyWith(fontSize: 11.sp, color: GCal.muted)),
                    ],
                  ),
                ),
                if (c.syncing.value)
                  SizedBox(
                      width: 20.r,
                      height: 20.r,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: GCal.violet))
                else
                  Switch(
                    value: s.deviceSyncEnabled,
                    activeColor: GCal.violet,
                    onChanged: (v) => _onSyncChanged(context, c, v),
                  ),
              ],
            )),
          ],
        );
      }),
    );
  }

  Future<void> _onSyncChanged(
      BuildContext context, GoalendarController c, bool v) async {
    if (!v) {
      c.disableSync();
      return;
    }
    // Priming BEFORE the native prompt — explain why, then request.
    final go = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: GCal.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r)),
        title: Text('Connect your calendar', style: GCal.h1),
        content: Text(
            'Goalendar can show your existing iPhone events and add your '
            'Goalendar events to your calendar — so you see everything in one '
            'place and get native reminders. Your events go in a separate '
            '"Goalshare" calendar you can hide or remove anytime.',
            style: GCal.body.copyWith(height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Not now',
                  style: GCal.body.copyWith(color: GCal.muted))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Connect',
                  style: GCal.body.copyWith(
                      color: GCal.violet, fontWeight: FontWeight.w800))),
        ],
      ),
    );
    if (go != true) return;
    final ok = await c.enableSync();
    if (!ok) {
      Get.rawSnackbar(
        message:
            'Calendar access is off. Enable it in Settings › GoalShare › Calendars.',
        duration: const Duration(seconds: 4),
      );
    } else {
      Get.rawSnackbar(
          message: 'Calendar synced ✓', duration: const Duration(seconds: 2));
    }
  }

  Widget _section(String t) => Padding(
        padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
        child: Text(t, style: GCal.label),
      );

  Widget _card(Widget child) => Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
            color: GCal.card, borderRadius: BorderRadius.circular(16.r)),
        child: child,
      );

  Widget _seg(String label, bool on, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 11.h),
            decoration: BoxDecoration(
                color: on ? GCal.violet : GCal.bg,
                borderRadius: BorderRadius.circular(12.r)),
            child: Center(
              child: Text(label,
                  style: GCal.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: on ? Colors.white : GCal.text)),
            ),
          ),
        ),
      );

  Widget _toggle(String label, bool value, ValueChanged<bool> onCh) => Row(
        children: [
          Expanded(child: Text(label, style: GCal.body)),
          Switch(value: value, activeColor: GCal.violet, onChanged: onCh),
        ],
      );
}
