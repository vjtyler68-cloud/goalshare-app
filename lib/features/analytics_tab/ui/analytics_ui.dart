import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/features/achievements/achievements_controller.dart';
import 'package:spanx/features/analytics_tab/controller/report_analysis_controller.dart';
import 'package:spanx/features/mission/controller/mission_controller.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../controller/analytics_controller.dart';
import 'package:spanx/core/const/app_colors.dart';

Color get _kRed => AppColors.primaryColor;
Color get _kRedDk => AppColors.primaryDarkColor;
const _kBg     = Color(0xffF6F4F2);
const _kCard   = Color(0xffFFFFFF);
const _kText   = Color(0xff1A1010);
const _kMuted  = Color(0xff9E9090);

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller             = Get.put(AnalyticsController());
    final reportCtrl             = Get.put(ReportAnalysisController());
    final missionCtrl            = Get.find<MissionController>();
    final achievements           = Get.find<AchievementsController>();

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_kRed, _kRedDk], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 6.h),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                            SizedBox(width: 4.w),
                            Text('Back', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    Text('Performance', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white70, fontSize: 12.sp)),
                    Text('Analytics', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 26.sp, fontWeight: FontWeight.w800)),
                    SizedBox(height: 14.h),
                    // Today's quick stats
                    Obx(() => Row(
                      children: [
                        _HeaderChip(label: 'Homes Today', value: '${missionCtrl.homesKnocked.value}'),
                        SizedBox(width: 10.w),
                        _HeaderChip(label: 'Sales Today', value: '${missionCtrl.salesMade.value}'),
                        SizedBox(width: 10.w),
                        _HeaderChip(label: 'Level', value: achievements.levelTitle),
                      ],
                    )),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(child: CircularProgressIndicator(color: _kRed));
              }
              return RefreshIndicator(
                // Refresh the REAL data sources (server report + missions),
                // not the legacy in-memory sample loader that used to run here.
                onRefresh: () async {
                  await Future.wait([
                    reportCtrl.fetchReportAnalytics(),
                    missionCtrl.fetchMission(),
                  ]);
                },
                color: _kRed,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // All-time career stats
                      _buildCareerSummary(achievements),
                      SizedBox(height: 16.h),

                      // Conversion funnel
                      _buildConversionFunnel(missionCtrl),
                      SizedBox(height: 16.h),

                      // Goal Completion Trend chart
                      _buildGoalTrend(reportCtrl),
                      SizedBox(height: 16.h),

                      // Progress Distribution
                      _buildDistribution(reportCtrl),
                      SizedBox(height: 16.h),

                      // Mission performance
                      _buildMissionPerformance(reportCtrl),
                      SizedBox(height: 16.h),

                      // Summary cards
                      _buildSummaryCards(reportCtrl),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Career Summary ────────────────────────────────────────────────────────

  Widget _buildCareerSummary(AchievementsController ach) {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('All-Time Career'),
        SizedBox(height: 10.h),
        Row(children: [
          Expanded(child: _BigStatCard(label: 'Homes\nKnocked', value: '${ach.totalHomesAllTime.value}', color: const Color(0xff6366F1), icon: Icons.home_outlined)),
          SizedBox(width: 8.w),
          Expanded(child: _BigStatCard(label: 'People\nSpoken To', value: '${ach.totalPeopleAllTime.value}', color: const Color(0xff10B981), icon: Icons.people_outline)),
          SizedBox(width: 8.w),
          Expanded(child: _BigStatCard(label: 'Sales\nClosed', value: '${ach.totalSalesAllTime.value}', color: _kRed, icon: Icons.attach_money)),
        ]),
      ],
    ));
  }

  // ── Conversion Funnel ────────────────────────────────────────────────────

  Widget _buildConversionFunnel(MissionController mc) {
    return Obx(() {
      final homes = mc.homesKnocked.value;
      final people = mc.peopleTalkedTo.value;
      final sales = mc.salesMade.value;
      final talkRate = homes > 0 ? (people / homes * 100).toStringAsFixed(1) : '0.0';
      final closeRate = people > 0 ? (sales / people * 100).toStringAsFixed(1) : '0.0';

      return Container(
        padding: EdgeInsets.all(18.r),
        decoration: _cardDecor(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Today\'s Conversion Funnel'),
            SizedBox(height: 14.h),
            _FunnelStep(label: 'Doors Knocked', value: homes, maxValue: homes > 0 ? homes : 1, color: const Color(0xff6366F1)),
            SizedBox(height: 8.h),
            _FunnelStep(label: 'People Talked To', value: people, maxValue: homes > 0 ? homes : 1, color: const Color(0xff10B981)),
            SizedBox(height: 8.h),
            _FunnelStep(label: 'Sales Made', value: sales, maxValue: homes > 0 ? homes : 1, color: _kRed),
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(child: _RateChip(label: 'Talk Rate', rate: '$talkRate%', color: const Color(0xff10B981))),
                SizedBox(width: 8.w),
                Expanded(child: _RateChip(label: 'Close Rate', rate: '$closeRate%', color: _kRed)),
              ],
            ),
          ],
        ),
      );
    });
  }

  // ── Goal Trend ────────────────────────────────────────────────────────────

  Widget _buildGoalTrend(ReportAnalysisController ctrl) {
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Goal Completion Trend'),
          SizedBox(height: 14.h),
          SizedBox(
            height: 180.h,
            child: Obx(() {
              final trend = ctrl.reportMissionTrend.value;
              if (trend?.labels == null || trend!.labels!.isEmpty) {
                return _emptyChart('No trend data yet. Create and complete missions to see your trend.');
              }
              final chartData = List.generate(trend.labels!.length, (i) => GoalTrendChartData(
                day: trend.labels![i],
                created: trend.created![i],
                completed: trend.completed![i],
              ));
              return SfCartesianChart(
                plotAreaBorderWidth: 0,
                backgroundColor: Colors.transparent,
                primaryXAxis: CategoryAxis(
                  axisLine: const AxisLine(width: 0),
                  majorTickLines: const MajorTickLines(size: 0),
                  labelStyle: TextStyle(color: _kMuted, fontSize: 10.sp),
                ),
                primaryYAxis: NumericAxis(
                  isVisible: false,
                  majorGridLines: const MajorGridLines(width: 0),
                ),
                legend: Legend(isVisible: true, position: LegendPosition.bottom, textStyle: TextStyle(color: _kMuted, fontSize: 10.sp)),
                series: <CartesianSeries<GoalTrendChartData, String>>[
                  SplineAreaSeries<GoalTrendChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (d, _) => d.day,
                    yValueMapper: (d, _) => d.completed,
                    name: 'Completed',
                    color: const Color(0xff10B981).withOpacity(0.3),
                    borderColor: const Color(0xff10B981),
                    borderWidth: 3,
                    splineType: SplineType.natural,
                  ),
                  SplineAreaSeries<GoalTrendChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (d, _) => d.day,
                    yValueMapper: (d, _) => d.created,
                    name: 'Created',
                    color: _kRed.withOpacity(0.2),
                    borderColor: _kRed,
                    borderWidth: 3,
                    splineType: SplineType.natural,
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Distribution ──────────────────────────────────────────────────────────

  Widget _buildDistribution(ReportAnalysisController ctrl) {
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Mission Distribution'),
          SizedBox(height: 14.h),
          Obx(() {
            final cats = ctrl.categoryDistribution;
            if (cats.isEmpty) return _emptyChart('No mission data yet.');
            final total = cats.fold(0, (s, c) => s + (c.count ?? 0));
            final chartData = cats.map((c) {
              final pct = total > 0 ? (c.count ?? 0) / total * 100.0 : 0.0;
              return ProgressDistributionData(category: c.category ?? '', percentage: pct);
            }).toList();
            return Row(children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 130.h,
                  child: SfCircularChart(
                    backgroundColor: Colors.transparent,
                    series: <CircularSeries<ProgressDistributionData, String>>[
                      DoughnutSeries<ProgressDistributionData, String>(
                        dataSource: chartData,
                        xValueMapper: (d, _) => d.category,
                        yValueMapper: (d, _) => d.percentage,
                        pointColorMapper: (d, _) => _catColor(d.category),
                        innerRadius: '60%',
                        cornerStyle: CornerStyle.bothCurve,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  children: chartData.map((d) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    child: Row(children: [
                      Container(width: 10.w, height: 10.h, decoration: BoxDecoration(color: _catColor(d.category), shape: BoxShape.circle)),
                      SizedBox(width: 8.w),
                      Expanded(child: Text(d.category, style: AppFonts.spaceGrotesk.copyWith(fontSize: 11.sp, color: _kMuted))),
                      Text('${d.percentage.toInt()}%', style: AppFonts.spaceGrotesk.copyWith(fontSize: 11.sp, fontWeight: FontWeight.w700, color: _kText)),
                    ]),
                  )).toList(),
                ),
              ),
            ]);
          }),
        ],
      ),
    );
  }

  // ── Mission Performance ───────────────────────────────────────────────────

  Widget _buildMissionPerformance(ReportAnalysisController ctrl) {
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Mission Performance'),
          SizedBox(height: 14.h),
          Obx(() {
            final month = ctrl.reportMonth.value;
            final summary = ctrl.reportSummary.value;
            final perfData = [
              PerformanceData(label: 'Created', monthly: month?.totals?.goalsCreated ?? 0, allTime: summary?.totalGoals ?? 0),
              PerformanceData(label: 'Completed', monthly: month?.totals?.goalsCompleted ?? 0, allTime: summary?.completedGoals ?? 0),
            ];
            return SizedBox(
              height: 150.h,
              child: SfCartesianChart(
                plotAreaBorderWidth: 0,
                backgroundColor: Colors.transparent,
                primaryXAxis: CategoryAxis(
                  axisLine: const AxisLine(width: 0),
                  majorTickLines: const MajorTickLines(size: 0),
                  labelStyle: TextStyle(color: _kMuted, fontSize: 10.sp),
                ),
                primaryYAxis: NumericAxis(isVisible: false, majorGridLines: const MajorGridLines(width: 0)),
                legend: Legend(isVisible: true, position: LegendPosition.bottom, textStyle: TextStyle(color: _kMuted, fontSize: 10.sp)),
                series: <CartesianSeries<PerformanceData, String>>[
                  ColumnSeries<PerformanceData, String>(
                    dataSource: perfData,
                    xValueMapper: (d, _) => d.label,
                    yValueMapper: (d, _) => d.monthly,
                    name: 'This Month',
                    color: _kRed,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  ColumnSeries<PerformanceData, String>(
                    dataSource: perfData,
                    xValueMapper: (d, _) => d.label,
                    yValueMapper: (d, _) => d.allTime,
                    name: 'All Time',
                    color: const Color(0xff10B981),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Summary Cards ─────────────────────────────────────────────────────────

  Widget _buildSummaryCards(ReportAnalysisController ctrl) {
    return Obx(() {
      final summary = ctrl.reportSummary.value;
      return Row(children: [
        Expanded(child: _SummaryCard(label: 'Total Completed', value: '${summary?.completedGoals ?? 0}', icon: Icons.task_alt, color: const Color(0xff10B981))),
        SizedBox(width: 10.w),
        Expanded(child: _SummaryCard(label: 'Total Missions', value: '${summary?.totalGoals ?? 0}', icon: Icons.flag_rounded, color: _kRed)),
        SizedBox(width: 10.w),
        Expanded(child: _SummaryCard(label: 'Completion %', value: '${summary?.salesPercent ?? 0}%', icon: Icons.percent, color: const Color(0xff6366F1))),
      ]);
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String t) => Text(t, style: AppFonts.spaceGrotesk.copyWith(fontSize: 15.sp, fontWeight: FontWeight.w800, color: _kText));

  BoxDecoration _cardDecor() => BoxDecoration(
    color: _kCard,
    borderRadius: BorderRadius.circular(18.r),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 3))],
  );

  Widget _emptyChart(String msg) => Center(
    child: Padding(
      padding: EdgeInsets.all(20.r),
      child: Text(msg, style: AppFonts.spaceGrotesk.copyWith(color: _kMuted, fontSize: 13.sp), textAlign: TextAlign.center),
    ),
  );

  Color _catColor(String cat) {
    switch (cat) {
      case 'Daily': return const Color(0xff6366F1);
      case 'Weekly': return const Color(0xff10B981);
      case 'Monthly': return const Color(0xffF59E0B);
      case 'Yearly': return const Color(0xff8B5CF6);
      default: return _kMuted;
    }
  }
}

// ── Small Widgets ─────────────────────────────────────────────────────────────

class _HeaderChip extends StatelessWidget {
  final String label, value;
  const _HeaderChip({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12.r)),
    child: Column(children: [
      Text(value, style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w800)),
      Text(label, style: AppFonts.spaceGrotesk.copyWith(color: Colors.white70, fontSize: 9.sp)),
    ]),
  );
}

class _BigStatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  final IconData icon;
  const _BigStatCard({required this.label, required this.value, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(12.r),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
    child: Column(children: [
      Container(width: 34.r, height: 34.r, decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 16)),
      SizedBox(height: 6.h),
      Text(value, style: AppFonts.spaceGrotesk.copyWith(fontSize: 20.sp, fontWeight: FontWeight.w800, color: const Color(0xff1A1010))),
      Text(label, style: AppFonts.spaceGrotesk.copyWith(fontSize: 9.sp, color: const Color(0xff9E9090), height: 1.3), textAlign: TextAlign.center),
    ]),
  );
}

class _FunnelStep extends StatelessWidget {
  final String label;
  final int value, maxValue;
  final Color color;
  const _FunnelStep({required this.label, required this.value, required this.maxValue, required this.color});
  @override
  Widget build(BuildContext context) {
    final pct = maxValue > 0 ? value / maxValue : 0.0;
    return Row(children: [
      SizedBox(width: 90.w, child: Text(label, style: AppFonts.spaceGrotesk.copyWith(fontSize: 11.sp, color: const Color(0xff9E9090)))),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(6), child: SizedBox(height: 10, child: LinearProgressIndicator(value: pct.clamp(0.0, 1.0), backgroundColor: color.withOpacity(0.1), valueColor: AlwaysStoppedAnimation<Color>(color))))),
      SizedBox(width: 8.w),
      Text('$value', style: AppFonts.spaceGrotesk.copyWith(fontSize: 12.sp, fontWeight: FontWeight.w700, color: color)),
    ]);
  }
}

class _RateChip extends StatelessWidget {
  final String label, rate;
  final Color color;
  const _RateChip({required this.label, required this.rate, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(12.r),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12.r)),
    child: Column(children: [
      Text(rate, style: AppFonts.spaceGrotesk.copyWith(fontSize: 20.sp, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: AppFonts.spaceGrotesk.copyWith(fontSize: 10.sp, color: const Color(0xff9E9090))),
    ]),
  );
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _SummaryCard({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(12.r),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14.r), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
    child: Column(children: [
      Icon(icon, color: color, size: 20),
      SizedBox(height: 4.h),
      Text(value, style: AppFonts.spaceGrotesk.copyWith(fontSize: 18.sp, fontWeight: FontWeight.w800, color: const Color(0xff1A1010))),
      Text(label, style: AppFonts.spaceGrotesk.copyWith(fontSize: 9.sp, color: const Color(0xff9E9090)), textAlign: TextAlign.center),
    ]),
  );
}

// Chart data classes
class GoalTrendChartData {
  final String day;
  final int created, completed;
  GoalTrendChartData({required this.day, required this.created, required this.completed});
}

class ProgressDistributionData {
  final String category;
  final double percentage;
  ProgressDistributionData({required this.category, required this.percentage});
}

class PerformanceData {
  final String label;
  final int monthly, allTime;
  PerformanceData({required this.label, required this.monthly, required this.allTime});
}
