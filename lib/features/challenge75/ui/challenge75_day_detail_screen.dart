import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:spanx/core/const/app_fonts.dart';

import '../controller/challenge75_controller.dart';
import '../data/challenge75_models.dart';
import 'challenge75_day_editor.dart';
import 'challenge75_theme.dart';

/// Review (and edit) a single day. Reached by tapping a square on the 75-day
/// grid. Past days can be edited — the change is flagged as edited; future days
/// are read-only until they arrive.
class Challenge75DayDetailScreen extends StatefulWidget {
  final int dayNumber;
  const Challenge75DayDetailScreen({super.key, required this.dayNumber});

  @override
  State<Challenge75DayDetailScreen> createState() =>
      _Challenge75DayDetailScreenState();
}

class _Challenge75DayDetailScreenState
    extends State<Challenge75DayDetailScreen> {
  late Challenge75Day _day;

  @override
  void initState() {
    super.initState();
    _day = Challenge75Controller.to.dayFor(widget.dayNumber).clone();
  }

  @override
  Widget build(BuildContext context) {
    final c = Challenge75Controller.to.config.value;
    if (c == null) {
      return const Scaffold(backgroundColor: C75.bg);
    }
    final date = Challenge75Controller.to.dateForDay(widget.dayNumber);
    final today = DateTime.now();
    final isFuture =
        date.isAfter(DateTime(today.year, today.month, today.day));
    final complete = _day.isComplete(c);

    return Scaffold(
      backgroundColor: C75.bg,
      appBar: AppBar(
        backgroundColor: C75.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: C75.text),
          onPressed: Get.back,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Day ${widget.dayNumber}',
                style: AppFonts.spaceGrotesk.copyWith(
                    color: C75.text,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900)),
            Text(DateFormat('EEE, MMM d').format(date),
                style: AppFonts.spaceGrotesk
                    .copyWith(color: C75.muted, fontSize: 11.sp)),
          ],
        ),
        actions: [
          if (!isFuture)
            Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: Center(
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: (complete ? C75.good : C75.bad)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(complete ? 'Complete' : 'Incomplete',
                      style: AppFonts.spaceGrotesk.copyWith(
                          color: complete ? C75.good : C75.bad,
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 40.h),
        children: [
          if (_day.edited)
            Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: const Color(0xffFFF4E5),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_note_rounded,
                      color: const Color(0xffB45309), size: 16.r),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Edited after the day — ${_editedWhen()}',
                      style: AppFonts.spaceGrotesk.copyWith(
                          color: const Color(0xffB45309), fontSize: 11.5.sp),
                    ),
                  ),
                ],
              ),
            ),
          Challenge75DayEditor(
            day: _day,
            config: c,
            enabled: !isFuture,
            onChanged: () => Challenge75Controller.to.saveDay(_day),
          ),
        ],
      ),
    );
  }

  String _editedWhen() {
    final iso = _day.editedAt;
    if (iso == null) return 'recently';
    try {
      return DateFormat('MMM d').format(DateTime.parse(iso));
    } catch (_) {
      return 'recently';
    }
  }
}
