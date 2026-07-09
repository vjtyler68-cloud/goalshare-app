class SubscriptionModel {
  final String? id;
  final int? amount;
  final String? name;
  final String? priceId;
  final String? productId;
  final List<String>? features;
  final String? description;
  final String? currency;
  final String? interval;
  final bool? active;
  final int? intervalCount;
  final int? freeTrailDays;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SubscriptionModel({
    this.id,
    this.amount,
    this.name,
    this.priceId,
    this.productId,
    this.features,
    this.description,
    this.currency,
    this.interval,
    this.active,
    this.intervalCount,
    this.freeTrailDays,
    this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      SubscriptionModel(
        id: json["id"],
        amount: json["amount"],
        name: json["name"],
        priceId: json["priceId"],
        productId: json["productId"],
        features: json["features"] == null
            ? []
            : List<String>.from(json["features"]!.map((x) => x)),
        description: json["description"],
        currency: json["currency"],
        interval: json["interval"],
        active: json["active"],
        intervalCount: json["intervalCount"],
        freeTrailDays: json["freeTrailDays"],
        createdAt: json["createdAt"] == null
            ? null
            : DateTime.tryParse(json["createdAt"].toString()),
        updatedAt: json["updatedAt"] == null
            ? null
            : DateTime.tryParse(json["updatedAt"].toString()),
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "amount": amount,
    "name": name,
    "priceId": priceId,
    "productId": productId,
    "features": features == null
        ? []
        : List<dynamic>.from(features!.map((x) => x)),
    "description": description,
    "currency": currency,
    "interval": interval,
    "active": active,
    "intervalCount": intervalCount,
    "freeTrailDays": freeTrailDays,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
  };
}
