import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/features/nutrition/controller/nutrition_controller.dart';
import 'package:spanx/features/nutrition/data/weight_entry.dart';
import 'package:spanx/features/nutrition/widgets/nutrition_sheets.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

const _kRed = Color(0xffE84040);
const _kRedDk = Color(0xff9B1414);
const _kBg = Color(0xffF6F4F2);
const _kCard = Color(0xffFFFFFF);
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);
const _kGreen = Color(0xff22C55E);
const _kBlue = Color(0xff6366F1);

class WeightTrackingScreen extends StatefulWidget {
  const WeightTrackingScreen({super.key});

  @override
  State<WeightTrackingScreen> createState() => _WeightTrackingScreenState();
}

class _WeightTrackingScreenState extends State<WeightTrackingScreen> {
  final NutritionController c = NutritionController.to;

  /// Days to show; 0 = all-time.
  int _range = 30;
  static const _ranges = {7: '7d', 30: '30d', 90: '90d', 0: 'All'};

  List<WeightEntry> get _visible {
    final all = c.weights.toList(); // already oldest → newest
    if (_range == 0) return all;
    final cutoff = DateTime.now().subtract(Duration(days: _range));
    final filtered = all.where((w) => w.date.isAfter(cutoff)).toList();
    return filtered.isEmpty ? all : filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _header(),
          Expanded(
            child: Obx(() {
              c.weights.length; // reactive
              c.goal.value; // reactive
              if (c.weights.isEmpty) return _empty();
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(18.r, 18.r, 18.r, 40.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _statusCard(),
                    SizedBox(height: 16.h),
                    _rangeToggle(),
                    SizedBox(height: 10.h),
                    _chartCard(),
                    SizedBox(height: 16.h),
                    _historyCard(),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _header() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kRed, _kRedDk],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
          child: Row(
            children: [
              GestureDetector(
                onTap: Get.back,
                child: Container(
                  width: 38.r,
                  height: 38.r,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2)),
                  child: Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 16.r),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Track Your Progress',
                        style: AppFonts.spaceGrotesk.copyWith(
                            color: Colors.white70, fontSize: 12.sp)),
                    Text('Weight',
                        style: AppFonts.spaceGrotesk.copyWith(
                            color: Colors.white,
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => NutritionSheets.logWeight(c),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r)),
                  child: Row(
                    children: [
                      Icon(Icons.add_rounded, color: _kRed, size: 18.r),
                      SizedBox(width: 4.w),
                      Text('Log',
                          style: AppFonts.spaceGrotesk.copyWith(
                              color: _kRed,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── PLAIN-LANGUAGE STATUS ───────────────────────────────────────────────────
  Widget _statusCard() {
    final s = _status();
    return Container(
      width: double.infinity,
      decoration: _cardDecor(),
      padding: EdgeInsets.all(18.r),
      child: Row(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
                color: s.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12.r)),
            child: Icon(s.icon, color: s.color, size: 24.r),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.headline,
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: _kText)),
                if (s.sub != null) ...[
                  SizedBox(height: 3.h),
                  Text(s.sub!,
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 11.sp, color: _kMuted, height: 1.35)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rangeToggle() {
    return Row(
      children: _ranges.entries.map((e) {
        final sel = e.key == _range;
        return Padding(
          padding: EdgeInsets.only(right: 8.w),
          child: GestureDetector(
            onTap: () => setState(() => _range = e.key),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: sel ? _kRed : _kCard,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: sel ? null : _softShadow,
              ),
              child: Text(e.value,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : _kMuted)),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── CHART ───────────────────────────────────────────────────────────────────
  Widget _chartCard() {
    final points = _visible;
    final goal = c.goal.value;
    final pacing = _pacingLine();

    return Container(
      width: double.infinity,
      decoration: _cardDecor(),
      padding: EdgeInsets.fromLTRB(8.r, 16.r, 12.r, 8.r),
      height: 280.h,
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        backgroundColor: Colors.transparent,
        legend: Legend(
            isVisible: true,
            position: LegendPosition.top,
            textStyle: TextStyle(color: _kMuted, fontSize: 10.sp)),
        primaryXAxis: DateTimeAxis(
          axisLine: const AxisLine(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          majorGridLines: const MajorGridLines(width: 0),
          labelStyle: TextStyle(color: _kMuted, fontSize: 9.sp),
          dateFormat: null,
          intervalType: DateTimeIntervalType.auto,
        ),
        primaryYAxis: NumericAxis(
          axisLine: const AxisLine(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          labelStyle: TextStyle(color: _kMuted, fontSize: 9.sp),
          labelFormat: '{value}',
          plotBands: goal?.goalWeightLbs != null
              ? <PlotBand>[
                  PlotBand(
                    start: goal!.goalWeightLbs,
                    end: goal.goalWeightLbs,
                    borderWidth: 1.5,
                    borderColor: _kGreen.withOpacity(0.7),
                    dashArray: const <double>[6, 4],
                    text: 'Goal',
                    textStyle: TextStyle(color: _kGreen, fontSize: 9.sp),
                    horizontalTextAlignment: TextAnchor.end,
                  ),
                ]
              : <PlotBand>[],
        ),
        series: <CartesianSeries<_WPoint, DateTime>>[
          if (pacing.length == 2)
            LineSeries<_WPoint, DateTime>(
              dataSource: pacing,
              xValueMapper: (p, _) => p.date,
              yValueMapper: (p, _) => p.weight,
              name: 'On-pace',
              color: _kBlue.withOpacity(0.6),
              width: 2,
              dashArray: const <double>[6, 4],
              markerSettings: const MarkerSettings(isVisible: false),
            ),
          LineSeries<_WPoint, DateTime>(
            dataSource:
                points.map((w) => _WPoint(w.date, w.weightLbs)).toList(),
            xValueMapper: (p, _) => p.date,
            yValueMapper: (p, _) => p.weight,
            name: 'Weight',
            color: _kRed,
            width: 3,
            markerSettings: MarkerSettings(
                isVisible: true,
                height: 5.r,
                width: 5.r,
                color: _kRed,
                borderColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _historyCard() {
    final recent = c.weights.reversed.toList(); // newest first
    return Container(
      width: double.infinity,
      decoration: _cardDecor(),
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('History',
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 15.sp, fontWeight: FontWeight.w800, color: _kText)),
          SizedBox(height: 10.h),
          ...recent.take(30).map((w) => Container(
                margin: EdgeInsets.only(bottom: 6.h),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                    color: _kBg, borderRadius: BorderRadius.circular(12.r)),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(_pretty(w.date),
                          style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: _kText)),
                    ),
                    Text('${_num(w.weightLbs)} lbs',
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: _kText)),
                    SizedBox(width: 10.w),
                    GestureDetector(
                      onTap: () => c.deleteWeight(w.id),
                      child: Icon(Icons.close_rounded,
                          size: 16.r, color: _kMuted),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── pacing + status math (linear trend, pure arithmetic) ─────────────────────
  List<_WPoint> _pacingLine() {
    final g = c.goal.value;
    if (g?.goalWeightLbs == null || c.weights.isEmpty) return const [];
    final start = c.weights.first;
    final goalW = g!.goalWeightLbs!;

    DateTime endDate;
    if (g.targetDate != null && g.targetDate!.isAfter(start.date)) {
      endDate = g.targetDate!;
    } else if (g.targetWeeklyRateLbs != null && g.targetWeeklyRateLbs != 0) {
      final weeks = (goalW - start.weightLbs) / g.targetWeeklyRateLbs!;
      if (weeks <= 0) return const [];
      endDate = start.date.add(Duration(days: (weeks * 7).round()));
    } else {
      return const [];
    }
    return [_WPoint(start.date, start.weightLbs), _WPoint(endDate, goalW)];
  }

  /// Least-squares slope in lbs/day across visible-or-all weigh-ins.
  double? _weeklyTrend() {
    final pts = c.weights;
    if (pts.length < 2) return null;
    final t0 = pts.first.date.millisecondsSinceEpoch.toDouble();
    final xs = pts
        .map((p) =>
            (p.date.millisecondsSinceEpoch - t0) / (1000 * 60 * 60 * 24))
        .toList();
    final ys = pts.map((p) => p.weightLbs).toList();
    final n = xs.length;
    final mx = xs.reduce((a, b) => a + b) / n;
    final my = ys.reduce((a, b) => a + b) / n;
    double numer = 0, den = 0;
    for (int i = 0; i < n; i++) {
      numer += (xs[i] - mx) * (ys[i] - my);
      den += (xs[i] - mx) * (xs[i] - mx);
    }
    if (den == 0) return null;
    return (numer / den) * 7; // per week
  }

  _Status _status() {
    final g = c.goal.value;
    final current = c.latestWeight?.weightLbs;
    if (g?.goalWeightLbs == null || current == null) {
      return _Status(
        icon: Icons.flag_rounded,
        color: _kMuted,
        headline: 'Set a goal weight to see your pace',
        sub: 'Head to Goal Setup to add a target — then this shows whether '
            'you\'re ahead, on track, or behind.',
      );
    }
    final goalW = g!.goalWeightLbs!;
    final remaining = goalW - current;
    if (remaining.abs() <= 1) {
      return _Status(
        icon: Icons.emoji_events_rounded,
        color: _kGreen,
        headline: 'You\'ve reached your goal! 🎉',
        sub: 'You\'re within a pound of ${_num(goalW)} lbs.',
      );
    }
    final trend = _weeklyTrend();
    if (trend == null) {
      return _Status(
        icon: Icons.timeline_rounded,
        color: _kBlue,
        headline: 'Log a few more weigh-ins',
        sub: 'Two or more readings unlock your trend and projected date.',
      );
    }
    final towardGoal = (remaining < 0 && trend < 0) || (remaining > 0 && trend > 0);
    if (!towardGoal || trend.abs() < 0.05) {
      return _Status(
        icon: Icons.trending_flat_rounded,
        color: _kRed,
        headline: 'Your weight is holding steady',
        sub: 'At the moment you\'re not moving toward ${_num(goalW)} lbs — '
            'small daily deficit/surplus changes will restart your trend.',
      );
    }
    final weeksToGoal = remaining / trend; // both signs align → positive
    final projected =
        DateTime.now().add(Duration(days: (weeksToGoal * 7).round()));

    if (g.targetDate != null) {
      final diffWeeks =
          projected.difference(g.targetDate!).inDays / 7.0;
      if (diffWeeks < -1) {
        // Projected to arrive materially earlier than the target date.
        return _Status(
          icon: Icons.rocket_launch_rounded,
          color: _kGreen,
          headline:
              'Ahead of schedule — on pace to hit ${_num(goalW)} lbs around ${_pretty(projected)}',
          sub: 'That\'s about ${diffWeeks.abs().round()} week(s) sooner than your '
              '${_pretty(g.targetDate!)} target. Pace: ${_rate(trend)}/week.',
        );
      }
      if (diffWeeks <= 0.5) {
        return _Status(
          icon: Icons.check_circle_rounded,
          color: _kGreen,
          headline:
              'On track to hit ${_num(goalW)} lbs by ${_pretty(g.targetDate!)}',
          sub: 'Current pace: ${_rate(trend)}/week.',
        );
      }
      return _Status(
        icon: Icons.schedule_rounded,
        color: _kRed,
        headline:
            'About ${diffWeeks.round()} week(s) behind your ${_pretty(g.targetDate!)} target',
        sub: 'At ${_rate(trend)}/week you\'d reach ${_num(goalW)} lbs around '
            '${_pretty(projected)}.',
      );
    }

    return _Status(
      icon: Icons.check_circle_rounded,
      color: _kGreen,
      headline: 'On track to hit ${_num(goalW)} lbs around ${_pretty(projected)}',
      sub: 'Current pace: ${_rate(trend)}/week.',
    );
  }

  // ── shared ────────────────────────────────────────────────────────────────
  Widget _empty() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(30.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monitor_weight_rounded,
                color: _kRed.withOpacity(0.35), size: 54.r),
            SizedBox(height: 16.h),
            Text('No weigh-ins yet',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
            SizedBox(height: 6.h),
            Text('Log your weight to start your trend and see whether you\'re '
                'on pace for your goal.',
                textAlign: TextAlign.center,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 13.sp, color: _kMuted, height: 1.5)),
            SizedBox(height: 20.h),
            ElevatedButton.icon(
              onPressed: () => NutritionSheets.logWeight(c),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: Text('Log Weight',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kRed,
                  elevation: 0,
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 13.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r))),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecor() => BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: _softShadow,
      );

  List<BoxShadow> get _softShadow => [
        BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 14,
            offset: const Offset(0, 4)),
      ];

  String _num(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
  String _rate(double weekly) => '${weekly < 0 ? '−' : '+'}${_num(weekly.abs())} lb';
  String _pretty(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

class _WPoint {
  final DateTime date;
  final double weight;
  _WPoint(this.date, this.weight);
}

class _Status {
  final IconData icon;
  final Color color;
  final String headline;
  final String? sub;
  _Status({required this.icon, required this.color, required this.headline, this.sub});
}
