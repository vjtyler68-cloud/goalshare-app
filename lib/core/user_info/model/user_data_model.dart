
class UserDataModel {
  final String? id;
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final String? role;
  final String? status;
  final String? describe;
  final String? city;
  final String? address;
  final String? profile;
  final bool? isApproved;
  final bool? isDeleted;
  final dynamic subscriptionId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final dynamic subscription;

  UserDataModel({
    this.id,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.role,
    this.status,
    this.describe,
    this.city,
    this.address,
    this.profile,
    this.isApproved,
    this.isDeleted,
    this.subscriptionId,
    this.createdAt,
    this.updatedAt,
    this.subscription,
  });

  factory UserDataModel.fromJson(Map<String, dynamic> json) => UserDataModel(
    id: json["id"],
    fullName: json["fullName"],
    email: json["email"],
    phoneNumber: json["phoneNumber"],
    role: json["role"],
    status: json["status"],
    describe: json["describe"],
    city: json["city"],
    address: json["address"],
    profile: json["profile"],
    isApproved: json["isApproved"],
    isDeleted: json["isDeleted"],
    subscriptionId: json["subscriptionId"],
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
    subscription: json["subscription"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "fullName": fullName,
    "email": email,
    "phoneNumber": phoneNumber,
    "role": role,
    "status": status,
    "describe": describe,
    "city": city,
    "address": address,
    "profile": profile,
    "isApproved": isApproved,
    "isDeleted": isDeleted,
    "subscriptionId": subscriptionId,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "subscription": subscription,
  };
}
