class SubscriptionPageModel {
  final String? id;
  final String? title;
  final String? type;
  final int? duration;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? remainingDays;

  SubscriptionPageModel({
    this.id,
    this.title,
    this.type,
    this.duration,
    this.startDate,
    this.endDate,
    this.remainingDays,
  });

  SubscriptionPageModel copyWith({
    String? id,
    String? title,
    String? type,
    int? duration,
    DateTime? startDate,
    DateTime? endDate,
    int? remainingDays,
  }) =>
      SubscriptionPageModel(
        id: id ?? this.id,
        title: title ?? this.title,
        type: type ?? this.type,
        duration: duration ?? this.duration,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        remainingDays: remainingDays ?? this.remainingDays,
      );

  factory SubscriptionPageModel.fromJson(Map<String, dynamic> json) => SubscriptionPageModel(
    id: json["id"],
    title: json["title"],
    type: json["type"],
    duration: json["duration"],
    startDate: json["startDate"] == null ? null : DateTime.parse(json["startDate"]),
    endDate: json["endDate"] == null ? null : DateTime.parse(json["endDate"]),
    remainingDays: json["remainingDays"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "type": type,
    "duration": duration,
    "startDate": startDate?.toIso8601String(),
    "endDate": endDate?.toIso8601String(),
    "remainingDays": remainingDays,
  };
}
