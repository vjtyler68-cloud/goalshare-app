import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import 'package:spanx/features/orgs/controller/org_controller.dart';

import '../data/canvass_api.dart';
import '../data/canvass_pin.dart';
import '../data/canvass_status.dart';
import '../data/canvass_territory.dart';
import '../data/property_detail.dart';

/// Drives the Solar Cowboys canvassing map. Pins live on the backend, scoped by
/// the user's role in their current org (admin → every rep's pins, rep → only
/// their own — enforced server-side). Reads the active org from [OrgController].
class CanvassController extends GetxController {
  static CanvassController get to => Get.isRegistered<CanvassController>()
      ? Get.find<CanvassController>()
      : Get.put(CanvassController(), permanent: true);

  final RxList<CanvassPin> pins = <CanvassPin>[].obs;
  final RxList<CanvassTerritory> territories = <CanvassTerritory>[].obs;
  final RxBool loading = false.obs;

  /// Admin only: freehand area-drawing mode is active.
  final RxBool drawMode = false.obs;

  /// Admin only: filter the map to one rep (null = show everyone).
  final RxnString repFilter = RxnString();

  String? get orgId => OrgController.to.myOrg.value?.id;
  bool get isAdmin => OrgController.to.myOrg.value?.isAdmin ?? false;
  bool get inOrg => orgId != null;

  Future<void> load() async {
    final id = orgId;
    if (id == null) return;
    loading.value = true;
    try {
      final results = await Future.wait([
        CanvassApi.instance.pins(id),
        CanvassApi.instance.territories(id),
      ]);
      pins.assignAll(results[0] as List<CanvassPin>);
      territories.assignAll(results[1] as List<CanvassTerritory>);
    } finally {
      loading.value = false;
    }
  }

  /// Ensure the org roster is loaded so the admin's assign picker has real rep
  /// names. No-op for reps (only admins can assign).
  Future<void> ensureRoster() async {
    if (!isAdmin) return;
    if (OrgController.to.roster.isEmpty) {
      await OrgController.to.refreshRoster();
    }
  }

  List<CanvassPin> get visiblePins {
    final f = repFilter.value;
    if (f == null) return pins.toList();
    // A rep "owns" a door if they dropped it OR it's assigned to them.
    return pins.where((p) => p.repId == f || p.assignedRepId == f).toList();
  }

  /// Distinct reps across the loaded pins — creators AND assignees — for the
  /// admin filter chips.
  List<({String id, String name})> get reps {
    final map = <String, String>{};
    for (final p in pins) {
      map[p.repId] = p.repName;
      if ((p.assignedRepId ?? '').isNotEmpty) {
        map[p.assignedRepId!] = p.assignedRepName ?? 'Rep';
      }
    }
    return [for (final e in map.entries) (id: e.key, name: e.value)];
  }

  /// Team members an admin can assign a lead to — the live org roster (loaded by
  /// OrgController for admins), falling back to reps already seen on pins.
  List<({String id, String name})> get assignableReps {
    final roster = OrgController.to.roster;
    if (roster.isNotEmpty) {
      return [for (final m in roster) (id: m.userId, name: m.name)];
    }
    return reps;
  }

  // ── Territories ─────────────────────────────────────────────────────────────
  /// Areas to draw on the map. When the admin filters to one rep, only that
  /// rep's areas show.
  List<CanvassTerritory> get visibleTerritories {
    final f = repFilter.value;
    if (f == null) return territories.toList();
    return territories.where((t) => t.assignedRepIds.contains(f)).toList();
  }

  /// Ray-casting point-in-polygon test.
  bool _inPoly(double lat, double lng, List<LatLng> poly) {
    if (poly.length < 3) return false;
    var inside = false;
    for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final xi = poly[i].longitude, yi = poly[i].latitude;
      final xj = poly[j].longitude, yj = poly[j].latitude;
      final hit = ((yi > lat) != (yj > lat)) &&
          (lng < (xj - xi) * (lat - yi) / (yj - yi) + xi);
      if (hit) inside = !inside;
    }
    return inside;
  }

  /// Every loaded door that falls inside [t] (most recently updated first).
  List<CanvassPin> pinsInTerritory(CanvassTerritory t) {
    final list = pins.where((p) => _inPoly(p.lat, p.lng, t.points)).toList();
    list.sort((a, b) => (b.updatedAt ?? DateTime(0))
        .compareTo(a.updatedAt ?? DateTime(0)));
    return list;
  }

  Future<CanvassTerritory?> createTerritory({
    required List<LatLng> points,
    required String name,
    required String color,
    required List<String> repIds,
    required List<String> repNames,
  }) async {
    final id = orgId;
    if (id == null) return null;
    final t = await CanvassApi.instance.createTerritory(id, {
      'name': name,
      'color': color,
      'points': [
        for (final p in points) {'lat': p.latitude, 'lng': p.longitude}
      ],
      'assignedRepIds': repIds,
      'assignedRepNames': repNames,
    });
    if (t != null) territories.insert(0, t);
    return t;
  }

  Future<void> updateTerritory(
      CanvassTerritory t, Map<String, dynamic> body) async {
    final updated = await CanvassApi.instance.updateTerritory(t.id, body);
    if (updated != null) {
      final i = territories.indexWhere((x) => x.id == t.id);
      if (i >= 0) territories[i] = updated;
      territories.refresh();
    }
  }

  Future<void> deleteTerritory(CanvassTerritory t) async {
    final ok = await CanvassApi.instance.removeTerritory(t.id);
    if (ok) territories.removeWhere((x) => x.id == t.id);
  }

  // ── Mutations ───────────────────────────────────────────────────────────────
  Future<CanvassPin?> drop({
    required double lat,
    required double lng,
    required String status,
    Map<String, String>? addr,
    String? homeownerName,
    String? notes,
    String? phone,
  }) async {
    final id = orgId;
    if (id == null) return null;
    final body = <String, dynamic>{
      'lat': lat,
      'lng': lng,
      'status': status,
      if (addr != null) ...addr,
      if (homeownerName != null && homeownerName.isNotEmpty)
        'homeownerName': homeownerName,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    };
    final pin = await CanvassApi.instance.create(id, body);
    if (pin != null) pins.insert(0, pin);
    return pin;
  }

  Future<void> updatePin(CanvassPin p, Map<String, dynamic> body) async {
    final updated = await CanvassApi.instance.update(p.id, body);
    if (updated != null) {
      final i = pins.indexWhere((x) => x.id == p.id);
      if (i >= 0) pins[i] = updated;
      pins.refresh();
    }
  }

  /// Assign (or reassign) a door to a rep. Pass an empty [repId] to unassign.
  /// Admin only (enforced server-side). Returns the updated pin, or null.
  Future<CanvassPin?> assign(CanvassPin p,
      {required String repId, String repName = ''}) async {
    final updated =
        await CanvassApi.instance.assign(p.id, repId: repId, repName: repName);
    if (updated != null) {
      final i = pins.indexWhere((x) => x.id == p.id);
      if (i >= 0) pins[i] = updated;
      pins.refresh();
    }
    return updated;
  }

  Future<void> deletePin(CanvassPin p) async {
    final ok = await CanvassApi.instance.remove(p.id);
    if (ok) pins.removeWhere((x) => x.id == p.id);
  }

  /// On-demand home + owner lookup for a door, cached on the pin so it's only
  /// ever charged once. [estimate] adds the market-value call. Returns the
  /// detail (or null on failure / not-configured).
  Future<PropertyDetail?> enrichPin(CanvassPin p, {bool estimate = false}) async {
    final detail = await CanvassApi.instance.enrichPin(p.id, estimate: estimate);
    if (detail != null && detail.found) {
      p.enrichment = detail;
      p.enrichedAt = DateTime.now();
      final i = pins.indexWhere((x) => x.id == p.id);
      if (i >= 0) pins.refresh();
    }
    return detail;
  }

  // ── Stats ───────────────────────────────────────────────────────────────────
  bool _isToday(DateTime? d) =>
      d != null && DateUtils.isSameDay(d, DateTime.now());

  int get doorsToday => visiblePins.where((p) => _isToday(p.createdAt)).length;
  int get apptsTotal =>
      visiblePins.where((p) => CanvassStatus.isAppt(p.status)).length;
  int get salesTotal =>
      visiblePins.where((p) => CanvassStatus.isSale(p.status)).length;
  int get totalPins => visiblePins.length;

  /// Per-rep tallies for the admin leaderboard, ranked by sales then doors.
  List<({String name, int doors, int appts, int sales})> get leaderboard {
    final by = <String, ({String name, int doors, int appts, int sales})>{};
    for (final p in pins) {
      final cur = by[p.repId] ??
          (name: p.repName, doors: 0, appts: 0, sales: 0);
      by[p.repId] = (
        name: p.repName,
        doors: cur.doors + 1,
        appts: cur.appts + (CanvassStatus.isAppt(p.status) ? 1 : 0),
        sales: cur.sales + (CanvassStatus.isSale(p.status) ? 1 : 0),
      );
    }
    final list = by.values.toList();
    list.sort((a, b) {
      final s = b.sales.compareTo(a.sales);
      return s != 0 ? s : b.doors.compareTo(a.doors);
    });
    return list;
  }
}
