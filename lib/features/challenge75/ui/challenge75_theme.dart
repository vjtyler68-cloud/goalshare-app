import 'package:flutter/material.dart';

/// Shared palette for the 75 Challenge screens — a clean, encouraging light
/// surface so the variant accent (red / orange / green / indigo) carries the
/// mood. Kept in one place so every tab reads identically.
class C75 {
  C75._();
  static const Color bg = Color(0xffF5F6FA);
  static const Color card = Colors.white;
  static const Color text = Color(0xff14181F);
  static const Color muted = Color(0xff8A93A6);
  static const Color line = Color(0xffEDEFF4);
  static const Color field = Color(0xffF2F3F8);
  static const Color good = Color(0xff22C55E);
  static const Color bad = Color(0xffEF4444);

  /// A tasteful two-stop gradient from [c] to a darker shade — used on the
  /// hero card, the progress ring and primary buttons.
  static LinearGradient grad(Color c) {
    final hsl = HSLColor.fromColor(c);
    final darker =
        hsl.withLightness((hsl.lightness * 0.78).clamp(0.0, 1.0)).toColor();
    return LinearGradient(
      colors: [c, darker],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

/// A rounded-cap arc progress ring — the premium look for the Today hero.
class C75RingPainter extends CustomPainter {
  final double pct; // 0..1
  final Color ringColor;
  final Color trackColor;
  final double stroke;
  const C75RingPainter({
    required this.pct,
    required this.ringColor,
    required this.trackColor,
    this.stroke = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - stroke) / 2;
    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, track);
    final ring = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    const start = -1.5707963267948966; // -90° (12 o'clock)
    final sweep = (pct.clamp(0.0, 1.0)) * 6.283185307179586;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      ring,
    );
  }

  @override
  bool shouldRepaint(C75RingPainter old) =>
      old.pct != pct ||
      old.ringColor != ringColor ||
      old.trackColor != trackColor ||
      old.stroke != stroke;
}
