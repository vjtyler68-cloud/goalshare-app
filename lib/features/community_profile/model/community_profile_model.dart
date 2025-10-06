// class SuggestedPeopleModel {
//   final String? id;
//   final String? email;
//   final String? fullName;
//   final dynamic profile;
//
//   SuggestedPeopleModel({
//     this.id,
//     this.email,
//     this.fullName,
//     this.profile,
//   });
//
//   factory SuggestedPeopleModel.fromJson(Map<String, dynamic> json) => SuggestedPeopleModel(
//     id: json["id"],
//     email: json["email"],
//     fullName: json["fullName"],
//     profile: json["profile"],
//   );
//
//   Map<String, dynamic> toJson() => {
//     "id": id,
//     "email": email,
//     "fullName": fullName,
//     "profile": profile,
//   };
// }

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

