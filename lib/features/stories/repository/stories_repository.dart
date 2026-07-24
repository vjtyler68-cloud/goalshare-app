import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firebase_service.dart';
import '../model/story_model.dart';

/// All Firestore reads/writes for Stories live here.
///
/// Data model:
///   stories/{storyId}
///     authorId, authorName, authorImage
///     image     : base64 JPEG (compressed on device)
///     caption   : String
///     createdAt : Timestamp
///     expireAt  : Timestamp  (createdAt + 24h) — the active-window key
///     viewers   : [appUserId, …]
///
/// The active-stories query filters on `expireAt > now` and orders by the same
/// field, so it only needs Firestore's automatic single-field index — no
/// composite index / console step required.
class StoriesRepository {
  FirebaseFirestore get _db => FirebaseService.instance.db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('stories');

  static const Duration _ttl = Duration(hours: 24);

  /// Live stream of every currently-active story across all users.
  Stream<List<Story>> watchActive() {
    return _col
        .where('expireAt', isGreaterThan: Timestamp.now())
        .orderBy('expireAt')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Story.fromDoc(d.id, d.data())).toList());
  }

  Future<void> post({
    required String authorId,
    required String authorName,
    required String authorImage,
    required String imageData,
    required String caption,
  }) async {
    final now = DateTime.now();
    await _col.add({
      'authorId': authorId,
      'authorName': authorName,
      'authorImage': authorImage,
      'image': imageData,
      'caption': caption,
      'createdAt': Timestamp.fromDate(now),
      'expireAt': Timestamp.fromDate(now.add(_ttl)),
      'viewers': <String>[],
    });
  }

  /// Record that [uid] has seen a story (drives the seen/unseen ring).
  Future<void> markViewed(String storyId, String uid) async {
    await _col.doc(storyId).set({
      'viewers': FieldValue.arrayUnion([uid]),
    }, SetOptions(merge: true));
  }

  /// Set (or replace) [uid]'s emoji reaction on a story. A dot-path field
  /// update touches only that one map key, so it can't clobber others.
  Future<void> setReaction(String storyId, String uid, String emoji) async {
    await _col.doc(storyId).update({'reactions.$uid': emoji});
  }

  /// Append a comment to a story's `comments` array. The map must carry a
  /// client [Timestamp] for `at` — serverTimestamp() is rejected inside
  /// arrayUnion elements.
  Future<void> addComment(
      String storyId, Map<String, dynamic> commentMap) async {
    await _col.doc(storyId).set({
      'comments': FieldValue.arrayUnion([commentMap]),
    }, SetOptions(merge: true));
  }

  /// Fetch a single story's latest state (used to refresh a viewer/comment
  /// sheet with the freshest reactions/comments). Returns null if it's gone.
  Future<Story?> fetchOne(String storyId) async {
    final doc = await _col.doc(storyId).get();
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return Story.fromDoc(doc.id, data);
  }

  Future<void> delete(String storyId) async {
    await _col.doc(storyId).delete();
  }

  /// Best-effort cleanup of this user's own expired stories. Called on startup
  /// so the collection doesn't grow forever. (A Firestore TTL policy on
  /// `expireAt` can replace this once the project moves to Blaze.)
  ///
  /// Uses an equality-only query (automatic single-field index) and filters the
  /// expired ones client-side, so no composite index / console step is needed.
  Future<void> purgeMyExpired(String authorId) async {
    try {
      final snap = await _col.where('authorId', isEqualTo: authorId).get();
      final now = DateTime.now();
      for (final d in snap.docs) {
        final expire = d.data()['expireAt'];
        final expireAt = expire is Timestamp ? expire.toDate() : now;
        if (now.isAfter(expireAt)) {
          await d.reference.delete();
        }
      }
    } catch (_) {
      // Non-critical; expired stories are already filtered out of the UI.
    }
  }
}
