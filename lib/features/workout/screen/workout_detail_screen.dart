import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controller/workout_controller.dart';
import '../data/cardio_run.dart' show formatDuration;
import '../data/workout_models.dart';
import '../data/workout_theme.dart';

/// Read-only recap of a completed workout — every exercise, set, weight, rep,
/// RPE and PR you logged. Reached by tapping a card in "Recent Workouts".
class WorkoutDetailScreen extends StatelessWidget {
  final WorkoutSession session;
  const WorkoutDetailScreen({super.key, required this.session});

  WorkoutController get c => WorkoutController.to;

  @override
  Widget build(BuildContext context) {
    final unit = c.unit.value;
    return Scaffold(
      backgroundColor: WT.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _header(unit)),
            if (session.exercises.isEmpty)
              SliverToBoxAdapter(child: _empty())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _exerciseCard(session.exercises[i], unit),
                  childCount: session.exercises.length,
                ),
              ),
            SliverToBoxAdapter(child: SizedBox(height: 36.h)),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- header
  Widget _header(String unit) {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 16.h),
      decoration: const BoxDecoration(
        color: WT.surface,
        border: Border(bottom: BorderSide(color: WT.stroke)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: Get.back,
                child: Icon(Icons.chevron_left, color: WT.textHi, size: 30.sp),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Text('${session.emoji}  ${session.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: WT.textHi,
                        fontWeight: FontWeight.w900,
                        fontSize: 20.sp)),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Padding(
            padding: EdgeInsets.only(left: 34.w),
            child: Text(
              '${_dateLabel(session.startedAt)} · ${formatDuration(session.durationSec)}',
              style: TextStyle(color: WT.textMid, fontSize: 12.5.sp),
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              _chip('${session.totalSets}', 'sets', WT.flame),
              SizedBox(width: 10.w),
              _chip(_compact(session.totalVolume), '$unit volume', WT.volt),
              SizedBox(width: 10.w),
              _chip('${session.prCount}', 'PRs', WT.amber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String value, String label, Color accent) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: WT.surfaceHi,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 19.sp)),
            SizedBox(height: 2.h),
            Text(label,
                style: TextStyle(color: WT.textMid, fontSize: 10.5.sp)),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return Padding(
      padding: EdgeInsets.all(40.w),
      child: Center(
        child: Text('No exercises were logged in this workout.',
            textAlign: TextAlign.center,
            style: TextStyle(color: WT.textMid, fontSize: 14.sp)),
      ),
    );
  }

  // -------------------------------------------------------- exercise + sets
  Widget _exerciseCard(ExerciseLog log, String unit) {
    return Container(
      margin: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 0),
      decoration: BoxDecoration(
        color: WT.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: WT.stroke),
      ),
      child: Column(
        children: [
          // header
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 8.h),
            child: Row(
              children: [
                Container(
                  width: 8.w,
                  height: 26.h,
                  decoration: BoxDecoration(
                    gradient: WT.flameGrad,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: WT.textHi,
                              fontWeight: FontWeight.w900,
                              fontSize: 16.sp)),
                      Text(
                          '${log.muscle.label} · ${log.doneSets} ${log.doneSets == 1 ? 'set' : 'sets'}',
                          style: TextStyle(color: WT.textMid, fontSize: 11.sp)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // column labels
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                _hLabel('SET', 40.w),
                Expanded(child: _hLabel(log.timed ? 'TIME' : '$unit × REPS'.toUpperCase(), null)),
                _hLabel('RPE', 48.w),
                _hLabel('', 30.w),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          ...(_numberedSets(log)),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }

  /// Build a row per set, numbering working sets and tagging warmup/drop/failure.
  List<Widget> _numberedSets(ExerciseLog log) {
    final rows = <Widget>[];
    var workingNo = 0;
    for (final s in log.sets) {
      final isWorkingType = s.type == SetType.working || s.type == SetType.failure;
      if (isWorkingType) workingNo++;
      rows.add(_setRow(log, s, s.type == SetType.working ? workingNo : null));
    }
    return rows;
  }

  Widget _setRow(ExerciseLog log, SetEntry s, int? number) {
    final typeColor = WT.setTypeColor(s.type.id);
    final label = s.type == SetType.working ? '$number' : (s.type.short.isEmpty ? '•' : s.type.short);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: s.isPr ? WT.volt.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10.r),
        border: s.isPr ? Border.all(color: WT.volt.withOpacity(0.5)) : null,
      ),
      child: Row(
        children: [
          // set # / type
          SizedBox(
            width: 40.w,
            child: Center(
              child: Container(
                width: 26.w,
                height: 26.w,
                decoration: BoxDecoration(
                  color: s.type == SetType.working
                      ? WT.surfaceHi
                      : typeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: Text(label,
                      style: TextStyle(
                          color: s.type == SetType.working ? WT.textHi : typeColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 12.sp)),
                ),
              ),
            ),
          ),
          // weight × reps (or time)
          Expanded(
            child: Text(
              _setValue(log, s),
              style: TextStyle(
                  color: WT.textHi,
                  fontWeight: FontWeight.w800,
                  fontSize: 15.sp),
            ),
          ),
          // rpe
          SizedBox(
            width: 48.w,
            child: Center(
              child: Text(
                s.rpe == null ? '–' : _fmt(s.rpe!),
                style: TextStyle(
                    color: s.rpe == null ? WT.textLow : WT.amber,
                    fontWeight: FontWeight.w800,
                    fontSize: 14.sp),
              ),
            ),
          ),
          // PR / done marker
          SizedBox(
            width: 30.w,
            child: Center(
              child: s.isPr
                  ? Icon(Icons.emoji_events_rounded, color: WT.volt, size: 18.sp)
                  : Icon(Icons.check_rounded,
                      color: s.done ? WT.volt : WT.textLow, size: 18.sp),
            ),
          ),
        ],
      ),
    );
  }

  /// The middle column: "135 × 8", "BW × 12", or a timed duration.
  String _setValue(ExerciseLog log, SetEntry s) {
    if (log.timed) {
      final d = s.durationSec ?? 0;
      return d > 0 ? formatDuration(d) : '—';
    }
    final reps = s.reps ?? 0;
    if (log.bodyweight || (s.weight ?? 0) == 0) {
      return reps > 0 ? 'BW × $reps' : '—';
    }
    return '${_fmt(s.weight!)} × $reps';
  }

  Widget _hLabel(String t, double? w) => SizedBox(
        width: w,
        child: Text(t,
            textAlign: w == null ? TextAlign.left : TextAlign.center,
            style: TextStyle(
                color: WT.textLow,
                fontWeight: FontWeight.w800,
                fontSize: 10.sp,
                letterSpacing: 0.5)),
      );
}

String _fmt(num n) {
  if (n == n.roundToDouble()) return n.toInt().toString();
  return n.toStringAsFixed(1);
}

String _compact(num n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return _fmt(n);
}

String _dateLabel(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(d.year, d.month, d.day);
  final diff = today.difference(that).inDays;
  final time = TimeOfDay.fromDateTime(d).format24();
  if (diff == 0) return 'Today · $time';
  if (diff == 1) return 'Yesterday · $time';
  if (diff < 7) return '$diff days ago · $time';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[d.month - 1]} ${d.day} · $time';
}

extension _TimeFmt on TimeOfDay {
  /// Simple "h:mm am/pm" without needing a BuildContext/MaterialLocalizations.
  String format24() {
    final h12 = hourOfPeriod == 0 ? 12 : hourOfPeriod;
    final mm = minute.toString().padLeft(2, '0');
    final ap = period == DayPeriod.am ? 'am' : 'pm';
    return '$h12:$mm $ap';
  }
}
