import 'package:cloud_firestore/cloud_firestore.dart';

/// One item in the Friends Activity Feed — a "win" someone shared or an
/// achievement/streak the app auto-posted on their behalf.
class Activity {
  final String id;
  final String authorId;
  final String authorName;
  final String authorImage;

  /// 'win' (manual share) | 'achievement' | 'streak' | 'goal'.
  final String type;

  /// The headline, e.g. `unlocked "Hot Streak"` or the user's own words.
  final String title;
  final String emoji;

  /// Optional photo attached to a win, as a base64 JPEG (empty when none).
  final String imageData;

  final DateTime createdAt;
  final List<String> cheeredBy;
  final int commentCount;

  Activity({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorImage,
    required this.type,
    required this.title,
    required this.emoji,
    this.imageData = '',
    required this.createdAt,
    required this.cheeredBy,
    required this.commentCount,
  });

  bool get hasImage => imageData.isNotEmpty;
  int get cheerCount => cheeredBy.length;
  bool cheeredByMe(String uid) => cheeredBy.contains(uid);

  String get ageLabel {
    final d = DateTime.now().difference(createdAt);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays < 7) return '${d.inDays}d';
    return '${(d.inDays / 7).floor()}w';
  }

  factory Activity.fromDoc(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'];
    return Activity(
      id: id,
      authorId: (data['authorId'] ?? '') as String,
      authorName: (data['authorName'] ?? '') as String,
      authorImage: (data['authorImage'] ?? '') as String,
      type: (data['type'] ?? 'win') as String,
      title: (data['title'] ?? '') as String,
      emoji: (data['emoji'] ?? '🎉') as String,
      imageData: (data['image'] ?? '') as String,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      cheeredBy: (data['cheeredBy'] as List?)?.cast<String>() ?? const [],
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A comment on an activity — lightweight encouragement / accountability.
class ActivityComment {
  final String id;
  final String authorId;
  final String authorName;
  final String authorImage;
  final String text;
  final DateTime createdAt;

  ActivityComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorImage,
    required this.text,
    required this.createdAt,
  });

  String get ageLabel {
    final d = DateTime.now().difference(createdAt);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }

  factory ActivityComment.fromDoc(String id, Map<String, dynamic> data) {
    final ts = data['createdAt'];
    return ActivityComment(
      id: id,
      authorId: (data['authorId'] ?? '') as String,
      authorName: (data['authorName'] ?? '') as String,
      authorImage: (data['authorImage'] ?? '') as String,
      text: (data['text'] ?? '') as String,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
