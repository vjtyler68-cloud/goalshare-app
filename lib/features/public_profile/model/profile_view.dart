/// A lightweight, source-agnostic snapshot of a person used by the public
/// "View Profile" screen. Any list in the app (followers, following, friends,
/// search, a chat header) can build one of these from whatever model it holds.
class ProfileView {
  final String id;
  final String name;
  final String email;
  final String image;
  final bool isVerified;
  final String? bio;

  /// True when this is the signed-in user's own profile (hides the Message /
  /// Follow actions and shows self-oriented copy instead).
  final bool isMe;

  const ProfileView({
    required this.id,
    required this.name,
    this.email = '',
    this.image = '',
    this.isVerified = false,
    this.bio,
    this.isMe = false,
  });
}
