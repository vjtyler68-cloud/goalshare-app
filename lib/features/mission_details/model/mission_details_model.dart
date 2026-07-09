
class MissionDetailsModel {
  final String? id;
  final String? title;
  final int? clientTarget;
  final String? category;
  final String? priority;
  final DateTime? dueDate;
  final String? status;
  final String? userId;
  final List<Client>? clients;
  final List<Affirmation>? myWhies;
  final List<Affirmation>? affirmations;
  final String? description;
  final int? breakTimeSpent;
  final int? salesCompletedCount;
  final dynamic contactProgress;
  final int? totalReached;
  final int? totalTalkedTo;
  final int? progressPercentage;

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
    this.breakTimeSpent,
    this.salesCompletedCount,
    this.contactProgress,
    this.totalReached,
    this.totalTalkedTo,
    this.progressPercentage,
  });

  MissionDetailsModel copyWith({
    String? id,
    String? title,
    int? clientTarget,
    String? category,
    String? priority,
    DateTime? dueDate,
    String? status,
    String? userId,
    List<Client>? clients,
    List<Affirmation>? myWhies,
    List<Affirmation>? affirmations,
    String? description,
    int? breakTimeSpent,
    int? salesCompletedCount,
    dynamic contactProgress,
    int? totalReached,
    int? totalTalkedTo,
    int? progressPercentage,
  }) =>
      MissionDetailsModel(
        id: id ?? this.id,
        title: title ?? this.title,
        clientTarget: clientTarget ?? this.clientTarget,
        category: category ?? this.category,
        priority: priority ?? this.priority,
        dueDate: dueDate ?? this.dueDate,
        status: status ?? this.status,
        userId: userId ?? this.userId,
        clients: clients ?? this.clients,
        myWhies: myWhies ?? this.myWhies,
        affirmations: affirmations ?? this.affirmations,
        description: description ?? this.description,
        breakTimeSpent: breakTimeSpent ?? this.breakTimeSpent,
        salesCompletedCount: salesCompletedCount ?? this.salesCompletedCount,
        contactProgress: contactProgress ?? this.contactProgress,
        totalReached: totalReached ?? this.totalReached,
        totalTalkedTo: totalTalkedTo ?? this.totalTalkedTo,
        progressPercentage: progressPercentage ?? this.progressPercentage,
      );

  factory MissionDetailsModel.fromJson(Map<String, dynamic> json) => MissionDetailsModel(
    id: json["id"],
    title: json["title"],
    clientTarget: json["clientTarget"],
    category: json["category"],
    priority: json["priority"],
    dueDate: json["dueDate"] == null ? null : DateTime.tryParse(json["dueDate"].toString()),
    status: json["status"],
    userId: json["userId"],
    clients: json["clients"] == null ? [] : List<Client>.from(json["clients"]!.map((x) => Client.fromJson(x))),
    myWhies: json["myWhies"] == null ? [] : List<Affirmation>.from(json["myWhies"]!.map((x) => Affirmation.fromJson(x))),
    affirmations: json["affirmations"] == null ? [] : List<Affirmation>.from(json["affirmations"]!.map((x) => Affirmation.fromJson(x))),
    description: json["description"],
    breakTimeSpent: json["breakTimeSpent"],
    salesCompletedCount: json["salesCompletedCount"],
    contactProgress: json["contactProgress"],
    totalReached: json["totalReached"],
    totalTalkedTo: json["totalTalkedTo"],
    progressPercentage: json["progressPercentage"],
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
    "clients": clients == null ? [] : List<dynamic>.from(clients!.map((x) => x.toJson())),
    "myWhies": myWhies == null ? [] : List<dynamic>.from(myWhies!.map((x) => x.toJson())),
    "affirmations": affirmations == null ? [] : List<dynamic>.from(affirmations!.map((x) => x.toJson())),
    "description": description,
    "breakTimeSpent": breakTimeSpent,
    "salesCompletedCount": salesCompletedCount,
    "contactProgress": contactProgress,
    "totalReached": totalReached,
    "totalTalkedTo": totalTalkedTo,
    "progressPercentage": progressPercentage,
  };
}

class Affirmation {
  final String? id;
  final String? text;

  Affirmation({
    this.id,
    this.text,
  });

  Affirmation copyWith({
    String? id,
    String? text,
  }) =>
      Affirmation(
        id: id ?? this.id,
        text: text ?? this.text,
      );

  factory Affirmation.fromJson(Map<String, dynamic> json) => Affirmation(
    id: json["id"],
    text: json["text"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "text": text,
  };
}

class Client {
  final String? id;
  final String? name;
  final String? status;
  final int? timeSpent;
  final String? notes;
  final String? phone;

  Client({
    this.id,
    this.name,
    this.status,
    this.timeSpent,
    this.notes,
    this.phone,
  });

  Client copyWith({
    String? id,
    String? name,
    String? status,
    int? timeSpent,
    String? notes,
    String? phone,
  }) =>
      Client(
        id: id ?? this.id,
        name: name ?? this.name,
        status: status ?? this.status,
        timeSpent: timeSpent ?? this.timeSpent,
        notes: notes ?? this.notes,
        phone: phone ?? this.phone,
      );

  factory Client.fromJson(Map<String, dynamic> json) => Client(
    id: json["id"],
    name: json["name"],
    status: json["status"],
    timeSpent: json["timeSpent"],
    notes: json["notes"],
    phone: json["phone"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "status": status,
    "timeSpent": timeSpent,
    "notes": notes,
    "phone": phone,
  };
}
