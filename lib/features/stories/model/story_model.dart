import 'package:cloud_firestore/cloud_firestore.dart';

/// A single "story" — a photo (+ optional caption) a user posts that stays
/// visible to everyone for 24 hours, then quietly disappears.
///
/// The photo is stored as a base64-encoded, aggressively-compressed JPEG right
/// on the Firestore document. That keeps the whole feature $0 on the free Spark
/// plan (no Cloud Storage / Blaze billing required). Compression on the device
/// keeps each photo well under Firestore's 1 MB per-document limit.
class Story {
  final String id;
  final String authorId;
  final String authorName;
  final String authorImage;
  final String imageData; // base64 JPEG
  final String caption;
  final DateTime createdAt;
  final DateTime expireAt;
  final List<String> viewers;

  Story({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorImage,
    required this.imageData,
    required this.caption,
    required this.createdAt,
    required this.expireAt,
    required this.viewers,
  });

  bool get isActive => DateTime.now().isBefore(expireAt);

  bool isViewedBy(String uid) => viewers.contains(uid);

  /// "3h ago" / "12m ago" style relative age used in the viewer header.
  String get ageLabel {
    final d = DateTime.now().difference(createdAt);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  factory Story.fromDoc(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    final expire = data['expireAt'];
    final createdAt = created is Timestamp ? created.toDate() : DateTime.now();
    final expireAt = expire is Timestamp
        ? expire.toDate()
        : createdAt.add(const Duration(hours: 24));
    return Story(
      id: id,
      authorId: (data['authorId'] ?? '') as String,
      authorName: (data['authorName'] ?? '') as String,
      authorImage: (data['authorImage'] ?? '') as String,
      imageData: (data['image'] ?? '') as String,
      caption: (data['caption'] ?? '') as String,
      createdAt: createdAt,
      expireAt: expireAt,
      viewers: (data['viewers'] as List?)?.cast<String>() ?? const [],
    );
  }
}

/// All of one person's active stories, grouped for the stories bar + viewer.
class UserStories {
  final String authorId;
  final String authorName;
  final String authorImage;
  final String authorUsername;
  final List<Story> stories; // oldest → newest

  UserStories({
    required this.authorId,
    required this.authorName,
    required this.authorImage,
    this.authorUsername = '',
    required this.stories,
  });

  bool get isEmpty => stories.isEmpty;
  bool get isNotEmpty => stories.isNotEmpty;

  /// True when [uid] has already seen every story in this group (drives the
  /// grey vs. colourful ring).
  bool allViewedBy(String uid) => stories.every((s) => s.isViewedBy(uid));

  DateTime get latestAt => stories
      .map((s) => s.createdAt)
      .reduce((a, b) => a.isAfter(b) ? a : b);
}
