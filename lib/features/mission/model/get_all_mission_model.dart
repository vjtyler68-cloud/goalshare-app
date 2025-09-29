

class GetAllMissionModel {
  final String? id;
  final String? title;
  final int? clientTarget;
  final String? description;
  final String? category;
  final String? priority;
  final DateTime? dueDate;
  final String? status;
  final String? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GetAllMissionModel({
    this.id,
    this.title,
    this.clientTarget,
    this.description,
    this.category,
    this.priority,
    this.dueDate,
    this.status,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory GetAllMissionModel.fromJson(Map<String, dynamic> json) => GetAllMissionModel(
    id: json["id"],
    title: json["title"],
    clientTarget: json["clientTarget"],
    description: json["description"],
    category: json["category"],
    priority: json["priority"],
    dueDate: json["dueDate"] == null ? null : DateTime.parse(json["dueDate"]),
    status: json["status"],
    userId: json["userId"],
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "clientTarget": clientTarget,
    "description": description,
    "category": category,
    "priority": priority,
    "dueDate": dueDate?.toIso8601String(),
    "status": status,
    "userId": userId,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
  };
}


