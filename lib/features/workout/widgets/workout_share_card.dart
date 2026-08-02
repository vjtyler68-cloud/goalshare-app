import 'dart:io';
import 'dart:math' as math;
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
  // GPS trace for a run/walk, as (lng, lat) points. When 2+ points are given
  // the card draws the route Strava-style as its hero; otherwise the classic
  // centered layout is used (strength workouts / streaks have no route).
  List<Offset>? routePoints,
  // Optional absolute date shown on the card (e.g. "Aug 2, 2026").
  String? dateLabel,
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
      routePoints: routePoints,
      dateLabel: dateLabel,
    ),
    barrierDismissible: true,
  );
}

class _WorkoutShareDialog extends StatefulWidget {
  final GlobalKey boundaryKey;
  final String eyebrow, bigValue, bigLabel, subtitle, emoji;
  final bool isPr;
  final List<Offset>? routePoints;
  final String? dateLabel;

  const _WorkoutShareDialog({
    required this.boundaryKey,
    required this.eyebrow,
    required this.bigValue,
    required this.bigLabel,
    required this.subtitle,
    required this.emoji,
    required this.isPr,
    required this.routePoints,
    required this.dateLabel,
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
              routePoints: widget.routePoints,
              dateLabel: widget.dateLabel,
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

  /// (lng, lat) GPS trace. 2+ points → the route becomes the card's hero.
  final List<Offset>? routePoints;

  /// Optional absolute date (e.g. "Aug 2, 2026") shown beside the eyebrow.
  final String? dateLabel;

  const WorkoutShareCard({
    super.key,
    required this.eyebrow,
    required this.bigValue,
    required this.bigLabel,
    required this.subtitle,
    this.emoji = '🔥',
    this.isPr = false,
    this.routePoints,
    this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isPr ? WT.volt : WT.flame;
    final hasRoute = routePoints != null && routePoints!.length >= 2;
    return Container(
      width: 320,
      height: 400,
      decoration: BoxDecoration(
        color: WT.bg,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: accent.withOpacity(0.35), width: 1.5),
      ),
      child: hasRoute ? _routeLayout(accent) : _classicLayout(accent),
    );
  }

  /// Run/walk card: the recorded route is the hero, stats sit beneath it.
  Widget _routeLayout(Color accent) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerBadges(),
          const SizedBox(height: 14),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                decoration: BoxDecoration(
                  color: WT.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: accent.withOpacity(0.30)),
                ),
                child: CustomPaint(
                  painter: _RouteTracePainter(routePoints!, accent),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _statsBlock(accent),
          const SizedBox(height: 12),
          _footer(),
        ],
      ),
    );
  }

  /// Original centered layout — strength workouts / streaks with no GPS route.
  Widget _classicLayout(Color accent) {
    return Stack(
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
              _headerBadges(),
              const Spacer(),
              _statsBlock(accent),
              const Spacer(),
              _footer(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerBadges() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
    );
  }

  Widget _statsBlock(Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(eyebrow.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: accent,
                  )),
            ),
            if (dateLabel != null && dateLabel!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(dateLabel!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.6),
                    )),
              ),
          ],
        ),
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
                    fontSize: 65,
                    height: 1.0,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  )),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
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
      ],
    );
  }

  Widget _footer() {
    return Row(
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
    );
  }
}

/// Draws a run/walk GPS trace Strava-style: the polyline fitted into the panel
/// with its true proportions, a soft glow, and start (mint) / finish (flame)
/// dots. Pure Canvas — no map tiles — so it rasterises instantly and never
/// captures a half-loaded map when the card is turned into a PNG.
class _RouteTracePainter extends CustomPainter {
  final List<Offset> pts; // (lng, lat)
  final Color color;

  const _RouteTracePainter(this.pts, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (pts.length < 2 || size.isEmpty) return;

    // Local equirectangular projection: longitude degrees are squeezed by
    // cos(latitude) so the shape isn't stretched sideways.
    final meanLat = pts.map((p) => p.dy).reduce((a, b) => a + b) / pts.length;
    final cosLat = math.cos(meanLat * math.pi / 180.0);
    final proj = [for (final p in pts) Offset(p.dx * cosLat, p.dy)];

    var minX = proj.first.dx, maxX = proj.first.dx;
    var minY = proj.first.dy, maxY = proj.first.dy;
    for (final p in proj) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }
    final spanX = maxX - minX;
    final spanY = maxY - minY;

    const pad = 20.0;
    final availW = math.max(1.0, size.width - pad * 2);
    final availH = math.max(1.0, size.height - pad * 2);
    // Fit preserving aspect ratio; guard a dead-straight run (one span is 0).
    final sx = spanX > 0 ? availW / spanX : double.infinity;
    final sy = spanY > 0 ? availH / spanY : double.infinity;
    var scale = math.min(sx, sy);
    if (!scale.isFinite) scale = math.min(availW, availH);

    final drawnW = spanX * scale;
    final drawnH = spanY * scale;
    final dx = pad + (availW - drawnW) / 2;
    final dy = pad + (availH - drawnH) / 2;

    Offset project(Offset p) => Offset(
          dx + (p.dx - minX) * scale,
          dy + (maxY - p.dy) * scale, // flip Y so north points up
        );

    final path = Path();
    final first = project(proj.first);
    path.moveTo(first.dx, first.dy);
    for (var i = 1; i < proj.length; i++) {
      final m = project(proj[i]);
      path.lineTo(m.dx, m.dy);
    }

    // Soft glow underlay.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color.withOpacity(0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // Crisp route line.
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );

    // Start (mint) & finish (flame) markers — always distinct colours.
    _dot(canvas, project(proj.first), WT.volt);
    _dot(canvas, project(proj.last), color == WT.volt ? WT.flame : color);
  }

  void _dot(Canvas canvas, Offset c, Color fill) {
    canvas.drawCircle(c, 6.5, Paint()..color = Colors.white);
    canvas.drawCircle(c, 4.5, Paint()..color = fill);
  }

  @override
  bool shouldRepaint(covariant _RouteTracePainter old) =>
      old.pts != pts || old.color != color;
}
