

class GetAllMissionModel {
  final String? id;
  final String? title;
  final int? clientTarget;
  final String? description;
  final String? category;
  final String? priority;
  final DateTime? dueDate;
  final String? status;
  final int? breakTimeSpent;
  final List<Client>? clients;
  final int? reachedClientsTime;
  final int? totalReached;

  GetAllMissionModel({
    this.id,
    this.title,
    this.clientTarget,
    this.description,
    this.category,
    this.priority,
    this.dueDate,
    this.status,
    this.breakTimeSpent,
    this.clients,
    this.reachedClientsTime,
    this.totalReached,
  });

  factory GetAllMissionModel.fromJson(Map<String, dynamic> json) => GetAllMissionModel(
    id: json["id"],
    title: json["title"],
    clientTarget: json["clientTarget"],
    description: json["description"],
    category: json["category"],
    priority: json["priority"],
    dueDate: json["dueDate"] == null ? null : DateTime.tryParse(json["dueDate"].toString()),
    status: json["status"],
    breakTimeSpent: json["breakTimeSpent"],
    clients: json["clients"] == null ? [] : List<Client>.from(json["clients"]!.map((x) => Client.fromJson(x))),
    reachedClientsTime: json["reachedClientsTime"],
    totalReached: json["totalReached"],
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
    "breakTimeSpent": breakTimeSpent,
    "clients": clients == null ? [] : List<dynamic>.from(clients!.map((x) => x.toJson())),
    "reachedClientsTime": reachedClientsTime,
    "totalReached": totalReached,
  };
}

class Client {
  final String? status;
  final int? timeSpent;

  Client({
    this.status,
    this.timeSpent,
  });

  factory Client.fromJson(Map<String, dynamic> json) => Client(
    status: json["status"],
    timeSpent: json["timeSpent"],
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "timeSpent": timeSpent,
  };
}


