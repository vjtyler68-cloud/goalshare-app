
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
  final Subscription? subscription;
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
    this.subscription,
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
    Subscription? subscription,
    bool? isApproved,
    DateTime? subscriptionStart,
    DateTime? subscriptionEnd,
  }) =>
      UserDataModel(
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
        subscription: subscription ?? this.subscription,
        isApproved: isApproved ?? this.isApproved,
        subscriptionStart: subscriptionStart ?? this.subscriptionStart,
        subscriptionEnd: subscriptionEnd ?? this.subscriptionEnd,
      );

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
    subscription: json["subscription"] == null ? null : Subscription.fromJson(json["subscription"]),
    isApproved: json["isApproved"],
    subscriptionStart: json["subscriptionStart"] == null ? null : DateTime.parse(json["subscriptionStart"]),
    subscriptionEnd: json["subscriptionEnd"] == null ? null : DateTime.parse(json["subscriptionEnd"]),
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
    "subscription": subscription?.toJson(),
    "isApproved": isApproved,
    "subscriptionStart": subscriptionStart?.toIso8601String(),
    "subscriptionEnd": subscriptionEnd?.toIso8601String(),
  };
}

class Subscription {
  final String? id;
  final String? title;
  final int? price;

  Subscription({
    this.id,
    this.title,
    this.price,
  });

  Subscription copyWith({
    String? id,
    String? title,
    int? price,
  }) =>
      Subscription(
        id: id ?? this.id,
        title: title ?? this.title,
        price: price ?? this.price,
      );

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
    id: json["id"],
    title: json["title"],
    price: json["price"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "price": price,
  };
}
