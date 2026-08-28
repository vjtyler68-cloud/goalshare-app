import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import 'package:spanx/core/const/app_fonts.dart';

import '../controller/canvass_controller.dart';
import '../data/canvass_api.dart';
import '../data/canvass_pin.dart';
import '../data/canvass_status.dart';
import '../data/canvass_territory.dart';
import 'canvass_pin_sheet.dart';
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

  // Freehand draw state.
  final List<LatLng> _draft = [];
  Offset? _lastLocal;

  @override
  void initState() {
    super.initState();
    if (c.inOrg && c.canUse) c.load();
    _locate();
  }

  Future<void> _locate({bool recenter = true}) async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition()
          .timeout(const Duration(seconds: 8));
      if (!mounted) return;
      setState(() => _me = LatLng(pos.latitude, pos.longitude));
      if (recenter) {
        try {
          _map.move(_me!, 18);
          _zoom = 18;
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _dropAt(LatLng ll) async {
    if (c.drawMode.value) return;
    final addr =
        await CanvassApi.instance.reverseGeocode(ll.latitude, ll.longitude);
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
      );

  List<Widget> _tileLayers() {
    switch (_layer) {
      case _MapLayer.street:
        return [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: _ua,
            maxNativeZoom: 19,
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
          ),
        ];
    }
  }

  // ── Clustering ──────────────────────────────────────────────────────────────
  List<_Cluster> _buildClusters(List<CanvassPin> pins) {
    if (_zoom >= 16 || pins.length <= 1) {
      return [for (final p in pins) _Cluster(p.lat, p.lng, [p])];
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
    return Scaffold(
      backgroundColor: _brand,
      body: Stack(
        children: [
          Obx(() {
            final drawing = c.drawMode.value;
            final pins = c.visiblePins;
            final terrs = c.visibleTerritories;
            final clusters = _buildClusters(pins);
            return FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: _me ?? _fallback,
                initialZoom: _me == null ? 4 : 18,
                maxZoom: 20,
                backgroundColor: _brand,
                onTap: (_, ll) => _dropAt(ll),
                onPositionChanged: (cam, _) {
                  if ((cam.zoom - _zoom).abs() > 0.3) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && (cam.zoom - _zoom).abs() > 0.3) {
                        setState(() => _zoom = cam.zoom);
                      }
                    });
                  }
                },
                interactionOptions: InteractionOptions(
                  flags: drawing
                      ? InteractiveFlag.none
                      : (InteractiveFlag.pinchZoom |
                          InteractiveFlag.drag |
                          InteractiveFlag.doubleTapZoom |
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
                        color: t.colorValue.withOpacity(0.25),
                        borderColor: t.colorValue,
                        borderStrokeWidth: 3,
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
                  PolylineLayer(polylines: [
                    Polyline(points: _draft, color: _accent, strokeWidth: 3),
                  ]),
                if (_me != null)
                  MarkerLayer(markers: [
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
                            BoxShadow(color: Colors.black38, blurRadius: 4)
                          ],
                        ),
                      ),
                    ),
                  ]),
                // Territory labels
                MarkerLayer(
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
                  markers: [
                    for (final cl in clusters)
                      if (cl.count == 1)
                        Marker(
                          point: LatLng(cl.lat, cl.lng),
                          width: 34,
                          height: 40,
                          alignment: Alignment.topCenter,
                          child: GestureDetector(
                            onTap: () => showCanvassPinSheet(context,
                                pin: cl.pins.first),
                            child: Icon(Icons.location_on,
                                color:
                                    CanvassStatus.byCode(cl.pins.first.status)
                                        .color,
                                size: 34,
                                shadows: const [
                                  Shadow(color: Colors.black54, blurRadius: 3)
                                ]),
                          ),
                        )
                      else
                        Marker(
                          point: LatLng(cl.lat, cl.lng),
                          width: _bubbleSize(cl.count),
                          height: _bubbleSize(cl.count),
                          child: GestureDetector(
                            onTap: () => _map.move(LatLng(cl.lat, cl.lng),
                                (_zoom + 2).clamp(4, 20).toDouble()),
                            child: _clusterBubble(cl.count),
                          ),
                        ),
                  ],
                ),
              ],
            );
          }),
          // Freehand draw capture (admin, only while drawing)
          Obx(() => c.drawMode.value
              ? Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    onPanStart: (d) {
                      _draft.clear();
                      _lastLocal = null;
                      _addDraftPoint(d.localPosition);
                    },
                    onPanUpdate: (d) => _addDraftPoint(d.localPosition),
                    onPanEnd: (_) => _finishDraw(),
                  ),
                )
              : const SizedBox.shrink()),
          _topBar(),
          _rightControls(),
          Obx(() => c.drawMode.value ? _drawToolbar() : _fabs()),
          _attribution(),
        ],
      ),
    );
  }

  // ── Freehand drawing ──────────────────────────────────────────────────────
  void _addDraftPoint(Offset local) {
    if (_lastLocal != null && (local - _lastLocal!).distance < 6) return;
    _lastLocal = local;
    try {
      final ll = _map.camera.offsetToCrs(local);
      setState(() => _draft.add(ll));
    } catch (_) {}
  }

  Future<void> _finishDraw() async {
    if (_draft.length < 3) {
      setState(() {
        _draft.clear();
        _lastLocal = null;
      });
      return;
    }
    final pts = List<LatLng>.from(_draft);
    final created = await showCreateTerritorySheet(context, pts);
    if (!mounted) return;
    setState(() {
      _draft.clear();
      _lastLocal = null;
    });
    if (created == true) c.drawMode.value = false;
  }

  void _toggleDraw() {
    c.drawMode.value = !c.drawMode.value;
    setState(() {
      _draft.clear();
      _lastLocal = null;
    });
  }

  Widget _drawToolbar() => Positioned(
        left: 16.w,
        right: 16.w,
        bottom: 26.h,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
              color: _brand.withOpacity(0.92),
              borderRadius: BorderRadius.circular(16.r)),
          child: Row(
            children: [
              const Icon(Icons.gesture_rounded, color: _accent, size: 20),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                    'Drag your finger to trace the area, then lift to name it.',
                    style: AppFonts.spaceGrotesk.copyWith(
                        color: Colors.white, fontSize: 11.5.sp, height: 1.3)),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: _toggleDraw,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(18.r)),
                  child: Text('Cancel',
                      style: AppFonts.spaceGrotesk.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.sp)),
                ),
              ),
            ],
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
        child: Text('$count',
            style: AppFonts.spaceGrotesk.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: count < 100 ? 13.sp : 11.sp)),
      );

  Widget _territoryLabel(CanvassTerritory t) => Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
          decoration: BoxDecoration(
              color: _brand.withOpacity(0.82),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: t.colorValue, width: 1.5)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8.r,
                height: 8.r,
                decoration:
                    BoxDecoration(color: t.colorValue, shape: BoxShape.circle),
              ),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(t.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.spaceGrotesk.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.sp)),
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
            _round(_layerIcon(), _openLayerPicker),
            if (c.isAdmin) ...[
              SizedBox(height: 8.h),
              Obx(() => _roundActive(
                  Icons.gesture_rounded, c.drawMode.value, _toggleDraw)),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8.h),
            _layerOption('Hybrid — satellite + street labels', _MapLayer.hybrid,
                Icons.map_rounded),
            _layerOption('Satellite', _MapLayer.satellite,
                Icons.satellite_alt_rounded),
            _layerOption('Street map — most current 2026 data',
                _MapLayer.street, Icons.map_outlined),
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
      title: Text(label,
          style: AppFonts.spaceGrotesk.copyWith(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xff17171C))),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
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
                        'No areas yet. Tap “Draw area”, trace a block with your finger, then assign it to your reps.',
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 12.5.sp,
                            color: const Color(0xff8A8A96),
                            height: 1.4)),
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
                        borderRadius: BorderRadius.circular(24.r)),
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
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                        color: _brand.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(16.r)),
                    child: Obx(() => Row(
                          children: [
                            const Icon(Icons.wb_sunny_rounded,
                                color: _accent, size: 18),
                            SizedBox(width: 8.w),
                            Text('Sales Ranch',
                                style: AppFonts.spaceGrotesk.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.sp)),
                            const Spacer(),
                            _stat('${c.doorsToday}', 'today'),
                            _stat('${c.apptsTotal}', 'appt'),
                            _stat('${c.salesTotal}', 'sale'),
                          ],
                        )),
                  ),
                ),
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
            Text(v,
                style: AppFonts.spaceGrotesk.copyWith(
                    color: _accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 15.sp,
                    height: 1)),
            Text(l,
                style: AppFonts.spaceGrotesk
                    .copyWith(color: Colors.white70, fontSize: 8.5.sp)),
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
                borderRadius: BorderRadius.circular(18.r)),
            child: Text(label,
                style: AppFonts.spaceGrotesk.copyWith(
                    color: on ? _brand : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp)),
          ),
        ),
      );

  Widget _round(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38.r,
          height: 38.r,
          decoration: BoxDecoration(
              color: _brand.withOpacity(0.85), shape: BoxShape.circle),
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
              shape: BoxShape.circle),
          child: Icon(icon, color: on ? _brand : Colors.white, size: 20.r),
        ),
      );

  Widget _fabs() => Positioned(
        right: 16.w,
        bottom: 30.h,
        child: Column(
          children: [
            FloatingActionButton(
              heroTag: 'canvass_locate',
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () => _locate(),
              child: const Icon(Icons.my_location_rounded, color: _brand),
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
              label: Text('Drop pin',
                  style: AppFonts.spaceGrotesk.copyWith(
                      color: _brand, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );

  Widget _attribution() => Positioned(
        left: 8.w,
        bottom: 6.h,
        child: Text('© Esri, Maxar · OpenStreetMap',
            style: TextStyle(color: Colors.white54, fontSize: 8.5.sp)),
      );

  // ── Stats / leaderboard sheet ───────────────────────────────────────────────
  void _openStats() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
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

  Widget _locked() => Scaffold(
        backgroundColor: _brand,
        appBar: AppBar(
            backgroundColor: _brand,
            elevation: 0,
            leading: IconButton(
                onPressed: Get.back,
                icon: const Icon(Icons.arrow_back, color: Colors.white))),
        body: Center(
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
                        color: Colors.white70, fontSize: 12.5.sp, height: 1.5)),
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
                icon: const Icon(Icons.arrow_back, color: Colors.white))),
        body: Center(
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
                    style: AppFonts.spaceGrotesk
                        .copyWith(color: Colors.white70, fontSize: 12.5.sp, height: 1.5)),
              ],
            ),
          ),
        ),
      );
}

/// A geographic cluster of pins (running centroid).
class _Cluster {
  double sumLat;
  double sumLng;
  final List<CanvassPin> pins;
  _Cluster(double lat, double lng, this.pins)
      : sumLat = lat,
        sumLng = lng;

  double get lat => sumLat / pins.length;
  double get lng => sumLng / pins.length;
  int get count => pins.length;
}
