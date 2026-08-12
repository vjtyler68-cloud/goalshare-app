import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import 'package:spanx/core/const/app_fonts.dart';

import '../controller/canvass_controller.dart';
import '../data/canvass_api.dart';
import '../data/canvass_status.dart';
import 'canvass_pin_sheet.dart';

/// Solar Cowboys canvassing map — free satellite tiles (Esri World Imagery),
/// tap anywhere to drop a pin, tap a pin to update its status.
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

  @override
  void initState() {
    super.initState();
    if (c.inOrg) c.load();
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
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _dropAt(LatLng ll) async {
    // Reverse-geocode the address (free, best-effort) before opening the sheet.
    final addr =
        await CanvassApi.instance.reverseGeocode(ll.latitude, ll.longitude);
    if (!mounted) return;
    showCanvassPinSheet(context, dropAt: ll, address: addr);
  }

  @override
  Widget build(BuildContext context) {
    if (!c.inOrg) return _noOrg();
    return Scaffold(
      backgroundColor: _brand,
      body: Stack(
        children: [
          Obx(() {
            final pins = c.visiblePins;
            return FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: _me ?? _fallback,
                initialZoom: _me == null ? 4 : 18,
                maxZoom: 20,
                backgroundColor: _brand,
                onTap: (_, ll) => _dropAt(ll),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom |
                      InteractiveFlag.drag |
                      InteractiveFlag.doubleTapZoom |
                      InteractiveFlag.flingAnimation,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.goal.share',
                  maxNativeZoom: 19,
                ),
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
                MarkerLayer(
                  markers: [
                    for (final p in pins)
                      Marker(
                        point: LatLng(p.lat, p.lng),
                        width: 34,
                        height: 40,
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                          onTap: () => showCanvassPinSheet(context, pin: p),
                          child: Icon(Icons.location_on,
                              color: CanvassStatus.byCode(p.status).color,
                              size: 34,
                              shadows: const [
                                Shadow(color: Colors.black54, blurRadius: 3)
                              ]),
                        ),
                      ),
                  ],
                ),
              ],
            );
          }),
          _topBar(),
          _fabs(),
          _attribution(),
        ],
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
                            Text('Solar Cowboys',
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
                    'Canvassing pins live inside your Solar Cowboys organization. '
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
