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

  /// Emoji reactions keyed by the reactor's app user id (one latest per user).
  final Map<String, String> reactions;

  /// Comments in the order they were added (oldest → newest).
  final List<StoryComment> comments;

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
    this.reactions = const {},
    this.comments = const [],
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
      reactions: _parseReactions(data['reactions']),
      comments: _parseComments(data['comments']),
    );
  }

  static Map<String, String> _parseReactions(dynamic raw) {
    if (raw is Map) {
      final out = <String, String>{};
      raw.forEach((k, v) {
        if (k != null && v != null) out[k.toString()] = v.toString();
      });
      return out;
    }
    return const {};
  }

  static List<StoryComment> _parseComments(dynamic raw) {
    if (raw is List) {
      final out = <StoryComment>[];
      for (final e in raw) {
        if (e is Map) {
          out.add(StoryComment.fromMap(Map<String, dynamic>.from(e)));
        }
      }
      out.sort((a, b) => a.at.compareTo(b.at));
      return out;
    }
    return const [];
  }
}

/// One comment left on a story. Stored as a plain map inside the story doc's
/// `comments` array (arrayUnion-friendly — uses a client Timestamp, since
/// serverTimestamp isn't allowed inside array elements).
class StoryComment {
  final String uid;
  final String name;
  final String image;
  final String text;
  final DateTime at;

  StoryComment({
    required this.uid,
    required this.name,
    required this.image,
    required this.text,
    required this.at,
  });

  factory StoryComment.fromMap(Map<String, dynamic> m) {
    final rawAt = m['at'];
    final at = rawAt is Timestamp ? rawAt.toDate() : DateTime.now();
    return StoryComment(
      uid: (m['uid'] ?? '') as String,
      name: (m['name'] ?? '') as String,
      image: (m['image'] ?? '') as String,
      text: (m['text'] ?? '') as String,
      at: at,
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
