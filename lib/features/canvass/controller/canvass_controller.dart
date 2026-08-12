import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:spanx/features/orgs/controller/org_controller.dart';

import '../data/canvass_api.dart';
import '../data/canvass_pin.dart';
import '../data/canvass_status.dart';

/// Drives the Solar Cowboys canvassing map. Pins live on the backend, scoped by
/// the user's role in their current org (admin → every rep's pins, rep → only
/// their own — enforced server-side). Reads the active org from [OrgController].
class CanvassController extends GetxController {
  static CanvassController get to => Get.isRegistered<CanvassController>()
      ? Get.find<CanvassController>()
      : Get.put(CanvassController(), permanent: true);

  final RxList<CanvassPin> pins = <CanvassPin>[].obs;
  final RxBool loading = false.obs;

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
      pins.assignAll(await CanvassApi.instance.pins(id));
    } finally {
      loading.value = false;
    }
  }

  List<CanvassPin> get visiblePins {
    final f = repFilter.value;
    if (f == null) return pins.toList();
    return pins.where((p) => p.repId == f).toList();
  }

  /// Distinct reps across the loaded pins (for the admin filter chips).
  List<({String id, String name})> get reps {
    final map = <String, String>{};
    for (final p in pins) {
      map[p.repId] = p.repName;
    }
    return [for (final e in map.entries) (id: e.key, name: e.value)];
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

  Future<void> deletePin(CanvassPin p) async {
    final ok = await CanvassApi.instance.remove(p.id);
    if (ok) pins.removeWhere((x) => x.id == p.id);
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
