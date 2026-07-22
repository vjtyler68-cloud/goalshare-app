import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/const/app_fonts.dart';
import '../controller/feed_controller.dart';
import '../model/activity.dart';
import 'comments_sheet.dart';
import 'share_win_sheet.dart';

Color get _kRed => AppColors.primaryColor;
Color get _kRedDk => AppColors.primaryDarkColor;
const _kBg = Color(0xffF6F4F2);
const _kCard = Color(0xffFFFFFF);
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// The Friends Activity Feed — a scroll of everyone's wins with cheers +
/// comments. This is the accountability loop: your friends see your progress,
/// cheer you on, and you do the same for them.
class FeedScreen extends StatelessWidget {
  FeedScreen({super.key});

  final FeedController c = FeedController.to;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _header(),
          Expanded(
            child: !c.ready
                ? _offline()
                : Obx(() {
                    if (c.isLoading.value && c.activities.isEmpty) {
                      return Center(
                          child: CircularProgressIndicator(color: _kRed));
                    }
                    if (c.activities.isEmpty) return _empty();
                    return ListView.builder(
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 100.h),
                      itemCount: c.activities.length,
                      itemBuilder: (_, i) => _ActivityCard(
                        activity: c.activities[i],
                        controller: c,
                      ),
                    );
                  }),
          ),
        ],
      ),
      floatingActionButton: !c.ready
          ? null
          : FloatingActionButton.extended(
              backgroundColor: _kRed,
              onPressed: () => ShareWinSheet.show(c),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text('Share a win',
                  style: AppFonts.spaceGrotesk.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
    );
  }

  Widget _header() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kRed, _kRedDk],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(8.w, 8.h, 12.w, 16.h),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              ),
              Text('Activity',
                  style: AppFonts.spaceGrotesk.copyWith(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              IconButton(
                onPressed: _openSettings,
                icon: const Icon(Icons.tune_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSettings() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 28.h),
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
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r)),
              ),
            ),
            Obx(() => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: _kRed,
                  value: c.shareWins.value,
                  onChanged: c.setShareWins,
                  title: Text('Auto-share my wins',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: _kText)),
                  subtitle: Text(
                      'Post my achievements & streak milestones to friends automatically.',
                      style: AppFonts.spaceGrotesk
                          .copyWith(fontSize: 12.sp, color: _kMuted)),
                )),
          ],
        ),
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🔥', style: TextStyle(fontSize: 48.sp)),
            SizedBox(height: 14.h),
            Text('No wins yet',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
            SizedBox(height: 8.h),
            Text(
                'Be the first to share a win — or add friends so their progress shows up here.',
                textAlign: TextAlign.center,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 13.sp, color: _kMuted, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _offline() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Text(
          'Connect to the internet to see your friends’ activity.',
          textAlign: TextAlign.center,
          style: AppFonts.spaceGrotesk
              .copyWith(fontSize: 14.sp, color: _kMuted, height: 1.5),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Activity activity;
  final FeedController controller;
  const _ActivityCard({required this.activity, required this.controller});

  @override
  Widget build(BuildContext context) {
    final a = activity;
    final mine = controller.isMine(a);
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(url: a.authorImage, name: a.authorName, size: 42),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(mine ? 'You' : a.authorName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.spaceGrotesk.copyWith(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w800,
                                  color: _kText)),
                        ),
                        SizedBox(width: 6.w),
                        Text('· ${a.ageLabel}',
                            style: AppFonts.spaceGrotesk
                                .copyWith(fontSize: 11.sp, color: _kMuted)),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    _headline(a, mine),
                  ],
                ),
              ),
              if (mine)
                GestureDetector(
                  onTap: () => _confirmDelete(),
                  child: Padding(
                    padding: EdgeInsets.all(4.r),
                    child: Icon(Icons.more_horiz, color: _kMuted, size: 20.r),
                  ),
                ),
            ],
          ),
          // Optional attached photo
          if (a.hasImage) ...[
            SizedBox(height: 12.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(14.r),
              child: _ActivityPhoto(base64: a.imageData),
            ),
          ],
          SizedBox(height: 12.h),
          Row(
            children: [
              _CheerButton(activity: a, controller: controller),
              SizedBox(width: 18.w),
              GestureDetector(
                onTap: () => CommentsSheet.show(controller, a),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Icon(Icons.mode_comment_outlined,
                        size: 20.r, color: _kMuted),
                    SizedBox(width: 6.w),
                    Text(
                        a.commentCount == 0 ? 'Comment' : '${a.commentCount}',
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: _kMuted)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headline(Activity a, bool mine) {
    // Achievements/streaks read "<name> unlocked …"; wins are the user's words.
    final isEvent = a.type == 'achievement' || a.type == 'streak';
    if (isEvent) {
      return Row(
        children: [
          Text(a.emoji, style: TextStyle(fontSize: 15.sp)),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(a.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: _kText)),
          ),
        ],
      );
    }
    return Text('${a.emoji}  ${a.title}',
        style: AppFonts.spaceGrotesk.copyWith(
            fontSize: 14.sp,
            color: _kText,
            height: 1.35,
            fontWeight: FontWeight.w500));
  }

  void _confirmDelete() {
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
      title: Text('Remove this?',
          style: AppFonts.spaceGrotesk.copyWith(
              fontWeight: FontWeight.w800, fontSize: 16.sp)),
      content: Text('It disappears from everyone’s feed.',
          style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp)),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            Get.back();
            controller.deleteActivity(activity);
          },
          child: const Text('Remove', style: TextStyle(color: Colors.red)),
        ),
      ],
    ));
  }
}

/// Decodes an attached win photo (base64 JPEG) once and shows it full-width.
class _ActivityPhoto extends StatelessWidget {
  final String base64;
  const _ActivityPhoto({required this.base64});

  @override
  Widget build(BuildContext context) {
    Uint8List bytes;
    try {
      bytes = base64Decode(base64);
    } catch (_) {
      return const SizedBox.shrink();
    }
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: 360.h),
      child: Image.memory(
        bytes,
        width: double.infinity,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}

class _CheerButton extends StatelessWidget {
  final Activity activity;
  final FeedController controller;
  const _CheerButton({required this.activity, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cheered = activity.cheeredByMe(controller.myId);
    return GestureDetector(
      onTap: () => controller.toggleCheer(activity),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Text('🔥',
              style: TextStyle(
                  fontSize: 18.sp,
                  color: cheered ? null : Colors.grey.withOpacity(0.4))),
          SizedBox(width: 6.w),
          Text(
            activity.cheerCount == 0
                ? 'Cheer'
                : '${activity.cheerCount}',
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: cheered ? _kRed : _kMuted),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String url;
  final String name;
  final double size;
  const _Avatar({required this.url, required this.name, this.size = 42});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'U' : name.trim()[0].toUpperCase();
    final fallback = Container(
      width: size.r,
      height: size.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
            colors: [_kRed, _kRedDk],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
      ),
      child: Text(initial,
          style: AppFonts.spaceGrotesk.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: (size * 0.4).sp)),
    );
    if (url.trim().isEmpty) return fallback;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: size.r,
        height: size.r,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}
