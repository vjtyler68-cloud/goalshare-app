import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/health/health_service.dart';
import '../controller/cardio_controller.dart';
import '../controller/workout_controller.dart';
import '../data/cardio_run.dart';
import '../data/workout_theme.dart';
import '../widgets/workout_share_card.dart';

/// Strava-style live run/walk tracker. All tracking state lives in
/// [CardioController], so this screen is just a viewport — leaving it (or
/// backgrounding the app) does NOT stop the run. Finishing drops straight into
/// the route summary.
class CardioTrackingScreen extends StatefulWidget {
  final String kind; // 'run' | 'walk'
  const CardioTrackingScreen({super.key, required this.kind});

  @override
  State<CardioTrackingScreen> createState() => _CardioTrackingScreenState();
}

class _CardioTrackingScreenState extends State<CardioTrackingScreen> {
  final MapController _map = MapController();
  CardioController get c => CardioController.to;
  Worker? _posWorker;

  static const LatLng _fallback = LatLng(39.8283, -98.5795);

  @override
  void initState() {
    super.initState();
    // We ARE the tracker now — tell the global mini-bar to stand down.
    c.viewing.value = true;
    if (!c.tracking.value) {
      c.kind.value = widget.kind;
      c.prepare().then((_) => _center());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _center());
    }
    // Follow the runner as fresh fixes arrive.
    _posWorker = ever<LatLng?>(c.current, (ll) {
      if (ll != null && c.tracking.value && !c.paused.value && mounted) {
        try {
          _map.move(ll, _map.camera.zoom);
        } catch (_) {}
      }
    });
  }

  void _center() {
    final cur = c.current.value;
    if (cur != null && mounted) {
      try {
        _map.move(cur, 16.5);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _posWorker?.dispose();
    // Left the tracker — the global mini-bar takes over so the run stays
    // visible (and one tap away) on every other screen.
    c.viewing.value = false;
    // Intentionally does NOT stop tracking — CardioController keeps the run
    // alive so the user can use the rest of the app and return via the banner.
    super.dispose();
  }

  bool get _miles => WorkoutController.to.useMiles;

  String _distStr() {
    final v = _miles
        ? c.distanceMeters.value / 1609.34
        : c.distanceMeters.value / 1000.0;
    return v.toStringAsFixed(2);
  }

  String _paceStr() {
    final dist = c.distanceMeters.value;
    if (dist <= 0) return '--:--';
    final sec = c.elapsedSec.value / (_miles ? dist / 1609.34 : dist / 1000.0);
    return formatPace(sec);
  }

  Future<void> _finish() async {
    final run = await c.finish();
    if (!mounted) return;
    if (run == null) {
      Get.back();
      return;
    }
    // Straight into the Strava-style summary: route map + distance/time/pace.
    Get.off(() => RunRouteViewer(run: run));
  }

  void _confirmExit() {
    if (!c.tracking.value) {
      Get.back();
      return;
    }
    Get.dialog(Dialog(
      backgroundColor: WT.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.all(22.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Leave this ${c.kind.value}?',
                style: TextStyle(
                    color: WT.textHi,
                    fontWeight: FontWeight.w900,
                    fontSize: 18.sp)),
            SizedBox(height: 6.h),
            Text(
                'It keeps tracking in the background — jump back in from the '
                'banner on My Workout.',
                textAlign: TextAlign.center,
                style: TextStyle(color: WT.textMid, fontSize: 13.sp)),
            SizedBox(height: 20.h),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Get.back();
                    Get.back();
                  },
                  child: Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(vertical: 13.h),
                    decoration: BoxDecoration(
                        gradient: WT.voltGrad,
                        borderRadius: BorderRadius.circular(14.r)),
                    child: Text('Keep tracking',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.sp)),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    c.discard();
                    Get.back();
                    Get.back();
                  },
                  child: Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(vertical: 13.h),
                    decoration: BoxDecoration(
                        color: WT.surfaceHi,
                        borderRadius: BorderRadius.circular(14.r)),
                    child: Text('Discard',
                        style: TextStyle(
                            color: WT.danger,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.sp)),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WT.bg,
      body: Stack(
        children: [
          // MAP — rebuilds only when the route / current position changes.
          Obx(() {
            final pts = c.route.toList();
            final cur = c.current.value;
            return FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: cur ?? _fallback,
                initialZoom: cur == null ? 3.5 : 16.5,
                backgroundColor: WT.bg,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                  // If the primary dark tiles fail to load on-device, fall back
                  // to standard OSM tiles so the user NEVER stares at a blank map.
                  fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.goal.share',
                ),
                if (pts.length >= 2)
                  PolylineLayer(polylines: [
                    Polyline(points: pts, strokeWidth: 6, color: WT.flame),
                  ]),
                if (cur != null)
                  MarkerLayer(markers: [
                    Marker(
                      point: cur,
                      width: 26,
                      height: 26,
                      child: Container(
                        decoration: BoxDecoration(
                          color: WT.flame,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                                color: WT.flame.withOpacity(0.5), blurRadius: 8)
                          ],
                        ),
                      ),
                    ),
                  ]),
              ],
            );
          }),
          // TOP — close button + live stats. Uses the REAL top inset PLUS 12pt
          // of breathing room, with a hard 74pt floor: the Dynamic Island /
          // status bar is ~59pt tall, so a bare 60pt floor rendered the stats
          // pressed right up against the clock ("stuck at the top"). The floor
          // also covers the safe-area inset coming through as 0 under this
          // app's custom-engine setup.
          Padding(
            padding: EdgeInsets.only(
                top: math.max(
                    MediaQuery.viewPaddingOf(context).top + 12.0, 74.0)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0),
                  child: Row(
                    children: [
                      _roundBtn(Icons.close_rounded, _confirmExit),
                      const Spacer(),
                      Obx(() => Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: WT.surface.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                                '${c.emoji} ${c.label}${c.paused.value ? ' · paused' : ''}',
                                style: TextStyle(
                                    color: WT.textHi,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.sp)),
                          )),
                      const Spacer(),
                      SizedBox(width: 44.w),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 12.w),
                  padding:
                      EdgeInsets.symmetric(vertical: 14.h, horizontal: 6.w),
                  decoration: BoxDecoration(
                    color: WT.surface.withOpacity(0.94),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: WT.stroke),
                  ),
                  child: Obx(() => Row(
                        children: [
                          _bigStat(
                              _distStr(), _miles ? 'miles' : 'km', WT.flame),
                          _bigStat(formatDuration(c.elapsedSec.value), 'time',
                              WT.textHi),
                          _bigStat(
                              _paceStr(), _miles ? '/mi' : '/km', WT.volt),
                        ],
                      )),
                ),
                SizedBox(height: 4.h),
                // Visible build tag so it's provable WHICH app version is
                // rendering this screen (repeated "old build vs new build"
                // confusion). Bump alongside pubspec version.
                Text('build 258',
                    style: TextStyle(color: WT.textLow, fontSize: 9.sp)),
              ],
            ),
          ),
          // BOTTOM — status + controls, clear of the home indicator.
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: WT.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                border: Border(top: BorderSide(color: WT.stroke)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 14.h),
                  child: Obx(() {
                    final tracking = c.tracking.value;
                    final status = c.status.value;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (status.isNotEmpty && !tracking)
                          Padding(
                            padding: EdgeInsets.only(bottom: 12.h),
                            child: Text(status,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: WT.amber, fontSize: 12.5.sp)),
                          ),
                        _controls(tracking, c.paused.value),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls(bool tracking, bool paused) {
    if (!tracking) {
      return GestureDetector(
        onTap: () => c.start(widget.kind).then((_) => _center()),
        child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: 17.h),
          decoration: BoxDecoration(
            gradient: WT.flameGrad,
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Text('START ${widget.kind == 'walk' ? 'WALK' : 'RUN'}',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16.sp,
                  letterSpacing: 1)),
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => paused ? c.resume() : c.pause(),
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(vertical: 15.h),
              decoration: BoxDecoration(
                color: WT.surfaceHi,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(paused ? 'RESUME' : 'PAUSE',
                  style: TextStyle(
                      color: WT.textHi,
                      fontWeight: FontWeight.w900,
                      fontSize: 15.sp)),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: GestureDetector(
            onTap: _finish,
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(vertical: 15.h),
              decoration: BoxDecoration(
                gradient: WT.voltGrad,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text('FINISH',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 15.sp)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bigStat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              maxLines: 1,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 26.sp,
                  fontFeatures: const [FontFeature.tabularFigures()])),
          SizedBox(height: 2.h),
          Text(label, style: TextStyle(color: WT.textMid, fontSize: 11.sp)),
        ],
      ),
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: WT.bg.withOpacity(0.85),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: WT.textHi, size: 24.sp),
        ),
      );
}

/// The post-run summary AND the replay of any saved run: the full route drawn
/// on the map with distance / time / pace — Strava-style.
class RunRouteViewer extends StatefulWidget {
  final CardioRun run;
  const RunRouteViewer({super.key, required this.run});

  @override
  State<RunRouteViewer> createState() => _RunRouteViewerState();
}

class _RunRouteViewerState extends State<RunRouteViewer> {
  final MapController _map = MapController();
  CardioRun get run => widget.run;

  // Real steps + active-energy calories pulled from Apple Health for this run's
  // window (null until loaded / when HealthKit is off — estimates show first).
  int? _hkSteps;
  int? _hkCalories;

  @override
  void initState() {
    super.initState();
    _loadHealthMetrics();
  }

  Future<void> _loadHealthMetrics() async {
    final end = DateTime.fromMillisecondsSinceEpoch(
        run.endedAtMs ?? DateTime.now().millisecondsSinceEpoch);
    final res =
        await HealthService.instance.readActivityForWindow(run.startedAt, end);
    if (res != null && mounted) {
      setState(() {
        if (res.steps > 0) _hkSteps = res.steps;
        if (res.calories > 0) _hkCalories = res.calories;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pts = run.points.map((p) => LatLng(p.lat, p.lng)).toList();
    final miles = WorkoutController.to.useMiles;
    final distStr = '${(miles ? run.miles : run.km).toStringAsFixed(2)} '
        '${miles ? 'mi' : 'km'}';
    final paceStr =
        '${formatPace(miles ? run.paceSecPerMile : run.paceSecPerKm)} '
        '${miles ? '/mi' : '/km'}';
    final speedStr =
        '${(miles ? run.avgSpeedMph : run.avgSpeedKmh).toStringAsFixed(1)} '
        '${miles ? 'mph' : 'km/h'}';
    final steps = NumberFormat.decimalPattern()
        .format(_hkSteps ?? run.estimatedSteps);
    final calories = _hkCalories ?? run.estimatedCalories;
    final mapH = MediaQuery.sizeOf(context).height * 0.44;

    return Scaffold(
      backgroundColor: WT.bg,
      body: Column(
        children: [
          // ── ROUTE MAP ────────────────────────────────────────────────────
          SizedBox(
            height: mapH,
            child: Stack(
              children: [
                Positioned.fill(
                  child: FlutterMap(
                    mapController: _map,
                    options: MapOptions(
                      initialCenter: pts.isNotEmpty
                          ? pts.first
                          : const LatLng(39.8283, -98.5795),
                      initialZoom: pts.isEmpty ? 3.5 : 14,
                      backgroundColor: WT.bg,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                      ),
                      onMapReady: () {
                        if (pts.length >= 2) {
                          _map.fitCamera(CameraFit.bounds(
                            bounds: LatLngBounds.fromPoints(pts),
                            padding: const EdgeInsets.all(50),
                          ));
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                        fallbackUrl:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.goal.share',
                      ),
                      if (pts.length >= 2)
                        PolylineLayer(polylines: [
                          Polyline(
                              points: pts, strokeWidth: 6, color: WT.flame),
                        ]),
                      if (pts.isNotEmpty)
                        MarkerLayer(markers: [
                          Marker(
                              point: pts.first,
                              width: 22,
                              height: 22,
                              child: _pin(WT.volt)),
                          if (pts.length >= 2)
                            Marker(
                                point: pts.last,
                                width: 22,
                                height: 22,
                                child: _pin(WT.flame)),
                        ]),
                    ],
                  ),
                ),
                if (pts.length < 2)
                  Center(
                    child: Text('No route was recorded for this one.',
                        style: TextStyle(color: WT.textMid, fontSize: 13.sp)),
                  ),
                Positioned(
                  top: math.max(MediaQuery.viewPaddingOf(context).top, 44.0),
                  left: 12.w,
                  child: GestureDetector(
                    onTap: Get.back,
                    child: Container(
                      width: 42.w,
                      height: 42.w,
                      decoration: BoxDecoration(
                        color: WT.bg.withOpacity(0.9),
                        shape: BoxShape.circle,
                        border: Border.all(color: WT.stroke),
                      ),
                      child: Icon(Icons.chevron_left,
                          color: WT.textHi, size: 26.sp),
                    ),
                  ),
                ),
                // Share this run as a story-ready card (Snapchat/TikTok/IG/…).
                Positioned(
                  top: math.max(MediaQuery.viewPaddingOf(context).top, 44.0),
                  right: 12.w,
                  child: GestureDetector(
                    onTap: _shareRun,
                    child: Container(
                      width: 42.w,
                      height: 42.w,
                      decoration: BoxDecoration(
                        color: WT.bg.withOpacity(0.9),
                        shape: BoxShape.circle,
                        border: Border.all(color: WT.stroke),
                      ),
                      child: Icon(Icons.ios_share,
                          color: WT.textHi, size: 20.sp),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── ACTIVITY SUMMARY ─────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(22.w, 20.h, 22.w, 30.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${run.emoji}  ${run.timeOfDayTitle}',
                      style: TextStyle(
                          color: WT.textHi,
                          fontWeight: FontWeight.w900,
                          fontSize: 26.sp)),
                  SizedBox(height: 6.h),
                  Text(_whenStr(),
                      style: TextStyle(color: WT.textMid, fontSize: 13.5.sp)),
                  if (_isLongest) ...[
                    SizedBox(height: 14.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: WT.volt.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: WT.volt.withOpacity(0.4)),
                      ),
                      child: Row(children: [
                        Icon(Icons.emoji_events_rounded,
                            color: WT.volt, size: 18.sp),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                              'Longest ${run.label.toLowerCase()} yet — nice work!',
                              style: TextStyle(
                                  color: WT.textHi,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.sp)),
                        ),
                      ]),
                    ),
                  ],
                  SizedBox(height: 24.h),
                  _statRow('Distance', distStr, 'Moving Time',
                      formatDuration(run.movingSeconds)),
                  _divider(),
                  _statRow('Pace', paceStr, 'Calories', '$calories cal'),
                  _divider(),
                  _statRow('Steps', steps, 'Avg Speed', speedStr),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Share this run as a story-ready image card. Reuses the workout share
  /// dialog; it's a single-image share so Snapchat, TikTok, Instagram, etc. all
  /// accept it.
  void _shareRun() {
    final miles = WorkoutController.to.useMiles;
    final cals = _hkCalories ?? run.estimatedCalories;
    // The recorded GPS trace, drawn on the card as a Strava-style route line.
    // Sent as (lng, lat) — the painter fits + projects it.
    final route = run.points.map((p) => Offset(p.lng, p.lat)).toList();
    showWorkoutShareDialog(
      eyebrow: run.timeOfDayTitle,
      bigValue: (miles ? run.miles : run.km).toStringAsFixed(2),
      bigLabel: miles ? 'mi' : 'km',
      subtitle: '${formatDuration(run.movingSeconds)} · '
          '${formatPace(miles ? run.paceSecPerMile : run.paceSecPerKm)} '
          '${miles ? '/mi' : '/km'} · $cals cal',
      emoji: run.emoji,
      isPr: _isLongest,
      routePoints: route,
      dateLabel: DateFormat('MMM d, yyyy').format(run.startedAt),
    );
  }

  /// "Today at 7:24 AM" / "Yesterday at ..." / "Wed, Jul 29 at ...".
  String _whenStr() {
    final d = run.startedAt;
    final now = DateTime.now();
    final days = DateTime(now.year, now.month, now.day)
        .difference(DateTime(d.year, d.month, d.day))
        .inDays;
    final time = DateFormat('h:mm a').format(d);
    if (days == 0) return 'Today at $time';
    if (days == 1) return 'Yesterday at $time';
    return '${DateFormat('EEE, MMM d').format(d)} at $time';
  }

  /// True when this run/walk is the longest of its kind on record.
  bool get _isLongest {
    final same =
        WorkoutController.to.runs.where((r) => r.kind == run.kind).toList();
    if (same.length < 2 || run.distanceMeters <= 0) return false;
    final maxDist =
        same.map((r) => r.distanceMeters).reduce((a, b) => a > b ? a : b);
    return run.distanceMeters >= maxDist;
  }

  Widget _pin(Color color) => Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
      );

  Widget _divider() => Padding(
        padding: EdgeInsets.symmetric(vertical: 18.h),
        child: Divider(height: 1, color: WT.stroke),
      );

  Widget _statRow(String l1, String v1, String l2, String v2) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_statCell(l1, v1), _statCell(l2, v2)],
      );

  Widget _statCell(String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: WT.textMid,
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600)),
            SizedBox(height: 4.h),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: WT.textHi,
                    fontWeight: FontWeight.w900,
                    fontSize: 23.sp,
                    fontFeatures: const [FontFeature.tabularFigures()])),
          ],
        ),
      );
}
