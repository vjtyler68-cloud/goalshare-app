import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';

import '../../../core/firebase/firebase_service.dart';
import '../../../core/global_widgets/app_snackbar.dart';
import '../../../core/local/local_data.dart';
import '../../../core/user_info/user_info_controller.dart';
import '../../friends/controller/friends_controller.dart';
import '../model/activity.dart';
import '../repository/feed_repository.dart';

/// Drives the Friends Activity Feed: streams recent activities, filters them to
/// me + my friends, and handles cheering, commenting and sharing wins.
class FeedController extends GetxController {
  /// Stable singleton — mirrors [StoriesController.to]. Ensures a single,
  /// permanent instance bootstraps once (when Firebase is ready) and stays
  /// alive across feed opens, so the share/stream path is never on a
  /// half-initialised throwaway instance.
  static FeedController get to => Get.isRegistered<FeedController>()
      ? Get.find<FeedController>()
      : Get.put(FeedController(), permanent: true);

  final _repo = FeedRepository();
  final _local = LocalService();

  /// Feed filtered to me + my friends, newest first.
  final RxList<Activity> activities = <Activity>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool posting = false.obs;

  /// The privacy toggle surfaced in the feed's settings sheet.
  final RxBool shareWins = true.obs;

  String _myId = '';
  String _myName = '';
  String _myImage = '';

  List<Activity> _allRecent = const [];
  StreamSubscription? _sub;
  Worker? _friendsWorker;

  bool get ready => FirebaseService.instance.isReady;
  String get myId => _myId;

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  @override
  void onClose() {
    _sub?.cancel();
    _friendsWorker?.dispose();
    super.onClose();
  }

  Future<void> _bootstrap() async {
    shareWins.value = await _local.getShareWins();
    await _ensureIdentity();
    await _startStream();
  }

  /// Resolve who I am (id/name/photo) from local storage + the live profile.
  /// Idempotent, and re-run right before a write so a post never goes out with
  /// a stale/empty author.
  Future<void> _ensureIdentity() async {
    if (_myId.isEmpty) _myId = await _local.getUserId() ?? '';
    if (_myName.isEmpty) _myName = await _local.getName() ?? '';
    if (_myImage.isEmpty) _myImage = await _local.getImagePath() ?? '';
    if (Get.isRegistered<UserInfoController>()) {
      final u = Get.find<UserInfoController>().userData.value;
      if (u != null) {
        if ((u.fullName ?? '').isNotEmpty) _myName = u.fullName!;
        if ((u.profile ?? '').isNotEmpty) _myImage = u.profile!;
      }
    }
  }

  /// Subscribe to the live feed. Waits out a cold-start race where Firebase
  /// isn't ready the instant the controller is created (previously this
  /// returned early and the feed stayed permanently empty).
  Future<void> _startStream() async {
    if (_sub != null) return; // already streaming
    var tries = 0;
    while (!ready && tries < 25) {
      await Future.delayed(const Duration(milliseconds: 400));
      tries++;
    }
    if (!ready) return;

    // Keep the friends list warm so the feed filter is correct, and re-filter
    // whenever it changes (e.g. a request gets accepted).
    final friends = FriendsController.to;
    _friendsWorker ??= ever(friends.friends, (_) => _applyFilter());

    isLoading.value = true;
    _sub = _repo.watchRecent().listen(
      (all) {
        _allRecent = all;
        _applyFilter();
        isLoading.value = false;
      },
      onError: (e) {
        log('Feed stream error: $e');
        isLoading.value = false;
      },
    );
  }

  void _applyFilter() {
    final friendIds =
        FriendsController.to.friends.map((f) => f.id).toSet();
    final visible = _allRecent
        .where((a) => a.authorId == _myId || friendIds.contains(a.authorId))
        .toList();
    activities.assignAll(visible);
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> toggleCheer(Activity a) async {
    if (_myId.isEmpty) return;
    final on = !a.cheeredByMe(_myId);
    try {
      await _repo.toggleCheer(a.id, _myId, on);
    } catch (e) {
      log('cheer failed: $e');
    }
  }

  /// Post a win. Text and/or a photo — a photo on its own is allowed so people
  /// can just share a picture of the moment.
  Future<void> shareWin(String text, {String base64Image = ''}) async {
    final t = text.trim();
    if ((t.isEmpty && base64Image.isEmpty) || posting.value) return;
    posting.value = true;
    try {
      // Resolve identity + make sure we're streaming, so the new win shows up.
      await _ensureIdentity();
      await _startStream();
      // Manual share always posts, regardless of the auto-share toggle.
      await _repo.post(
        authorId: _myId,
        authorName: _myName,
        authorImage: _myImage,
        type: 'win',
        title: t,
        emoji: '💪',
        imageData: base64Image,
      );
      AppSnackBar.show(
          message: 'Win shared with your friends 🎉', isSuccessful: true);
    } catch (e) {
      log('shareWin failed: $e');
      // Surface the real reason (e.g. PERMISSION_DENIED, network) so a failure
      // is diagnosable instead of a generic "try again".
      AppSnackBar.show(message: 'Share failed: $e', isSuccessful: false);
    } finally {
      posting.value = false;
    }
  }

  Stream<List<ActivityComment>> comments(String activityId) =>
      _repo.watchComments(activityId);

  Future<void> addComment(String activityId, String text) async {
    final t = text.trim();
    if (t.isEmpty || _myId.isEmpty) return;
    try {
      await _repo.addComment(
        activityId,
        authorId: _myId,
        authorName: _myName,
        authorImage: _myImage,
        text: t,
      );
    } catch (e) {
      log('addComment failed: $e');
      AppSnackBar.show(
          message: "Couldn't post your comment", isSuccessful: false);
    }
  }

  Future<void> deleteActivity(Activity a) async {
    try {
      await _repo.delete(a.id);
      AppSnackBar.show(message: 'Removed', isSuccessful: true);
    } catch (_) {
      AppSnackBar.show(message: "Couldn't remove that", isSuccessful: false);
    }
  }

  Future<void> setShareWins(bool value) async {
    shareWins.value = value;
    await _local.setShareWins(value);
  }

  bool isMine(Activity a) => a.authorId == _myId;
}
