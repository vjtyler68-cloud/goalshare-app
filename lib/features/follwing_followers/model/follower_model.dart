class UserFollowModel {
  final String id;
  final String name;
  final String email;
  final String profileImage;
  final bool isFollowing;
  final DateTime? followedAt;
  final bool? isVerified;
  final String? bio;

  UserFollowModel({
    required this.id,
    required this.name,
    required this.email,
    required this.profileImage,
    this.isFollowing = false,
    this.followedAt,
    this.isVerified = false,
    this.bio,
  });

  UserFollowModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImage,
    bool? isFollowing,
    DateTime? followedAt,
    bool? isVerified,
    String? bio,
  }) {
    return UserFollowModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      isFollowing: isFollowing ?? this.isFollowing,
      followedAt: followedAt ?? this.followedAt,
      isVerified: isVerified ?? this.isVerified,
      bio: bio ?? this.bio,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': name,
      'email': email,
      'profile': profileImage,
      'isFollowing': isFollowing,
      'followedAt': followedAt?.toIso8601String(),
      'isVerified': isVerified,
      'bio': bio,
    };
  }

  factory UserFollowModel.fromJson(Map<String, dynamic> json) {
    return UserFollowModel(
      id: json['id'] ?? '',
      name: json['fullName'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      profileImage: json['profile'] ?? json['profileImage'] ?? '',
      isFollowing: json['isFollowing'] ?? false,
      followedAt: json['followedAt'] != null
          ? DateTime.tryParse(json['followedAt'].toString())
          : null,
      isVerified: json['isVerified'] ?? false,
      bio: json['bio'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserFollowModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}