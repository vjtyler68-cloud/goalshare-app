import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A small, live magnetic compass that sits in the Mission header (to the right
/// of the Start Day pill). Shows a whole compass rose — fixed N/E/S/W dial with
/// a tick ring — and a two-tone needle that swings to magnetic north:
/// the NORTH end is flame-red (with a soft glow), the SOUTH end is cool silver.
///
/// Heading comes from [FlutterCompass]. On hardware without a magnetometer
/// (e.g. the iOS simulator) the stream is null/empty, so the needle simply
/// rests pointing up and the dial still renders — it never blanks out.
class MissionCompass extends StatefulWidget {
  const MissionCompass({super.key, this.diameter});

  /// Logical diameter; defaults to a header-friendly 52.
  final double? diameter;

  @override
  State<MissionCompass> createState() => _MissionCompassState();
}

class _MissionCompassState extends State<MissionCompass> {
  double? _heading; // degrees, 0 = magnetic north, null while unknown
  StreamSubscription<CompassEvent>? _sub;

  @override
  void initState() {
    super.initState();
    // `events` is null on platforms without compass support.
    _sub = FlutterCompass.events?.listen((event) {
      if (!mounted) return;
      setState(() => _heading = event.heading);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = (widget.diameter ?? 52).w;
    final headingRad = ((_heading ?? 0) * (math.pi / 180));
    return SizedBox(
      width: d,
      height: d,
      child: CustomPaint(
        painter: _CompassPainter(
          headingRad: headingRad,
          live: _heading != null,
        ),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter({required this.headingRad, required this.live});

  /// Current heading in radians (0 = north). The needle rotates by -heading so
  /// its red end always points toward magnetic north as the phone turns.
  final double headingRad;

  /// Whether a real reading is driving the needle (dims slightly if not).
  final bool live;

  static const _north = Color(0xffFF4D3D);
  static const _northGlow = Color(0xffFF6B5E);
  static const _south = Color(0xffCBD5E1);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2;

    // ── Glass face ────────────────────────────────────────────────────────
    final face = Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.3, -0.4),
        colors: [Color(0xff2B3040), Color(0xff0E1118)],
        stops: [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, face);

    // Outer ring.
    canvas.drawCircle(
      center,
      r - 0.75,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withOpacity(0.22),
    );

    // ── Tick ring (every 30°; cardinals are longer/brighter) ─────────────────
    for (int i = 0; i < 12; i++) {
      final a = i * (math.pi / 6) - math.pi / 2; // start at top
      final cardinal = i % 3 == 0;
      final outer = r - 3;
      final inner = cardinal ? r - 8 : r - 6;
      final p1 = center + Offset(math.cos(a) * outer, math.sin(a) * outer);
      final p2 = center + Offset(math.cos(a) * inner, math.sin(a) * inner);
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..strokeWidth = cardinal ? 1.6 : 1.0
          ..color = Colors.white.withOpacity(cardinal ? 0.85 : 0.32),
      );
    }

    // ── Fixed cardinal letters ───────────────────────────────────────────────
    final letterR = r - 15;
    _drawLetter(canvas, center, 'N', -math.pi / 2, letterR, _northGlow, r,
        bold: true);
    _drawLetter(canvas, center, 'E', 0, letterR, Colors.white70, r);
    _drawLetter(canvas, center, 'S', math.pi / 2, letterR, Colors.white70, r);
    _drawLetter(canvas, center, 'W', math.pi, letterR, Colors.white70, r);

    // ── Swinging two-tone needle ─────────────────────────────────────────────
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-headingRad);

    final len = r * 0.66;
    final baseW = r * 0.16;
    final opacity = live ? 1.0 : 0.55;

    // Soft glow behind the north half.
    final northPath = Path()
      ..moveTo(0, -len)
      ..lineTo(-baseW, 0)
      ..lineTo(baseW, 0)
      ..close();
    canvas.drawPath(
      northPath,
      Paint()
        ..color = _northGlow.withOpacity(0.55 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(
      northPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_northGlow, _north],
        ).createShader(Rect.fromLTRB(-baseW, -len, baseW, 0))
        ..color = Colors.white.withOpacity(opacity),
    );

    // South half — cool silver.
    final southPath = Path()
      ..moveTo(0, len)
      ..lineTo(-baseW, 0)
      ..lineTo(baseW, 0)
      ..close();
    canvas.drawPath(
      southPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [_south, const Color(0xff8FA0B5)],
        ).createShader(Rect.fromLTRB(-baseW, 0, baseW, len))
        ..color = Colors.white.withOpacity(opacity),
    );
    canvas.restore();

    // ── Center hub ───────────────────────────────────────────────────────────
    canvas.drawCircle(center, r * 0.11 + 1.5, Paint()..color = Colors.white);
    canvas.drawCircle(
        center, r * 0.11, Paint()..color = const Color(0xff0E1118));
  }

  void _drawLetter(Canvas canvas, Offset center, String ch, double angle,
      double radius, Color color, double r,
      {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: ch,
        style: TextStyle(
          color: color,
          fontSize: r * 0.30,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final pos = center +
        Offset(math.cos(angle) * radius, math.sin(angle) * radius) -
        Offset(tp.width / 2, tp.height / 2);
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(_CompassPainter old) =>
      old.headingRad != headingRad || old.live != live;
}
