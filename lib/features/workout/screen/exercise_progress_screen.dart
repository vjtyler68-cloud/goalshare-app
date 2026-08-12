import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../controller/workout_controller.dart';
import '../data/workout_theme.dart';

typedef _PP = ({DateTime date, double topWeight, double bestE1rm, int topReps});

/// Strength progress over time for one exercise — est. 1RM & top weight trends,
/// with all-time bests. The retention/motivation payoff of logging.
class ExerciseProgressScreen extends StatelessWidget {
  final String exerciseId;
  final String name;
  const ExerciseProgressScreen(
      {super.key, required this.exerciseId, required this.name});

  @override
  Widget build(BuildContext context) {
    final c = WorkoutController.to;
    final pts = c.exerciseProgress(exerciseId);
    final bestE1rm =
        pts.fold<double>(0, (a, p) => p.bestE1rm > a ? p.bestE1rm : a);
    final bestW =
        pts.fold<double>(0, (a, p) => p.topWeight > a ? p.topWeight : a);
    final unit = c.unit.value.toUpperCase();

    return Scaffold(
      backgroundColor: WT.bg,
      appBar: AppBar(
        backgroundColor: WT.bg,
        elevation: 0,
        foregroundColor: WT.textHi,
        title: Text(name,
            style: TextStyle(
                color: WT.textHi, fontWeight: FontWeight.w800, fontSize: 17.sp)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 30.h),
        children: [
          Row(
            children: [
              _stat('${bestE1rm.round()} $unit', 'Best est. 1RM', WT.flame),
              SizedBox(width: 10.w),
              _stat('${bestW.round()} $unit', 'Top weight', WT.volt),
              SizedBox(width: 10.w),
              _stat('${pts.length}', 'Sessions', WT.textHi),
            ],
          ),
          SizedBox(height: 18.h),
          if (pts.length < 2)
            _lowData()
          else ...[
            Text('STRENGTH TREND',
                style: TextStyle(
                    color: WT.textLow,
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6)),
            SizedBox(height: 6.h),
            Container(
              height: 280.h,
              padding: EdgeInsets.only(top: 10.h, right: 8.w),
              decoration: BoxDecoration(
                  color: WT.surface,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(color: WT.stroke)),
              child: SfCartesianChart(
                legend: const Legend(
                    isVisible: true,
                    position: LegendPosition.top,
                    textStyle: TextStyle(color: Colors.white70, fontSize: 11)),
                plotAreaBorderWidth: 0,
                primaryXAxis: DateTimeAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                  axisLine: AxisLine(color: WT.stroke),
                  labelStyle:
                      const TextStyle(color: Colors.white54, fontSize: 9),
                  dateFormat: DateFormat.MMMd(),
                ),
                primaryYAxis: NumericAxis(
                  majorGridLines: MajorGridLines(width: 0.5, color: WT.stroke),
                  axisLine: const AxisLine(width: 0),
                  labelStyle:
                      const TextStyle(color: Colors.white54, fontSize: 9),
                ),
                series: <CartesianSeries<_PP, DateTime>>[
                  LineSeries<_PP, DateTime>(
                    name: 'Est. 1RM',
                    dataSource: pts,
                    xValueMapper: (p, _) => p.date,
                    yValueMapper: (p, _) => p.bestE1rm,
                    color: WT.flame,
                    width: 3,
                    markerSettings: MarkerSettings(
                        isVisible: true,
                        color: WT.flame,
                        borderColor: Colors.white,
                        borderWidth: 1.5),
                  ),
                  LineSeries<_PP, DateTime>(
                    name: 'Top weight',
                    dataSource: pts,
                    xValueMapper: (p, _) => p.date,
                    yValueMapper: (p, _) => p.topWeight,
                    color: WT.volt,
                    width: 2,
                    dashArray: const [5, 4],
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Text(
                'Est. 1RM uses the Epley formula (weight × [1 + reps ÷ 30]). '
                'Every session is your heaviest working set that day.',
                style: TextStyle(
                    color: WT.textLow, fontSize: 11.sp, height: 1.5)),
          ],
        ],
      ),
    );
  }

  Widget _stat(String value, String label, Color color) => Expanded(
        child: Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
              color: WT.surface,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: WT.stroke)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 18.sp)),
              SizedBox(height: 2.h),
              Text(label,
                  style: TextStyle(color: WT.textMid, fontSize: 10.5.sp)),
            ],
          ),
        ),
      );

  Widget _lowData() => Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
            color: WT.surface,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: WT.stroke)),
        child: Column(
          children: [
            Icon(Icons.show_chart_rounded, color: WT.flame, size: 40.r),
            SizedBox(height: 10.h),
            Text('Log a couple more sessions',
                style: TextStyle(
                    color: WT.textHi,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.sp)),
            SizedBox(height: 4.h),
            Text('Your strength trend line appears once you\'ve trained this '
                'exercise at least twice.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: WT.textMid, fontSize: 12.sp, height: 1.5)),
          ],
        ),
      );
}
