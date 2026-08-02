import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/global_widgets/app_snackbar.dart';
import '../data/workout_theme.dart';

/// Goalshare: a one-tap, story-ready progress card. Rasterised at 3x → PNG →
/// system share sheet — identical mechanism to the app's streak_share_card, so
/// it drops into the existing share-loop (every share carries the brand).
Future<void> showWorkoutShareDialog({
  required String eyebrow,
  required String bigValue,
  required String bigLabel,
  required String subtitle,
  String emoji = '🔥',
  bool isPr = false,
}) async {
  final boundaryKey = GlobalKey();
  await Get.dialog(
    _WorkoutShareDialog(
      boundaryKey: boundaryKey,
      eyebrow: eyebrow,
      bigValue: bigValue,
      bigLabel: bigLabel,
      subtitle: subtitle,
      emoji: emoji,
      isPr: isPr,
    ),
    barrierDismissible: true,
  );
}

class _WorkoutShareDialog extends StatefulWidget {
  final GlobalKey boundaryKey;
  final String eyebrow, bigValue, bigLabel, subtitle, emoji;
  final bool isPr;

  const _WorkoutShareDialog({
    required this.boundaryKey,
    required this.eyebrow,
    required this.bigValue,
    required this.bigLabel,
    required this.subtitle,
    required this.emoji,
    required this.isPr,
  });

  @override
  State<_WorkoutShareDialog> createState() => _WorkoutShareDialogState();
}

class _WorkoutShareDialogState extends State<_WorkoutShareDialog> {
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary = widget.boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('card not ready');
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('encode failed');

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/goalshare_workout_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      // Single-image share with NO bundled text. On iOS, files+text is a
      // MULTI-ITEM share, and Snapchat + TikTok's share extensions only accept a
      // lone image — with text attached they drop out of the share sheet (or
      // fail), which is exactly why Instagram worked and they didn't. The card
      // itself already carries the brand + goalsharewin.com, so nothing is lost.
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
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
            child: WorkoutShareCard(
              eyebrow: widget.eyebrow,
              bigValue: widget.bigValue,
              bigLabel: widget.bigLabel,
              subtitle: widget.subtitle,
              emoji: widget.emoji,
              isPr: widget.isPr,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _pill('Close', false, Get.back),
              SizedBox(width: 12.w),
              _pill(_sharing ? 'Sharing…' : 'Share  🚀', true, _share),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, bool filled, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 13.h),
        decoration: BoxDecoration(
          gradient: filled ? WT.flameGrad : null,
          color: filled ? null : Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(26.r),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// The visual card — fixed logical size for a crisp ~960×1200 (4:5) social image.
class WorkoutShareCard extends StatelessWidget {
  final String eyebrow, bigValue, bigLabel, subtitle, emoji;
  final bool isPr;

  const WorkoutShareCard({
    super.key,
    required this.eyebrow,
    required this.bigValue,
    required this.bigLabel,
    required this.subtitle,
    this.emoji = '🔥',
    this.isPr = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isPr ? WT.volt : WT.flame;
    return Container(
      width: 320,
      height: 400,
      decoration: BoxDecoration(
        color: WT.bg,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: accent.withOpacity(0.35), width: 1.5),
      ),
      child: Stack(
        children: [
          // Glow
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accent.withOpacity(0.35), accent.withOpacity(0.0)],
                ),
              ),
            ),
          ),
          Positioned(
            right: -24,
            bottom: -24,
            child: Text(emoji,
                style: TextStyle(
                    fontSize: 170, color: Colors.white.withOpacity(0.06))),
          ),
          Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('MY WORKOUT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Colors.white,
                          )),
                    ),
                    const Spacer(),
                    if (isPr)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: WT.voltGrad,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('NEW PR 🏆',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              color: Colors.black,
                            )),
                      ),
                  ],
                ),
                const Spacer(),
                Text(eyebrow.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: accent,
                    )),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(bigValue,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 82,
                            height: 1.0,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          )),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(bigLabel,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withOpacity(0.85),
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.75),
                    )),
                const Spacer(),
                Row(
                  children: [
                    Text('Build your future daily',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.white.withOpacity(0.7),
                        )),
                    const Spacer(),
                    const Text('goalsharewin.com',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        )),
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
