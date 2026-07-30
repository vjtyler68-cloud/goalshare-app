import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../controller/workout_controller.dart';
import '../data/cardio_run.dart';
import '../data/workout_theme.dart';

/// Strava-style live run/walk tracker: streams GPS, draws the route on a free
/// OpenStreetMap map, and shows live distance / time / pace. Saves the full
/// route so it can be redrawn later.
class CardioTrackingScreen extends StatefulWidget {
  final String kind; // 'run' | 'walk'
  const CardioTrackingScreen({super.key, required this.kind});

  @override
  State<CardioTrackingScreen> createState() => _CardioTrackingScreenState();
}

class _CardioTrackingScreenState extends State<CardioTrackingScreen> {
  final MapController _map = MapController();
  StreamSubscription<Position>? _sub;
  Timer? _timer;

  final List<LatLng> _route = <LatLng>[];
  LatLng? _current;
  LatLng? _lastPoint;

  double _distance = 0; // metres
  int _elapsed = 0; // seconds
  int _startMs = 0;

  bool _tracking = false;
  bool _paused = false;
  bool _saving = false;
  String _status = 'Getting your location…';

  static const LatLng _fallback = LatLng(39.8283, -98.5795); // US centroid

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _prepare() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => _status =
            'Location is off — turn it on in Settings to track your route.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() => _status =
            'Location permission is needed to map your run. Enable it in Settings.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _current = LatLng(pos.latitude, pos.longitude);
        _status = '';
      });
      _map.move(_current!, 16.5);
    } catch (e) {
      if (mounted) setState(() => _status = 'Could not get your location yet.');
    }
  }

  void _start() {
    if (_status.isNotEmpty) {
      _prepare();
      return;
    }
    setState(() {
      _tracking = true;
      _paused = false;
      _startMs = DateTime.now().millisecondsSinceEpoch;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_paused && mounted) setState(() => _elapsed++);
    });
    const settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 4,
    );
    _sub = Geolocator.getPositionStream(locationSettings: settings)
        .listen(_onPosition);
  }

  void _onPosition(Position p) {
    final ll = LatLng(p.latitude, p.longitude);
    if (!_paused) {
      if (_lastPoint == null) {
        _route.add(ll);
        _lastPoint = ll;
      } else {
        final d = Geolocator.distanceBetween(
            _lastPoint!.latitude, _lastPoint!.longitude, ll.latitude, ll.longitude);
        // Ignore GPS jitter (<2 m) and impossible jumps (>120 m/tick) or poor fixes.
        if (p.accuracy <= 30 && d >= 2 && d < 120) {
          _distance += d;
          _route.add(ll);
          _lastPoint = ll;
        }
      }
    }
    if (!mounted) return;
    setState(() => _current = ll);
    if (_tracking && !_paused) _map.move(ll, _map.camera.zoom);
  }

  void _togglePause() => setState(() => _paused = !_paused);

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    _sub?.cancel();
    _timer?.cancel();
    final run = CardioRun(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      kind: widget.kind,
      startedAtMs: _startMs == 0 ? DateTime.now().millisecondsSinceEpoch : _startMs,
      endedAtMs: DateTime.now().millisecondsSinceEpoch,
      distanceMeters: _distance,
      movingSeconds: _elapsed,
      points: _route.map((l) => GeoPoint(l.latitude, l.longitude)).toList(),
    );
    await WorkoutController.to.saveRun(run);
    Get.back();
    Get.rawSnackbar(
      message:
          '${run.emoji} ${_distStr()} ${WorkoutController.to.useMiles ? 'mi' : 'km'} logged — nice work!',
      backgroundColor: WT.volt,
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.TOP,
      margin: EdgeInsets.all(12.w),
      borderRadius: 14.r,
    );
  }

  void _confirmExit() {
    if (!_tracking) {
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
            Text('Discard this ${widget.kind}?',
                style: TextStyle(
                    color: WT.textHi,
                    fontWeight: FontWeight.w900,
                    fontSize: 18.sp)),
            SizedBox(height: 6.h),
            Text('Your route so far won\'t be saved.',
                style: TextStyle(color: WT.textMid, fontSize: 13.sp)),
            SizedBox(height: 20.h),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: Get.back,
                  child: Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(vertical: 13.h),
                    decoration: BoxDecoration(
                        color: WT.surfaceHi,
                        borderRadius: BorderRadius.circular(14.r)),
                    child: Text('Keep going',
                        style: TextStyle(
                            color: WT.textHi,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.sp)),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    _sub?.cancel();
                    _timer?.cancel();
                    Get.back();
                    Get.back();
                  },
                  child: Container(
                    alignment: Alignment.center,
                    padding: EdgeInsets.symmetric(vertical: 13.h),
                    decoration: BoxDecoration(
                        color: WT.danger,
                        borderRadius: BorderRadius.circular(14.r)),
                    child: Text('Discard',
                        style: TextStyle(
                            color: Colors.white,
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

  String _distStr() {
    final miles = WorkoutController.to.useMiles;
    final v = miles ? _distance / 1609.34 : _distance / 1000.0;
    return v.toStringAsFixed(2);
  }

  String _paceStr() {
    final miles = WorkoutController.to.useMiles;
    if (_distance <= 0) return '--:--';
    final sec = _elapsed / (miles ? _distance / 1609.34 : _distance / 1000.0);
    return formatPace(sec);
  }

  @override
  Widget build(BuildContext context) {
    final miles = WorkoutController.to.useMiles;
    return Scaffold(
      backgroundColor: WT.bg,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _current ?? _fallback,
              initialZoom: _current == null ? 3.5 : 16.5,
              // Without this, flutter_map paints the un-tiled area light gray
              // (0xFFE0E0E0) — a "gray screen" until tiles load. Keep it on-brand.
              backgroundColor: WT.bg,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.goal.share',
              ),
              if (_route.length >= 2)
                PolylineLayer(polylines: [
                  Polyline(points: _route, strokeWidth: 6, color: WT.flame),
                ]),
              if (_current != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _current!,
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
          ),
          // top bar
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  _roundBtn(Icons.close_rounded, _confirmExit),
                  const Spacer(),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: WT.bg.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                        '${widget.kind == 'walk' ? '🚶 Walk' : '🏃 Run'}${_paused ? ' · paused' : ''}',
                        style: TextStyle(
                            color: WT.textHi,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.sp)),
                  ),
                  const Spacer(),
                  SizedBox(width: 44.w),
                ],
              ),
            ),
          ),
          // bottom panel
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 28.h),
              decoration: BoxDecoration(
                color: WT.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                border: Border(top: BorderSide(color: WT.stroke)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_status.isNotEmpty && !_tracking)
                    Padding(
                      padding: EdgeInsets.only(bottom: 14.h),
                      child: Text(_status,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: WT.amber, fontSize: 12.5.sp)),
                    ),
                  Row(
                    children: [
                      _bigStat(_distStr(), miles ? 'miles' : 'km', WT.flame),
                      _bigStat(formatDuration(_elapsed), 'time', WT.textHi),
                      _bigStat(_paceStr(), miles ? '/mi' : '/km', WT.volt),
                    ],
                  ),
                  SizedBox(height: 18.h),
                  _controls(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls() {
    if (!_tracking) {
      return GestureDetector(
        onTap: _start,
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
            onTap: _togglePause,
            child: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(vertical: 15.h),
              decoration: BoxDecoration(
                color: WT.surfaceHi,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(_paused ? 'RESUME' : 'PAUSE',
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
              child: Text(_saving ? 'SAVING…' : 'FINISH',
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

/// Read-only replay of a saved run's route on the map.
class RunRouteViewer extends StatelessWidget {
  final CardioRun run;
  RunRouteViewer({super.key, required this.run});

  final MapController _map = MapController();

  @override
  Widget build(BuildContext context) {
    final pts = run.points.map((p) => LatLng(p.lat, p.lng)).toList();
    final miles = WorkoutController.to.useMiles;
    final dist = (miles ? run.miles : run.km).toStringAsFixed(2);
    final pace = formatPace(miles ? run.paceSecPerMile : run.paceSecPerKm);
    return Scaffold(
      backgroundColor: WT.bg,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter:
                  pts.isNotEmpty ? pts.first : const LatLng(39.8283, -98.5795),
              initialZoom: pts.isEmpty ? 3.5 : 14,
              backgroundColor: WT.bg,
              onMapReady: () {
                if (pts.length >= 2) {
                  _map.fitCamera(CameraFit.bounds(
                    bounds: LatLngBounds.fromPoints(pts),
                    padding: const EdgeInsets.all(60),
                  ));
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.goal.share',
              ),
              if (pts.length >= 2)
                PolylineLayer(polylines: [
                  Polyline(points: pts, strokeWidth: 6, color: WT.flame),
                ]),
            ],
          ),
          if (pts.length < 2)
            Center(
              child: Text('No route was recorded for this one.',
                  style: TextStyle(color: WT.textMid, fontSize: 13.sp)),
            ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: GestureDetector(
                onTap: Get.back,
                child: Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                      color: WT.bg.withOpacity(0.85), shape: BoxShape.circle),
                  child: Icon(Icons.chevron_left, color: WT.textHi, size: 26.sp),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 26.h),
              decoration: BoxDecoration(
                color: WT.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                border: Border(top: BorderSide(color: WT.stroke)),
              ),
              child: Row(
                children: [
                  _stat('${run.emoji} $dist', miles ? 'miles' : 'km', WT.flame),
                  _stat(formatDuration(run.movingSeconds), 'time', WT.textHi),
                  _stat(pace, miles ? '/mi' : '/km', WT.volt),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, Color color) => Expanded(
        child: Column(
          children: [
            Text(value,
                maxLines: 1,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 22.sp)),
            SizedBox(height: 2.h),
            Text(label, style: TextStyle(color: WT.textMid, fontSize: 11.sp)),
          ],
        ),
      );
}
