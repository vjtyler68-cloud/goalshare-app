import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/subpage_appbar_widget.dart';
import 'package:spanx/features/analytics_tab/controller/report_analysis_controller.dart';

import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../core/const/app_colors.dart';
import '../../../core/const/app_fonts.dart';
import '../../../core/const/app_images.dart';
import '../../../core/const/app_size.dart';
import '../../../core/global_widgets/app_loading.dart';
import '../../../core/global_widgets/custom_text.dart';
import '../controller/analytics_controller.dart';
import '../model/report_analysis_model.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AnalyticsController());
    final reportAnalysisController = Get.put(ReportAnalysisController());

    return BackgroundScreen(
      child: SafeArea(
        child: Column(
          children: [
            // Header Section
            // _buildHeader(controller),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: SubPageAppbarWidget(
                appbarTitle: "Reports & Analytics",
                onPressed: () {
                  Get.back();
                },
              ),
            ),
            // SizedBox(height: 10.h),
            // Content
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return Center(child: loading());
                }

                if (controller.analyticsData.value == null) {
                  return const Center(child: Text('No data available'));
                }

                return _buildContent(controller, reportAnalysisController);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    AnalyticsController controller,
    ReportAnalysisController reportAnalysisController,
  ) {
    return RefreshIndicator(
      onRefresh: () async => controller.refreshData(),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress Section
            _buildProgressSection(reportAnalysisController),

            // Goal Completion Trend
            _buildGoalTrendSection(reportAnalysisController),

            SizedBox(height: 24.h),

            // Progress Distribution
            _buildProgressDistributionSection(reportAnalysisController),

            SizedBox(height: 24.h),

            // Performance Analytics
            _buildPerformanceSection(reportAnalysisController),

            SizedBox(height: 24.h),

            // Summary Cards
            _buildSummaryCards(reportAnalysisController),

            SizedBox(height: 100.h),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(ReportAnalysisController controller) {
    final progressInfo = controller.reportSummary.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress
        Row(
          children: [
            Text(
              'Progress',
              style: AppFonts.spaceGrotesk.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16.sp,
                color: AppColors.greyColor70,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),

        // grids
        SizedBox(
          height: 210.h,
          child: GridView(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSizes.w(10),
              mainAxisSpacing: AppSizes.h(10),
              childAspectRatio: 1.8,
            ),
            children: [
              // all the widgets are written down of this file
              _progressBackground(
                _progressInfo(
                  'Sales',
                  AppImages.flame,
                  '${progressInfo?.salesPercent ?? 0}%',
                  '(Task completed)',
                ),
              ),
              _progressBackground(
                _progressInfo(
                  'Client Sessions',
                  AppImages.handshake,
                  '${progressInfo?.completedGoals ?? 0} ',
                  '(Total ${progressInfo?.totalClients ?? 0} Client)',
                ),
              ),
              _progressBackground(
                _progressInfo(
                  'Time Management',
                  AppImages.time,
                  '${progressInfo?.totalTimeSpentHoursAll ?? 0} Hr',
                  '',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _progressInfo(
    String heading,
    String iconPath,
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // title
        Text(
          heading,
          style: AppFonts.spaceGrotesk.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 13.sp,
            color: AppColors.greyColor70,
          ),
        ),
        SizedBox(height: 5.h),
        // row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 24.h,
              child: Image.asset(iconPath, fit: BoxFit.cover),
            ),
            SizedBox(width: 5.w),
            Text(
              title,
              style: AppFonts.spaceGrotesk.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16.sp,
                color: AppColors.greyColor70,
              ),
            ),
            SizedBox(width: 5.w),
            Text(
              subtitle,
              style: AppFonts.spaceGrotesk.copyWith(
                // fontWeight: FontWeight.bold,
                fontSize: 7.sp,
                color: AppColors.blackColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _progressBackground(Widget widget) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 13.h),
      width: AppSizes.w(220),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppImages.bg_minicard),
          fit: BoxFit.fill,
        ),
        // color: AppColors.lightPinkColor,
        borderRadius: BorderRadius.circular(13.r),
      ),
      child: widget,
    );
  }

  Widget _buildGoalTrendSection(ReportAnalysisController controller) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          smallText(
            text: 'Goal Completion Trend',
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 180.h,
            child: Obx(() {
              final trend = controller.reportMissionTrend.value;
              if (trend?.labels == null || trend!.labels!.isEmpty) {
                return Center(child: Text('No trend data'));
              }

              // Combine labels, created, completed into chart data
              List<GoalTrendChartData> chartData = List.generate(
                trend!.labels!.length,
                (index) => GoalTrendChartData(
                  day: trend.labels![index],
                  created: trend.created![index],
                  completed: trend.completed![index],
                ),
              );

              return AnimatedOpacity(
                opacity: 1.0, // You can add animation logic if needed
                duration: const Duration(milliseconds: 800),
                child: SfCartesianChart(
                  plotAreaBorderWidth: 0,
                  backgroundColor: Colors.transparent,
                  primaryXAxis: CategoryAxis(
                    axisLine: const AxisLine(width: 0),
                    majorTickLines: const MajorTickLines(size: 0),
                    labelStyle: TextStyle(
                      color: Colors.black54,
                      fontSize: 10.sp,
                    ),
                  ),
                  primaryYAxis: NumericAxis(
                    isVisible: false,
                    axisLine: const AxisLine(width: 0),
                    majorTickLines: const MajorTickLines(size: 0),
                    majorGridLines: const MajorGridLines(width: 0),
                  ),
                  legend: Legend(
                    isVisible: true,
                    position: LegendPosition.bottom,
                    textStyle: TextStyle(
                      color: Colors.black54,
                      fontSize: 10.sp,
                    ),
                  ),
                  series: <CartesianSeries<GoalTrendChartData, String>>[
                    SplineAreaSeries<GoalTrendChartData, String>(
                      dataSource: chartData,
                      xValueMapper: (data, _) => data.day,
                      yValueMapper: (data, _) => data.completed,
                      name: 'Completed',
                      color: const Color(0xFF4ECDC4).withOpacity(0.6),
                      borderColor: const Color(0xFF4ECDC4),
                      borderWidth: 3,
                      splineType: SplineType.natural,
                    ),
                    SplineAreaSeries<GoalTrendChartData, String>(
                      dataSource: chartData,
                      xValueMapper: (data, _) => data.day,
                      yValueMapper: (data, _) => data.created,
                      name: 'Created',
                      color: const Color(0xFFFF6B6B).withOpacity(0.6),
                      borderColor: const Color(0xFFFF6B6B),
                      borderWidth: 3,
                      splineType: SplineType.natural,
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressDistributionSection(
    ReportAnalysisController controller,
  ) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          smallText(
            text: 'Progress Distribution',
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 140.h,
                  child: Obx(() {
                    final categories = controller.categoryDistribution;
                    if (categories.isEmpty)
                      return Center(child: Text('No data'));

                    int totalCount = categories.fold(
                      0,
                      (sum, item) => sum + (item.count ?? 0),
                    );
                    if (totalCount == 0) totalCount = 1; // avoid div by zero

                    List<ProgressDistributionData> chartData = categories.map((
                      item,
                    ) {
                      double pct = (item.count ?? 0) / totalCount * 100;
                      return ProgressDistributionData(
                        category: item.category ?? '',
                        percentage: pct,
                      );
                    }).toList();

                    return SfCircularChart(
                      backgroundColor: Colors.transparent,
                      series:
                          <CircularSeries<ProgressDistributionData, String>>[
                            RadialBarSeries<ProgressDistributionData, String>(
                              dataSource: chartData,
                              xValueMapper: (data, _) => data.category,
                              yValueMapper: (data, _) => data.percentage,
                              pointColorMapper: (data, _) =>
                                  _getCategoryColor(data.category),
                              cornerStyle: CornerStyle.bothCurve,
                              radius: '100%',
                              innerRadius: '40%',
                              gap: '10%',
                              trackColor: Colors.grey.withOpacity(0.2),
                              maximumValue: 100,
                              useSeriesColor: true,
                              dataLabelSettings: const DataLabelSettings(
                                isVisible: false,
                              ),
                            ),
                          ],
                    );
                  }),
                ),
              ),
              Expanded(
                flex: 2,
                child: Obx(() {
                  final categories = controller.categoryDistribution;
                  int totalCount = categories.fold(
                    0,
                    (sum, item) => sum + (item.count ?? 0),
                  );
                  if (totalCount == 0) totalCount = 1;

                  return Column(
                    children: categories.map((item) {
                      double pct = (item.count ?? 0) / totalCount * 100;
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        child: Row(
                          children: [
                            Container(
                              width: 12.w,
                              height: 12.h,
                              decoration: BoxDecoration(
                                color: _getCategoryColor(item.category ?? ''),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: smallerText(
                                text: item.category ?? '',
                                color: Colors.black54,
                              ),
                            ),
                            smallerText(
                              text: '${pct.toInt()}%',
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Daily':
        return Colors.blue;
      case 'Weekly':
        return Colors.green;
      case 'Monthly':
        return Colors.orange;
      case 'Yearly':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /*
  Widget _buildGoalTrendSection(AnalyticsController controller) {
    final data = controller.analyticsData.value!;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          smallText(
            text: 'Goal Completion Trend',
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: 16.h),

          // SizedBox(
          //   height: 180.h,
          //   child: Obx(() => AnimatedOpacity(
          //     opacity: controller.animationValue.value,
          //     duration: const Duration(milliseconds: 800),
          //     child: SfCartesianChart(
          //       plotAreaBorderWidth: 0,
          //       backgroundColor: Colors.transparent,
          //       primaryXAxis: CategoryAxis(
          //         axisLine: const AxisLine(width: 0),
          //         majorTickLines: const MajorTickLines(size: 0),
          //         labelStyle: TextStyle(color: Colors.black54, fontSize: 10.sp),
          //       ),
          //       primaryYAxis: NumericAxis(
          //         isVisible: false,
          //         axisLine: const AxisLine(width: 0),
          //         majorTickLines: const MajorTickLines(size: 0),
          //         majorGridLines: const MajorGridLines(width: 0),
          //       ),
          //       legend: Legend(
          //         isVisible: true,
          //         position: LegendPosition.bottom,
          //         textStyle: TextStyle(color: Colors.black54, fontSize: 10.sp),
          //       ),
          //       series: <ChartSeries<GoalTrendData, String>>[
          //         AreaSeries<GoalTrendData, String>(
          //           dataSource: data.goalTrend,
          //           xValueMapper: (GoalTrendData data, _) => data.day,
          //           yValueMapper: (GoalTrendData data, _) => data.completed,
          //           name: 'Completed',
          //           color: const Color(0xFFFF6B6B).withOpacity(0.7),
          //           borderColor: const Color(0xFFFF6B6B),
          //           borderWidth: 2,
          //         ),
          //         AreaSeries<GoalTrendData, String>(
          //           dataSource: data.goalTrend,
          //           xValueMapper: (GoalTrendData data, _) => data.day,
          //           yValueMapper: (GoalTrendData data, _) => data.pending,
          //           name: 'Pending',
          //           color: const Color(0xFFFFA726).withOpacity(0.7),
          //           borderColor: const Color(0xFFFFA726),
          //           borderWidth: 2,
          //         ),
          //       ],
          //     ),
          //   )),
          // ),
        ],
      ),
    );
  }


  Widget _buildProgressDistributionSection(AnalyticsController controller) {
    final data = controller.analyticsData.value!;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          smallText(
            text: 'Progress Distribution',
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: 16.h),

          Row(
            children: [
              // Doughnut Chart
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 120.h,
                  child: Obx(
                    () => AnimatedOpacity(
                      opacity: controller.animationValue.value,
                      duration: const Duration(milliseconds: 800),
                      child: SfCircularChart(
                        backgroundColor: Colors.transparent,
                        series:
                            <CircularSeries<ProgressDistributionData, String>>[
                              DoughnutSeries<ProgressDistributionData, String>(
                                dataSource: data.progressDistribution,
                                xValueMapper:
                                    (ProgressDistributionData data, _) =>
                                        data.category,
                                yValueMapper:
                                    (ProgressDistributionData data, _) =>
                                        data.percentage,
                                pointColorMapper:
                                    (ProgressDistributionData data, _) =>
                                        controller.getProgressColor(
                                          data.category,
                                        ),
                                innerRadius: '60%',
                                cornerStyle: CornerStyle.bothCurve,
                                strokeWidth: 3,
                                strokeColor: Colors.white,
                              ),
                            ],
                      ),
                    ),
                  ),
                ),
              ),

              // Legend
              Expanded(
                flex: 2,
                child: Column(
                  children: data.progressDistribution.map((item) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Row(
                        children: [
                          Container(
                            width: 12.w,
                            height: 12.h,
                            decoration: BoxDecoration(
                              color: controller.getProgressColor(item.category),
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: smallerText(
                              text: item.category,
                              color: Colors.black54,
                            ),
                          ),
                          smallerText(
                            text: '${item.percentage.toInt()}%',
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
*/
  Widget _buildPerformanceSection(ReportAnalysisController controller) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          smallText(
            text: 'Performance Analytics',
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: 16.h),
          SizedBox(
            height: 160.h,
            child: Obx(() {
              final month = controller.reportMonth.value;
              final summary = controller.reportSummary.value;

              final List<PerformanceData> perfData = [
                PerformanceData(
                  label: 'Created',
                  monthly: month?.totals?.goalsCreated ?? 0,
                  allTime: summary?.totalGoals ?? 0,
                ),
                PerformanceData(
                  label: 'Completed',
                  monthly: month?.totals?.goalsCompleted ?? 0,
                  allTime: summary?.completedGoals ?? 0,
                ),
              ];

              return SfCartesianChart(
                plotAreaBorderWidth: 0,
                backgroundColor: Colors.transparent,
                primaryXAxis: CategoryAxis(
                  axisLine: const AxisLine(width: 0),
                  majorTickLines: const MajorTickLines(size: 0),
                  labelStyle: TextStyle(color: Colors.black54, fontSize: 10.sp),
                ),
                primaryYAxis: NumericAxis(
                  isVisible: false,
                  axisLine: const AxisLine(width: 0),
                  majorTickLines: const MajorTickLines(size: 0),
                  majorGridLines: const MajorGridLines(width: 0),
                ),
                legend: Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                  textStyle: TextStyle(color: Colors.black54, fontSize: 10.sp),
                ),
                series: <CartesianSeries<PerformanceData, String>>[
                  ColumnSeries<PerformanceData, String>(
                    dataSource: perfData,
                    xValueMapper: (data, _) => data.label,
                    yValueMapper: (data, _) => data.monthly,
                    name: 'This Month',
                    color: const Color(0xFFFF6B6B),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  ColumnSeries<PerformanceData, String>(
                    dataSource: perfData,
                    xValueMapper: (data, _) => data.label,
                    yValueMapper: (data, _) => data.allTime,
                    name: 'All Time',
                    color: const Color(0xFF4ECDC4),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(ReportAnalysisController controller) {
    final summary = controller.reportSummary.value;
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                smallText(text: 'Total Completed', color: Colors.black),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ECDC4),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.task_alt,
                        color: Colors.white,
                        size: 10.w,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    headingText(
                      text: '${summary?.completedGoals ?? 0}',
                      color: Colors.black87,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                smallText(text: 'Total Goals', color: Colors.black),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA726),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(Icons.flag, color: Colors.white, size: 16.w),
                    ),
                    SizedBox(width: 8.w),
                    headingText(
                      text: '${summary?.totalGoals ?? 0}',
                      color: Colors.black87,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Note: Make sure to add these dependencies in pubspec.yaml:
// syncfusion_flutter_charts: ^24.1.41
// percent_indicator: ^4.2.1
class PerformanceData {
  final String label;
  final int monthly;
  final int allTime;

  PerformanceData({
    required this.label,
    required this.monthly,
    required this.allTime,
  });
}

class ProgressDistributionData {
  final String category;
  final double percentage;

  ProgressDistributionData({required this.category, required this.percentage});
}
