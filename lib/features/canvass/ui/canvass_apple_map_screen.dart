import 'dart:async';
import 'dart:math' as math;
// Custom pin bitmaps (colour + emoji) are drawn offscreen with a PictureRecorder
// → PNG bytes → BitmapDescriptor.fromBytes; ui-prefixed for PictureRecorder /
// ImageByteFormat (Canvas/Paint/Path/Offset come from material unprefixed).
import 'dart:ui' as ui;

// Apple Maps (MapKit) — crisp NATIVE satellite/hybrid imagery, no key/token/
// billing on iOS. This is the "everyone else's canvassing map looks sharper"
// imagery: Apple's own aerial capture that no raster-tile source (Mapbox/Esri)
// can serve. `LatLng`, `Annotation`, `Polygon`, `CameraPosition`, `MapType`,
// `BitmapDescriptor` … all come from here.
import 'package:apple_maps_flutter/apple_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
// latlong2 only for the pin sheet's `dropAt` (the rest of Sales Ranch speaks
// latlong2); prefixed so it never collides with Apple's own `LatLng`.
import 'package:latlong2/latlong.dart' as ll;

import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/features/orgs/ui/territory_metrics_bar.dart';

import '../controller/canvass_controller.dart';
import '../data/canvass_api.dart';
import '../data/canvass_grid.dart';
import '../data/canvass_pin.dart';
import '../data/canvass_status.dart';
import '../data/canvass_territory.dart';
import 'canvass_pin_sheet.dart';
import 'canvass_pipeline_screen.dart';
import 'canvass_territory_sheet.dart';

/// Sales Ranch — Apple Maps build (iOS). Native MapKit hybrid imagery + native
/// door pins + the Ameren hosting-capacity grid drawn as native polygons for the
/// area on screen. Reuses [CanvassController], the pin sheet, and every data
/// model — only the map ENGINE changes (Apple vs the flutter_map/Mapbox build in
/// canvass_map_screen.dart, which stays as the Android path).
class CanvassAppleMapScreen extends StatefulWidget {
  const CanvassAppleMapScreen({super.key});

  @override
  State<CanvassAppleMapScreen> createState() => _CanvassAppleMapScreenState();
}

class _CanvassAppleMapScreenState extends State<CanvassAppleMapScreen> {
  static const _brand = Color(0xff0F172A);
  static const _accent = Color(0xffF59E0B); // Solar gold

  final CanvassController c = CanvassController.to;
  AppleMapController? _apple;

  // Custom door-pin bitmaps (status colour + its emoji cue — 📅 💰 ☀️ …), cached
  // by a semantic key so each is rendered once. A pin shows a plain hue marker
  // for the instant before its bitmap finishes drawing.
  final Map<String, BitmapDescriptor> _markers = {};
  final Set<String> _markerBuilding = {};
  final Map<String, BitmapDescriptor> _clusterMarkers = {};
  final Set<String> _clusterBuilding = {};
  bool _solarPrefetchScheduled = false;

  // US center — the opening view until we get a GPS fix.
  static const LatLng _fallback = LatLng(39.5, -98.35);

  LatLng? _me; // live device location (kept fresh silently, no map churn)
  LatLng _center = _fallback; // last camera center (for drop-at-view + grid bbox)
  double _zoom = 4;
  MapType _mapType = MapType.hybrid;
  double? _south;
  double? _west;
  double? _north;
  double? _east;

  // Admin area-drawing: MapKit gives no finger-drag→coordinate like flutter_map's
  // offsetToCrs, so instead of a freehand swipe you TAP each corner of the block.
  // Each map tap (onTap → LatLng) adds a vertex; Save turns the corners into a
  // territory you assign to reps. Drawing state (draw mode) is shared via
  // c.drawMode so the toggle button + rest of the app stay in sync.
  final List<LatLng> _draft = [];

  StreamSubscription<Position>? _posSub;
  Timer? _idleDebounce;

  @override
  void initState() {
    super.initState();
    _warmMarkers();
    if (c.inOrg && c.canUse && c.pins.isEmpty) c.load();
    _initLocation();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _idleDebounce?.cancel();
    super.dispose();
  }

  // ── Location ────────────────────────────────────────────────────────────────
  Future<void> _initLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) _applyPos(last, recenter: true);
      try {
        final pos = await Geolocator.getCurrentPosition()
            .timeout(const Duration(seconds: 8));
        _applyPos(pos, recenter: _me == null);
      } catch (_) {}
      _posSub?.cancel();
      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 8,
        ),
      ).listen((p) => _applyPos(p, recenter: false));
    } catch (_) {}
  }

  /// Update our stored location. We DON'T setState on every fix — Apple draws
  /// the blue location dot natively, so there's nothing for us to repaint; the
  /// FABs read [_me] fresh at tap time. Only recenter (first fix) touches the
  /// camera, via the controller.
  void _applyPos(Position p, {required bool recenter}) {
    if (!mounted) return;
    final at = LatLng(p.latitude, p.longitude);
    final firstFix = _me == null;
    _me = at;
    if (recenter) {
      try {
        _apple?.animateCamera(CameraUpdate.newLatLngZoom(at, 17));
      } catch (_) {}
    }
    // One rebuild on the very first fix so the locate button lights up.
    if (firstFix && mounted) setState(() {});
  }

  void _recenterOnMe() {
    final me = _me;
    if (me != null) {
      try {
        _apple?.animateCamera(CameraUpdate.newLatLngZoom(me, 17));
      } catch (_) {}
    } else {
      _initLocation();
    }
  }

  // ── Drop a pin ──────────────────────────────────────────────────────────────
  Future<void> _dropAt(LatLng at) async {
    if (c.drawMode.value) return; // taps place area corners while drawing
    final addr = await CanvassApi.instance.reverseGeocode(
      at.latitude,
      at.longitude,
    );
    if (!mounted) return;
    showCanvassPinSheet(
      context,
      dropAt: ll.LatLng(at.latitude, at.longitude),
      address: addr,
    );
  }

  // ── Camera → grid / sun refresh ─────────────────────────────────────────────
  void _onCameraMove(CameraPosition pos) {
    _center = pos.target;
    _zoom = pos.zoom;
  }

  void _onCameraIdle() {
    // The map stopped moving — refresh the things pinned to the current view.
    _idleDebounce?.cancel();
    _idleDebounce = Timer(const Duration(milliseconds: 250), () {
      _updateVisibleRegion();
      _refreshGrid();
      if (c.solarMode.value) c.fetchAreaSun(_center.latitude, _center.longitude);
    });
  }

  Future<void> _updateVisibleRegion() async {
    if (_apple == null) return;
    try {
      final bounds = await _apple!.getVisibleRegion();
      final latPad = (bounds.northeast.latitude - bounds.southwest.latitude) * 0.35;
      final lngPad =
          (bounds.northeast.longitude - bounds.southwest.longitude) * 0.35;
      if (!mounted) return;
      setState(() {
        _south = bounds.southwest.latitude - latPad;
        _west = bounds.southwest.longitude - lngPad;
        _north = bounds.northeast.latitude + latPad;
        _east = bounds.northeast.longitude + lngPad;
      });
    } catch (_) {}
  }

  void _scheduleSolarPrefetch(List<CanvassPin> pins) {
    if (_solarPrefetchScheduled) return;
    _solarPrefetchScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _solarPrefetchScheduled = false;
      if (!mounted || !c.solarMode.value) return;
      c.ensureSolarForVisible(pins);
    });
  }

  /// Pull Ameren hosting-capacity segments for whatever's on screen (the free
  /// public FeatureServer viewport path — HcCell polygons). Gated to zoom ≥ 12:
  /// the state has 1.67M segments, so a zoomed-out fetch would just return 2000
  /// arbitrary ones. Zoomed in on a neighborhood — where you actually knock —
  /// it's exact. Assigning `c.gridCells` re-runs the map's Obx to redraw.
  Future<void> _refreshGrid() async {
    if (!c.gridMode.value || _apple == null) return;
    if (_zoom < 12) {
      c.clearGrid();
      return;
    }
    try {
      final b = await _apple!.getVisibleRegion();
      await c.fetchGrid(
        west: b.southwest.longitude,
        south: b.southwest.latitude,
        east: b.northeast.longitude,
        north: b.northeast.latitude,
      );
    } catch (_) {}
  }

  // ── Colours ─────────────────────────────────────────────────────────────────
  /// A door's colour — by roof solar-fit in Solar mode, else by status.
  Color _pinColor(CanvassPin p) {
    if (c.solarMode.value) {
      final s = p.solar;
      if (s != null) {
        switch (s.fit) {
          case 'good':
            return const Color(0xff22C55E);
          case 'ok':
            return const Color(0xffF59E0B);
          default:
            return const Color(0xffEF4444);
        }
      }
    }
    return CanvassStatus.byCode(p.status).color;
  }

  /// Apple annotations tint by a single HUE (0–360), so we hand it the door
  /// colour's real hue — dispositions keep the exact palette used everywhere
  /// else. Un-knocked homes (a desaturated slate that would render as a random
  /// blue) get a clean azure "fresh prospect" pin instead.
  double _hue(CanvassPin p) {
    if (p.status == 'NV' && !c.solarMode.value) {
      return BitmapDescriptor.hueAzure;
    }
    return HSVColor.fromColor(_pinColor(p)).hue;
  }

  /// A door's marker: a custom bitmap (status colour + its emoji cue) once drawn,
  /// else a plain hue pin for the split second before it's ready.
  BitmapDescriptor _iconFor(CanvassPin p) {
    final emoji = CanvassStatus.emojiFor(p.status);
    final solarActive = c.solarMode.value && p.solar != null;
    final key =
        solarActive ? 'solar_${p.solar!.fit}_${p.status}' : 'status_${p.status}';
    final cached = _markers[key];
    if (cached != null) return cached;
    _ensureMarker(_pinColor(p), emoji, key);
    return BitmapDescriptor.defaultAnnotationWithHue(_hue(p));
  }

  Future<void> _ensureMarker(Color color, String emoji, String key) async {
    if (_markers.containsKey(key) || _markerBuilding.contains(key)) return;
    _markerBuilding.add(key);
    final bmp = await _buildMarker(color, emoji);
    _markerBuilding.remove(key);
    if (!mounted) return;
    _markers[key] = bmp;
    setState(() {}); // swap the fallback pin for the real emoji bitmap
  }

  int _clusterBucket(int count) {
    if (count < 10) return count;
    if (count < 100) return (count / 10).round() * 10;
    if (count < 1000) return (count / 100).round() * 100;
    return 1000;
  }

  BitmapDescriptor _clusterIcon(int count) {
    final bucket = _clusterBucket(count);
    final key = 'cluster_$bucket';
    final cached = _clusterMarkers[key];
    if (cached != null) return cached;
    _ensureClusterMarker(bucket, key);
    return BitmapDescriptor.defaultAnnotationWithHue(BitmapDescriptor.hueOrange);
  }

  Future<void> _ensureClusterMarker(int count, String key) async {
    if (_clusterMarkers.containsKey(key) || _clusterBuilding.contains(key)) {
      return;
    }
    _clusterBuilding.add(key);
    final bmp = await _buildClusterMarker(count);
    _clusterBuilding.remove(key);
    if (!mounted) return;
    _clusterMarkers[key] = bmp;
    setState(() {});
  }

  Future<BitmapDescriptor> _buildClusterMarker(int count) async {
    const size = 92.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 5,
      Paint()..color = _brand,
    );
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = Colors.white,
    );
    final label = count >= 1000 ? '1k+' : '$count';
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 27,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      const Offset(size / 2, size / 2) -
          Offset(tp.width / 2, tp.height / 2),
    );
    final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  /// Pre-render every status marker up front so pins show their emoji from the
  /// first frame instead of flickering in. Solar-mode combos build lazily.
  Future<void> _warmMarkers() async {
    for (final s in CanvassStatus.all) {
      final key = 'status_${s.code}';
      if (_markers.containsKey(key)) continue;
      _markers[key] = await _buildMarker(s.color, CanvassStatus.emojiFor(s.code));
    }
    if (mounted) setState(() {});
  }

  /// Draw a teardrop pin (status colour, white ring) with the emoji in its face,
  /// offscreen, to PNG bytes. Default annotation anchor (0.5, 1.0) lands the
  /// tail tip on the coordinate.
  Future<BitmapDescriptor> _buildMarker(Color color, String emoji) async {
    const double w = 88, h = 112;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(w / 2, w / 2);
    const double radius = w / 2 - 8;
    final fill = Paint()..color = color;
    // Soft drop shadow.
    canvas.drawCircle(
      center + const Offset(0, 3),
      radius + 2,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // Pointer tail down to the anchor.
    final tail = Path()
      ..moveTo(w / 2 - radius * 0.55, center.dy + radius * 0.45)
      ..lineTo(w / 2, h - 4)
      ..lineTo(w / 2 + radius * 0.55, center.dy + radius * 0.45)
      ..close();
    canvas.drawPath(tail, fill);
    // Body + white ring.
    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = Colors.white,
    );
    // Emoji cue (or a clean white dot when a status has none).
    if (emoji.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(
            text: emoji,
            style: const TextStyle(fontSize: radius * 0.95)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
    } else {
      canvas.drawCircle(center, radius * 0.34, Paint()..color = Colors.white);
    }
    final img = await recorder.endRecording().toImage(w.toInt(), h.toInt());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  // ── Annotation / polygon sets (rebuilt inside the map's Obx) ─────────────────
  List<_AppleCluster> _buildClusters(List<CanvassPin> pins) {
    if (_zoom >= 18 || pins.length <= 1) {
      return [
        for (final p in pins)
          _AppleCluster(p.lat, p.lng, [p]),
      ];
    }
    final cell = 2.0 / math.pow(2, math.max(0, _zoom - 3));
    final buckets = <String, _AppleCluster>{};
    for (final p in pins) {
      final gx = (p.lng / cell).floor();
      final gy = (p.lat / cell).floor();
      final key = '$gx:$gy';
      final bucket = buckets[key];
      if (bucket == null) {
        buckets[key] = _AppleCluster(p.lat, p.lng, [p]);
      } else {
        bucket.pins.add(p);
        bucket.sumLat += p.lat;
        bucket.sumLng += p.lng;
      }
    }
    for (final bucket in buckets.values) {
      bucket.centerLat = bucket.sumLat / bucket.pins.length;
      bucket.centerLng = bucket.sumLng / bucket.pins.length;
    }
    return buckets.values.toList();
  }

  List<CanvassPin> _pinsForMap(List<CanvassPin> pins) {
    final south = _south;
    final west = _west;
    final north = _north;
    final east = _east;
    if (south == null || west == null || north == null || east == null) {
      return pins;
    }
    return pins
        .where((p) =>
            p.lat >= south &&
            p.lat <= north &&
            p.lng >= west &&
            p.lng <= east)
        .toList();
  }

  Set<Annotation> _annotations(List<CanvassPin> pins, bool drawing) {
    final set = <Annotation>{};
    for (final cluster in _buildClusters(pins)) {
      if (cluster.pins.length == 1) {
        final p = cluster.pins.first;
        set.add(Annotation(
          annotationId: AnnotationId(p.id),
          position: LatLng(p.lat, p.lng),
          icon: _iconFor(p),
          infoWindow: InfoWindow(
            title: p.shortAddress,
            snippet: CanvassStatus.byCode(p.status).label,
          ),
          // Don't open a door sheet mid-draw — taps are placing area corners.
          onTap: drawing ? null : () => showCanvassPinSheet(context, pin: p),
        ));
      } else {
        set.add(Annotation(
          annotationId: AnnotationId(
            'cluster_${cluster.centerLat.toStringAsFixed(5)}_'
            '${cluster.centerLng.toStringAsFixed(5)}',
          ),
          position: LatLng(cluster.centerLat, cluster.centerLng),
          icon: _clusterIcon(cluster.pins.length),
          infoWindow: InfoWindow(
            title: '${cluster.pins.length} homes',
            snippet: 'Tap to zoom in',
          ),
          onTap: () {
            final nextZoom = math.min(18.0, _zoom + 2);
            _apple?.animateCamera(CameraUpdate.newLatLngZoom(
              LatLng(cluster.centerLat, cluster.centerLng),
              nextZoom,
            ));
          },
        ));
      }
    }
    // Corner markers for the area being traced, so each tap is visibly placed.
    if (drawing) {
      for (var i = 0; i < _draft.length; i++) {
        set.add(Annotation(
          annotationId: AnnotationId('draft_$i'),
          position: _draft[i],
          icon: BitmapDescriptor.defaultAnnotationWithHue(
              BitmapDescriptor.hueYellow),
          infoWindow: InfoWindow(title: 'Corner ${i + 1}'),
        ));
      }
    }
    return set;
  }

  Set<Polygon> _polygons(bool drawing) {
    final polys = <Polygon>{};
    // The area currently being traced (once there are enough corners to fill).
    if (drawing && _draft.length >= 3) {
      polys.add(Polygon(
        polygonId: PolygonId('draft_area'),
        points: List<LatLng>.from(_draft),
        fillColor: _accent.withValues(alpha: 0.2),
        strokeColor: _accent,
        strokeWidth: 3,
      ));
    }
    // Territory outlines (view only — freehand drawing stays on the flutter_map
    // build; MapKit can't convert a finger point to a coordinate).
    for (final t in c.visibleTerritories) {
      if (t.points.length < 3) continue;
      polys.add(Polygon(
        polygonId: PolygonId('terr_${t.id}'),
        points: [for (final q in t.points) LatLng(q.latitude, q.longitude)],
        fillColor: t.colorValue.withValues(alpha: 0.06),
        strokeColor: t.colorValue.withValues(alpha: 0.85),
        strokeWidth: 2,
        consumeTapEvents: true,
        onTap: () => _openTerritory(t),
      ));
    }
    // Ameren grid — hosting-capacity zones, coloured green→amber→red for how much
    // new solar the local grid can take.
    if (c.gridMode.value && _zoom >= 12) {
      var i = 0;
      for (final cell in c.gridCells) {
        if (cell.ring.length < 3) continue;
        polys.add(Polygon(
          polygonId: PolygonId('grid_${i++}'),
          points: [
            for (final q in cell.ring) LatLng(q.latitude, q.longitude),
          ],
          fillColor: cell.color.withValues(alpha: 0.16),
          strokeColor: cell.color.withValues(alpha: 0.9),
          strokeWidth: 1,
        ));
      }
    }
    return polys;
  }

  /// The outline connecting the tapped corners (shows before the area has 3+
  /// points to fill).
  Set<Polyline> _draftPolylines(bool drawing) {
    if (!drawing || _draft.length < 2) return const <Polyline>{};
    return {
      Polyline(
        polylineId: PolylineId('draft_line'),
        points: List<LatLng>.from(_draft),
        color: _accent,
        width: 3,
      ),
    };
  }

  void _onMapTap(LatLng at) {
    if (!c.drawMode.value) return;
    setState(() => _draft.add(at));
  }

  void _toggleDraw() {
    c.drawMode.value = !c.drawMode.value;
    setState(() => _draft.clear());
  }

  void _undoDraft() {
    if (_draft.isEmpty) return;
    setState(() => _draft.removeLast());
  }

  /// Turn the tapped corners into a named territory (assign it to reps in the
  /// sheet). Reuses the exact same create flow as the flutter_map build.
  Future<void> _commitDraw() async {
    if (_draft.length < 3) return;
    final pts = [for (final q in _draft) ll.LatLng(q.latitude, q.longitude)];
    final created = await showCreateTerritorySheet(context, pts);
    if (!mounted) return;
    setState(() => _draft.clear());
    if (created == true) c.drawMode.value = false;
  }

  void _openTerritory(CanvassTerritory t) {
    if (!mounted) return;
    showTerritorySheet(context, t);
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (!c.inOrg) return _fallbackScreen(_noOrgBody());
    if (!c.canUse) return _fallbackScreen(_lockedBody());
    return Scaffold(
      backgroundColor: _brand,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Obx(() {
                  final pins = _pinsForMap(c.visiblePins);
                  final drawing = c.drawMode.value;
                  // Solar mode: colour the on-screen doors by roof fit.
                  if (c.solarMode.value) {
                    _scheduleSolarPrefetch(pins);
                  }
                  return AppleMap(
                    initialCameraPosition: CameraPosition(
                      target: _me ?? _fallback,
                      zoom: _me == null ? 4 : 16,
                    ),
                    mapType: _mapType,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    compassEnabled: true,
                    rotateGesturesEnabled: true,
                    annotations: _annotations(pins, drawing),
                    polygons: _polygons(drawing),
                    polylines: _draftPolylines(drawing),
                    onMapCreated: (ctrl) => _apple = ctrl,
                    onCameraMove: _onCameraMove,
                    onCameraIdle: _onCameraIdle,
                    // While drawing, a tap drops an area corner; otherwise a
                    // long-press drops a door pin.
                    onTap: drawing ? _onMapTap : null,
                    onLongPress: drawing ? null : _dropAt,
                  );
                }),
                _topBar(),
                _rightControls(),
                Obx(() =>
                    c.solarMode.value ? _sunBanner() : const SizedBox.shrink()),
                Obx(() =>
                    c.gridMode.value ? _gridLegend() : const SizedBox.shrink()),
                Obx(() => c.drawMode.value ? _drawToolbar() : _fabs()),
                _attribution(),
                Obx(() {
                  if (!c.loading.value) return const SizedBox.shrink();
                  return Positioned(
                    top: MediaQuery.of(context).padding.top + 112.h,
                    left: 18.w,
                    right: 18.w,
                    child: _syncingChip(),
                  );
                }),
              ],
            ),
          ),
          const TerritoryMetricsBar(),
        ],
      ),
    );
  }

  Widget _syncingChip() => Container(
        padding: EdgeInsets.symmetric(vertical: 9.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: _brand.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 14.r,
              height: 14.r,
              child: const CircularProgressIndicator(
                  strokeWidth: 2, color: _accent),
            ),
            SizedBox(width: 9.w),
            Text(
              'Syncing doors and territories…',
              style: AppFonts.spaceGrotesk
                  .copyWith(color: Colors.white, fontSize: 11.5.sp),
            ),
          ],
        ),
      );

  // ── Top bar ──────────────────────────────────────────────────────────────────
  Widget _topBar() {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 0),
        child: Column(
          children: [
            Row(
              children: [
                _round(Icons.arrow_back, Get.back),
                SizedBox(width: 8.w),
                Expanded(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: _brand.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Obx(
                      () => Row(
                        children: [
                          const Icon(Icons.wb_sunny_rounded,
                              color: _accent, size: 18),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'Sales Ranch',
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: AppFonts.spaceGrotesk.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          _stat('${c.doorsToday}', 'today'),
                          _stat('${c.apptsTotal}', 'appts'),
                          _stat('${c.salesTotal}', 'sales'),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Obx(() => c.loading.value
                    ? _round(Icons.hourglass_top_rounded, () {})
                    : _round(Icons.refresh_rounded, () => c.load())),
                SizedBox(width: 8.w),
                _round(Icons.leaderboard_rounded, _openStats),
              ],
            ),
            if (c.isAdmin)
              Obx(() {
                final reps = c.reps;
                if (reps.isEmpty) return const SizedBox();
                return Container(
                  margin: EdgeInsets.only(top: 8.h),
                  height: 34.h,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _repChip('All reps', c.repFilter.value == null,
                          () => c.repFilter.value = null),
                      for (final r in reps)
                        _repChip(r.name, c.repFilter.value == r.id,
                            () => c.repFilter.value = r.id),
                    ],
                  ),
                );
              }),
            Obx(() {
              final off = c.offline.value;
              final n = c.pendingCount.value;
              if (!off && n == 0) return const SizedBox.shrink();
              final plural = n == 1 ? '' : 's';
              return Container(
                margin: EdgeInsets.only(top: 8.h),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: (off
                          ? const Color(0xffB45309)
                          : const Color(0xff0F172A))
                      .withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      off ? Icons.cloud_off_rounded : Icons.cloud_sync_rounded,
                      color: Colors.white,
                      size: 15.r,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        off
                            ? (n > 0
                                ? 'Offline — $n change$plural will sync when you’re back'
                                : 'Offline — working from your saved map')
                            : 'Syncing $n change$plural…',
                        style: AppFonts.spaceGrotesk.copyWith(
                          color: Colors.white,
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _stat(String v, String l) => Padding(
        padding: EdgeInsets.only(left: 6.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              v,
              style: AppFonts.spaceGrotesk.copyWith(
                color: _accent,
                fontWeight: FontWeight.w900,
                fontSize: 13.sp,
                height: 1,
              ),
            ),
            Text(
              l,
              style: AppFonts.spaceGrotesk
                  .copyWith(color: Colors.white70, fontSize: 7.5.sp),
            ),
          ],
        ),
      );

  Widget _repChip(String label, bool on, VoidCallback onTap) => Padding(
        padding: EdgeInsets.only(right: 6.w),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? _accent : _brand.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Text(
              label,
              style: AppFonts.spaceGrotesk.copyWith(
                color: on ? _brand : Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12.sp,
              ),
            ),
          ),
        ),
      );

  // ── Right controls ───────────────────────────────────────────────────────────
  Widget _rightControls() => Positioned(
        right: 10.w,
        top: MediaQuery.of(context).padding.top + 62.h,
        child: Column(
          children: [
            _round(_layerIcon(), _openLayerPicker),
            SizedBox(height: 8.h),
            Obx(() => _roundActive(
                Icons.wb_sunny_rounded, c.solarMode.value, _toggleSolar)),
            SizedBox(height: 8.h),
            Obx(() => _roundActive(
                Icons.bolt_rounded, c.gridMode.value, _toggleGrid)),
            SizedBox(height: 8.h),
            Obx(() => _roundActive(
                  Icons.filter_alt_rounded,
                  c.statusFilter.value != null || c.repFilter.value != null,
                  _openFilters,
                )),
            SizedBox(height: 8.h),
            _round(Icons.view_list_rounded,
                () => Get.to(() => const CanvassPipelineScreen())),
            // Admin: draw a new territory by tapping its corners.
            if (c.isAdmin) ...[
              SizedBox(height: 8.h),
              Obx(() => _roundActive(
                  Icons.gesture_rounded, c.drawMode.value, _toggleDraw)),
            ],
          ],
        ),
      );

  IconData _layerIcon() {
    switch (_mapType) {
      case MapType.hybrid:
        return Icons.map_rounded;
      case MapType.satellite:
        return Icons.satellite_alt_rounded;
      default:
        return Icons.map_outlined;
    }
  }

  void _openLayerPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8.h),
            _layerOption('Hybrid — satellite + street labels', MapType.hybrid,
                Icons.map_rounded),
            _layerOption(
                'Satellite', MapType.satellite, Icons.satellite_alt_rounded),
            _layerOption('Street map', MapType.standard, Icons.map_outlined),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  Widget _layerOption(String label, MapType type, IconData icon) {
    final on = _mapType == type;
    return ListTile(
      leading: Icon(icon, color: on ? _accent : const Color(0xff8A8A96)),
      title: Text(
        label,
        style: AppFonts.spaceGrotesk.copyWith(
          fontSize: 13.5.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xff17171C),
        ),
      ),
      trailing: on ? const Icon(Icons.check_rounded, color: _accent) : null,
      onTap: () {
        setState(() => _mapType = type);
        Navigator.pop(context);
      },
    );
  }

  void _toggleSolar() {
    c.solarMode.value = !c.solarMode.value;
    if (c.solarMode.value) {
      c.ensureSolarForVisible(c.visiblePins);
      c.fetchAreaSun(_center.latitude, _center.longitude);
    } else {
      c.clearAreaSun();
    }
  }

  void _toggleGrid() {
    c.gridMode.value = !c.gridMode.value;
    if (c.gridMode.value) {
      _refreshGrid();
    } else {
      c.clearGrid();
    }
  }

  // ── FABs ─────────────────────────────────────────────────────────────────────
  Widget _fabs() => Positioned(
        right: 16.w,
        bottom: 30.h,
        child: Column(
          children: [
            FloatingActionButton(
              heroTag: 'canvass_apple_locate',
              mini: true,
              backgroundColor: _me != null ? _accent : Colors.white,
              onPressed: _recenterOnMe,
              child: Icon(Icons.my_location_rounded,
                  color: _me != null ? Colors.white : _brand),
            ),
            SizedBox(height: 12.h),
            FloatingActionButton.extended(
              heroTag: 'canvass_apple_drop',
              backgroundColor: _accent,
              onPressed: () => _dropAt(_me ?? _center),
              icon: const Icon(Icons.add_location_alt_rounded, color: _brand),
              label: Text(
                'Drop pin',
                style: AppFonts.spaceGrotesk
                    .copyWith(color: _brand, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );

  // ── Draw-area toolbar (admin) — tap corners, then save ───────────────────────
  Widget _drawToolbar() {
    final ready = _draft.length >= 3;
    return Positioned(
      left: 16.w,
      right: 16.w,
      bottom: 26.h,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: _brand.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.touch_app_rounded, color: _accent, size: 20),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    ready
                        ? 'Nice — ${_draft.length} corners. Tap more to shape it, or save the area.'
                        : 'Tap each corner of the area (at least 3). Pan the map to reach them.',
                    style: AppFonts.spaceGrotesk.copyWith(
                      color: Colors.white,
                      fontSize: 11.5.sp,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 11.h),
            Row(
              children: [
                _drawAction('Cancel', Colors.white.withValues(alpha: 0.15),
                    Colors.white, _toggleDraw),
                if (_draft.isNotEmpty) ...[
                  SizedBox(width: 8.w),
                  _drawAction('Undo', Colors.white.withValues(alpha: 0.15),
                      Colors.white, _undoDraft),
                ],
                const Spacer(),
                if (ready)
                  _drawAction('Save area', _accent, _brand, _commitDraw),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawAction(String label, Color bg, Color fg, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Text(
            label,
            style: AppFonts.spaceGrotesk.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
              fontSize: 12.sp,
            ),
          ),
        ),
      );

  // ── Sun banner (reads c.areaSun / c.areaSunLoading via the enclosing Obx) ─────
  Widget _sunBanner() {
    final s = c.areaSun.value;
    final loading = c.areaSunLoading.value;
    Color tone = _accent;
    String text;
    if (s != null) {
      tone = _sunTone(s.rating);
      final sys = s.annualKwhPerKw != null
          ? ' · 6 kW ≈ ${_kWhK(s.systemKwh(6))}/yr'
          : '';
      text =
          '${s.peakSunHours.toStringAsFixed(1)} sun hrs/day · ${_sunWord(s.rating)}$sys';
    } else if (loading) {
      text = 'Reading the sun for this area…';
    } else {
      text = 'Sun data unavailable here';
    }
    return Positioned(
      top: MediaQuery.of(context).padding.top + 108.h,
      left: 14.w,
      right: 14.w,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
          decoration: BoxDecoration(
            color: _brand.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(color: tone.withValues(alpha: 0.9), width: 1.4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wb_sunny_rounded, color: tone, size: 16.r),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.spaceGrotesk.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5.sp,
                  ),
                ),
              ),
              if (loading) ...[
                SizedBox(width: 8.w),
                SizedBox(
                  width: 11.r,
                  height: 11.r,
                  child: const CircularProgressIndicator(
                      strokeWidth: 1.6, color: Colors.white),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _sunTone(String rating) {
    switch (rating) {
      case 'excellent':
        return const Color(0xff22C55E);
      case 'good':
        return const Color(0xffF59E0B);
      case 'fair':
        return const Color(0xffFB923C);
      default:
        return const Color(0xff94A3B8);
    }
  }

  String _sunWord(String rating) {
    switch (rating) {
      case 'excellent':
        return 'Excellent sun';
      case 'good':
        return 'Good sun';
      case 'fair':
        return 'Fair sun';
      default:
        return 'Low sun';
    }
  }

  String _kWhK(int kwh) =>
      kwh >= 1000 ? '${(kwh / 1000).toStringAsFixed(1)}k kWh' : '$kwh kWh';

  // ── Grid legend ──────────────────────────────────────────────────────────────
  Widget _gridLegend() {
    return Positioned(
      left: 10.w,
      bottom: 24.h,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: _brand.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, color: _accent, size: 13),
                SizedBox(width: 5.w),
                Text('AMEREN GRID',
                    style: AppFonts.spaceGrotesk.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 9.sp,
                        letterSpacing: 0.5)),
                Obx(() => c.gridLoading.value
                    ? Padding(
                        padding: EdgeInsets.only(left: 6.w),
                        child: SizedBox(
                          width: 9.r,
                          height: 9.r,
                          child: const CircularProgressIndicator(
                              strokeWidth: 1.6, color: Colors.white),
                        ),
                      )
                    : const SizedBox.shrink()),
              ],
            ),
            SizedBox(height: 6.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _legendDot(HcCell.openColor, 'More'),
                SizedBox(width: 9.w),
                _legendDot(HcCell.limitedColor, 'Some'),
                SizedBox(width: 9.w),
                _legendDot(HcCell.constrainedColor, 'Tight'),
              ],
            ),
            SizedBox(height: 3.h),
            Obx(() => Text(
                  _zoom < 12
                      ? 'zoom in to see the grid'
                      : 'capacity for new solar${c.gridCells.isEmpty ? " · none here" : ""}',
                  style: AppFonts.spaceGrotesk
                      .copyWith(color: Colors.white54, fontSize: 7.5.sp),
                )),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9.r,
            height: 9.r,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 4.w),
          Text(label,
              style: AppFonts.spaceGrotesk
                  .copyWith(color: Colors.white, fontSize: 9.sp)),
        ],
      );

  // ── Filters sheet ────────────────────────────────────────────────────────────
  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      builder: (_) => SafeArea(
        child: Obx(() {
          final active = c.statusFilter.value;
          final statuses = <({String label, String? code})>[
            (label: 'All doors', code: null),
            (label: 'Unvisited', code: 'NV'),
            (label: 'Not home', code: 'NH'),
            (label: 'Interested', code: 'interested'),
            (label: 'Appointment', code: 'APPT'),
            (label: 'Sale', code: 'sale'),
            (label: 'Worked', code: 'worked'),
          ];
          return Padding(
            padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 18.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Map filters',
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w900,
                            color: _brand)),
                    const Spacer(),
                    Text('${c.visiblePins.length} doors',
                        style: AppFonts.spaceGrotesk.copyWith(
                            color: const Color(0xff8A8A96), fontSize: 12.sp)),
                  ],
                ),
                SizedBox(height: 13.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    for (final s in statuses)
                      _filterChip(s.label, active == s.code, () {
                        c.statusFilter.value = s.code;
                        Navigator.pop(context);
                      }),
                  ],
                ),
                if (c.isAdmin) ...[
                  SizedBox(height: 18.h),
                  Text('REP',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xff8A8A96),
                          letterSpacing: .6)),
                  SizedBox(height: 8.h),
                  SizedBox(
                    height: 40.h,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _filterChip('All reps', c.repFilter.value == null, () {
                          c.repFilter.value = null;
                          Navigator.pop(context);
                        }),
                        for (final r in c.reps)
                          Padding(
                            padding: EdgeInsets.only(left: 8.w),
                            child: _filterChip(
                                r.name, c.repFilter.value == r.id, () {
                              c.repFilter.value = r.id;
                              Navigator.pop(context);
                            }),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 9.h),
          decoration: BoxDecoration(
            color: selected ? _accent : const Color(0xffF1F3F6),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
                color: selected ? _accent : const Color(0xffE1E5EA)),
          ),
          child: Text(
            label,
            style: AppFonts.spaceGrotesk.copyWith(
              color: selected ? _brand : const Color(0xff394150),
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );

  // ── Stats / leaderboard sheet ────────────────────────────────────────────────
  void _openStats() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => Obx(() {
        final board = c.leaderboard;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 18.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.isAdmin ? 'Team leaderboard' : 'My numbers',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 16.sp, fontWeight: FontWeight.w800)),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    _bigStat('${c.totalPins}', 'Doors'),
                    _bigStat('${c.apptsTotal}', 'Appts'),
                    _bigStat('${c.salesTotal}', 'Sales'),
                  ],
                ),
                if (c.isAdmin && board.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  ...board.asMap().entries.map((e) {
                    final r = e.value;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: Row(
                        children: [
                          Text('${e.key + 1}',
                              style: AppFonts.spaceGrotesk.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: _accent,
                                  fontSize: 14.sp)),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(r.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.spaceGrotesk.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.sp)),
                          ),
                          Text('${r.doors} · ${r.appts} · ${r.sales}',
                              style: AppFonts.spaceGrotesk.copyWith(
                                  color: const Color(0xff8A8A96),
                                  fontSize: 12.sp)),
                        ],
                      ),
                    );
                  }),
                  SizedBox(height: 4.h),
                  Text('doors · appts · sales',
                      style: AppFonts.spaceGrotesk.copyWith(
                          color: const Color(0xff8A8A96), fontSize: 10.sp)),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _bigStat(String v, String l) => Expanded(
        child: Column(
          children: [
            Text(v,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                    color: _brand)),
            Text(l,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 11.sp, color: const Color(0xff8A8A96))),
          ],
        ),
      );

  Widget _attribution() => Positioned(
        left: 8.w,
        bottom: 6.h,
        child: Text('© Apple Maps · Ameren (grid)',
            style: TextStyle(color: Colors.white54, fontSize: 8.5.sp)),
      );

  // ── Shared round buttons ─────────────────────────────────────────────────────
  Widget _round(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38.r,
          height: 38.r,
          decoration: BoxDecoration(
            color: _brand.withValues(alpha: 0.85),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20.r),
        ),
      );

  Widget _roundActive(IconData icon, bool on, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38.r,
          height: 38.r,
          decoration: BoxDecoration(
            color: on ? _accent : _brand.withValues(alpha: 0.85),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: on ? _brand : Colors.white, size: 20.r),
        ),
      );

  // ── Locked / no-org states ───────────────────────────────────────────────────
  Widget _fallbackScreen(Widget body) => Scaffold(
        backgroundColor: _brand,
        appBar: AppBar(
          backgroundColor: _brand,
          elevation: 0,
          leading: IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        body: body,
      );

  Widget _lockedBody() => Center(
        child: Padding(
          padding: EdgeInsets.all(30.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded, color: _accent, size: 52),
              SizedBox(height: 14.h),
              Text('Sales Ranch isn’t open yet',
                  textAlign: TextAlign.center,
                  style: AppFonts.spaceGrotesk.copyWith(
                      color: Colors.white,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800)),
              SizedBox(height: 6.h),
              Text(
                'Your team admin hasn’t opened Sales Ranch to the team yet. '
                'Check back once they turn it on.',
                textAlign: TextAlign.center,
                style: AppFonts.spaceGrotesk.copyWith(
                    color: Colors.white70, fontSize: 12.5.sp, height: 1.5),
              ),
            ],
          ),
        ),
      );

  Widget _noOrgBody() => Center(
        child: Padding(
          padding: EdgeInsets.all(30.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wb_sunny_rounded, color: _accent, size: 52),
              SizedBox(height: 14.h),
              Text('Join your sales team first',
                  textAlign: TextAlign.center,
                  style: AppFonts.spaceGrotesk.copyWith(
                      color: Colors.white,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800)),
              SizedBox(height: 6.h),
              Text(
                'Sales Ranch lives inside your sales team’s organization. '
                'Join or create it, then come back to start knocking.',
                textAlign: TextAlign.center,
                style: AppFonts.spaceGrotesk.copyWith(
                    color: Colors.white70, fontSize: 12.5.sp, height: 1.5),
              ),
            ],
          ),
        ),
      );
}

class _AppleCluster {
  double centerLat;
  double centerLng;
  final List<CanvassPin> pins;
  double sumLat;
  double sumLng;

  _AppleCluster(double lat, double lng, this.pins)
      : centerLat = lat,
        centerLng = lng,
        sumLat = lat,
        sumLng = lng;
}
