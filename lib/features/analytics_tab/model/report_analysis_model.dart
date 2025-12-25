

class ReportAnalysisModel {
  final Month? month;
  final GoalTrend? goalTrend;
  final List<CategoryDistribution>? categoryDistribution;
  final List<RecentActivity>? recentActivity;
  final SummaryAllTime? summaryAllTime;

  ReportAnalysisModel({
    this.month,
    this.goalTrend,
    this.categoryDistribution,
    this.recentActivity,
    this.summaryAllTime,
  });

  ReportAnalysisModel copyWith({
    Month? month,
    GoalTrend? goalTrend,
    List<CategoryDistribution>? categoryDistribution,
    List<RecentActivity>? recentActivity,
    SummaryAllTime? summaryAllTime,
  }) =>
      ReportAnalysisModel(
        month: month ?? this.month,
        goalTrend: goalTrend ?? this.goalTrend,
        categoryDistribution: categoryDistribution ?? this.categoryDistribution,
        recentActivity: recentActivity ?? this.recentActivity,
        summaryAllTime: summaryAllTime ?? this.summaryAllTime,
      );

  factory ReportAnalysisModel.fromJson(Map<String, dynamic> json) => ReportAnalysisModel(
    month: json["month"] == null ? null : Month.fromJson(json["month"]),
    goalTrend: json["goalTrend"] == null ? null : GoalTrend.fromJson(json["goalTrend"]),
    categoryDistribution: json["categoryDistribution"] == null ? [] : List<CategoryDistribution>.from(json["categoryDistribution"]!.map((x) => CategoryDistribution.fromJson(x))),
    recentActivity: json["recentActivity"] == null ? [] : List<RecentActivity>.from(json["recentActivity"]!.map((x) => RecentActivity.fromJson(x))),
    summaryAllTime: json["summaryAllTime"] == null ? null : SummaryAllTime.fromJson(json["summaryAllTime"]),
  );

  Map<String, dynamic> toJson() => {
    "month": month?.toJson(),
    "goalTrend": goalTrend?.toJson(),
    "categoryDistribution": categoryDistribution == null ? [] : List<dynamic>.from(categoryDistribution!.map((x) => x.toJson())),
    "recentActivity": recentActivity == null ? [] : List<dynamic>.from(recentActivity!.map((x) => x.toJson())),
    "summaryAllTime": summaryAllTime?.toJson(),
  };
}

class CategoryDistribution {
  final String? category;
  final int? count;

  CategoryDistribution({
    this.category,
    this.count,
  });

  CategoryDistribution copyWith({
    String? category,
    int? count,
  }) =>
      CategoryDistribution(
        category: category ?? this.category,
        count: count ?? this.count,
      );

  factory CategoryDistribution.fromJson(Map<String, dynamic> json) => CategoryDistribution(
    category: json["category"],
    count: json["count"],
  );

  Map<String, dynamic> toJson() => {
    "category": category,
    "count": count,
  };
}
class GoalTrendChartData {
  final String day;
  final int created;
  final int completed;
  final int pending; // you can derive pending = created - completed, or from API if available

  GoalTrendChartData({
    required this.day,
    required this.created,
    required this.completed,
    this.pending = 0,
  });
}
class GoalTrend {
  final List<String>? labels;
  final List<int>? created;
  final List<int>? completed;
  final GoalTrendTotals? totals;

  GoalTrend({
    this.labels,
    this.created,
    this.completed,
    this.totals,
  });

  GoalTrend copyWith({
    List<String>? labels,
    List<int>? created,
    List<int>? completed,
    GoalTrendTotals? totals,
  }) =>
      GoalTrend(
        labels: labels ?? this.labels,
        created: created ?? this.created,
        completed: completed ?? this.completed,
        totals: totals ?? this.totals,
      );

  factory GoalTrend.fromJson(Map<String, dynamic> json) => GoalTrend(
    labels: json["labels"] == null ? [] : List<String>.from(json["labels"]!.map((x) => x)),
    created: json["created"] == null ? [] : List<int>.from(json["created"]!.map((x) => x)),
    completed: json["completed"] == null ? [] : List<int>.from(json["completed"]!.map((x) => x)),
    totals: json["totals"] == null ? null : GoalTrendTotals.fromJson(json["totals"]),
  );

  Map<String, dynamic> toJson() => {
    "labels": labels == null ? [] : List<dynamic>.from(labels!.map((x) => x)),
    "created": created == null ? [] : List<dynamic>.from(created!.map((x) => x)),
    "completed": completed == null ? [] : List<dynamic>.from(completed!.map((x) => x)),
    "totals": totals?.toJson(),
  };
}

class GoalTrendTotals {
  final int? created;
  final int? completed;

  GoalTrendTotals({
    this.created,
    this.completed,
  });

  GoalTrendTotals copyWith({
    int? created,
    int? completed,
  }) =>
      GoalTrendTotals(
        created: created ?? this.created,
        completed: completed ?? this.completed,
      );

  factory GoalTrendTotals.fromJson(Map<String, dynamic> json) => GoalTrendTotals(
    created: json["created"],
    completed: json["completed"],
  );

  Map<String, dynamic> toJson() => {
    "created": created,
    "completed": completed,
  };
}

class Month {
  final int? year;
  final int? month;
  final DateTime? startDate;
  final DateTime? endDate;
  final MonthTotals? totals;

  Month({
    this.year,
    this.month,
    this.startDate,
    this.endDate,
    this.totals,
  });

  Month copyWith({
    int? year,
    int? month,
    DateTime? startDate,
    DateTime? endDate,
    MonthTotals? totals,
  }) =>
      Month(
        year: year ?? this.year,
        month: month ?? this.month,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        totals: totals ?? this.totals,
      );

  factory Month.fromJson(Map<String, dynamic> json) => Month(
    year: json["year"],
    month: json["month"],
    startDate: json["startDate"] == null ? null : DateTime.parse(json["startDate"]),
    endDate: json["endDate"] == null ? null : DateTime.parse(json["endDate"]),
    totals: json["totals"] == null ? null : MonthTotals.fromJson(json["totals"]),
  );

  Map<String, dynamic> toJson() => {
    "year": year,
    "month": month,
    "startDate": startDate?.toIso8601String(),
    "endDate": endDate?.toIso8601String(),
    "totals": totals?.toJson(),
  };
}

class MonthTotals {
  final int? goalsCreated;
  final int? goalsCompleted;
  final int? clientsCompleted;
  final int? totalTimeMinutes;
  final int? totalTimeHours;
  final int? goalsCreatedTimeMinutes;
  final int? goalsCreatedTimeHours;

  MonthTotals({
    this.goalsCreated,
    this.goalsCompleted,
    this.clientsCompleted,
    this.totalTimeMinutes,
    this.totalTimeHours,
    this.goalsCreatedTimeMinutes,
    this.goalsCreatedTimeHours,
  });

  MonthTotals copyWith({
    int? goalsCreated,
    int? goalsCompleted,
    int? clientsCompleted,
    int? totalTimeMinutes,
    int? totalTimeHours,
    int? goalsCreatedTimeMinutes,
    int? goalsCreatedTimeHours,
  }) =>
      MonthTotals(
        goalsCreated: goalsCreated ?? this.goalsCreated,
        goalsCompleted: goalsCompleted ?? this.goalsCompleted,
        clientsCompleted: clientsCompleted ?? this.clientsCompleted,
        totalTimeMinutes: totalTimeMinutes ?? this.totalTimeMinutes,
        totalTimeHours: totalTimeHours ?? this.totalTimeHours,
        goalsCreatedTimeMinutes: goalsCreatedTimeMinutes ?? this.goalsCreatedTimeMinutes,
        goalsCreatedTimeHours: goalsCreatedTimeHours ?? this.goalsCreatedTimeHours,
      );

  factory MonthTotals.fromJson(Map<String, dynamic> json) => MonthTotals(
    goalsCreated: json["goalsCreated"],
    goalsCompleted: json["goalsCompleted"],
    clientsCompleted: json["clientsCompleted"],
    totalTimeMinutes: json["totalTimeMinutes"],
    totalTimeHours: json["totalTimeHours"],
    goalsCreatedTimeMinutes: json["goalsCreatedTimeMinutes"],
    goalsCreatedTimeHours: json["goalsCreatedTimeHours"],
  );

  Map<String, dynamic> toJson() => {
    "goalsCreated": goalsCreated,
    "goalsCompleted": goalsCompleted,
    "clientsCompleted": clientsCompleted,
    "totalTimeMinutes": totalTimeMinutes,
    "totalTimeHours": totalTimeHours,
    "goalsCreatedTimeMinutes": goalsCreatedTimeMinutes,
    "goalsCreatedTimeHours": goalsCreatedTimeHours,
  };
}

class RecentActivity {
  final String? id;
  final String? name;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? timeSpentMinutes;
  final int? timeSpentHoursDecimal;
  final String? timeSpentFormatted;

  RecentActivity({
    this.id,
    this.name,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.timeSpentMinutes,
    this.timeSpentHoursDecimal,
    this.timeSpentFormatted,
  });

  RecentActivity copyWith({
    String? id,
    String? name,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? timeSpentMinutes,
    int? timeSpentHoursDecimal,
    String? timeSpentFormatted,
  }) =>
      RecentActivity(
        id: id ?? this.id,
        name: name ?? this.name,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        timeSpentMinutes: timeSpentMinutes ?? this.timeSpentMinutes,
        timeSpentHoursDecimal: timeSpentHoursDecimal ?? this.timeSpentHoursDecimal,
        timeSpentFormatted: timeSpentFormatted ?? this.timeSpentFormatted,
      );

  factory RecentActivity.fromJson(Map<String, dynamic> json) => RecentActivity(
    id: json["id"],
    name: json["name"],
    status: json["status"],
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
    timeSpentMinutes: json["timeSpentMinutes"],
    timeSpentHoursDecimal: json["timeSpentHoursDecimal"],
    timeSpentFormatted: json["timeSpentFormatted"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "status": status,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "timeSpentMinutes": timeSpentMinutes,
    "timeSpentHoursDecimal": timeSpentHoursDecimal,
    "timeSpentFormatted": timeSpentFormatted,
  };
}

class SummaryAllTime {
  final int? totalGoals;
  final int? completedGoals;
  final int? pendingGoals;
  final int? salesPercent;
  final int? totalClients;
  final int? totalTimeSpentHoursAll;
  final int? totalTimeSpentMinutesAll;

  SummaryAllTime({
    this.totalGoals,
    this.completedGoals,
    this.pendingGoals,
    this.salesPercent,
    this.totalClients,
    this.totalTimeSpentHoursAll,
    this.totalTimeSpentMinutesAll,
  });

  SummaryAllTime copyWith({
    int? totalGoals,
    int? completedGoals,
    int? pendingGoals,
    int? salesPercent,
    int? totalClients,
    int? totalTimeSpentHoursAll,
    int? totalTimeSpentMinutesAll,
  }) =>
      SummaryAllTime(
        totalGoals: totalGoals ?? this.totalGoals,
        completedGoals: completedGoals ?? this.completedGoals,
        pendingGoals: pendingGoals ?? this.pendingGoals,
        salesPercent: salesPercent ?? this.salesPercent,
        totalClients: totalClients ?? this.totalClients,
        totalTimeSpentHoursAll: totalTimeSpentHoursAll ?? this.totalTimeSpentHoursAll,
        totalTimeSpentMinutesAll: totalTimeSpentMinutesAll ?? this.totalTimeSpentMinutesAll,
      );

  factory SummaryAllTime.fromJson(Map<String, dynamic> json) => SummaryAllTime(
    totalGoals: json["totalGoals"],
    completedGoals: json["completedGoals"],
    pendingGoals: json["pendingGoals"],
    salesPercent: json["salesPercent"],
    totalClients: json["totalClients"],
    totalTimeSpentHoursAll: json["totalTimeSpentHoursAll"],
    totalTimeSpentMinutesAll: json["totalTimeSpentMinutesAll"],
  );

  Map<String, dynamic> toJson() => {
    "totalGoals": totalGoals,
    "completedGoals": completedGoals,
    "pendingGoals": pendingGoals,
    "salesPercent": salesPercent,
    "totalClients": totalClients,
    "totalTimeSpentHoursAll": totalTimeSpentHoursAll,
    "totalTimeSpentMinutesAll": totalTimeSpentMinutesAll,
  };
}

