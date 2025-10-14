class SubscriptionPageModel {
  final String? id;
  final String? title;
  final String? type;
  final int? duration;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? remainingDays;

  const SubscriptionPageModel({
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

  /// ✅ Safely parse dates (avoids Invalid date format)
  factory SubscriptionPageModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return SubscriptionPageModel.empty();

    DateTime? tryParseDate(String? dateString) {
      if (dateString == null) return null;
      try {
        return DateTime.parse(dateString);
      } catch (_) {
        return null;
      }
    }

    return SubscriptionPageModel(
      id: json["id"],
      title: json["title"],
      type: json["type"],
      duration: json["duration"],
      startDate: tryParseDate(json["startDate"]),
      endDate: tryParseDate(json["endDate"]),
      remainingDays: json["remainingDays"],
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "type": type,
    "duration": duration,
    "startDate": startDate?.toIso8601String(),
    "endDate": endDate?.toIso8601String(),
    "remainingDays": remainingDays,
  };

  /// ✅ Use this for no-subscription cases
  factory SubscriptionPageModel.empty() => const SubscriptionPageModel();
}
