import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/const/app_fonts.dart';
import '../controller/goflow_controller.dart';
import '../data/goflow_models.dart';
import '../service/goflow_service.dart';
import 'goflow_log_sheet.dart';

const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// A compact month calendar: logged days show a flow dot, the predicted next
/// period window is softly shaded, today is ringed. Tap any day (not in the
/// future beyond today) to log it.
class GoFlowCalendar extends StatefulWidget {
  const GoFlowCalendar({super.key});

  @override
  State<GoFlowCalendar> createState() => _GoFlowCalendarState();
}

class _GoFlowCalendarState extends State<GoFlowCalendar> {
  late DateTime _month; // first of the shown month

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _month = DateTime(n.year, n.month, 1);
  }

  void _shift(int by) =>
      setState(() => _month = DateTime(_month.year, _month.month + by, 1));

  Color get _accent => GoFlowController.to.accentColor;

  Color _flowColor(GoFlowIntensity f) {
    switch (f) {
      case GoFlowIntensity.light:
        return _accent.withOpacity(0.45);
      case GoFlowIntensity.medium:
        return _accent.withOpacity(0.72);
      case GoFlowIntensity.heavy:
        return _accent;
      case GoFlowIntensity.none:
        return Colors.transparent;
    }
  }

  bool _inWindow(DateTime d, DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    final x = DateTime(d.year, d.month, d.day);
    return !x.isBefore(DateTime(a.year, a.month, a.day)) &&
        !x.isAfter(DateTime(b.year, b.month, b.day));
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = GoFlowController.to;
      c.entries.length; // reactive dependency
      c.settings.value;
      final status = c.status;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final firstWeekday = _month.weekday % 7; // Sun=0
      final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
      final cells = <Widget>[];
      for (int i = 0; i < firstWeekday; i++) {
        cells.add(const SizedBox.shrink());
      }
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(_month.year, _month.month, day);
        final entry = c.entryFor(date);
        final isFuture = date.isAfter(today);
        final isToday = date == today;
        final inPredWindow = c.settings.value.role == GoFlowRole.self &&
            status.confidence == GoFlowConfidence.ready &&
            _inWindow(date, status.nextWindowStart, status.nextWindowEnd);
        final isFertile = c.settings.value.role == GoFlowRole.self &&
            status.confidence != GoFlowConfidence.none &&
            status.isFertileOn(date);
        cells.add(
            _dayCell(date, entry, isFuture, isToday, inPredWindow, isFertile));
      }

      return Column(
        children: [
          Row(
            children: [
              _navBtn(Icons.chevron_left, () => _shift(-1)),
              Expanded(
                child: Center(
                  child: Text(_monthLabel(_month),
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: _kText)),
                ),
              ),
              _navBtn(Icons.chevron_right, () => _shift(1)),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              for (final d in const ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                Expanded(
                  child: Center(
                    child: Text(d,
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: _kMuted)),
                  ),
                ),
            ],
          ),
          SizedBox(height: 6.h),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4.h,
            crossAxisSpacing: 4.w,
            children: cells,
          ),
          SizedBox(height: 10.h),
          _legend(),
        ],
      );
    });
  }

  static const Color _fertile = Color(0xff5FA98A);

  Widget _dayCell(DateTime date, GoFlowEntry? entry, bool isFuture,
      bool isToday, bool inPredWindow, bool isFertile) {
    final flow = entry?.flow ?? GoFlowIntensity.none;
    final bleeding = flow.isBleeding;
    final showFertile = isFertile && !bleeding;
    return GestureDetector(
      onTap: isFuture ? null : () => GoFlowLogSheet.show(date),
      child: Container(
        decoration: BoxDecoration(
          color: bleeding
              ? _flowColor(flow)
              : showFertile
                  ? _fertile.withOpacity(0.16)
                  : (inPredWindow
                      ? _accent.withOpacity(0.10)
                      : Colors.transparent),
          borderRadius: BorderRadius.circular(10.r),
          border: isToday
              ? Border.all(color: _accent, width: 1.5)
              : showFertile
                  ? Border.all(color: _fertile.withOpacity(0.5), width: 1)
                  : (inPredWindow && !bleeding
                      ? Border.all(color: _accent.withOpacity(0.4), width: 1)
                      : null),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${date.day}',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 12.5.sp,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                      color: bleeding
                          ? Colors.white
                          : (isFuture ? _kMuted : _kText))),
              if (entry != null && !bleeding)
                Container(
                  margin: EdgeInsets.only(top: 2.h),
                  width: 4.r,
                  height: 4.r,
                  decoration:
                      BoxDecoration(color: _accent, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legend() {
    Widget dot(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 10.r,
                height: 10.r,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            SizedBox(width: 4.w),
            Text(label,
                style: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 10.5.sp, color: _kMuted)),
          ],
        );
    return Wrap(
      spacing: 14.w,
      runSpacing: 6.h,
      alignment: WrapAlignment.center,
      children: [
        dot(_accent, 'Period'),
        dot(_fertile.withOpacity(0.4), 'Fertile'),
        dot(_accent.withOpacity(0.12), 'Predicted'),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 10.r,
                height: 10.r,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _accent, width: 1.5))),
            SizedBox(width: 4.w),
            Text('Today',
                style: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 10.5.sp, color: _kMuted)),
          ],
        ),
      ],
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(6.r),
          child: Icon(icon, color: _kText, size: 22.r),
        ),
      );

  String _monthLabel(DateTime m) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December'
    ];
    return '${names[m.month - 1]} ${m.year}';
  }
}
