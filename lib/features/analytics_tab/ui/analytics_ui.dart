import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/subpage_appbar_widget.dart';
import 'package:spanx/features/analytics_tab/controller/report_analysis_controller.dart';
import 'package:spanx/features/mission/controller/mission_controller.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/const/app_colors.dart';
import '../../../core/const/app_fonts.dart';
import '../../../core/const/app_images.dart';
import '../../../core/const/app_size.dart';
import '../../../core/global_widgets/app_loading.dart';
import '../../../core/global_widgets/custom_text.dart';
import '../controller/analytics_controller.dart';
import '../model/analytics_model.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AnalyticsController());
    final reportAnalysisController = Get.put(ReportAnalysisController());
    final totalReached = Get.find<MissionController>().totalReachedClient;

    return BackgroundScreen(child: SafeArea(
      child: Column(
        children: [
          // Header Section
          // _buildHeader(controller),
          Padding(
            padding:  EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: SubPageAppbarWidget(appbarTitle: "Reports & Analytics", onPressed: (){Get.back();}),
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
    ));

    // return Scaffold(
    //   body: Container(
    //     decoration: const BoxDecoration(
    //       gradient: LinearGradient(
    //         begin: Alignment.topCenter,
    //         end: Alignment.bottomCenter,
    //         colors: [
    //           Color(0xFFFFB6B6), // Light pink at top
    //           Color(0xFFFFA07A), // Light salmon at bottom
    //         ],
    //       ),
    //     ),
    //     child:
    //
    //     SafeArea(
    //       child: Column(
    //         children: [
    //           // Header Section
    //           // _buildHeader(controller),
    //           Padding(
    //             padding:  EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
    //             child: SubPageAppbarWidget(appbarTitle: "Reports & Analytics", onPressed: (){Get.back();}),
    //           ),
    //           // SizedBox(height: 10.h),
    //           // Content
    //           Expanded(
    //             child: Obx(() {
    //               if (controller.isLoading.value) {
    //                 return Center(child: loading());
    //               }
    //
    //               if (controller.analyticsData.value == null) {
    //                 return const Center(child: Text('No data available'));
    //               }
    //
    //               return _buildContent(controller);
    //             }),
    //           ),
    //         ],
    //       ),
    //     ),
    //   ),
    // );
  }

  Widget _buildHeader(AnalyticsController controller, ReportAnalysisController reportController) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: controller.onBackPressed,
            child: Container(
              padding: EdgeInsets.all(8.w),
              child: Icon(
                Icons.arrow_back_ios,
                color: Colors.black87,
                size: 20.w,
              ),
            ),
          ),

          SizedBox(width: 8.w),

          // Title
          headingText(text: 'Reports & Analytics', color: Colors.black87),
        ],
      ),
    );
  }

  Widget _buildContent(AnalyticsController controller, ReportAnalysisController reportAnalysisController) {
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
            _buildGoalTrendSection(controller),

            SizedBox(height: 24.h),

            // Progress Distribution
            _buildProgressDistributionSection(controller),

            SizedBox(height: 24.h),

            // Performance Analytics
            _buildPerformanceSection(controller),

            SizedBox(height: 24.h),

            // Summary Cards
            _buildSummaryCards(controller),

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
                  '${progressInfo?.salesPercent}%',
                  '(Task completed)',
                ),
              ),
              _progressBackground(
                _progressInfo(
                  'Client Sessions',
                  AppImages.handshake,
                  '33',
                  '(Total ${progressInfo?.totalClients} Client)',
                ),
              ),
              _progressBackground(
                _progressInfo(
                  'Time Management',
                  AppImages.time,
                  '${progressInfo?.totalTimeSpentHoursAll}Hr',
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
      padding: EdgeInsets.symmetric(
        horizontal: 5.w,
        vertical: 13.h,
      ),
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

          SizedBox(
            height: 180.h,
            child: Obx(
              () => AnimatedOpacity(
                opacity: controller.animationValue.value,
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
                  series: <CartesianSeries<GoalTrendData, String>>[
                    SplineAreaSeries<GoalTrendData, String>(
                      dataSource: data.goalTrend,
                      xValueMapper: (GoalTrendData data, _) => data.day,
                      yValueMapper: (GoalTrendData data, _) => data.completed,
                      name: 'Completed',
                      color: const Color(0xFF4ECDC4).withOpacity(0.6),
                      borderColor: const Color(0xFF4ECDC4),
                      borderWidth: 3,
                      splineType: SplineType.natural,
                      cardinalSplineTension: 0.5,
                    ),
                    SplineAreaSeries<GoalTrendData, String>(
                      dataSource: data.goalTrend,
                      xValueMapper: (GoalTrendData data, _) => data.day,
                      yValueMapper: (GoalTrendData data, _) => data.pending,
                      name: 'Pending',
                      color: const Color(0xFFFF6B6B).withOpacity(0.6),
                      borderColor: const Color(0xFFFF6B6B),
                      borderWidth: 3,
                      splineType: SplineType.natural,
                      cardinalSplineTension: 0.5,
                    ),
                  ],
                ),
              ),
            ),
          ),
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
              // Radial Bar Chart
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 140.h,
                  child: Obx(
                    () => AnimatedOpacity(
                      opacity: controller.animationValue.value,
                      duration: const Duration(milliseconds: 800),
                      child: SfCircularChart(
                        backgroundColor: Colors.transparent,
                        series: <CircularSeries<ProgressDistributionData, String>>[
                          RadialBarSeries<ProgressDistributionData, String>(
                            dataSource: data.progressDistribution,
                            xValueMapper: (ProgressDistributionData data, _) =>
                                data.category,
                            yValueMapper: (ProgressDistributionData data, _) =>
                                data.percentage,
                            pointColorMapper:
                                (ProgressDistributionData data, _) =>
                                    controller.getProgressColor(data.category),
                            cornerStyle: CornerStyle.bothCurve,
                            radius: '100%',
                            innerRadius: '40%',
                            gap: '10%',
                            trackColor: Colors.grey.withOpacity(0.2),
                            trackBorderWidth: 1,
                            trackBorderColor: Colors.grey.withOpacity(0.3),
                            maximumValue:
                                100, // Set to 100 so percentages are out of 100%
                            useSeriesColor: true,
                            dataLabelSettings: const DataLabelSettings(
                              isVisible: false,
                            ),
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
  Widget _buildPerformanceSection(AnalyticsController controller) {
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
            text: 'Performance Analytics',
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          SizedBox(height: 16.h),

          SizedBox(
            height: 160.h,
            child: Obx(
              () => AnimatedOpacity(
                opacity: controller.animationValue.value,
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
                  series: <CartesianSeries<dynamic, dynamic>>[
                    ColumnSeries<PerformanceData, String>(
                      dataSource: data.performanceAnalytics,
                      xValueMapper: (PerformanceData data, _) => data.week,
                      yValueMapper: (PerformanceData data, _) => data.target,
                      name: 'Target',
                      color: const Color(0xFFFF6B6B),
                      width: 0.6,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    ColumnSeries<PerformanceData, String>(
                      dataSource: data.performanceAnalytics,
                      xValueMapper: (PerformanceData data, _) => data.week,
                      yValueMapper: (PerformanceData data, _) => data.completed,
                      name: 'Completed',
                      color: const Color(0xFF4ECDC4),
                      width: 0.6,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(AnalyticsController controller) {
    final data = controller.analyticsData.value!;

    return Row(
      children: [
        // Total Completed
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
                      text: '${data.totalCompleted}',
                      color: Colors.black87,
                    ),
                  ],
                ),
                //  smallerText(text: 'Tasks completed', color: Colors.black54),
              ],
            ),
          ),
        ),

        SizedBox(width: 12.w),

        // Average Time
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
                smallText(text: 'Avg Time', color: Colors.black),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA726),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.schedule,
                        color: Colors.white,
                        size: 16.w,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    headingText(text: data.avgTime, color: Colors.black87),
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
