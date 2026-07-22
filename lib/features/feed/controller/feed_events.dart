import 'dart:developer';

import 'package:get/get.dart';

import '../../../core/firebase/firebase_service.dart';
import '../../../core/local/local_data.dart';
import '../../../core/user_info/user_info_controller.dart';
import '../repository/feed_repository.dart';

/// Fire-and-forget helper for AUTO-posting wins to the Friends Activity Feed
/// from non-UI code (e.g. the achievements controller when a badge unlocks).
///
/// Every auto-post is gated by [LocalService.getShareWins] (the user's privacy
/// toggle) and by Firebase readiness, so it silently no-ops when either is off.
/// Manual "Share a win" posts live in [FeedController] and ignore the toggle.
class FeedEvents {
  FeedEvents._();

  static final FeedRepository _repo = FeedRepository();
  static final LocalService _local = LocalService();

  static Future<void> _autoPost({
    required String type,
    required String title,
    required String emoji,
  }) async {
    if (!FirebaseService.instance.isReady) return;
    if (!await _local.getShareWins()) return;

    final id = await _local.getUserId() ?? '';
    if (id.isEmpty) return;

    var name = await _local.getName() ?? '';
    var image = await _local.getImagePath() ?? '';
    if (Get.isRegistered<UserInfoController>()) {
      final u = Get.find<UserInfoController>().userData.value;
      if (u != null) {
        if ((u.fullName ?? '').isNotEmpty) name = u.fullName!;
        if ((u.profile ?? '').isNotEmpty) image = u.profile!;
      }
    }

    try {
      await _repo.post(
        authorId: id,
        authorName: name,
        authorImage: image,
        type: type,
        title: title,
        emoji: emoji,
      );
    } catch (e) {
      log('FeedEvents auto-post failed: $e');
    }
  }

  /// A badge just unlocked — broadcast it to friends.
  static void achievementUnlocked(String title, String emoji) {
    _autoPost(type: 'achievement', title: 'unlocked "$title"', emoji: emoji);
  }

  /// A streak hit a milestone (3, 7, 14, 30, …).
  static void streakMilestone(int days) {
    _autoPost(type: 'streak', title: 'is on a $days-day streak', emoji: '🔥');
  }
}
