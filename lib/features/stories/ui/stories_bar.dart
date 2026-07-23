import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/const/app_fonts.dart';
import '../controller/stories_controller.dart';
import 'story_ring.dart';

/// Horizontal "stories" strip of your friends' active stories.
///
/// Your own story now lives on the Home-header avatar (Snapchat/IG style), so
/// this tray shows friends only — and collapses to zero height (no gap) when no
/// friend has a story, keeping the home layout tight.
class StoriesBar extends StatelessWidget {
  StoriesBar({super.key});

  final StoriesController c = StoriesController.to;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final others = c.otherGroups;
      if (!c.ready || others.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: EdgeInsets.only(top: 4.h, bottom: 18.h),
        child: SizedBox(
          height: 96.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            physics: const BouncingScrollPhysics(),
            children: [
              for (final g in others)
                _tile(
                  label: g.authorUsername.isNotEmpty
                      ? '@${g.authorUsername}'
                      : g.authorName,
                  child: StoryRing(
                    imageUrl: g.authorImage,
                    name: g.authorName,
                    hasStory: true,
                    seen: g.allViewedBy(c.myId),
                    onTap: () => c.openGroup(g),
                  ),
                  onTap: () => c.openGroup(g),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _tile({
    required String label,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 74.w,
        padding: EdgeInsets.symmetric(horizontal: 4.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            child,
            SizedBox(height: 6.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xff1A1010),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
