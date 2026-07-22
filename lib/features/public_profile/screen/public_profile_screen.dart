import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/const/app_fonts.dart';
import '../../chat_tab/controller/chat_controller.dart';
import '../../stories/controller/stories_controller.dart';
import '../../stories/model/story_model.dart';
import '../../stories/ui/story_ring.dart';
import '../model/profile_view.dart';

/// The "View Profile" screen — a bigger, richer look at a person: large photo
/// (tap to view full-screen, or open their story if they have one), name, bio,
/// and quick actions (Message / Follow).
///
/// Deliberately decoupled: callers pass a [ProfileView] plus optional follow
/// context, so this one screen serves followers, following, search, friends and
/// chat headers alike.
class PublicProfileScreen extends StatefulWidget {
  final ProfileView user;

  /// Show the "Message" action (defaults on for other people).
  final bool showMessage;

  /// When non-null, a Follow / Following button appears. The initial state is
  /// [isFollowing]; tapping calls [onFollowToggle].
  final bool? isFollowing;
  final VoidCallback? onFollowToggle;

  const PublicProfileScreen({
    super.key,
    required this.user,
    this.showMessage = true,
    this.isFollowing,
    this.onFollowToggle,
  });

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  late bool _following = widget.isFollowing ?? false;

  ProfileView get u => widget.user;

  Color get _kRed => AppColors.primaryColor;
  Color get _kRedDk => AppColors.primaryDarkColor;

  /// If the Stories feature is loaded and this person has active stories,
  /// returns their group so we can ring the avatar and open it on tap.
  UserStories? get _activeStory {
    if (!Get.isRegistered<StoriesController>()) return null;
    final c = Get.find<StoriesController>();
    if (u.isMe) return c.myGroup.value;
    for (final g in c.otherGroups) {
      if (g.authorId == u.id) return g;
    }
    return null;
  }

  void _onAvatarTap() {
    final story = _activeStory;
    if (story != null && story.isNotEmpty) {
      Get.find<StoriesController>().openGroup(story);
    } else if (u.image.trim().isNotEmpty) {
      Get.to(() => _FullscreenPhoto(imageUrl: u.image),
          transition: Transition.fadeIn);
    }
  }

  void _message() {
    if (!Get.isRegistered<MessagesController>()) {
      Get.put(MessagesController());
    }
    Get.find<MessagesController>().startChatWith(
      userId: u.id,
      name: u.name,
      email: u.email,
      image: u.image,
    );
  }

  void _toggleFollow() {
    widget.onFollowToggle?.call();
    setState(() => _following = !_following);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F4F2),
      body: Column(
        children: [
          _hero(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
              child: Column(
                children: [
                  if ((u.bio ?? '').trim().isNotEmpty) _bioCard(),
                  if (!u.isMe) _actions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    final hasStory = (_activeStory?.isNotEmpty ?? false);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kRed, _kRedDk],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32.r),
          bottomRight: Radius.circular(32.r),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 26.h),
          child: Column(
            children: [
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    padding: EdgeInsets.all(8.r),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20.r),
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              // Avatar (ring if they have a story) — tap to enlarge / view story
              StoryRing(
                imageUrl: u.image,
                name: u.name,
                size: 104,
                hasStory: hasStory,
                seen: hasStory
                    ? _activeStory!
                        .allViewedBy(Get.find<StoriesController>().myId)
                    : false,
                onTap: _onAvatarTap,
              ),
              SizedBox(height: 8.h),
              if (hasStory)
                Text('Tap to view story',
                    style: AppFonts.spaceGrotesk
                        .copyWith(color: Colors.white70, fontSize: 11.sp))
              else if (u.image.trim().isNotEmpty)
                Text('Tap photo to enlarge',
                    style: AppFonts.spaceGrotesk
                        .copyWith(color: Colors.white70, fontSize: 11.sp)),
              SizedBox(height: 10.h),
              // Name + verified
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      u.name.isEmpty ? 'User' : u.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.spaceGrotesk.copyWith(
                          color: Colors.white,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (u.isVerified) ...[
                    SizedBox(width: 6.w),
                    Icon(Icons.verified_rounded,
                        color: Colors.white, size: 20.r),
                  ],
                ],
              ),
              if (u.email.trim().isNotEmpty) ...[
                SizedBox(height: 3.h),
                Text(u.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.spaceGrotesk
                        .copyWith(color: Colors.white70, fontSize: 13.sp)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _bioCard() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About',
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xff9E9090))),
          SizedBox(height: 6.h),
          Text(u.bio!.trim(),
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 14.sp,
                  color: const Color(0xff1A1010),
                  height: 1.5)),
        ],
      ),
    );
  }

  Widget _actions() {
    return Row(
      children: [
        if (widget.showMessage)
          Expanded(
            child: _actionButton(
              label: 'Message',
              icon: Icons.chat_bubble_outline_rounded,
              filled: true,
              onTap: _message,
            ),
          ),
        if (widget.showMessage && widget.isFollowing != null)
          SizedBox(width: 12.w),
        if (widget.isFollowing != null)
          Expanded(
            child: _actionButton(
              label: _following ? 'Following' : 'Follow',
              icon: _following
                  ? Icons.check_rounded
                  : Icons.person_add_alt_1_rounded,
              filled: !_following,
              onTap: _toggleFollow,
            ),
          ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: filled ? _kRed : Colors.white,
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: _kRed, width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18.r, color: filled ? Colors.white : _kRed),
            SizedBox(width: 8.w),
            Text(
              label,
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: filled ? Colors.white : _kRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple pinch-to-zoom full-screen photo view.
class _FullscreenPhoto extends StatelessWidget {
  final String imageUrl;
  const _FullscreenPhoto({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white38,
                    size: 60),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
