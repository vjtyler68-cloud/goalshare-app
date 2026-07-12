import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../const/app_fonts.dart';
import '../global_widgets/app_snackbar.dart';

/// The share-loop: a branded, story-ready streak card the user can post with
/// one tap (Duolingo/Strava-style). Every share is free acquisition — the card
/// carries the GoalShare brand + site.
///
/// Usage: `showStreakShareDialog(streak: 12, best: 20);`
Future<void> showStreakShareDialog({
  required int streak,
  required int best,
  String ritualName = 'Morning Priming',
}) async {
  final boundaryKey = GlobalKey();
  await Get.dialog(
    _StreakShareDialog(
      boundaryKey: boundaryKey,
      streak: streak,
      best: best,
      ritualName: ritualName,
    ),
    barrierDismissible: true,
  );
}

class _StreakShareDialog extends StatefulWidget {
  final GlobalKey boundaryKey;
  final int streak;
  final int best;
  final String ritualName;

  const _StreakShareDialog({
    required this.boundaryKey,
    required this.streak,
    required this.best,
    required this.ritualName,
  });

  @override
  State<_StreakShareDialog> createState() => _StreakShareDialogState();
}

class _StreakShareDialogState extends State<_StreakShareDialog> {
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      // Rasterise the card at 3x for a crisp ~1080px-wide social image.
      final boundary = widget.boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('card not ready');
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('encode failed');

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/goalshare_streak_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text:
            '🔥 ${widget.streak} days of ${widget.ritualName.toLowerCase()} on GoalShare. Build your future daily → goalsharewin.com',
      ));
    } catch (_) {
      AppSnackBar.error('Could not share right now. Please try again.');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            key: widget.boundaryKey,
            child: StreakShareCard(
              streak: widget.streak,
              best: widget.best,
              ritualName: widget.ritualName,
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pillButton(
                label: 'Close',
                filled: false,
                onTap: Get.back,
              ),
              SizedBox(width: 10.w),
              _pillButton(
                label: _sharing ? 'Sharing…' : 'Share  🔥',
                filled: true,
                onTap: _share,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pillButton({
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 26.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: Colors.white.withOpacity(0.6)),
        ),
        child: Text(
          label,
          style: AppFonts.spaceGrotesk.copyWith(
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            color: filled ? const Color(0xff9B1414) : Colors.white,
          ),
        ),
      ),
    );
  }
}

/// The visual card itself — fixed logical size so the 3x capture lands at a
/// crisp social-friendly resolution (~960x1200, 4:5).
class StreakShareCard extends StatelessWidget {
  final int streak;
  final int best;
  final String ritualName;

  const StreakShareCard({
    super.key,
    required this.streak,
    required this.best,
    this.ritualName = 'Morning Priming',
  });

  @override
  Widget build(BuildContext context) {
    final isRecord = streak >= best && streak > 1;
    return Container(
      width: 320,
      height: 400,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xffE84040), Color(0xff9B1414)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Oversized watermark flame for depth.
          Positioned(
            right: -30,
            bottom: -20,
            child: Text(
              '🔥',
              style: TextStyle(
                fontSize: 160,
                color: Colors.white.withOpacity(0.10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'GOALSHARE',
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                Text('🔥', style: const TextStyle(fontSize: 44)),
                const SizedBox(height: 4),
                Text(
                  '$streak',
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 88,
                    height: 1.0,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  streak == 1 ? 'DAY STREAK' : 'DAYS IN A ROW',
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isRecord
                      ? '$ritualName · Personal best 🏆'
                      : '$ritualName · Best: $best days',
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      'Build your future daily',
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'goalsharewin.com',
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
