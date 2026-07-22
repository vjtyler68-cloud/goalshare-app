import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/user_info/user_info_controller.dart';
import 'package:spanx/features/stories/controller/stories_controller.dart';

/// The Home-header avatar — Snapchat/Instagram style: your profile picture IS
/// your story ring. Tap it to add to (or view) your story. A warm gradient ring
/// appears when you have an active story; a small "+" invites you to post.
///
/// Changing your profile photo now lives on the Profile tab (tap your avatar
/// there), so this stays a single, uncluttered story control.
class HeaderStoryAvatar extends StatelessWidget {
  const HeaderStoryAvatar({super.key});

  static const _storyGradient = LinearGradient(
    colors: [Color(0xffFF8A34), Color(0xffFF3D77), Color(0xffFFC24B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  String _initials(String n) {
    final p = n.trim().split(RegExp(r'\s+'));
    if (p.isEmpty || p[0].isEmpty) return 'U';
    if (p.length == 1) return p[0][0].toUpperCase();
    return '${p[0][0]}${p[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = Get.find<UserInfoController>();
    final stories = StoriesController.to;
    return Obx(() {
      final u = userInfo.userData.value;
      final name = u?.fullName ?? '';
      final photo = (u?.profile ?? '').trim();
      final hasStory = stories.myGroup.value != null;

      return GestureDetector(
        onTap: stories.openMine,
        child: SizedBox(
          width: 58.r,
          height: 58.r,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Gradient story ring (only when a story is live)
              if (hasStory)
                Container(
                  width: 56.r,
                  height: 56.r,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _storyGradient,
                  ),
                ),
              // White ring / gap — keeps the avatar crisp on the coloured header
              Container(
                width: (hasStory ? 50 : 56).r,
                height: (hasStory ? 50 : 56).r,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
              // The profile photo (or initials fallback)
              SizedBox(
                width: (hasStory ? 44 : 51).r,
                height: (hasStory ? 44 : 51).r,
                child: ClipOval(child: _avatarImg(photo, name)),
              ),
              // "+" badge — ALWAYS adds a new story (even when you already have
              // one live), so you can keep adding. Its own tap target wins over
              // the avatar's tap, which instead views your current story.
              Positioned(
                bottom: -2,
                right: -2,
                child: GestureDetector(
                  onTap: stories.addStory,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 22.r,
                    height: 22.r,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(Icons.add, color: Colors.white, size: 13.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _avatarImg(String photo, String name) {
    final fallback = Container(
      color: AppColors.primaryDarkColor,
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: AppFonts.spaceGrotesk.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 18.sp,
        ),
      ),
    );
    if (photo.isEmpty) return fallback;
    return CachedNetworkImage(
      imageUrl: photo,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => fallback,
    );
  }
}
