

class MotivationalNudgesModel {
  final String? id;
  final String? title;
  final String? image;
  final String? userId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MotivationalNudgesModel({
    this.id,
    this.title,
    this.image,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  factory MotivationalNudgesModel.fromJson(Map<String, dynamic> json) => MotivationalNudgesModel(
    id: json["id"],
    title: json["title"],
    image: json["image"],
    userId: json["userId"],
    createdAt: json["createdAt"] == null ? null : DateTime.tryParse(json["createdAt"].toString()),
    updatedAt: json["updatedAt"] == null ? null : DateTime.tryParse(json["updatedAt"].toString()),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "image": image,
    "userId": userId,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
  };
}
