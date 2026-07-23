import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firebase_service.dart';
import '../model/activity.dart';

/// All Firestore reads/writes for the Friends Activity Feed.
///
/// Data model:
///   activities/{activityId}
///     authorId, authorName, authorImage
///     type, title, emoji
///     createdAt : Timestamp
///     cheeredBy : [appUserId, …]
///     commentCount : int   (denormalised for the card)
///   activities/{activityId}/comments/{commentId}
///     authorId, authorName, authorImage, text, createdAt
///
/// The feed query orders by `createdAt` only (automatic single-field index),
/// then the controller filters to me + my friends client-side — so no composite
/// index / console step is required.
class FeedRepository {
  FirebaseFirestore get _db => FirebaseService.instance.db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('activities');

  Stream<List<Activity>> watchRecent({int limit = 150}) {
    return _col
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Activity.fromDoc(d.id, d.data())).toList());
  }

  Future<void> post({
    required String authorId,
    required String authorName,
    required String authorImage,
    required String type,
    required String title,
    required String emoji,
    String imageData = '',
  }) async {
    await _col.add({
      'authorId': authorId,
      'authorName': authorName,
      'authorImage': authorImage,
      'type': type,
      'title': title,
      'emoji': emoji,
      'image': imageData,
      'createdAt': Timestamp.now(),
      'cheeredBy': <String>[],
      'commentCount': 0,
    });
  }

  Future<void> toggleCheer(String activityId, String uid, bool on) async {
    await _col.doc(activityId).set({
      'cheeredBy':
          on ? FieldValue.arrayUnion([uid]) : FieldValue.arrayRemove([uid]),
    }, SetOptions(merge: true));
  }

  Stream<List<ActivityComment>> watchComments(String activityId) {
    return _col
        .doc(activityId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ActivityComment.fromDoc(d.id, d.data()))
            .toList());
  }

  Future<void> addComment(
    String activityId, {
    required String authorId,
    required String authorName,
    required String authorImage,
    required String text,
  }) async {
    final activityRef = _col.doc(activityId);
    await activityRef.collection('comments').add({
      'authorId': authorId,
      'authorName': authorName,
      'authorImage': authorImage,
      'text': text,
      'createdAt': Timestamp.now(),
    });
    // Keep the card's comment count in sync.
    await activityRef.set(
      {'commentCount': FieldValue.increment(1)},
      SetOptions(merge: true),
    );
  }

  Future<void> delete(String activityId) async {
    await _col.doc(activityId).delete();
  }
}
