import 'dart:async';
import 'dart:math' as math;
// dart:ui prefixed — `Path` collides with latlong2's Path and `TextDirection`
// with intl's, so the compass painter reaches for the canvas ones explicitly.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import 'package:spanx/core/const/app_fonts.dart';

import 'package:spanx/features/orgs/ui/territory_metrics_bar.dart';

import '../controller/canvass_controller.dart';
import '../data/cached_tile_provider.dart';
import '../data/canvass_api.dart';
import '../data/canvass_pin.dart';
import '../data/canvass_status.dart';
import '../data/canvass_territory.dart';
import 'canvass_pin_sheet.dart';
import 'canvass_pipeline_screen.dart';
import 'canvass_territory_sheet.dart';

enum _MapLayer { hybrid, satellite, street }

/// Solar Cowboys canvassing map — free satellite tiles (Esri World Imagery),
/// tap anywhere to drop a pin, tap a pin to update its status, and (admin)
/// trace territories to hand whole areas to reps.
class CanvassMapScreen extends StatefulWidget {
  const CanvassMapScreen({super.key});

  @override
  State<CanvassMapScreen> createState() => _CanvassMapScreenState();
}

class _CanvassMapScreenState extends State<CanvassMapScreen> {
  static const _brand = Color(0xff0F172A);
  static const _accent = Color(0xffF59E0B); // Solar gold

  final CanvassController c = CanvassController.to;
  final MapController _map = MapController();
  LatLng? _me;
  static const LatLng _fallback = LatLng(39.5, -98.35); // US center

  _MapLayer _layer = _MapLayer.hybrid;
  double _zoom = 4;
  double _rotation = 0; // map bearing in degrees (0 = north up)

  // Freehand draw state.
  final List<LatLng> _draft = [];
  Offset? _lastLocal;

  // Live location tracking.
  StreamSubscription<Position>? _posSub;
  bool _following = true; // keep the map centered on the rep as they move
  double? _accuracy; // GPS accuracy in metres (the "radius" around the dot)

  /// Ticks on every GPS update so ONLY the location dot + accuracy ring rebuild
  /// (not the tiles or the hundreds of door markers). This is what keeps the
  /// map lag-free while walking — no full-tree rebuild every few metres.
  final ValueNotifier<int> _gps = ValueNotifier<int>(0);

  // Request high-DPI ("retina") tiles on 2x/3x screens for crisp 4K imagery.
  bool _retina = false;

  @override
  void initState() {
    super.initState();
    // Only fetch the first time — don't auto-reload every time we come back to
    // the screen (or the app resumes). Pins stay cached; use the refresh button
    // for fresh data.
    if (c.inOrg && c.canUse && c.pins.isEmpty) c.load();
    _startTracking();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _gps.dispose();
    super.dispose();
  }

  /// Get a quick fix, then follow the rep live so they always see where they
  /// are. The map re-centers on each update while [_following] is on.
  Future<void> _startTracking() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      // Start from the device's cached fix instead of loading the US overview
      // while the fresh GPS request is still resolving.
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        _applyPosition(lastKnown, recenter: true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _me == null) return;
          try {
            _map.move(_me!, 18);
          } catch (_) {}
        });
      }
      // Fast first fix so the dot appears quickly.
      try {
        final pos = await Geolocator.getCurrentPosition()
            .timeout(const Duration(seconds: 8));
        _applyPosition(pos, recenter: true);
      } catch (_) {}
      // Then follow the live stream.
      _posSub?.cancel();
      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 4,
        ),
      ).listen((pos) => _applyPosition(pos, recenter: _following));
    } catch (_) {}
  }

  void _applyPosition(Position pos, {required bool recenter}) {
    if (!mounted) return;
    _me = LatLng(pos.latitude, pos.longitude);
    _accuracy = pos.accuracy;
    // Repaint ONLY the location dot + accuracy ring — never the whole map. A
    // full setState here every 4 metres was the walking-lag culprit.
    _gps.value++;
    if (recenter) {
      try {
        _map.move(_me!, _zoom < 15 ? 18 : _zoom);
      } catch (_) {}
    }
  }

  /// Re-center on the rep and resume following (the locate button).
  void _recenterOnMe() {
    setState(() => _following = true);
    if (_me != null) {
      try {
        _map.move(_me!, _zoom < 15 ? 18 : _zoom);
      } catch (_) {}
    } else {
      _startTracking();
    }
  }

  Future<void> _dropAt(LatLng ll) async {
    if (c.drawMode.value) return;
    final addr = await CanvassApi.instance.reverseGeocode(
      ll.latitude,
      ll.longitude,
    );
    if (!mounted) return;
    showCanvassPinSheet(context, dropAt: ll, address: addr);
  }

  // ── Tiles / layers ──────────────────────────────────────────────────────────
  static const _ua = 'com.goal.share';

  TileLayer _esri() => TileLayer(
    urlTemplate:
        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    userAgentPackageName: _ua,
    maxNativeZoom: 19,
    // High-DPI imagery on 2x/3x phones — sharper, "4K" satellite view.
    retinaMode: _retina,
    // Keep more off-screen tiles in memory so panning back is instant (no
    // reload flashes) and the map feels quicker.
    keepBuffer: 5,
    panBuffer: 1,
    evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
    // Disk-cache tiles so viewed ground still renders with no signal.
    tileProvider: CachedTileProvider(headers: const {'User-Agent': _ua}),
  );

  List<Widget> _tileLayers() {
    switch (_layer) {
      case _MapLayer.street:
        return [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: _ua,
            maxNativeZoom: 19,
            retinaMode: _retina,
            keepBuffer: 5,
            panBuffer: 1,
            evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
            tileProvider:
                CachedTileProvider(headers: const {'User-Agent': _ua}),
          ),
        ];
      case _MapLayer.satellite:
        return [_esri()];
      case _MapLayer.hybrid:
        return [
          _esri(),
          TileLayer(
            urlTemplate:
                'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}',
            userAgentPackageName: _ua,
            maxNativeZoom: 19,
            retinaMode: _retina,
            keepBuffer: 5,
            panBuffer: 1,
            evictErrorTileStrategy: EvictErrorTileStrategy.dispose,
            tileProvider:
                CachedTileProvider(headers: const {'User-Agent': _ua}),
          ),
        ];
    }
  }

  // ── Clustering ──────────────────────────────────────────────────────────────
  List<_Cluster> _buildClusters(List<CanvassPin> pins) {
    if (_zoom >= 16 || pins.length <= 1) {
      return [
        for (final p in pins) _Cluster(p.lat, p.lng, [p]),
      ];
    }
    final cell = 0.9 / math.pow(2, _zoom - 3); // degrees per grid cell
    final buckets = <String, _Cluster>{};
    for (final p in pins) {
      final gx = (p.lng / cell).floor();
      final gy = (p.lat / cell).floor();
      final key = '$gx:$gy';
      final b = buckets[key];
      if (b == null) {
        buckets[key] = _Cluster(p.lat, p.lng, [p]);
      } else {
        b.pins.add(p);
        b.sumLat += p.lat;
        b.sumLng += p.lng;
      }
    }
    return buckets.values.toList();
  }

  double _bubbleSize(int count) {
    if (count < 10) return 30;
    if (count < 100) return 40;
    if (count < 1000) return 50;
    return 60;
  }

  @override
  Widget build(BuildContext context) {
    if (!c.inOrg) return _noOrg();
    if (!c.canUse) return _locked();
    _retina = MediaQuery.of(context).devicePixelRatio > 1.3;
    return Scaffold(
      backgroundColor: _brand,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
          Obx(() {
            final drawing = c.drawMode.value;
            final pins = c.visiblePins;
            final terrs = c.visibleTerritories;
            final clusters = _buildClusters(pins);
            // Solar mode: auto-fill roof solar-fit for the doors on screen.
            if (c.solarMode.value) {
              WidgetsBinding.instance.addPostFrameCallback(
                  (_) => c.ensureSolarForVisible(pins));
            }
            final route = c.breadcrumbOn.value
                ? c.todayRoute(c.breadcrumbRepId)
                : const <({CanvassPin pin, DateTime at})>[];
            return FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: _me ?? _fallback,
                initialZoom: _me == null ? 4 : 18,
                // Retina mode uses native z19 imagery at display z18. Going
                // farther only stretches those pixels and looks blurry.
                maxZoom: 18,
                backgroundColor: _brand,
                onTap: (_, ll) => _dropAt(ll),
                onPositionChanged: (cam, hasGesture) {
                  // A manual pan/zoom stops auto-follow so the rep can look
                  // around; the locate button resumes it.
                  if (hasGesture && _following) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _following = false);
                    });
                  }
                  final zoomChanged = (cam.zoom - _zoom).abs() > 0.3;
                  final rotChanged = (cam.rotation - _rotation).abs() > 1;
                  if (zoomChanged || rotChanged) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() {
                        _zoom = cam.zoom;
                        _rotation = cam.rotation;
                      });
                    });
                  }
                },
                interactionOptions: InteractionOptions(
                  // Two-finger rotate lets reps spin the map 360° to see homes
                  // from any angle / face their direction of travel.
                  flags: drawing
                      ? InteractiveFlag.none
                      : (InteractiveFlag.pinchZoom |
                            InteractiveFlag.pinchMove |
                            InteractiveFlag.drag |
                            InteractiveFlag.doubleTapZoom |
                            InteractiveFlag.rotate |
                            InteractiveFlag.flingAnimation),
                ),
              ),
              children: [
                ..._tileLayers(),
                // Territory areas
                PolygonLayer(
                  polygons: [
                    for (final t in terrs)
                      Polygon(
                        points: t.points,
                        color: t.colorValue.withValues(alpha: 0.04),
                        borderColor: t.colorValue.withValues(alpha: 0.72),
                        borderStrokeWidth: 1.5,
                      ),
                    if (_draft.length >= 3)
                      Polygon(
                        points: _draft,
                        color: _accent.withOpacity(0.2),
                        borderColor: _accent,
                        borderStrokeWidth: 3,
                      ),
                  ],
                ),
                if (drawing && _draft.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(points: _draft, color: _accent, strokeWidth: 3),
                    ],
                  ),
                // Route breadcrumb — today's stops in order.
                if (route.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [
                          for (final s in route) LatLng(s.pin.lat, s.pin.lng),
                        ],
                        color: const Color(0xff38BDF8),
                        strokeWidth: 3.5,
                      ),
                    ],
                  ),
                if (route.isNotEmpty)
                  MarkerLayer(
                    rotate: true, // keep pins/labels upright as the map rotates
                    markers: [
                      for (var i = 0; i < route.length; i++)
                        Marker(
                          point: LatLng(route[i].pin.lat, route[i].pin.lng),
                          width: 20,
                          height: 20,
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xff0EA5E9),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                // Live GPS accuracy radius + rep dot. Wrapped in their own
                // ValueListenableBuilders so a position update repaints ONLY
                // these two layers — the tiles and door markers stay put.
                ValueListenableBuilder<int>(
                  valueListenable: _gps,
                  builder: (_, _, _) {
                    if (_me == null || _accuracy == null) {
                      return const SizedBox.shrink();
                    }
                    return CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _me!,
                          radius: _accuracy!.clamp(8, 120).toDouble(),
                          useRadiusInMeter: true,
                          color: Colors.blueAccent.withOpacity(0.12),
                          borderColor: Colors.blueAccent.withOpacity(0.4),
                          borderStrokeWidth: 1,
                        ),
                      ],
                    );
                  },
                ),
                ValueListenableBuilder<int>(
                  valueListenable: _gps,
                  builder: (_, _, _) {
                    if (_me == null) return const SizedBox.shrink();
                    return MarkerLayer(
                      rotate: true, // keep the dot upright as the map rotates
                      markers: [
                        Marker(
                          point: _me!,
                          width: 22,
                          height: 22,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(color: Colors.black38, blurRadius: 4),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                // Territory labels
                MarkerLayer(
                  rotate: true, // keep pins/labels upright as the map rotates
                  markers: [
                    for (final t in terrs)
                      if (t.center != null)
                        Marker(
                          point: t.center!,
                          width: 150,
                          height: 30,
                          child: GestureDetector(
                            onTap: () => showTerritorySheet(context, t),
                            child: _territoryLabel(t),
                          ),
                        ),
                  ],
                ),
                // Pins / clusters
                MarkerLayer(
                  rotate: true, // keep pins/labels upright as the map rotates
                  markers: [
                    for (final cl in clusters)
                      if (cl.count == 1)
                        Marker(
                          point: LatLng(cl.lat, cl.lng),
                          width: 44,
                          height: 58,
                          alignment: Alignment.bottomCenter,
                          child: GestureDetector(
                            onTap: () => showCanvassPinSheet(
                              context,
                              pin: cl.pins.first,
                            ),
                            child: _homeMarker(cl.pins.first),
                          ),
                        )
                      else
                        Marker(
                          point: LatLng(cl.lat, cl.lng),
                          width: _bubbleSize(cl.count),
                          height: _bubbleSize(cl.count),
                          child: GestureDetector(
                            onTap: () => _map.move(
                              LatLng(cl.lat, cl.lng),
                              (_zoom + 2).clamp(4, 19).toDouble(),
                            ),
                            child: _clusterBubble(cl.count),
                          ),
                        ),
                  ],
                ),
              ],
            );
          }),
          // Freehand draw capture (admin, only while drawing)
          Obx(
            () => c.drawMode.value
                ? Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                      onPanStart: (d) {
                        // Don't wipe the outline — append. Trace the area in as
                        // many swipes as you want, lifting between passes.
                        _lastLocal = null;
                        _addDraftPoint(d.localPosition);
                      },
                      onPanUpdate: (d) => _addDraftPoint(d.localPosition),
                      onPanEnd: (_) => setState(() => _lastLocal = null),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          _topBar(),
          Obx(() {
            if (c.loading.value) {
              return Positioned(
                top: MediaQuery.of(context).padding.top + 112.h,
                left: 18.w,
                right: 18.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: 9.h,
                    horizontal: 12.w,
                  ),
                  decoration: BoxDecoration(
                    color: _brand.withOpacity(.9),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14.r,
                        height: 14.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _accent,
                        ),
                      ),
                      SizedBox(width: 9.w),
                      Text(
                        'Syncing doors and territories…',
                        style: AppFonts.spaceGrotesk.copyWith(
                          color: Colors.white,
                          fontSize: 11.5.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (c.loadError.value != null) {
              return Positioned(
                left: 18.w,
                right: 18.w,
                bottom: 92.h,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xffFFF7ED),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          color: Color(0xffC2410C),
                          size: 19,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            c.loadError.value!,
                            style: AppFonts.spaceGrotesk.copyWith(
                              color: const Color(0xff7C2D12),
                              fontSize: 11.5.sp,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: c.load,
                          child: Text(
                            'Retry',
                            style: AppFonts.spaceGrotesk.copyWith(
                              color: const Color(0xff9A3412),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          _rightControls(),
          Obx(() => c.drawMode.value ? _drawToolbar() : _fabs()),
          Obx(
            () =>
                c.breadcrumbOn.value ? _routeFooter() : const SizedBox.shrink(),
          ),
          _attribution(),
              ],
            ),
          ),
          // Door-knock goal tracker — Doors / Talked / Bills + live compass,
          // in sync with the Metrics tab. Kept at the bottom of Sales Ranch.
          const TerritoryMetricsBar(),
        ],
      ),
    );
  }

  // ── Freehand drawing ──────────────────────────────────────────────────────
  void _addDraftPoint(Offset local) {
    // Sample finely so the outline hugs the finger (smooth curves, not stiff
    // angular jumps).
    if (_lastLocal != null && (local - _lastLocal!).distance < 3) return;
    _lastLocal = local;
    try {
      final ll = _map.camera.offsetToCrs(local);
      setState(() => _draft.add(ll));
    } catch (_) {}
  }

  /// Turn the traced outline into a named territory (explicit — never on lift).
  Future<void> _commitDraw() async {
    if (_draft.length < 3) return;
    final pts = List<LatLng>.from(_draft);
    final created = await showCreateTerritorySheet(context, pts);
    if (!mounted) return;
    setState(() {
      _draft.clear();
      _lastLocal = null;
    });
    if (created == true) c.drawMode.value = false;
  }

  void _redoDraw() => setState(() {
        _draft.clear();
        _lastLocal = null;
      });

  void _toggleDraw() {
    c.drawMode.value = !c.drawMode.value;
    setState(() {
      _draft.clear();
      _lastLocal = null;
    });
  }

  Future<void> _loadHomes() async {
    final at = _me ?? _map.camera.center;
    Get.rawSnackbar(
      message: 'Loading homes in this area…',
      duration: const Duration(seconds: 2),
      margin: EdgeInsets.all(12.r),
      borderRadius: 12,
      backgroundColor: _brand,
    );
    final n = await c.seedHomes(lat: at.latitude, lng: at.longitude);
    Get.rawSnackbar(
      message: n > 0
          ? 'Added $n homes — tap any to work it'
          : 'No new homes found in this area',
      duration: const Duration(seconds: 3),
      margin: EdgeInsets.all(12.r),
      borderRadius: 12,
      backgroundColor: _brand,
    );
  }

  Widget _drawToolbar() {
    final ready = _draft.length >= 3;
    return Positioned(
      left: 16.w,
      right: 16.w,
      bottom: 26.h,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: _brand.withOpacity(0.92),
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
                        ? 'Nice. Swipe again to extend it, redo, or save the area.'
                        : 'Trace the area with your finger — swipe as many times as you need to shape it.',
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
                _drawAction(
                    'Cancel', Colors.white.withOpacity(0.15), Colors.white,
                    _toggleDraw),
                if (_draft.isNotEmpty) ...[
                  SizedBox(width: 8.w),
                  _drawAction('Redo', Colors.white.withOpacity(0.15),
                      Colors.white, _redoDraw),
                ],
                const Spacer(),
                if (ready) _drawAction('Save area', _accent, _brand, _commitDraw),
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

  void _toggleSolar() {
    c.solarMode.value = !c.solarMode.value;
    if (c.solarMode.value) c.ensureSolarForVisible(c.visiblePins);
  }

  /// A door's marker colour — by roof solar-fit in Solar mode, else by status.
  Color _pinColor(CanvassPin p) {
    if (c.solarMode.value) {
      final s = p.solar;
      if (s == null) return const Color(0xff94A3B8); // grey — unknown / loading
      switch (s.fit) {
        case 'good':
          return const Color(0xff22C55E);
        case 'ok':
          return const Color(0xffF59E0B);
        default:
          return const Color(0xffEF4444);
      }
    }
    return CanvassStatus.byCode(p.status).color;
  }

  Widget _homeMarker(CanvassPin pin) {
    final emoji = CanvassStatus.emojiFor(pin.status);
    return SizedBox(
      width: 44.r,
      height: 58.r,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Icon(
            Icons.location_on,
            color: _pinColor(pin),
            size: 36.r,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 3)],
          ),
          if (emoji.isNotEmpty)
            Positioned(
              top: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.r, vertical: 2.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: CanvassStatus.byCode(pin.status).color,
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  emoji,
                  style: TextStyle(fontSize: 17.sp, height: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Compass that snaps the map back to north. The needle points to true north
  /// as the map rotates; tapping resets the bearing to 0.
  /// A real compass rose — not a bare arrow. The card spins so the red/gold
  /// north needle always points to true north as the map rotates; tap snaps the
  /// map back to north-up.
  Widget _resetNorthButton() => GestureDetector(
        onTap: () {
          try {
            _map.rotate(0);
          } catch (_) {}
          setState(() => _rotation = 0);
        },
        child: Container(
          width: 46.r,
          height: 46.r,
          padding: EdgeInsets.all(5.r),
          decoration: BoxDecoration(
            color: _brand,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 1),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 5)],
          ),
          child: Transform.rotate(
            angle: -_rotation * math.pi / 180,
            child: CustomPaint(painter: _CompassRosePainter(_accent)),
          ),
        ),
      );

  Widget _clusterBubble(int count) => Container(
    decoration: BoxDecoration(
      color: _brand,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
    ),
    alignment: Alignment.center,
    child: Text(
      '$count',
      style: AppFonts.spaceGrotesk.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: count < 100 ? 13.sp : 11.sp,
      ),
    ),
  );

  Widget _territoryLabel(CanvassTerritory t) => Center(
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _brand.withOpacity(0.82),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: t.colorValue, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8.r,
            height: 8.r,
            decoration: BoxDecoration(
              color: t.colorValue,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              t.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.spaceGrotesk.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11.sp,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  // ── Right-side controls: layers, draw (admin), areas (admin) ────────────────
  Widget _rightControls() => Positioned(
    right: 10.w,
    top: MediaQuery.of(context).padding.top + 62.h,
    child: Column(
      children: [
        // Reset-to-north compass — only while the map is rotated.
        if (_rotation.abs() > 1) ...[
          _resetNorthButton(),
          SizedBox(height: 8.h),
        ],
        _round(_layerIcon(), _openLayerPicker),
        SizedBox(height: 8.h),
        // Solar mode — colours doors by roof solar-fit.
        Obx(() =>
            _roundActive(Icons.wb_sunny_rounded, c.solarMode.value, _toggleSolar)),
        SizedBox(height: 8.h),
        Obx(
          () => _roundActive(
            Icons.filter_alt_rounded,
            c.statusFilter.value != null || c.repFilter.value != null,
            _openFilters,
          ),
        ),
        SizedBox(height: 8.h),
        _round(
          Icons.view_list_rounded,
          () => Get.to(() => const CanvassPipelineScreen()),
        ),
        SizedBox(height: 8.h),
        Obx(
          () => _roundActive(
            Icons.route_rounded,
            c.breadcrumbOn.value,
            () => c.breadcrumbOn.toggle(),
          ),
        ),
        if (c.isAdmin) ...[
          SizedBox(height: 8.h),
          Obx(
            () => c.seeding.value
                ? _round(Icons.hourglass_top_rounded, () {})
                : _round(Icons.maps_home_work_rounded, _loadHomes),
          ),
          SizedBox(height: 8.h),
          Obx(
            () => _roundActive(
              Icons.gesture_rounded,
              c.drawMode.value,
              _toggleDraw,
            ),
          ),
          SizedBox(height: 8.h),
          _round(Icons.layers_rounded, _openAreas),
        ],
      ],
    ),
  );

  IconData _layerIcon() {
    switch (_layer) {
      case _MapLayer.hybrid:
        return Icons.map_rounded;
      case _MapLayer.satellite:
        return Icons.satellite_alt_rounded;
      case _MapLayer.street:
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
            _layerOption(
              'Hybrid — satellite + street labels',
              _MapLayer.hybrid,
              Icons.map_rounded,
            ),
            _layerOption(
              'Satellite',
              _MapLayer.satellite,
              Icons.satellite_alt_rounded,
            ),
            _layerOption('Street map', _MapLayer.street, Icons.map_outlined),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }

  Widget _layerOption(String label, _MapLayer layer, IconData icon) {
    final on = _layer == layer;
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
        setState(() => _layer = layer);
        Navigator.pop(context);
      },
    );
  }

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
                    Text(
                      'Territories',
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xff17171C),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${ts.length}',
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xff8A8A96),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                if (ts.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Text(
                      'No areas yet. Tap “Draw area”, trace a block with your finger, then assign it to your reps.',
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 12.5.sp,
                        color: const Color(0xff8A8A96),
                        height: 1.4,
                      ),
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
                      child: Text(
                        'Draw a new area',
                        style: AppFonts.spaceGrotesk.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5.sp,
                        ),
                      ),
                    ),
                  ),
                ),
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
            _map.move(ctr, 14);
            _zoom = 14;
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
              decoration: BoxDecoration(
                color: t.colorValue,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xff17171C),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    t.repLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 11.sp,
                      color: const Color(0xff8A8A96),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$count doors',
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xff8A8A96),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top overlay: title, stats, admin rep filter ─────────────────────────────
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
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: _brand.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Obx(
                      () => Row(
                        children: [
                          const Icon(
                            Icons.wb_sunny_rounded,
                            color: _accent,
                            size: 18,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Sales Ranch',
                            style: AppFonts.spaceGrotesk.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14.sp,
                            ),
                          ),
                          const Spacer(),
                          _stat('${c.doorsToday}', 'today'),
                          _stat('${c.apptsTotal}', 'appt'),
                          _stat('${c.salesTotal}', 'sale'),
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
                      _repChip(
                        'All reps',
                        c.repFilter.value == null,
                        () => c.repFilter.value = null,
                      ),
                      for (final r in reps)
                        _repChip(
                          r.name,
                          c.repFilter.value == r.id,
                          () => c.repFilter.value = r.id,
                        ),
                    ],
                  ),
                );
              }),
            // Offline / sync status — only visible when there's something to say.
            Obx(() {
              final off = c.offline.value;
              final n = c.pendingCount.value;
              if (!off && n == 0) return const SizedBox.shrink();
              final plural = n == 1 ? '' : 's';
              return Container(
                margin: EdgeInsets.only(top: 8.h),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: (off ? const Color(0xffB45309) : const Color(0xff0F172A))
                      .withOpacity(0.94),
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
                    if (!off && n > 0)
                      SizedBox(
                        width: 12.r,
                        height: 12.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
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
    padding: EdgeInsets.only(left: 10.w),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          v,
          style: AppFonts.spaceGrotesk.copyWith(
            color: _accent,
            fontWeight: FontWeight.w900,
            fontSize: 15.sp,
            height: 1,
          ),
        ),
        Text(
          l,
          style: AppFonts.spaceGrotesk.copyWith(
            color: Colors.white70,
            fontSize: 8.5.sp,
          ),
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
          color: on ? _accent : _brand.withOpacity(0.85),
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

  Widget _round(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38.r,
      height: 38.r,
      decoration: BoxDecoration(
        color: _brand.withOpacity(0.85),
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
            color: on ? _accent : _brand.withOpacity(0.85),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: on ? _brand : Colors.white, size: 20.r),
        ),
      );

  Widget _fabs() => Positioned(
    right: 16.w,
    bottom: c.breadcrumbOn.value ? 130.h : 30.h,
    child: Column(
      children: [
        FloatingActionButton(
          heroTag: 'canvass_locate',
          mini: true,
          backgroundColor: _following ? _accent : Colors.white,
          onPressed: _recenterOnMe,
          child: Icon(Icons.my_location_rounded,
              color: _following ? Colors.white : _brand),
        ),
        SizedBox(height: 12.h),
        FloatingActionButton.extended(
          heroTag: 'canvass_drop',
          backgroundColor: _accent,
          onPressed: () {
            final at = _me ?? _map.camera.center;
            _dropAt(at);
          },
          icon: const Icon(Icons.add_location_alt_rounded, color: _brand),
          label: Text(
            'Drop pin',
            style: AppFonts.spaceGrotesk.copyWith(
              color: _brand,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );

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
                    Text(
                      'Map filters',
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w900,
                        color: _brand,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${c.visiblePins.length} doors',
                      style: AppFonts.spaceGrotesk.copyWith(
                        color: const Color(0xff8A8A96),
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5.h),
                Text(
                  'Filter pins and clusters without changing ownership.',
                  style: AppFonts.spaceGrotesk.copyWith(
                    color: const Color(0xff8A8A96),
                    fontSize: 11.5.sp,
                  ),
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
                  Text(
                    'REP',
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xff8A8A96),
                      letterSpacing: .6,
                    ),
                  ),
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
                              r.name,
                              c.repFilter.value == r.id,
                              () {
                                c.repFilter.value = r.id;
                                Navigator.pop(context);
                              },
                            ),
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
              color: selected ? _accent : const Color(0xffE1E5EA),
            ),
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

  // ── Route breadcrumb footer ─────────────────────────────────────────────────
  Widget _routeFooter() {
    final route = c.todayRoute(c.breadcrumbRepId);
    final fmt = DateFormat('h:mm a');
    final started = route.isEmpty ? '—' : fmt.format(route.first.at.toLocal());
    final ended = route.isEmpty ? '—' : fmt.format(route.last.at.toLocal());
    return Positioned(
      left: 10.w,
      right: 10.w,
      bottom: 12.h,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: _brand.withOpacity(0.92),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.route_rounded,
                  color: Color(0xff38BDF8),
                  size: 16,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Today’s route · ${route.length} stops',
                  style: AppFonts.spaceGrotesk.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5.sp,
                  ),
                ),
                const Spacer(),
                Text(
                  '$started – $ended',
                  style: AppFonts.spaceGrotesk.copyWith(
                    color: Colors.white70,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
            if (route.isEmpty)
              Padding(
                padding: EdgeInsets.only(top: 6.h),
                child: Text(
                  'No stops logged today yet.',
                  style: AppFonts.spaceGrotesk.copyWith(
                    color: Colors.white70,
                    fontSize: 10.5.sp,
                  ),
                ),
              )
            else ...[
              SizedBox(height: 8.h),
              SizedBox(
                height: 42.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: route.length,
                  separatorBuilder: (_, __) => SizedBox(width: 6.w),
                  itemBuilder: (_, i) {
                    final s = route[i];
                    final st = CanvassStatus.byCode(s.pin.status);
                    return GestureDetector(
                      onTap: () {
                        try {
                          _map.move(LatLng(s.pin.lat, s.pin.lng), 18);
                          _zoom = 18;
                        } catch (_) {}
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 26.r,
                            height: 26.r,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: st.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            fmt.format(s.at.toLocal()),
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 7.sp,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _attribution() => Positioned(
    left: 8.w,
    bottom: 6.h,
    child: Text(
      '© Esri, Maxar · OpenStreetMap',
      style: TextStyle(color: Colors.white54, fontSize: 8.5.sp),
    ),
  );

  // ── Stats / leaderboard sheet ───────────────────────────────────────────────
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
                Text(
                  c.isAdmin ? 'Team leaderboard' : 'My numbers',
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
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
                          Text(
                            '${e.key + 1}',
                            style: AppFonts.spaceGrotesk.copyWith(
                              fontWeight: FontWeight.w900,
                              color: _accent,
                              fontSize: 14.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              r.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.spaceGrotesk.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                          Text(
                            '${r.doors} · ${r.appts} · ${r.sales}',
                            style: AppFonts.spaceGrotesk.copyWith(
                              color: const Color(0xff8A8A96),
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  SizedBox(height: 4.h),
                  Text(
                    'doors · appts · sales',
                    style: AppFonts.spaceGrotesk.copyWith(
                      color: const Color(0xff8A8A96),
                      fontSize: 10.sp,
                    ),
                  ),
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
        Text(
          v,
          style: AppFonts.spaceGrotesk.copyWith(
            fontSize: 24.sp,
            fontWeight: FontWeight.w900,
            color: _brand,
          ),
        ),
        Text(
          l,
          style: AppFonts.spaceGrotesk.copyWith(
            fontSize: 11.sp,
            color: const Color(0xff8A8A96),
          ),
        ),
      ],
    ),
  );

  Widget _locked() => Scaffold(
    backgroundColor: _brand,
    appBar: AppBar(
      backgroundColor: _brand,
      elevation: 0,
      leading: IconButton(
        onPressed: Get.back,
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
    ),
    body: Center(
      child: Padding(
        padding: EdgeInsets.all(30.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded, color: _accent, size: 52),
            SizedBox(height: 14.h),
            Text(
              'Sales Ranch isn’t open yet',
              textAlign: TextAlign.center,
              style: AppFonts.spaceGrotesk.copyWith(
                color: Colors.white,
                fontSize: 17.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Your team admin hasn’t opened Sales Ranch to the team yet. '
              'Check back once they turn it on.',
              textAlign: TextAlign.center,
              style: AppFonts.spaceGrotesk.copyWith(
                color: Colors.white70,
                fontSize: 12.5.sp,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _noOrg() => Scaffold(
    backgroundColor: _brand,
    appBar: AppBar(
      backgroundColor: _brand,
      elevation: 0,
      leading: IconButton(
        onPressed: Get.back,
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
    ),
    body: Center(
      child: Padding(
        padding: EdgeInsets.all(30.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wb_sunny_rounded, color: _accent, size: 52),
            SizedBox(height: 14.h),
            Text(
              'Join your sales team first',
              textAlign: TextAlign.center,
              style: AppFonts.spaceGrotesk.copyWith(
                color: Colors.white,
                fontSize: 17.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Sales Ranch lives inside your sales team’s organization. '
              'Join or create it, then come back to start knocking.',
              textAlign: TextAlign.center,
              style: AppFonts.spaceGrotesk.copyWith(
                color: Colors.white70,
                fontSize: 12.5.sp,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A compact compass rose: red/gold north needle, light south tail, an "N"
/// marker and cardinal ticks — reads unmistakably as a compass at a glance.
class _CompassRosePainter extends CustomPainter {
  final Color north;
  _CompassRosePainter(this.north);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Cardinal ticks (N/E/S/W).
    final tick = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final dir = Offset(math.sin(a), -math.cos(a));
      canvas.drawLine(c + dir * (r - 6), c + dir * (r - 2), tick);
    }

    // Two-tone needle.
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

    // "N" marker at the top of the rose.
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

/// A geographic cluster of pins (running centroid).
class _Cluster {
  double sumLat;
  double sumLng;
  final List<CanvassPin> pins;
  _Cluster(double lat, double lng, this.pins) : sumLat = lat, sumLng = lng;

  double get lat => sumLat / pins.length;
  double get lng => sumLng / pins.length;
  int get count => pins.length;
}
