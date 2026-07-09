
class CommunityProfileModel {
  final String? id;
  final String? fullName;
  final String? businessType;
  final String? email;
  final String? phoneNumber;
  final Role? role;
  final Status? status;
  final String? describe;
  final String? city;
  final String? address;
  final String? profile;
  final String? fcmToken;
  final bool? isApproved;
  final bool? isDeleted;
  final DateTime? subscriptionStart;
  final DateTime? subscriptionEnd;
  final bool? hasUsedFree;
  final String? subscriptionId;
  final String? stripeCustomerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Subscription? subscription;

  CommunityProfileModel({
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
    this.subscription,
  });

  CommunityProfileModel copyWith({
    String? id,
    String? fullName,
    String? businessType,
    String? email,
    String? phoneNumber,
    Role? role,
    Status? status,
    String? describe,
    String? city,
    String? address,
    String? profile,
    String? fcmToken,
    bool? isApproved,
    bool? isDeleted,
    DateTime? subscriptionStart,
    DateTime? subscriptionEnd,
    bool? hasUsedFree,
    String? subscriptionId,
    String? stripeCustomerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Subscription? subscription,
  }) =>
      CommunityProfileModel(
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
        fcmToken: fcmToken ?? this.fcmToken,
        isApproved: isApproved ?? this.isApproved,
        isDeleted: isDeleted ?? this.isDeleted,
        subscriptionStart: subscriptionStart ?? this.subscriptionStart,
        subscriptionEnd: subscriptionEnd ?? this.subscriptionEnd,
        hasUsedFree: hasUsedFree ?? this.hasUsedFree,
        subscriptionId: subscriptionId ?? this.subscriptionId,
        stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        subscription: subscription ?? this.subscription,
      );

  factory CommunityProfileModel.fromJson(Map<String, dynamic> json) => CommunityProfileModel(
    id: json["id"],
    fullName: json["fullName"],
    businessType: json["businessType"],
    email: json["email"],
    phoneNumber: json["phoneNumber"],
    role: roleValues.map[json["role"]]!,
    status: statusValues.map[json["status"]]!,
    describe: json["describe"],
    city: json["city"],
    address: json["address"],
    profile: json["profile"],
    fcmToken: json["fcmToken"],
    isApproved: json["isApproved"],
    isDeleted: json["isDeleted"],
    subscriptionStart: json["subscriptionStart"] == null ? null : DateTime.tryParse(json["subscriptionStart"].toString()),
    subscriptionEnd: json["subscriptionEnd"] == null ? null : DateTime.tryParse(json["subscriptionEnd"].toString()),
    hasUsedFree: json["hasUsedFree"],
    subscriptionId: json["subscriptionId"],
    stripeCustomerId: json["stripeCustomerId"],
    createdAt: json["createdAt"] == null ? null : DateTime.tryParse(json["createdAt"].toString()),
    updatedAt: json["updatedAt"] == null ? null : DateTime.tryParse(json["updatedAt"].toString()),
    subscription: json["subscription"] == null ? null : Subscription.fromJson(json["subscription"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "fullName": fullName,
    "businessType": businessType,
    "email": email,
    "phoneNumber": phoneNumber,
    "role": roleValues.reverse[role],
    "status": statusValues.reverse[status],
    "describe": describe,
    "city": city,
    "address": address,
    "profile": profile,
    "fcmToken": fcmToken,
    "isApproved": isApproved,
    "isDeleted": isDeleted,
    "subscriptionStart": subscriptionStart?.toIso8601String(),
    "subscriptionEnd": subscriptionEnd?.toIso8601String(),
    "hasUsedFree": hasUsedFree,
    "subscriptionId": subscriptionId,
    "stripeCustomerId": stripeCustomerId,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "subscription": subscription?.toJson(),
  };
}

enum Role {
  USER
}

final roleValues = EnumValues({
  "USER": Role.USER
});

enum Status {
  ACTIVE
}

final statusValues = EnumValues({
  "ACTIVE": Status.ACTIVE
});

class Subscription {
  final String? id;
  final String? title;
  final int? price;
  final int? duration;
  final dynamic stripePriceId;
  final dynamic stripeProductId;
  final String? subscriptionType;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Subscription({
    this.id,
    this.title,
    this.price,
    this.duration,
    this.stripePriceId,
    this.stripeProductId,
    this.subscriptionType,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  Subscription copyWith({
    String? id,
    String? title,
    int? price,
    int? duration,
    dynamic stripePriceId,
    dynamic stripeProductId,
    String? subscriptionType,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Subscription(
        id: id ?? this.id,
        title: title ?? this.title,
        price: price ?? this.price,
        duration: duration ?? this.duration,
        stripePriceId: stripePriceId ?? this.stripePriceId,
        stripeProductId: stripeProductId ?? this.stripeProductId,
        subscriptionType: subscriptionType ?? this.subscriptionType,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
    id: json["id"],
    title: json["title"],
    price: json["price"],
    duration: json["duration"],
    stripePriceId: json["stripePriceId"],
    stripeProductId: json["stripeProductId"],
    subscriptionType: json["subscriptionType"],
    isActive: json["isActive"],
    createdAt: json["createdAt"] == null ? null : DateTime.tryParse(json["createdAt"].toString()),
    updatedAt: json["updatedAt"] == null ? null : DateTime.tryParse(json["updatedAt"].toString()),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "price": price,
    "duration": duration,
    "stripePriceId": stripePriceId,
    "stripeProductId": stripeProductId,
    "subscriptionType": subscriptionType,
    "isActive": isActive,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
  };
}

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}


class SuggestedPeopleModel {
  final String fullName;
  final String profile;
  bool isSelected;
  SuggestedPeopleModel({
    required this.fullName,
    required this.profile,
    this.isSelected = false,
  });
}