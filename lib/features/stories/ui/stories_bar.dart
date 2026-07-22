import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/const/app_fonts.dart';
import '../controller/stories_controller.dart';
import 'story_ring.dart';

/// Horizontal "stories" strip: your own ring first (with a + to post), then
/// every friend who has an active story. Hides itself entirely when Firebase
/// isn't available (stories are a shared feature).
class StoriesBar extends StatelessWidget {
  StoriesBar({super.key});

  final StoriesController c = Get.put(StoriesController(), permanent: true);

  @override
  Widget build(BuildContext context) {
    if (!c.ready) return const SizedBox.shrink();

    return Obx(() {
      final mine = c.myGroup.value;
      final others = c.otherGroups;

      return SizedBox(
        height: 96.h,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          physics: const BouncingScrollPhysics(),
          children: [
            // ── Your story ──────────────────────────────────────────────────
            _tile(
              label: 'Your story',
              child: StoryRing(
                imageUrl: mine?.authorImage ?? c.myImage,
                name: c.myName.isEmpty ? 'You' : c.myName,
                hasStory: mine != null,
                seen: false,
                showAddBadge: mine == null,
                onTap: c.openMine,
              ),
              onTap: c.openMine,
            ),
            // ── Everyone else ───────────────────────────────────────────────
            for (final g in others)
              _tile(
                label: g.authorName,
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
