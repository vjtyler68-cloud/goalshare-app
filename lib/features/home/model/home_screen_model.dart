import 'package:spanx/core/const/app_icons.dart';


class RecentActivityModel{
  final String iconPath;
  final String title;
  final String time;

  RecentActivityModel({required this.iconPath, required this.title, required this.time});

  static List<RecentActivityModel> recentActivity = [
    RecentActivityModel(iconPath: AppIcons.success, title: 'Completed session with Emma Wilson', time: '2 Hours Ago'),
    RecentActivityModel(iconPath: AppIcons.notification, title: 'New message from Community', time: '2 Hours Ago'),
    RecentActivityModel(iconPath: AppIcons.target, title: 'Achieved daily sales target', time: '2 Hours Ago'),
  ];
}

class HomeMyWhyModel {
  final String? id;
  final String? text;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  HomeMyWhyModel({
    this.id,
    this.text,
    this.createdAt,
    this.updatedAt,
  });

  HomeMyWhyModel copyWith({
    String? id,
    String? text,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      HomeMyWhyModel(
        id: id ?? this.id,
        text: text ?? this.text,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory HomeMyWhyModel.fromJson(Map<String, dynamic> json) => HomeMyWhyModel(
    id: json["id"],
    text: json["text"],
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "text": text,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
  };
}

