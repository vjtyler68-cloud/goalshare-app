import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';

/// A live magnetic compass rose — a fixed N/E/S/W dial with a tick ring and a
/// two-tone needle whose flame-red end tracks north as the phone turns.
///
/// **Works fully offline.** The heading comes from the device MAGNETOMETER via
/// [FlutterCompass] — a hardware sensor that needs no cell signal, Wi-Fi, or
/// data. It keeps working in a dead zone, a basement, the middle of a field,
/// anywhere. (On iOS the OS reports TRUE north when location is available and
/// magnetic north otherwise; on Android it's magnetic north.)
///
/// For accuracy the raw sensor stream — which is jittery — is run through a
/// circular low-pass filter and the needle is animated along the shortest path,
/// so it glides instead of twitching. A calibration cue appears when the sensor
/// reports low confidence (do a figure-8 to recalibrate). On hardware without a
/// magnetometer the dial still renders with the needle resting up.
class MissionCompass extends StatefulWidget {
  const MissionCompass({
    super.key,
    this.diameter,
    this.showReadout = false,
    this.ensureLocation = false,
  });

  /// Logical diameter; defaults to a header-friendly 52.
  final double? diameter;

  /// Show a live "312° NW" heading readout under the dial.
  final bool showReadout;

  /// Best-effort request location permission on mount. iOS needs location
  /// authorization to emit a heading, so field surfaces (the territory map)
  /// set this true; decorative placements leave it false.
  final bool ensureLocation;

  @override
  State<MissionCompass> createState() => _MissionCompassState();
}

class _MissionCompassState extends State<MissionCompass>
    with WidgetsBindingObserver {
  StreamSubscription<CompassEvent>? _sub;

  bool _has = false; // have we received a real reading yet?
  double _lastRaw = 0; // last raw heading, 0..360
  double _continuous = 0; // unwrapped heading (can exceed 360 / go negative)
  double _smoothed = 0; // low-pass-filtered continuous heading (degrees)
  double? _accuracy; // sensor confidence in radians (bigger = worse); null = unknown

  // How hard we smooth. Higher = snappier but jumpier; lower = calmer.
  static const double _alpha = 0.25;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.ensureLocation) _ensureLocationPermission();
    _subscribe();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The OS can pause the sensor stream in the background — re-subscribe on
    // resume so the compass always comes back to life.
    if (state == AppLifecycleState.resumed) _subscribe();
  }

  Future<void> _ensureLocationPermission() async {
    try {
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
    } catch (_) {
      // Best-effort only — the magnetometer still drives the dial regardless.
    }
  }

  void _subscribe() {
    _sub?.cancel();
    // `events` is null on platforms/devices without compass support.
    _sub = FlutterCompass.events?.listen(_onEvent);
  }

  void _onEvent(CompassEvent event) {
    if (!mounted) return;
    final h = event.heading;
    if (h == null || h.isNaN) return; // transient bad sample — keep last good
    final raw = ((h % 360) + 360) % 360;

    if (!_has) {
      _has = true;
      _lastRaw = raw;
      _continuous = raw;
      _smoothed = raw;
    } else {
      // Unwrap: take the shortest angular step so 359°→1° is +2°, not −358°.
      var delta = raw - _lastRaw;
      if (delta > 180) delta -= 360;
      if (delta < -180) delta += 360;
      _lastRaw = raw;
      _continuous += delta;
      // Circular low-pass toward the continuous target.
      _smoothed += _alpha * (_continuous - _smoothed);
    }
    setState(() => _accuracy = event.accuracy);
  }

  /// Sensor says its reading is unreliable → suggest a recalibration figure-8.
  /// Only trust a positive accuracy value; null / negative means "unknown", so
  /// we don't nag (iOS frequently reports unknown even when it's fine).
  bool get _needsCalibration =>
      _accuracy != null && _accuracy! > 0.5; // ~29°+ of uncertainty

  int get _degrees => (((_smoothed % 360) + 360) % 360).round() % 360;

  String get _cardinal {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return dirs[(((_degrees + 22.5) % 360) ~/ 45)];
  }

  @override
  Widget build(BuildContext context) {
    final d = (widget.diameter ?? 52).w;
    final dial = TweenAnimationBuilder<double>(
      tween: Tween<double>(end: _smoothed),
      duration: const Duration(milliseconds: 90),
      curve: Curves.linear,
      builder: (_, value, __) => SizedBox(
        width: d,
        height: d,
        child: CustomPaint(
          painter: _CompassPainter(
            headingRad: value * (math.pi / 180),
            live: _has,
            needsCalibration: _needsCalibration,
          ),
        ),
      ),
    );

    if (!widget.showReadout) return dial;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        dial,
        SizedBox(height: 2.h),
        Text(
          !_has
              ? 'Compass'
              : _needsCalibration
                  ? 'Calibrate'
                  : '$_degrees° $_cardinal',
          style: TextStyle(
            fontSize: 8.5.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            color: _needsCalibration
                ? const Color(0xffF59E0B)
                : const Color(0xff6B7280),
          ),
        ),
      ],
    );
  }
}

class _CompassPainter extends CustomPainter {
  _CompassPainter({
    required this.headingRad,
    required this.live,
    this.needsCalibration = false,
  });

  /// Current heading in radians (0 = north). The rose rotates by -heading so
  /// its red north end always points at magnetic/true north as the phone turns.
  final double headingRad;

  /// Whether a real reading is driving the needle (dims slightly if not).
  final bool live;

  /// Sensor is low-confidence — draw an amber ring cueing a figure-8 recal.
  final bool needsCalibration;

  static const _north = Color(0xffFF4D3D);
  static const _northGlow = Color(0xffFF6B5E);
  static const _south = Color(0xffCBD5E1);
  static const _amber = Color(0xffF59E0B);

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

    // Outer ring — amber + a soft glow when the sensor wants recalibrating.
    canvas.drawCircle(
      center,
      r - 0.75,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = needsCalibration ? 2.0 : 1.5
        ..color = needsCalibration
            ? _amber.withOpacity(0.9)
            : Colors.white.withOpacity(0.22),
    );
    if (needsCalibration) {
      canvas.drawCircle(
        center,
        r - 0.75,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..color = _amber.withOpacity(0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    // ── Fixed heading marker at the very top ─────────────────────────────────
    // Stays put while the dial spins beneath it — it points at the part of the
    // rose you're currently facing (Apple-compass style).
    canvas.drawPath(
      Path()
        ..moveTo(center.dx, 10)
        ..lineTo(center.dx - 5, 1)
        ..lineTo(center.dx + 5, 1)
        ..close(),
      Paint()..color = _north,
    );

    // ── Rotating rose: ticks + N/E/S/W letters + needle all turn together, so
    // N always points to north as you spin the phone. ────────────────────────
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-headingRad);

    // Tick ring (every 30°; cardinals longer/brighter).
    for (int i = 0; i < 12; i++) {
      final a = i * (math.pi / 6) - math.pi / 2; // start at top
      final cardinal = i % 3 == 0;
      final outer = r - 3;
      final inner = cardinal ? r - 8 : r - 6;
      canvas.drawLine(
        Offset(math.cos(a) * outer, math.sin(a) * outer),
        Offset(math.cos(a) * inner, math.sin(a) * inner),
        Paint()
          ..strokeWidth = cardinal ? 1.6 : 1.0
          ..color = Colors.white.withOpacity(cardinal ? 0.85 : 0.32),
      );
    }

    // Cardinal letters — revolve with the dial but stay upright (counter-rotated).
    final letterR = r - 15;
    _drawLetter(canvas, Offset.zero, 'N', -math.pi / 2, letterR, _northGlow, r,
        bold: true, uprightBy: headingRad);
    _drawLetter(canvas, Offset.zero, 'E', 0, letterR, Colors.white70, r,
        uprightBy: headingRad);
    _drawLetter(canvas, Offset.zero, 'S', math.pi / 2, letterR, Colors.white70, r,
        uprightBy: headingRad);
    _drawLetter(canvas, Offset.zero, 'W', math.pi, letterR, Colors.white70, r,
        uprightBy: headingRad);

    // ── Two-tone needle (turns with the rose; red end tracks north) ──────────
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
      {bool bold = false, double uprightBy = 0}) {
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
    final pos =
        center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
    // Position on the ring, then counter-rotate so the glyph stays upright
    // even though the whole rose is spinning.
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    if (uprightBy != 0) canvas.rotate(uprightBy);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CompassPainter old) =>
      old.headingRad != headingRad ||
      old.live != live ||
      old.needsCalibration != needsCalibration;
}
