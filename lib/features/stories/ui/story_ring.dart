import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/const/app_fonts.dart';

/// A circular avatar wrapped in an Instagram-style story ring.
///
/// * [hasStory] false → plain avatar, no ring.
/// * [hasStory] true + [seen] false → colourful gradient ring (unseen).
/// * [hasStory] true + [seen] true  → soft grey ring (already viewed).
/// * [showAddBadge] → a small "+" badge (used for "Your story").
class StoryRing extends StatelessWidget {
  final String imageUrl;
  final String name;
  final double size;
  final bool hasStory;
  final bool seen;
  final bool showAddBadge;
  final VoidCallback? onTap;

  const StoryRing({
    super.key,
    required this.imageUrl,
    required this.name,
    this.size = 62,
    this.hasStory = false,
    this.seen = false,
    this.showAddBadge = false,
    this.onTap,
  });

  String get _initial {
    final t = name.trim();
    return t.isEmpty ? 'U' : t[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final ringThickness = hasStory ? 3.0 : 0.0;
    final gap = hasStory ? 2.5 : 0.0;
    final avatarSize = size - (ringThickness + gap) * 2;

    final gradient = seen
        ? null
        : LinearGradient(
            colors: [
              AppColors.primaryColor,
              const Color(0xffFF8A34),
              const Color(0xffFFC24B),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Ring
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: gradient,
                color: hasStory && seen ? const Color(0xffD9D2CE) : null,
              ),
              padding: EdgeInsets.all(ringThickness),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                padding: EdgeInsets.all(gap),
                child: _avatar(avatarSize),
              ),
            ),
            if (showAddBadge)
              Positioned(
                bottom: -1,
                right: -1,
                child: Container(
                  width: 20.r,
                  height: 20.r,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(Icons.add, color: Colors.white, size: 12.r),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(double d) {
    final fallback = Container(
      width: d,
      height: d,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.primaryColor, AppColors.primaryDarkColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(
        _initial,
        style: AppFonts.spaceGrotesk.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: d * 0.4,
        ),
      ),
    );

    if (imageUrl.trim().isEmpty) return fallback;

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: d,
        height: d,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}
