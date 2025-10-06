
class UserDataModel {
  final String? id;
  final String? fullName;
  final dynamic businessType;
  final String? email;
  final String? phoneNumber;
  final String? role;
  final String? status;
  final String? describe;
  final String? city;
  final String? address;
  final String? profile;
  final dynamic fcmToken;
  final bool? isApproved;
  final bool? isDeleted;
  final dynamic subscriptionStart;
  final dynamic subscriptionEnd;
  final bool? hasUsedFree;
  final dynamic subscriptionId;
  final dynamic stripeCustomerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserDataModel({
    this.id,
    this.fullName,
    this.businessType,
    this.email,
    this.phoneNumber,
    this.role,
    this.status,
    this.describe,
    this.city,
    this.address,
    this.profile,
    this.fcmToken,
    this.isApproved,
    this.isDeleted,
    this.subscriptionStart,
    this.subscriptionEnd,
    this.hasUsedFree,
    this.subscriptionId,
    this.stripeCustomerId,
    this.createdAt,
    this.updatedAt,
  });

  factory UserDataModel.fromJson(Map<String, dynamic> json) => UserDataModel(
    id: json["id"],
    fullName: json["fullName"],
    businessType: json["businessType"],
    email: json["email"],
    phoneNumber: json["phoneNumber"],
    role: json["role"],
    status: json["status"],
    describe: json["describe"],
    city: json["city"],
    address: json["address"],
    profile: json["profile"],
    fcmToken: json["fcmToken"],
    isApproved: json["isApproved"],
    isDeleted: json["isDeleted"],
    subscriptionStart: json["subscriptionStart"],
    subscriptionEnd: json["subscriptionEnd"],
    hasUsedFree: json["hasUsedFree"],
    subscriptionId: json["subscriptionId"],
    stripeCustomerId: json["stripeCustomerId"],
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "fullName": fullName,
    "businessType": businessType,
    "email": email,
    "phoneNumber": phoneNumber,
    "role": role,
    "status": status,
    "describe": describe,
    "city": city,
    "address": address,
    "profile": profile,
    "fcmToken": fcmToken,
    "isApproved": isApproved,
    "isDeleted": isDeleted,
    "subscriptionStart": subscriptionStart,
    "subscriptionEnd": subscriptionEnd,
    "hasUsedFree": hasUsedFree,
    "subscriptionId": subscriptionId,
    "stripeCustomerId": stripeCustomerId,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
  };
}
