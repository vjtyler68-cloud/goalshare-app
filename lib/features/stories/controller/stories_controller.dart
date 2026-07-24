import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/const/app_fonts.dart';
import '../../../core/firebase/firebase_service.dart';
import '../../../core/global_widgets/app_snackbar.dart';
import '../../../core/local/local_data.dart';
import '../../../core/safety/block_controller.dart';
import '../../../core/safety/report_service.dart';
import '../../../core/user_info/user_info_controller.dart';
import '../../friends/controller/friends_controller.dart';
import '../model/story_model.dart';
import '../repository/stories_repository.dart';
import '../ui/story_compose_screen.dart';
import '../ui/story_viewer_screen.dart';

/// Drives the stories bar, posting flow and viewer.
///
/// Stories are inherently a shared/social feature, so they only light up when
/// Firebase is ready. If it isn't, [ready] is false and the bar hides itself.
class StoriesController extends GetxController {
  /// Safe singleton accessor — both the header avatar and the stories bar reach
  /// the controller through this, so whichever builds first registers it.
  static StoriesController get to => Get.isRegistered<StoriesController>()
      ? Get.find<StoriesController>()
      : Get.put(StoriesController(), permanent: true);

  final _repo = StoriesRepository();
  final _local = LocalService();

  /// Other people's active stories, ready for the bar (sorted unseen-first).
  final RxList<UserStories> otherGroups = <UserStories>[].obs;

  /// My own active stories (shown as the leading "Your story" ring).
  final Rxn<UserStories> myGroup = Rxn<UserStories>();

  final RxBool posting = false.obs;

  String _myId = '';
  String _myName = '';
  String _myImage = '';

  /// Raw stream cache + reported-story ids, so we can re-filter (block/report)
  /// without waiting for the next Firestore emission.
  List<Story> _allStories = const [];
  final Set<String> _hidden = {};

  StreamSubscription? _sub;
  Worker? _blockWorker;
  Worker? _friendsWorker;

  bool get ready => FirebaseService.instance.isReady;
  String get myId => _myId;
  String get myName => _myName;
  String get myImage => _myImage;

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  @override
  void onClose() {
    _sub?.cancel();
    _blockWorker?.dispose();
    _friendsWorker?.dispose();
    super.onClose();
  }

  Future<void> _bootstrap() async {
    _myId = await _local.getUserId() ?? '';
    _myName = await _local.getName() ?? '';
    _myImage = await _local.getImagePath() ?? '';
    _hidden.addAll(await _local.getHiddenStories());
    // Prefer the freshest name/photo from the live user profile when available.
    if (Get.isRegistered<UserInfoController>()) {
      final u = Get.find<UserInfoController>().userData.value;
      if (u != null) {
        if ((u.fullName ?? '').isNotEmpty) _myName = u.fullName!;
        if ((u.profile ?? '').isNotEmpty) _myImage = u.profile!;
      }
    }

    if (!ready || _myId.isEmpty) return;

    // Fire-and-forget cleanup of my own stale stories.
    _repo.purgeMyExpired(_myId);

    // Re-group when the block list OR my friends list changes (stories are
    // friends-only, and rings show each friend's current photo + @username).
    _blockWorker ??= ever(BlockController.to.blocked, (_) => _regroup());
    _friendsWorker ??= ever(FriendsController.to.friends, (_) => _regroup());

    _sub = _repo.watchActive().listen(
      _onStories,
      onError: (e) => log('Stories stream error: $e'),
    );
  }

  void _onStories(List<Story> all) {
    _allStories = all;
    _regroup();
  }

  void _regroup() {
    final now = DateTime.now();

    // Only people I'm connected to (my friends) — plus me — show up. Build a
    // lookup so each ring reflects that friend's CURRENT photo + @username.
    final friends = {for (final f in FriendsController.to.friends) f.id: f};

    final active = _allStories
        .where((s) =>
            now.isBefore(s.expireAt) &&
            !BlockController.to.isBlocked(s.authorId) &&
            !_hidden.contains(s.id) &&
            (s.authorId == _myId || friends.containsKey(s.authorId)))
        .toList();

    // Group by author.
    final byAuthor = <String, List<Story>>{};
    for (final s in active) {
      byAuthor.putIfAbsent(s.authorId, () => []).add(s);
    }

    // My own stories → the leading ring.
    final mine = byAuthor.remove(_myId);
    if (mine != null && mine.isNotEmpty) {
      mine.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      myGroup.value = UserStories(
        authorId: _myId,
        authorName: 'Your story',
        authorImage: _myImage.isNotEmpty ? _myImage : mine.first.authorImage,
        authorUsername: FriendsController.to.myUsername ?? '',
        stories: mine,
      );
    } else {
      myGroup.value = null;
    }

    // Everyone else — name/photo/username resolved from the friend record so
    // the ring always shows who it is (not a blank "U").
    final groups = byAuthor.entries.map((e) {
      final list = e.value..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final f = friends[e.key];
      final name =
          (f != null && f.name.trim().isNotEmpty) ? f.name : list.first.authorName;
      final image = (f != null && (f.profile ?? '').isNotEmpty)
          ? f.profile!
          : list.first.authorImage;
      return UserStories(
        authorId: e.key,
        authorName: name,
        authorImage: image,
        authorUsername: f?.username ?? '',
        stories: list,
      );
    }).toList();

    // Unseen first, then most-recent first.
    groups.sort((a, b) {
      final aSeen = a.allViewedBy(_myId);
      final bSeen = b.allViewedBy(_myId);
      if (aSeen != bSeen) return aSeen ? 1 : -1;
      return b.latestAt.compareTo(a.latestAt);
    });

    otherGroups.assignAll(groups);
  }

  // ── Posting ────────────────────────────────────────────────────────────────

  /// Opens the "add to your story" source chooser (camera / library).
  void addStory() {
    if (!ready) {
      AppSnackBar.show(
        message: 'Connect to the internet to post a story',
        isSuccessful: false,
      );
      return;
    }
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 28.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 14.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            Text('Add to your story',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xff1A1010))),
            SizedBox(height: 14.h),
            _sourceRow(Icons.photo_camera_rounded, 'Take a photo', () {
              Get.back();
              _pick(ImageSource.camera);
            }),
            _sourceRow(Icons.photo_library_rounded, 'Choose from library', () {
              Get.back();
              _pick(ImageSource.gallery);
            }),
          ],
        ),
      ),
    );
  }

  Widget _sourceRow(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: const Color(0xffF6F4F2),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          children: [
            Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Icon(icon, color: AppColors.primaryColor, size: 19.r),
            ),
            SizedBox(width: 12.w),
            Text(label,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff1A1010))),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(ImageSource source) async {
    XFile? image;
    try {
      // Aggressive compression keeps the base64 payload well under Firestore's
      // 1 MB document limit and keeps bandwidth (and cost) tiny.
      image = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 45,
      );
    } catch (_) {
      AppSnackBar.show(
        message:
            "Couldn't open the ${source == ImageSource.camera ? 'camera' : 'photo library'}",
        isSuccessful: false,
      );
      return;
    }
    if (image == null) return; // cancelled

    final bytes = await File(image.path).readAsBytes();
    final b64 = base64Encode(bytes);
    if (b64.length > 950000) {
      AppSnackBar.show(
        message: 'That photo is a bit large — try a different one',
        isSuccessful: false,
      );
      return;
    }
    // Hand off to the compose screen for an optional caption + confirm.
    Get.to(() => StoryComposeScreen(imageBytes: bytes, base64Image: b64));
  }

  /// Called by the compose screen once the user confirms.
  Future<void> publish(String base64Image, String caption) async {
    if (posting.value) return;
    posting.value = true;
    try {
      await _repo.post(
        authorId: _myId,
        authorName: _myName,
        authorImage: _myImage,
        imageData: base64Image,
        caption: caption.trim(),
      );
      AppSnackBar.show(message: 'Shared to your story ✨', isSuccessful: true);
    } catch (e) {
      log('Failed to post story: $e');
      AppSnackBar.show(
          message: "Couldn't share your story — try again",
          isSuccessful: false);
      rethrow;
    } finally {
      posting.value = false;
    }
  }

  // ── Viewing ──────────────────────────────────────────────────────────────

  void openGroup(UserStories group) {
    if (group.isEmpty) return;
    _markSeen(group);
    Get.to(
      () => StoryViewerScreen(group: group, isMine: group.authorId == _myId),
      transition: Transition.fadeIn,
    );
  }

  /// Open my own story ring; if I have none yet, jump straight to posting.
  void openMine() {
    final g = myGroup.value;
    if (g == null || g.isEmpty) {
      addStory();
    } else {
      openGroup(g);
    }
  }

  void _markSeen(UserStories group) {
    if (_myId.isEmpty) return;
    for (final s in group.stories) {
      // Don't record the author viewing their own story.
      if (s.authorId == _myId) continue;
      if (!s.isViewedBy(_myId)) {
        _repo.markViewed(s.id, _myId);
      }
    }
  }

  /// Record that I've seen a single story as it's advanced to in the viewer.
  /// Own stories are never counted as views.
  void markStorySeen(Story story) {
    if (_myId.isEmpty || story.authorId == _myId) return;
    if (story.isViewedBy(_myId)) return;
    _repo.markViewed(story.id, _myId);
  }

  // ── Social: reactions & comments ────────────────────────────────────────────

  String get myUsername => FriendsController.to.myUsername ?? '';

  /// Persist my emoji reaction to [story] (my latest replaces any previous).
  Future<void> setReaction(Story story, String emoji) async {
    if (_myId.isEmpty || !ready) return;
    try {
      await _repo.setReaction(story.id, _myId, emoji);
    } catch (e) {
      log('Failed to set reaction: $e');
    }
  }

  /// Add a comment to [story]. Returns the built [StoryComment] on success so
  /// the sheet can show it immediately, or null on failure.
  Future<StoryComment?> addComment(Story story, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _myId.isEmpty || !ready) return null;
    final now = DateTime.now();
    final map = <String, dynamic>{
      'uid': _myId,
      'name': _myName,
      'image': _myImage,
      'text': trimmed,
      'at': Timestamp.fromDate(now),
    };
    try {
      await _repo.addComment(story.id, map);
      return StoryComment(
        uid: _myId,
        name: _myName,
        image: _myImage,
        text: trimmed,
        at: now,
      );
    } catch (e) {
      log('Failed to add comment: $e');
      AppSnackBar.show(
          message: "Couldn't send that comment — try again",
          isSuccessful: false);
      return null;
    }
  }

  /// Fetch the freshest copy of a story (latest reactions/comments) for a sheet.
  Future<Story?> refreshStory(String storyId) async {
    if (!ready) return null;
    try {
      return await _repo.fetchOne(storyId);
    } catch (e) {
      log('Failed to refresh story: $e');
      return null;
    }
  }

  /// Resolve display info (name, @username, photo) for a viewer/commenter uid,
  /// preferring the current friend record, then the story author, else generic.
  ({String name, String username, String image}) resolveUser(
    String uid, {
    String fallbackName = '',
    String fallbackImage = '',
  }) {
    if (uid == _myId) {
      return (name: 'You', username: myUsername, image: _myImage);
    }
    for (final f in FriendsController.to.friends) {
      if (f.id == uid) {
        return (
          name: f.name.trim().isNotEmpty ? f.name : (fallbackName),
          username: f.username ?? '',
          image: (f.profile ?? '').isNotEmpty ? f.profile! : fallbackImage,
        );
      }
    }
    return (
      name: fallbackName.trim().isNotEmpty ? fallbackName : 'Someone',
      username: '',
      image: fallbackImage,
    );
  }

  Future<void> deleteStory(Story story) async {
    try {
      await _repo.delete(story.id);
      AppSnackBar.show(message: 'Story deleted', isSuccessful: true);
    } catch (_) {
      AppSnackBar.show(
          message: "Couldn't delete that story", isSuccessful: false);
    }
  }

  // ── Safety: block author / report story (Apple UGC) ─────────────────────────

  /// Block a story's author app-wide (also hides their feed posts + chat).
  Future<void> blockAuthor(Story story) async {
    if (story.authorId.isEmpty || story.authorId == _myId) return;
    final who =
        story.authorName.trim().isEmpty ? 'user' : story.authorName.trim();
    await BlockController.to.block(story.authorId, story.authorName);
    _regroup();
    AppSnackBar.show(
        message: "Blocked $who — you won't see their stories.",
        isSuccessful: true);
  }

  /// Hide a reported story from my view and record the report for moderation.
  Future<void> reportStory(Story story, String reason) async {
    _hidden.add(story.id);
    await _local.setHiddenStories(_hidden);
    _regroup();
    await ReportService.report(
      type: 'story',
      targetId: story.id,
      targetOwnerId: story.authorId,
      reason: reason,
    );
    AppSnackBar.show(
        message: "Thanks — we'll review it. Story hidden.",
        isSuccessful: true);
  }
}
