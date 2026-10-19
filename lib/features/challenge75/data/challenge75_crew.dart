import 'dart:developer';
import 'dart:math' show Random;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firebase_service.dart';

/// Optional friend accountability for the 75 Challenge.
///
/// A "crew" is a small shared group keyed by a short invite code. Each member
/// writes a lightweight progress summary (day, streak, today's %) and reads the
/// others' — so friends can keep each other honest. Entirely opt-in: you only
/// have a crew if you create or join one.
///
/// Built on the same Firebase the chat uses, and degrades the same way: if
/// Firebase isn't configured/reachable, [available] is false and the whole
/// sharing tab quietly offers local-only. Every call is wrapped so a failure
/// (including Firestore-rules denial before the rules are published) can never
/// crash the challenge — it just means sharing doesn't sync yet.
class Challenge75Crew {
  Challenge75Crew._();
  static final Challenge75Crew instance = Challenge75Crew._();

  static const String _crewsCol = 'challenge75_crews';
  static const String _membersCol = 'members';

  bool get available => FirebaseService.instance.isReady;

  FirebaseFirestore get _db => FirebaseService.instance.db;

  CollectionReference<Map<String, dynamic>> get _crews =>
      _db.collection(_crewsCol);

  /// Unambiguous code (no 0/O/1/I/L) so it's easy to read out loud / text.
  static String _generateCode() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
  }

  /// Create a new crew and join it as the first member. Returns the invite code
  /// on success, or null if sharing is unavailable / the write failed.
  Future<String?> createCrew({
    required String crewName,
    required String userId,
    required String userName,
  }) async {
    if (!available) return null;
    try {
      // Avoid colliding with an existing crew code (rare, but cheap to check).
      String code = _generateCode();
      for (var i = 0; i < 4; i++) {
        final existing = await _crews.doc(code).get();
        if (!existing.exists) break;
        code = _generateCode();
      }
      await _crews.doc(code).set({
        'name': crewName.trim().isEmpty ? 'My 75 Crew' : crewName.trim(),
        'createdBy': userId,
        'createdByName': userName,
        'members': FieldValue.arrayUnion([userId]),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return code;
    } catch (e) {
      log('Challenge75Crew.createCrew failed: $e');
      return null;
    }
  }

  /// Join an existing crew by code. Returns true if the crew exists and we were
  /// added; false if it doesn't exist or sharing is unavailable.
  Future<bool> joinCrew({
    required String code,
    required String userId,
    required String userName,
  }) async {
    if (!available) return false;
    final c = code.trim().toUpperCase();
    if (c.isEmpty) return false;
    try {
      final doc = await _crews.doc(c).get();
      if (!doc.exists) return false;
      await _crews.doc(c).set({
        'members': FieldValue.arrayUnion([userId]),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      log('Challenge75Crew.joinCrew failed: $e');
      return false;
    }
  }

  /// Leave a crew (removes your roster entry + membership). Best-effort.
  Future<void> leaveCrew({
    required String code,
    required String userId,
  }) async {
    if (!available) return;
    final c = code.trim().toUpperCase();
    try {
      await _crews.doc(c).collection(_membersCol).doc(userId).delete();
      await _crews.doc(c).set({
        'members': FieldValue.arrayRemove([userId]),
      }, SetOptions(merge: true));
    } catch (e) {
      log('Challenge75Crew.leaveCrew failed: $e');
    }
  }

  /// Fetch a crew's display name (null if it doesn't exist / unavailable).
  Future<String?> crewName(String code) async {
    if (!available) return null;
    try {
      final doc = await _crews.doc(code.trim().toUpperCase()).get();
      if (!doc.exists) return null;
      return (doc.data()?['name'] as String?) ?? 'My 75 Crew';
    } catch (e) {
      log('Challenge75Crew.crewName failed: $e');
      return null;
    }
  }

  /// Publish/refresh MY progress summary to the crew. Best-effort; silently
  /// no-ops when sharing is unavailable.
  Future<void> pushProgress({
    required String code,
    required String userId,
    required String userName,
    required String variantId,
    required int day,
    required int daysCompleted,
    required int streak,
    required double completionToday,
    required bool todayComplete,
  }) async {
    if (!available) return;
    final c = code.trim().toUpperCase();
    if (c.isEmpty) return;
    try {
      await _crews.doc(c).collection(_membersCol).doc(userId).set({
        'userId': userId,
        'name': userName,
        'variantId': variantId,
        'day': day,
        'daysCompleted': daysCompleted,
        'streak': streak,
        'completionToday': completionToday,
        'todayComplete': todayComplete,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      log('Challenge75Crew.pushProgress failed: $e');
    }
  }

  /// Live roster of everyone's progress, newest-update first.
  Stream<List<Challenge75CrewMember>> watchCrew(String code) {
    if (!available) return const Stream.empty();
    final c = code.trim().toUpperCase();
    try {
      return _crews
          .doc(c)
          .collection(_membersCol)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => Challenge75CrewMember.fromDoc(d.id, d.data()))
              .toList()
            ..sort((a, b) => b.daysCompleted.compareTo(a.daysCompleted)));
    } catch (e) {
      log('Challenge75Crew.watchCrew failed: $e');
      return const Stream.empty();
    }
  }
}

/// One member's shared progress line in a crew.
class Challenge75CrewMember {
  final String userId;
  final String name;
  final String variantId;
  final int day;
  final int daysCompleted;
  final int streak;
  final double completionToday; // 0..1
  final bool todayComplete;

  const Challenge75CrewMember({
    required this.userId,
    required this.name,
    required this.variantId,
    required this.day,
    required this.daysCompleted,
    required this.streak,
    required this.completionToday,
    required this.todayComplete,
  });

  factory Challenge75CrewMember.fromDoc(String id, Map<String, dynamic> d) =>
      Challenge75CrewMember(
        userId: (d['userId'] as String?) ?? id,
        name: (d['name'] as String?) ?? 'Teammate',
        variantId: (d['variantId'] as String?) ?? '',
        day: (d['day'] as num?)?.toInt() ?? 0,
        daysCompleted: (d['daysCompleted'] as num?)?.toInt() ?? 0,
        streak: (d['streak'] as num?)?.toInt() ?? 0,
        completionToday: (d['completionToday'] as num?)?.toDouble() ?? 0,
        todayComplete: d['todayComplete'] as bool? ?? false,
      );
}
