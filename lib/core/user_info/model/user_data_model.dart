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
  final String? username;
  final String? subscriptionId;
  final bool? isApproved;
  final DateTime? subscriptionStart;
  final DateTime? subscriptionEnd;

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
    this.username,
    this.subscriptionId,
    this.isApproved,
    this.subscriptionStart,
    this.subscriptionEnd,
  });

  UserDataModel copyWith({
    String? id,
    String? fullName,
    dynamic businessType,
    String? email,
    String? phoneNumber,
    String? role,
    String? status,
    String? describe,
    String? city,
    String? address,
    String? profile,
    String? username,
    String? subscriptionId,
    bool? isApproved,
    DateTime? subscriptionStart,
    DateTime? subscriptionEnd,
  }) => UserDataModel(
    id: id ?? this.id,
    fullName: fullName ?? this.fullName,
    businessType: businessType ?? this.businessType,
    email: email ?? this.email,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    role: role ?? this.role,
    status: status ?? this.status,
    describe: describe ?? this.describe,
    city: city ?? this.city,
    address: address ?? this.address,
    profile: profile ?? this.profile,
    username: username ?? this.username,
    subscriptionId: subscriptionId ?? this.subscriptionId,
    isApproved: isApproved ?? this.isApproved,
    subscriptionStart: subscriptionStart ?? this.subscriptionStart,
    subscriptionEnd: subscriptionEnd ?? this.subscriptionEnd,
  );

  /// Check if user has an active subscription (end date is in the future)
  bool get hasActiveSubscription {
    if (subscriptionEnd == null) return false;
    return subscriptionEnd!.isAfter(DateTime.now());
  }

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
    username: json["username"],
    subscriptionId: json["subscriptionId"],
    isApproved: json["isApproved"],
    subscriptionStart: json["subscriptionStart"] == null
        ? null
        : DateTime.tryParse(json["subscriptionStart"].toString()),
    subscriptionEnd: json["subscriptionEnd"] == null
        ? null
        : DateTime.tryParse(json["subscriptionEnd"].toString()),
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
    "username": username,
    "subscriptionId": subscriptionId,
    "isApproved": isApproved,
    "subscriptionStart": subscriptionStart?.toIso8601String(),
    "subscriptionEnd": subscriptionEnd?.toIso8601String(),
  };
}
