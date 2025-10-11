// class SubscriptionModel {
//   final String title;
//   final String price;
//   final String save;
//   final bool showSave;
//
//   SubscriptionModel({
//     required this.title,
//     required this.price,
//     required this.save,
//     required this.showSave,
//   });
//
//   static List<SubscriptionModel> subscriptionModelList = [
//     SubscriptionModel(
//       title: '3-Months Free Trial',
//       price: 'Free',
//       save: 'Save 5%',
//       showSave: false,
//     ),
//     SubscriptionModel(
//       title: 'Monthly Plan',
//       price: '\$9.99/month',
//       save: 'Save 10%',
//       showSave: false,
//     ),
//     SubscriptionModel(
//       title: 'Yearly Plan',
//       price: '\$99/year',
//       save: 'Save 17%',
//       showSave: true,
//     ),
//   ];
// }


class SubscriptionScreenModel {
  final String? id;
  final String? title;
  final double? price;
  final int? duration;
  final String? stripePriceId;
  final String? stripeProductId;
  final String? subscriptionType;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SubscriptionScreenModel({
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

  SubscriptionScreenModel copyWith({
    String? id,
    String? title,
    double? price,
    int? duration,
    String? stripePriceId,
    String? stripeProductId,
    String? subscriptionType,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      SubscriptionScreenModel(
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

  factory SubscriptionScreenModel.fromJson(Map<String, dynamic> json) => SubscriptionScreenModel(
    id: json["id"],
    title: json["title"],
    price: json["price"]?.toDouble(),
    duration: json["duration"],
    stripePriceId: json["stripePriceId"],
    stripeProductId: json["stripeProductId"],
    subscriptionType: json["subscriptionType"],
    isActive: json["isActive"],
    createdAt: json["createdAt"] == null ? null : DateTime.parse(json["createdAt"]),
    updatedAt: json["updatedAt"] == null ? null : DateTime.parse(json["updatedAt"]),
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
