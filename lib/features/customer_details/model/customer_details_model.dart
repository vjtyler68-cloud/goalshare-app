class CustomerDetailsModel {
  final String? name;
  final String? phone;
  final String? notes;
  final String? status;

  CustomerDetailsModel({this.name, this.phone, this.notes, this.status});

  factory CustomerDetailsModel.fromJson(Map<String, dynamic> json) =>
      CustomerDetailsModel(
        name: json["name"],
        phone: json["phone"],
        notes: json["notes"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
    "name": name,
    "phone": phone,
    "notes": notes,
    "status": status,
  };
}
