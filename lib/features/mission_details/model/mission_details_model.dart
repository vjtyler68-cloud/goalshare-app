
class MissionDetailsModel {
  final String? id;
  final String? title;
  final int? clientTarget;
  final String? category;
  final String? priority;
  final DateTime? dueDate;
  final String? status;
  final String? userId;
  final List<dynamic>? clients;
  final List<dynamic>? myWhies;
  final List<dynamic>? affirmations;
  final String? description;

  MissionDetailsModel({
    this.id,
    this.title,
    this.clientTarget,
    this.category,
    this.priority,
    this.dueDate,
    this.status,
    this.userId,
    this.clients,
    this.myWhies,
    this.affirmations,
    this.description,
  });

  factory MissionDetailsModel.fromJson(Map<String, dynamic> json) => MissionDetailsModel(
    id: json["id"],
    title: json["title"],
    clientTarget: json["clientTarget"],
    category: json["category"],
    priority: json["priority"],
    dueDate: json["dueDate"] == null ? null : DateTime.parse(json["dueDate"]),
    status: json["status"],
    userId: json["userId"],
    clients: json["clients"] == null ? [] : List<dynamic>.from(json["clients"]!.map((x) => x)),
    myWhies: json["myWhies"] == null ? [] : List<dynamic>.from(json["myWhies"]!.map((x) => x)),
    affirmations: json["affirmations"] == null ? [] : List<dynamic>.from(json["affirmations"]!.map((x) => x)),
    description: json["description"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "clientTarget": clientTarget,
    "category": category,
    "priority": priority,
    "dueDate": dueDate?.toIso8601String(),
    "status": status,
    "userId": userId,
    "clients": clients == null ? [] : List<dynamic>.from(clients!.map((x) => x)),
    "myWhies": myWhies == null ? [] : List<dynamic>.from(myWhies!.map((x) => x)),
    "affirmations": affirmations == null ? [] : List<dynamic>.from(affirmations!.map((x) => x)),
    "description": description,
  };
}
