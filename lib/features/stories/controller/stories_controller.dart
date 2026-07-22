import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/const/app_fonts.dart';
import '../../../core/firebase/firebase_service.dart';
import '../../../core/global_widgets/app_snackbar.dart';
import '../../../core/local/local_data.dart';
import '../../../core/user_info/user_info_controller.dart';
import '../model/story_model.dart';
import '../repository/stories_repository.dart';
import '../ui/story_compose_screen.dart';
import '../ui/story_viewer_screen.dart';

/// Drives the stories bar, posting flow and viewer.
///
/// Stories are inherently a shared/social feature, so they only light up when
/// Firebase is ready. If it isn't, [ready] is false and the bar hides itself.
class StoriesController extends GetxController {
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

  StreamSubscription? _sub;

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
    super.onClose();
  }

  Future<void> _bootstrap() async {
    _myId = await _local.getUserId() ?? '';
    _myName = await _local.getName() ?? '';
    _myImage = await _local.getImagePath() ?? '';
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

    _sub = _repo.watchActive().listen(
      _onStories,
      onError: (e) => log('Stories stream error: $e'),
    );
  }

  void _onStories(List<Story> all) {
    final now = DateTime.now();
    final active = all.where((s) => now.isBefore(s.expireAt)).toList();

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
        stories: mine,
      );
    } else {
      myGroup.value = null;
    }

    // Everyone else.
    final groups = byAuthor.entries.map((e) {
      final list = e.value..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return UserStories(
        authorId: e.key,
        authorName: list.first.authorName,
        authorImage: list.first.authorImage,
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
      if (!s.isViewedBy(_myId)) {
        _repo.markViewed(s.id, _myId);
      }
    }
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
}
