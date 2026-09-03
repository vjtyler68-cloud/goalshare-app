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
// flutter_map (prefixed `fm` — its Polyline/Polygon/MapController collide with
// Apple's) draws the Ameren grid as a transparent RASTER tile overlay stacked
// on the Apple map and synced to its camera. Ameren pre-rendered their dense
// grid to PNG tiles (AIC_LC MapServer), so this is plain image tiles — ~10x
// lighter than the vector renderer that used to freeze — cheap enough to stay
// live while you pan/zoom.
import 'package:flutter_map/flutter_map.dart' as fm;
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
import '../data/cached_tile_provider.dart';
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

  // Ameren grid = a transparent flutter_map RASTER overlay stacked on the Apple
  // map, driven to match its camera. Ameren pre-rendered the whole grid to PNG
  // tiles (AIC_LC MapServer), so the overlay just draws cached images — no live
  // vector decode, the thing that used to freeze iOS. `_gridZoomOffset` maps
  // Apple's zoom convention onto flutter_map's (calibrated from the real visible
  // bounds on idle, so the lines land exactly on the imagery at any zoom).
  final fm.MapController _gridMap = fm.MapController();
  double _gridZoomOffset = 0;

  // Admin area-drawing: MapKit gives no finger-drag→coordinate like flutter_map's
  // offsetToCrs, so instead of a freehand swipe you TAP each corner of the block.
  // Each map tap (onTap → LatLng) adds a vertex; Save turns the corners into a
  // territory you assign to reps. Drawing state (draw mode) is shared via
  // c.drawMode so the toggle button + rest of the app stay in sync.
  final List<LatLng> _draft = [];

  // ── Freehand area drawing ────────────────────────────────────────────────────
  // You DRAG a loop around the block (SalesRabbit-style), lift, and it closes —
  // no more tapping corner-by-corner. The finger path is captured in SCREEN
  // pixels (instant, no map round-trip) and converted to lat/lng on release via
  // the map's visible bounds + Web-Mercator math. The map is frozen while you
  // draw so that screen→coordinate mapping stays valid for the whole stroke.
  final List<Offset> _drawPath = []; // live finger path, screen px
  bool _isDrawing = false; // finger down, tracing right now
  Size _mapSize = Size.zero; // map area size (from LayoutBuilder)
  LatLngBounds? _drawBounds; // exact visible region captured at touch-down

  StreamSubscription<Position>? _posSub;
  Timer? _idleDebounce;

  // Map bearing (0 = north up). Kept in a ValueNotifier so the SalesRabbit-style
  // compass rose repaints as you rotate WITHOUT rebuilding the whole map.
  final ValueNotifier<double> _heading = ValueNotifier<double>(0);

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
    _heading.dispose();
    _gridMap.dispose();
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
    if (c.drawMode.value) return; // don't drop pins mid-draw (you're tracing an area)
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
    // Repaints only the compass rose (ValueListenableBuilder), never the map.
    if ((pos.heading - _heading.value).abs() > 0.5) {
      _heading.value = pos.heading;
    }
    // Live-track the grid overlay to the Apple camera. Raster tiles → a bare
    // move() is a cheap GPU redraw, so the grid follows the pan/zoom in real
    // time and stays glued to the imagery (no popping in when the camera stops).
    if (c.gridMode.value) _syncGrid(pos);
  }

  /// Snap the map back to north-up (the SalesRabbit-style compass tap).
  void _resetNorth() {
    try {
      _apple?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: _center, zoom: _zoom, heading: 0, pitch: 0),
      ));
    } catch (_) {}
    _heading.value = 0;
  }

  void _onCameraIdle() {
    // The map stopped moving — refresh the things pinned to the current view.
    _idleDebounce?.cancel();
    _idleDebounce = Timer(const Duration(milliseconds: 220), () {
      _updateVisibleRegion();
      if (c.gridMode.value) _calibrateGrid(); // snap grid exactly onto imagery
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
      c.ensureSolarForVisible(pins); // Google per-roof (if key configured)
      c.ensureSunlightForVisible(pins); // free PVGIS area-sun for every home
    });
  }

  // ── Ameren grid overlay (transparent raster flutter_map, camera-synced) ──────
  /// Cheap per-frame follow: move the grid map to the Apple camera. Called on
  /// every camera-move so the raster grid tracks the pan/zoom live. Just a
  /// transform update + redraw of already-cached PNG tiles — no decode, no
  /// network on the frame — so it stays smooth.
  void _syncGrid([CameraPosition? pos]) {
    if (!c.gridMode.value) return;
    final target = pos?.target ?? _center;
    final zoom = pos?.zoom ?? _zoom;
    final heading = pos?.heading ?? _heading.value;
    try {
      _gridMap.moveAndRotate(
        ll.LatLng(target.latitude, target.longitude),
        (zoom + _gridZoomOffset).clamp(1.0, 20.0),
        -heading,
      );
    } catch (_) {}
  }

  /// Exact sync on idle: derive flutter_map's zoom from Apple's real visible
  /// bounds (convention-independent → precise), so the grid lines land exactly
  /// on the imagery, and remember the Apple→flutter_map zoom offset that the
  /// live [_syncGrid] then reuses on every frame.
  Future<void> _calibrateGrid() async {
    if (!c.gridMode.value || _apple == null) return;
    try {
      final b = await _apple!.getVisibleRegion();
      final lngSpan = (b.northeast.longitude - b.southwest.longitude).abs();
      if (lngSpan < 1e-9 || !mounted) return;
      final w = MediaQuery.of(context).size.width;
      final fz = math.log(360 * w / (256 * lngSpan)) / math.ln2;
      _gridZoomOffset = fz - _zoom; // remember Apple→flutter_map offset
      _gridMap.moveAndRotate(
        ll.LatLng((b.southwest.latitude + b.northeast.latitude) / 2,
            (b.southwest.longitude + b.northeast.longitude) / 2),
        fz.clamp(1.0, 20.0),
        -_heading.value,
      );
    } catch (_) {}
  }

  Widget _gridOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: fm.FlutterMap(
          mapController: _gridMap,
          options: fm.MapOptions(
            initialCenter: ll.LatLng(_center.latitude, _center.longitude),
            initialZoom: (_zoom + _gridZoomOffset).clamp(1.0, 20.0),
            initialRotation: -_heading.value,
            backgroundColor: Colors.transparent,
            interactionOptions:
                const fm.InteractionOptions(flags: fm.InteractiveFlag.none),
          ),
          children: [
            fm.TileLayer(
              key: const ValueKey('ameren-grid-raster'),
              // Ameren's OWN pre-rendered hosting-capacity RASTER tiles: PNG,
              // transparent background, red→green new-solar capacity. Standard
              // Web-Mercator {z}/{y}/{x} (ArcGIS level/row/col), LOD 0–17 →
              // statewide zoom-out down to the individual block.
              urlTemplate:
                  'https://tiles.arcgis.com/tiles/3jEEGnl6c1x9Sze7/arcgis/rest/services/AIC_LC/MapServer/tile/{z}/{y}/{x}',
              maxNativeZoom: 17, // upscale z17 past LOD 17 rather than 404
              // Keep prior tiles on screen while the next zoom loads (no blank
              // flash), and disk-cache them so re-visits are instant.
              keepBuffer: 5,
              panBuffer: 1,
              userAgentPackageName: 'com.goal.share',
              tileProvider: CachedTileProvider(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Colours ─────────────────────────────────────────────────────────────────
  /// A door's colour. In Solar mode: Google's per-roof fit when we have it, else
  /// the FREE PVGIS area-sun rating (works everywhere, no key) so every home is
  /// coloured green→red for how good the area is for solar. Otherwise: status.
  Color _pinColor(CanvassPin p) {
    if (c.solarMode.value) {
      final s = p.solar;
      if (s != null) {
        switch (s.fit) {
          case 'good':
            return const Color(0xff16A34A);
          case 'ok':
            return const Color(0xffF59E0B);
          default:
            return const Color(0xffEF4444);
        }
      }
      final rating = c.sunRatingFor(p);
      if (rating != null) return _sunColor(rating);
    }
    return CanvassStatus.byCode(p.status).color;
  }

  /// PVGIS sun rating → pin colour.
  Color _sunColor(String rating) {
    switch (rating) {
      case 'excellent':
        return const Color(0xff16A34A); // deep green — great solar area
      case 'good':
        return const Color(0xff22C55E); // green
      case 'fair':
        return const Color(0xffF59E0B); // amber
      default:
        return const Color(0xffEF4444); // low — red
    }
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
    String key;
    if (c.solarMode.value) {
      if (p.solar != null) {
        key = 'solar_${p.solar!.fit}_${p.status}';
      } else {
        final rating = c.sunRatingFor(p);
        key =
            rating != null ? 'sun_${rating}_${p.status}' : 'status_${p.status}';
      }
    } else {
      key = 'status_${p.status}';
    }
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

  /// A premium teardrop map pin: a status-colour body with a soft top-lit
  /// gradient + drop shadow, a crisp white ring, and the emoji cue on a clean
  /// white disc so it reads sharply instead of sitting on a busy colour blob.
  /// The plugin builds the UIImage at UIScreen.main.scale, so these pixels map
  /// ~1:1 to the device (crisp) at a normal pin size. Default anchor (0.5, 1.0)
  /// lands the tip on the coordinate.
  Future<BitmapDescriptor> _buildMarker(Color color, String emoji) async {
    const double w = 88, h = 114;
    const double cx = w / 2; // 44
    const double headR = 34;
    const double headCy = headR + 5; // 39
    const double tipY = h - 3; // 111
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Smooth teardrop = head circle unioned with a curved tail to the tip.
    final head = Path()
      ..addOval(Rect.fromCircle(
          center: const Offset(cx, headCy), radius: headR));
    const theta = 0.98; // where the tail meets the head (rad from vertical)
    final tx = headR * math.sin(theta);
    final ty = headR * math.cos(theta);
    final tail = Path()
      ..moveTo(cx - tx, headCy + ty)
      ..quadraticBezierTo(
          cx - tx * 0.35, tipY - (tipY - headCy) * 0.30, cx, tipY)
      ..quadraticBezierTo(
          cx + tx * 0.35, tipY - (tipY - headCy) * 0.30, cx + tx, headCy + ty)
      ..close();
    final body = Path.combine(PathOperation.union, head, tail);

    // Soft shadow beneath the pin.
    canvas.drawPath(
      body.shift(const Offset(0, 2.5)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Body with a subtle top-lit gradient for depth.
    final light = Color.lerp(color, Colors.white, 0.30) ?? color;
    final dark = Color.lerp(color, Colors.black, 0.12) ?? color;
    canvas.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(cx, headCy - headR),
          const Offset(cx, tipY),
          [light, color, dark],
          const [0.0, 0.55, 1.0],
        ),
    );

    // Crisp white ring around the head.
    canvas.drawCircle(
      const Offset(cx, headCy),
      headR - 1.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white,
    );

    // Clean white disc that carries the emoji cue.
    const double discR = headR * 0.66;
    canvas.drawCircle(
        const Offset(cx, headCy), discR, Paint()..color = Colors.white);
    if (emoji.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(
            text: emoji, style: const TextStyle(fontSize: discR * 1.25)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas, const Offset(cx, headCy) - Offset(tp.width / 2, tp.height / 2));
    } else {
      canvas.drawCircle(
          const Offset(cx, headCy), discR * 0.5, Paint()..color = color);
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
    // Saved territory outlines. Tapping does nothing (no annoying pop); hold on
    // one to open or delete it, or open it from the Areas list.
    for (final t in c.visibleTerritories) {
      if (t.points.length < 3) continue;
      // View-only outline — tapping a territory no longer pops a sheet (that was
      // the annoying "second page"). Open one deliberately from the Areas list.
      polys.add(Polygon(
        polygonId: PolygonId('terr_${t.id}'),
        points: [for (final q in t.points) LatLng(q.latitude, q.longitude)],
        fillColor: t.colorValue.withValues(alpha: 0.06),
        strokeColor: t.colorValue.withValues(alpha: 0.85),
        strokeWidth: 2,
      ));
    }
    // (The Ameren grid is drawn as native polylines from vector tiles — see
    // _gridPolylines — so it shows statewide at any zoom.)
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

  void _toggleDraw() {
    c.drawMode.value = !c.drawMode.value;
    setState(() {
      _draft.clear();
      _drawPath.clear();
      _isDrawing = false;
    });
    if (c.drawMode.value) {
      // Freehand mapping assumes a flat, north-up view — snap the camera there so
      // the traced loop lands exactly where the finger drew it.
      try {
        _apple?.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: _center, zoom: _zoom, heading: 0, pitch: 0),
        ));
      } catch (_) {}
      _heading.value = 0;
    }
  }

  // ── Freehand drawing surface ─────────────────────────────────────────────────
  /// A transparent gesture+paint layer over the (frozen) map. A raw [Listener]
  /// (not a GestureDetector) reads pointer events directly, so the native map
  /// view can't steal the drag from the gesture arena.
  Widget _drawSurface() {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (ctx, cons) {
          _mapSize = cons.biggest;
          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _onDrawStart,
            onPointerMove: _onDrawMove,
            onPointerUp: _onDrawEnd,
            child: CustomPaint(
              painter: _LassoPainter(_isDrawing ? _drawPath : const [], _accent),
              size: Size.infinite,
            ),
          );
        },
      ),
    );
  }

  void _onDrawStart(PointerDownEvent e) {
    // Grab the exact visible bounds now; the map is frozen while drawing, so this
    // stays valid for the whole stroke (used to map screen px → lat/lng on lift).
    _drawBounds = null;
    _apple?.getVisibleRegion().then((b) {
      _drawBounds = b;
    }).catchError((_) {});
    setState(() {
      _isDrawing = true;
      _draft.clear();
      _drawPath
        ..clear()
        ..add(e.localPosition);
    });
  }

  void _onDrawMove(PointerMoveEvent e) {
    if (!_isDrawing) return;
    final p = e.localPosition;
    // Skip micro-moves so the path stays light (and the repaint stays cheap).
    if (_drawPath.isEmpty || (p - _drawPath.last).distance >= 4) {
      setState(() => _drawPath.add(p));
    }
  }

  Future<void> _onDrawEnd(PointerUpEvent e) async {
    if (!_isDrawing) return;
    _isDrawing = false;
    var b = _drawBounds;
    b ??= await _apple?.getVisibleRegion(); // in case the touch-down fetch lagged
    if (b == null || _drawPath.length < 3 || _mapSize == Size.zero) {
      setState(() => _drawPath.clear());
      return;
    }
    // Simplify the raw finger path (screen space) → a clean, light polygon, then
    // convert every point to a real coordinate. The loop auto-closes (a polygon
    // joins its last point to its first).
    final simplified = _rdp(_drawPath, 4.0);
    final pts = [for (final o in simplified) _screenToLatLng(o, _mapSize, b)];
    setState(() {
      _draft
        ..clear()
        ..addAll(pts);
      _drawPath.clear();
    });
  }

  /// Map a screen point (map-area local px) to a coordinate using the captured
  /// visible bounds. Longitude is linear; latitude uses Web-Mercator so the area
  /// lands precisely on the imagery at any latitude.
  LatLng _screenToLatLng(Offset o, Size size, LatLngBounds b) {
    final fx = (o.dx / size.width).clamp(0.0, 1.0);
    final fy = (o.dy / size.height).clamp(0.0, 1.0);
    final west = b.southwest.longitude, east = b.northeast.longitude;
    final north = b.northeast.latitude, south = b.southwest.latitude;
    final lng = west + fx * (east - west);
    double mercY(double d) => math.log(math.tan(math.pi / 4 + d * math.pi / 360));
    final yTop = mercY(north), yBot = mercY(south);
    final y = yTop + fy * (yBot - yTop);
    final lat = (2 * math.atan(math.exp(y)) - math.pi / 2) * 180 / math.pi;
    return LatLng(lat, lng);
  }

  /// Ramer–Douglas–Peucker simplification (screen space) — turns hundreds of raw
  /// finger samples into a clean handful of polygon vertices.
  List<Offset> _rdp(List<Offset> pts, double eps) {
    if (pts.length < 3) return List.of(pts);
    var dmax = 0.0;
    var idx = 0;
    final end = pts.length - 1;
    for (var i = 1; i < end; i++) {
      final d = _perpDist(pts[i], pts.first, pts[end]);
      if (d > dmax) {
        dmax = d;
        idx = i;
      }
    }
    if (dmax > eps) {
      final left = _rdp(pts.sublist(0, idx + 1), eps);
      final right = _rdp(pts.sublist(idx), eps);
      return [...left.sublist(0, left.length - 1), ...right];
    }
    return [pts.first, pts[end]];
  }

  double _perpDist(Offset p, Offset a, Offset b) {
    final dx = b.dx - a.dx, dy = b.dy - a.dy;
    final len2 = dx * dx + dy * dy;
    if (len2 == 0) return (p - a).distance;
    final t = ((p.dx - a.dx) * dx + (p.dy - a.dy) * dy) / len2;
    final proj = Offset(a.dx + t * dx, a.dy + t * dy);
    return (p - proj).distance;
  }

  // ── Long-press: drop a pin, or (on a drawn area) manage/delete it ────────────
  void _onLongPress(LatLng at) {
    // Admins holding on a drawn area get its actions (incl. Delete); everyone
    // else — and any hold on empty ground — just drops a door pin.
    final t = c.isAdmin ? c.territoryAt(at.latitude, at.longitude) : null;
    if (t != null) {
      _areaActionSheet(t, at);
      return;
    }
    _dropAt(at);
  }

  void _areaActionSheet(CanvassTerritory t, LatLng at) {
    final doors = c.pinsInTerritory(t).length;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 14.r,
                    height: 14.r,
                    decoration: BoxDecoration(
                        color: t.colorValue, shape: BoxShape.circle),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(t.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xff17171C))),
                  ),
                  Text('$doors doors',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xff8A8A96))),
                ],
              ),
              SizedBox(height: 8.h),
              _areaAction(Icons.add_location_alt_rounded, 'Drop a pin here',
                  const Color(0xff17171C), () {
                Navigator.pop(context);
                _dropAt(at);
              }),
              _areaAction(Icons.list_alt_rounded, 'Open area — doors & status',
                  const Color(0xff17171C), () {
                Navigator.pop(context);
                showTerritorySheet(context, t);
              }),
              _areaAction(Icons.delete_outline_rounded, 'Delete this area',
                  const Color(0xffEF4444), () {
                Navigator.pop(context);
                _confirmDeleteArea(t);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _areaAction(IconData icon, String label, Color color, VoidCallback tap) {
    return InkWell(
      onTap: tap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Row(
          children: [
            Icon(icon, size: 21.r, color: color),
            SizedBox(width: 12.w),
            Text(label,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteArea(CanvassTerritory t) {
    Get.defaultDialog(
      title: 'Delete area?',
      middleText:
          'This removes the "${t.name}" area. Doors inside stay on the map.',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xffEF4444),
      onConfirm: () {
        c.deleteTerritory(t);
        Get.back();
      },
    );
  }

  void _clearDraft() => setState(() {
        _draft.clear();
        _drawPath.clear();
      });

  /// Turn the traced loop into a named territory (assign it to reps in the
  /// sheet). Reuses the exact same create flow as the flutter_map build.
  Future<void> _commitDraw() async {
    if (_draft.length < 3) return;
    final pts = [for (final q in _draft) ll.LatLng(q.latitude, q.longitude)];
    final created = await showCreateTerritorySheet(context, pts);
    if (!mounted) return;
    setState(() => _draft.clear());
    if (created == true) c.drawMode.value = false;
  }

  // ── Areas list (deliberate — replaces the annoying tap-to-pop) ──────────────
  void _openAreas() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => SafeArea(
        child: Obx(() {
          final ts = c.territories;
          return Padding(
            padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 14.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Territories',
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xff17171C))),
                    const Spacer(),
                    Text('${ts.length}',
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xff8A8A96))),
                  ],
                ),
                SizedBox(height: 10.h),
                if (ts.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Text(
                      'No areas yet. Tap the ✋ draw button, then drag a loop around a block to circle it.',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 12.5.sp,
                          color: const Color(0xff8A8A96),
                          height: 1.4),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 320.h),
                    child: ListView(
                      shrinkWrap: true,
                      children: [for (final t in ts) _areaRow(t)],
                    ),
                  ),
                if (c.isAdmin) ...[
                  SizedBox(height: 12.h),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      if (!c.drawMode.value) _toggleDraw();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 13.h),
                      decoration: BoxDecoration(
                        color: _brand,
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      child: Center(
                        child: Text('Draw a new area',
                            style: AppFonts.spaceGrotesk.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5.sp)),
                      ),
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

  Widget _areaRow(CanvassTerritory t) {
    final count = c.pinsInTerritory(t).length;
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        final ctr = t.center;
        if (ctr != null) {
          try {
            _apple?.animateCamera(CameraUpdate.newLatLngZoom(
                LatLng(ctr.latitude, ctr.longitude), 14));
          } catch (_) {}
        }
        showTerritorySheet(context, t);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          children: [
            Container(
              width: 14.r,
              height: 14.r,
              decoration:
                  BoxDecoration(color: t.colorValue, shape: BoxShape.circle),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xff17171C))),
                  SizedBox(height: 1.h),
                  Text(t.repLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 11.sp, color: const Color(0xff8A8A96))),
                ],
              ),
            ),
            Text('$count doors',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xff8A8A96))),
          ],
        ),
      ),
    );
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
                    annotations: _annotations(pins, drawing),
                    polygons: _polygons(drawing),
                    polylines: _draftPolylines(drawing),
                    // Freeze the map while drawing so the finger traces the area
                    // instead of panning the map (and the screen→coord mapping
                    // stays fixed for the whole stroke).
                    scrollGesturesEnabled: !drawing,
                    zoomGesturesEnabled: !drawing,
                    rotateGesturesEnabled: !drawing,
                    pitchGesturesEnabled: !drawing,
                    onMapCreated: (ctrl) => _apple = ctrl,
                    onCameraMove: _onCameraMove,
                    onCameraIdle: _onCameraIdle,
                    // Long-press an empty spot drops a door pin; long-press ON a
                    // drawn area (admins) opens its actions incl. Delete.
                    onTap: null,
                    onLongPress: drawing ? null : _onLongPress,
                  );
                }),
                // Ameren grid — transparent RASTER flutter_map over the Apple
                // map, live-synced to its camera. Raster tiles (not the old
                // vector renderer) keep it smooth while panning/zooming.
                Obx(() => c.gridMode.value
                    ? _gridOverlay()
                    : const SizedBox.shrink()),
                // Freehand drawing surface — only present in draw mode. Sits
                // above the map (captures the drag) but below the top bar and
                // toolbar (so their buttons stay tappable).
                Obx(() => c.drawMode.value
                    ? _drawSurface()
                    : const SizedBox.shrink()),
                _topBar(),
                _rightControls(),
                Obx(() =>
                    c.solarMode.value ? _sunBanner() : const SizedBox.shrink()),
                Obx(() =>
                    c.solarMode.value ? _solarLegend() : const SizedBox.shrink()),
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
  Widget _compassButton() => ValueListenableBuilder<double>(
        valueListenable: _heading,
        builder: (_, heading, _) {
          // Hidden when north-up; heading runs 0..360.
          if (heading <= 1 || heading >= 359) return const SizedBox.shrink();
          return Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: GestureDetector(
              onTap: _resetNorth,
              child: Container(
                width: 46.r,
                height: 46.r,
                padding: EdgeInsets.all(5.r),
                decoration: BoxDecoration(
                  color: _brand,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 1),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 5)
                  ],
                ),
                child: Transform.rotate(
                  angle: -heading * math.pi / 180,
                  child: CustomPaint(painter: _CompassRosePainter(_accent)),
                ),
              ),
            ),
          );
        },
      );

  Widget _rightControls() => Positioned(
        right: 10.w,
        top: MediaQuery.of(context).padding.top + 62.h,
        child: Column(
          children: [
            // SalesRabbit-style compass rose — appears when the map is rotated,
            // spins to keep pointing true north, tap snaps back to north-up.
            // (Apple's own native compass stays on too via compassEnabled.)
            _compassButton(),
            _round(_layerIcon(), _openLayerPicker),
            SizedBox(height: 8.h),
            Obx(() => _roundActive(
                Icons.wb_sunny_rounded, c.solarMode.value, _toggleSolar)),
            SizedBox(height: 8.h),
            // ⚡ Ameren grid — toggles the transparent raster grid overlay ON the
            // map (statewide → block level), red→green new-solar capacity.
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
            SizedBox(height: 8.h),
            // Areas list — the deliberate way to open a territory (map taps no
            // longer pop one). "Draw a new area" inside is admin-only.
            _round(Icons.layers_rounded, _openAreas),
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
      c.ensureSolarForVisible(c.visiblePins); // Google per-roof (if key set)
      c.ensureSunlightForVisible(c.visiblePins); // free per-home sun colouring
      c.fetchAreaSun(_center.latitude, _center.longitude);
    } else {
      c.clearAreaSun();
    }
  }

  void _toggleGrid() {
    c.gridMode.value = !c.gridMode.value;
    if (c.gridMode.value) {
      // The overlay mounts this frame; snap it exactly onto the current view
      // once it's attached (calibrate derives the precise zoom from the bounds).
      WidgetsBinding.instance.addPostFrameCallback((_) => _calibrateGrid());
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
                const Icon(Icons.gesture_rounded, color: _accent, size: 20),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    ready
                        ? 'Area drawn. Save it, or redraw to try again.'
                        : 'Press and drag a loop around the block, then lift your '
                            'finger — it closes automatically.',
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
                if (ready) ...[
                  SizedBox(width: 8.w),
                  _drawAction('Redraw', Colors.white.withValues(alpha: 0.15),
                      Colors.white, _clearDraft),
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

  // ── Solar legend (what the coloured homes mean, only in Solar mode) ─────────
  Widget _solarLegend() {
    return Positioned(
      left: 10.w,
      // Stack above the grid legend when both overlays are on.
      bottom: c.gridMode.value ? 96.h : 24.h,
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
                const Icon(Icons.wb_sunny_rounded, color: _accent, size: 13),
                SizedBox(width: 5.w),
                Text('SOLAR POTENTIAL',
                    style: AppFonts.spaceGrotesk.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 9.sp,
                        letterSpacing: 0.5)),
              ],
            ),
            SizedBox(height: 6.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _legendDot(const Color(0xff16A34A), 'Great'),
                SizedBox(width: 9.w),
                _legendDot(const Color(0xffF59E0B), 'OK'),
                SizedBox(width: 9.w),
                _legendDot(const Color(0xffEF4444), 'Low'),
              ],
            ),
            SizedBox(height: 3.h),
            Text('sun for this area · tap a home for detail',
                style: AppFonts.spaceGrotesk
                    .copyWith(color: Colors.white54, fontSize: 7.5.sp)),
          ],
        ),
      ),
    );
  }

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
              ],
            ),
            SizedBox(height: 6.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _legendDot(HcCell.openColor, 'Open'),
                SizedBox(width: 9.w),
                _legendDot(HcCell.limitedColor, 'Some'),
                SizedBox(width: 9.w),
                _legendDot(HcCell.constrainedColor, 'Tight'),
              ],
            ),
            SizedBox(height: 3.h),
            Text('grid capacity for new solar · statewide',
                style: AppFonts.spaceGrotesk
                    .copyWith(color: Colors.white54, fontSize: 7.5.sp)),
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

/// A compact compass rose: red/gold north needle, light south tail, an "N"
/// marker and cardinal ticks — the SalesRabbit-style reset-to-north control.
class _CompassRosePainter extends CustomPainter {
  final Color north;
  _CompassRosePainter(this.north);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    final tick = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final dir = Offset(math.sin(a), -math.cos(a));
      canvas.drawLine(c + dir * (r - 6), c + dir * (r - 2), tick);
    }

    final w = r * 0.32;
    final len = r * 0.60;
    final northPath = ui.Path()
      ..moveTo(c.dx, c.dy - len)
      ..lineTo(c.dx - w, c.dy)
      ..lineTo(c.dx + w, c.dy)
      ..close();
    final southPath = ui.Path()
      ..moveTo(c.dx, c.dy + len)
      ..lineTo(c.dx - w, c.dy)
      ..lineTo(c.dx + w, c.dy)
      ..close();
    canvas.drawPath(southPath, Paint()..color = Colors.white70);
    canvas.drawPath(northPath, Paint()..color = north);
    canvas.drawCircle(c, r * 0.11, Paint()..color = Colors.white);

    final tp = TextPainter(
      text: TextSpan(
        text: 'N',
        style: TextStyle(
          color: north,
          fontSize: r * 0.36,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(c.dx - tp.width / 2, -1));
  }

  @override
  bool shouldRepaint(covariant _CompassRosePainter old) => old.north != north;
}

/// Paints the live freehand stroke (screen space) while the finger is down — an
/// instant, buttery preview of the loop, with a soft fill so it reads as an area.
/// Once you lift, the finished polygon is handed to the map and this clears.
class _LassoPainter extends CustomPainter {
  final List<Offset> path;
  final Color color;
  const _LassoPainter(this.path, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (path.length < 2) return;
    final line = Path()..moveTo(path.first.dx, path.first.dy);
    for (final o in path.skip(1)) {
      line.lineTo(o.dx, o.dy);
    }
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: 0.18);
    canvas.drawPath(Path.from(line)..close(), fill);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(line, stroke);
  }

  @override
  bool shouldRepaint(covariant _LassoPainter old) => old.path != path;
}
