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

// ===========================
// To parse this JSON data, do
//
//     final analyticsModel = analyticsModelFromJson(jsonString);


class AnalyticsModel {
  final Progress? progress;
  final List<GoalTrend>? goalTrend;
  final List<CategoryDistribution>? categoryDistribution;
  final Performance? performance;
  final List<RecentActivity>? recentActivity;

  AnalyticsModel({
    this.progress,
    this.goalTrend,
    this.categoryDistribution,
    this.performance,
    this.recentActivity,
  });

  factory AnalyticsModel.fromJson(Map<String, dynamic> json) => AnalyticsModel(
    progress: json["progress"] == null ? null : Progress.fromJson(json["progress"]),
    goalTrend: json["goalTrend"] == null ? [] : List<GoalTrend>.from(json["goalTrend"]!.map((x) => GoalTrend.fromJson(x))),
    categoryDistribution: json["categoryDistribution"] == null ? [] : List<CategoryDistribution>.from(json["categoryDistribution"]!.map((x) => CategoryDistribution.fromJson(x))),
    performance: json["performance"] == null ? null : Performance.fromJson(json["performance"]),
    recentActivity: json["recentActivity"] == null ? [] : List<RecentActivity>.from(json["recentActivity"]!.map((x) => RecentActivity.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "progress": progress?.toJson(),
    "goalTrend": goalTrend == null ? [] : List<dynamic>.from(goalTrend!.map((x) => x.toJson())),
    "categoryDistribution": categoryDistribution == null ? [] : List<dynamic>.from(categoryDistribution!.map((x) => x.toJson())),
    "performance": performance?.toJson(),
    "recentActivity": recentActivity == null ? [] : List<dynamic>.from(recentActivity!.map((x) => x.toJson())),
  };
}

class CategoryDistribution {
  final String? category;
  final int? count;

  CategoryDistribution({
    this.category,
    this.count,
  });

  factory CategoryDistribution.fromJson(Map<String, dynamic> json) => CategoryDistribution(
    category: json["category"],
    count: json["count"],
  );

  Map<String, dynamic> toJson() => {
    "category": category,
    "count": count,
  };
}

class GoalTrend {
  final Count? count;
  final String? status;

  GoalTrend({
    this.count,
    this.status,
  });

  factory GoalTrend.fromJson(Map<String, dynamic> json) => GoalTrend(
    count: json["_count"] == null ? null : Count.fromJson(json["_count"]),
    status: json["status"],
  );

  Map<String, dynamic> toJson() => {
    "_count": count?.toJson(),
    "status": status,
  };
}

class Count {
  final int? all;

  Count({
    this.all,
  });

  factory Count.fromJson(Map<String, dynamic> json) => Count(
    all: json["_all"],
  );

  Map<String, dynamic> toJson() => {
    "_all": all,
  };
}

class Performance {
  final The2025W40? the2025W40;

  Performance({
    this.the2025W40,
  });

  factory Performance.fromJson(Map<String, dynamic> json) => Performance(
    the2025W40: json["2025-W40"] == null ? null : The2025W40.fromJson(json["2025-W40"]),
  );

  Map<String, dynamic> toJson() => {
    "2025-W40": the2025W40?.toJson(),
  };
}

class The2025W40 {
  final int? target;
  final int? completed;

  The2025W40({
    this.target,
    this.completed,
  });

  factory The2025W40.fromJson(Map<String, dynamic> json) => The2025W40(
    target: json["target"],
    completed: json["completed"],
  );

  Map<String, dynamic> toJson() => {
    "target": target,
    "completed": completed,
  };
}

class Progress {
  final int? salesPercent;
  final int? totalClients;
  final int? totalTimeSpent;

  Progress({
    this.salesPercent,
    this.totalClients,
    this.totalTimeSpent,
  });

  factory Progress.fromJson(Map<String, dynamic> json) => Progress(
    salesPercent: json["salesPercent"],
    totalClients: json["totalClients"],
    totalTimeSpent: json["totalTimeSpent"],
  );

  Map<String, dynamic> toJson() => {
    "salesPercent": salesPercent,
    "totalClients": totalClients,
    "totalTimeSpent": totalTimeSpent,
  };
}

class RecentActivity {
  final String? id;
  final String? name;
  final String? status;
  final DateTime? createdAt;
  final int? timeSpent;
  final int? timeSpentDecimal;
  final String? timeSpentFormatted;

  RecentActivity({
    this.id,
    this.name,
    this.status,
    this.createdAt,
    this.timeSpent,
    this.timeSpentDecimal,
    this.timeSpentFormatted,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) => RecentActivity(
    id: json["id"],
    name: json["name"],
    status: json["status"],
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    timeSpent: json["timeSpent"],
    timeSpentDecimal: json["timeSpentDecimal"],
    timeSpentFormatted: json["timeSpentFormatted"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "status": status,
    "createdAt": createdAt?.toIso8601String(),
    "timeSpent": timeSpent,
    "timeSpentDecimal": timeSpentDecimal,
    "timeSpentFormatted": timeSpentFormatted,
  };
}




