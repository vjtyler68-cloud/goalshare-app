import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase/firebase_service.dart';
import '../local/local_data.dart';

/// One place to file a content report for moderation. Writes to the `reports`
/// Firestore collection. Best-effort — callers already hide the offending item
/// locally, so a failed write never blocks the safety action.
/// (Apple App Review Guideline 1.2 — report offensive content.)
class ReportService {
  ReportService._();

  /// [type] is 'feed' | 'chat' | 'story'. [targetId] is the reported item's id,
  /// [targetOwnerId] the id of whoever posted/sent it.
  static Future<void> report({
    required String type,
    required String targetId,
    required String targetOwnerId,
    required String reason,
  }) async {
    if (!FirebaseService.instance.isReady) return;
    try {
      final reporterId = await LocalService().getUserId() ?? '';
      await FirebaseService.instance.db.collection('reports').add({
        'type': type,
        'targetId': targetId,
        'targetOwnerId': targetOwnerId,
        'reporterId': reporterId,
        'reason': reason,
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      log('report write failed (item still hidden locally): $e');
    }
  }
}
