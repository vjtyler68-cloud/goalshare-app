// Chart Data Models
class SalesData {
  final String month;
  final double value;

  SalesData(this.month, this.value);
}

class GoalTrendData {
  final String day;
  final double completed;
  final double pending;

  GoalTrendData(this.day, this.completed, this.pending);
}

class ProgressDistributionData {
  final String category;
  final double percentage;
  final String color;

  ProgressDistributionData(this.category, this.percentage, this.color);
}

class PerformanceData {
  final String week;
  final double target;
  final double completed;

  PerformanceData(this.week, this.target, this.completed);
}

// Main Analytics Data Model
class AnalyticsData {
  final double totalSales;
  final int clientSessions;
  final double timeManagement;
  final String timeUnit;
  final List<SalesData> salesTrend;
  final List<GoalTrendData> goalTrend;
  final List<ProgressDistributionData> progressDistribution;
  final List<PerformanceData> performanceAnalytics;
  final int totalCompleted;
  final String avgTime;

  AnalyticsData({
    required this.totalSales,
    required this.clientSessions,
    required this.timeManagement,
    required this.timeUnit,
    required this.salesTrend,
    required this.goalTrend,
    required this.progressDistribution,
    required this.performanceAnalytics,
    required this.totalCompleted,
    required this.avgTime,
  });
}

// Dummy Data Generator
class AnalyticsDummyData {
  static AnalyticsData generateDummyData() {
    return AnalyticsData(
      totalSales: 500.0,
      clientSessions: 10,
      timeManagement: 8.5,
      timeUnit: 'Hr',
      salesTrend: _generateSalesTrend(),
      goalTrend: _generateGoalTrend(),
      progressDistribution: _generateProgressDistribution(),
      performanceAnalytics: _generatePerformanceData(),
      totalCompleted: 127,
      avgTime: '12.4h',
    );
  }

  static List<SalesData> _generateSalesTrend() {
    return [
      SalesData('Jan', 300),
      SalesData('Feb', 450),
      SalesData('Mar', 280),
      SalesData('Apr', 520),
      SalesData('May', 390),
      SalesData('Jun', 610),
      SalesData('Jul', 480),
      SalesData('Aug', 720),
      SalesData('Sep', 650),
      SalesData('Oct', 580),
      SalesData('Nov', 750),
      SalesData('Dec', 680),
    ];
  }

  static List<GoalTrendData> _generateGoalTrend() {
    return [
      GoalTrendData('Mon', 25, 35),
      GoalTrendData('Tue', 40, 30),
      GoalTrendData('Wed', 35, 25),
      GoalTrendData('Thu', 50, 40),
      GoalTrendData('Fri', 45, 35),
      GoalTrendData('Sat', 30, 20),
      GoalTrendData('Sun', 20, 15),
    ];
  }

  static List<ProgressDistributionData> _generateProgressDistribution() {
    return [
      ProgressDistributionData('Completed', 45.0, '#FF6B6B'),
      ProgressDistributionData('In Progress', 25.0, '#4ECDC4'),
      ProgressDistributionData('Pending', 20.0, '#45B7D1'),
      ProgressDistributionData('On Hold', 10.0, '#FFA726'),
    ];
  }

  static List<PerformanceData> _generatePerformanceData() {
    return [
      PerformanceData('Week 1', 80, 70),
      PerformanceData('Week 2', 60, 85),
      PerformanceData('Week 3', 90, 65),
      PerformanceData('Week 4', 70, 95),
      PerformanceData('Week 5', 85, 75),
      PerformanceData('Week 6', 75, 80),
    ];
  }
}
