import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import 'package:spanx/features/orgs/controller/org_controller.dart';

import '../data/canvass_api.dart';
import '../data/canvass_local_store.dart';
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
  final RxnString loadError = RxnString();

  /// Admin only: freehand area-drawing mode is active.
  final RxBool drawMode = false.obs;

  /// Show today's route breadcrumb trail on the map.
  final RxBool breadcrumbOn = false.obs;

  /// Admin only: filter the map to one rep (null = show everyone).
  final RxnString repFilter = RxnString();

  /// Map-native status filter. null means all.
  final RxnString statusFilter = RxnString();

  // ── Offline support ─────────────────────────────────────────────────────────
  /// True when the last network attempt failed — the rep is working from the
  /// on-device cache and any changes are being queued.
  final RxBool offline = false.obs;

  /// How many offline changes are waiting to sync.
  final RxInt pendingCount = 0.obs;

  final CanvassLocalStore _store = CanvassLocalStore.instance;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _flushing = false;
  int _seq = 0;

  String _localId() =>
      'local_${DateTime.now().microsecondsSinceEpoch}_${_seq++}';
  int _now() => DateTime.now().microsecondsSinceEpoch;
  bool _isLocal(String id) => id.startsWith('local_');

  @override
  void onInit() {
    super.onInit();
    // Auto-sync queued changes the moment signal comes back.
    _connSub = Connectivity().onConnectivityChanged.listen((res) {
      final online = res.any((r) => r != ConnectivityResult.none);
      if (online) flushQueue();
    });
    _refreshPending();
  }

  @override
  void onClose() {
    _connSub?.cancel();
    super.onClose();
  }

  Future<bool> _isOnline() async {
    try {
      final res = await Connectivity().checkConnectivity();
      return res.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return true; // assume online if the check itself fails
    }
  }

  Future<void> _refreshPending() async {
    pendingCount.value = (await _store.queue()).length;
  }

  /// Fire-and-forget snapshot of the current doors/areas to disk.
  void _persist() {
    final id = orgId;
    if (id == null) return;
    _store.saveSnapshot(id, pins.toList(), territories.toList());
  }

  String? get orgId => OrgController.to.myOrg.value?.id;
  bool get isAdmin => OrgController.to.myOrg.value?.isAdmin ?? false;
  bool get inOrg => orgId != null;

  /// Sales Ranch is admin-only until the admin opens it to the team.
  bool get canUse =>
      isAdmin || (OrgController.to.myOrg.value?.canvassEnabled ?? false);

  Future<void> load() async {
    final id = orgId;
    if (id == null) return;
    // Show the cached doors instantly (critical with no signal) before/while we
    // hit the network, so the map is never blank when a rep opens it in a dead
    // zone.
    if (pins.isEmpty || territories.isEmpty) {
      final cachedPins = await _store.loadPins(id);
      final cachedTerr = await _store.loadTerritories(id);
      if (pins.isEmpty && cachedPins.isNotEmpty) pins.assignAll(cachedPins);
      if (territories.isEmpty && cachedTerr.isNotEmpty) {
        territories.assignAll(cachedTerr);
      }
    }
    loading.value = true;
    loadError.value = null;
    try {
      List<CanvassPin>? loadedPins;
      List<CanvassTerritory>? loadedTerritories;
      Future<void> loadPins() async {
        try {
          loadedPins = await CanvassApi.instance.pins(id);
        } catch (_) {}
      }

      Future<void> loadTerritories() async {
        try {
          loadedTerritories = await CanvassApi.instance.territories(id);
        } catch (_) {}
      }

      await Future.wait<void>([
        loadPins(),
        loadTerritories(),
      ]);

      if (loadedPins != null) pins.assignAll(loadedPins!);
      if (loadedTerritories != null) {
        territories.assignAll(loadedTerritories!);
      }

      final fullyOnline = loadedPins != null && loadedTerritories != null;
      offline.value = !fullyOnline;
      // Re-apply any still-unsynced offline changes on top of fresh server data,
      // then push them up.
      await _applyPendingLocally();
      _persist();
      if (fullyOnline) {
        await flushQueue();
      } else if (loadedPins == null &&
          loadedTerritories == null &&
          pins.isEmpty &&
          territories.isEmpty) {
        loadError.value = 'Could not load the ranch map.';
      }
    } catch (_) {
      // Offline or server unreachable: keep the cache we already showed instead
      // of a hard error, so the rep can keep knocking.
      offline.value = true;
      await _applyPendingLocally();
      if (pins.isEmpty && territories.isEmpty) {
        loadError.value = 'Could not load the ranch map.';
      }
    } finally {
      loading.value = false;
      await _refreshPending();
    }
  }

  /// Re-apply the visible effect of any queued offline changes onto the current
  /// pin list (after a server load overwrites it), so nothing appears to revert
  /// before the queue finishes syncing.
  Future<void> _applyPendingLocally() async {
    final id = orgId;
    if (id == null) return;
    final q = await _store.queue();
    for (final op in q) {
      if (op.orgId != id) continue;
      switch (op.type) {
        case 'drop':
          if (op.tempId != null && !pins.any((x) => x.id == op.tempId)) {
            pins.insert(0, _tempPin(id, op));
          }
          break;
        case 'update':
          final i = pins.indexWhere((x) => x.id == op.pinId);
          if (i >= 0) {
            final b = op.body;
            if (b['status'] is String) pins[i].status = b['status'] as String;
            if (b['homeownerName'] is String) {
              pins[i].homeownerName = b['homeownerName'] as String;
            }
            if (b['phone'] is String) pins[i].phone = b['phone'] as String;
            if (b['notes'] is String) pins[i].notes = b['notes'] as String;
          }
          break;
        case 'delete':
          pins.removeWhere((x) => x.id == op.pinId);
          break;
      }
    }
    pins.refresh();
  }

  /// A stand-in pin for a door dropped while offline (until it syncs).
  CanvassPin _tempPin(String id, PendingOp op) {
    final b = op.body;
    return CanvassPin(
      id: op.tempId ?? _localId(),
      orgId: id,
      repId: OrgController.to.myUserId.value ?? '',
      repName: 'You',
      lat: (b['lat'] as num?)?.toDouble() ?? 0,
      lng: (b['lng'] as num?)?.toDouble() ?? 0,
      address: (b['address'] ?? '').toString(),
      city: (b['city'] ?? '').toString(),
      state: (b['state'] ?? '').toString(),
      zip: (b['zip'] ?? '').toString(),
      status: (b['status'] ?? 'NH').toString(),
      homeownerName: b['homeownerName'] as String?,
      notes: b['notes'] as String?,
      phone: b['phone'] as String?,
      createdAt: DateTime.now(),
      lastVisited: DateTime.now(),
    );
  }

  /// Replay every queued offline change in order, oldest first. Stops at the
  /// first failure (still offline) and keeps the rest for the next attempt.
  Future<void> flushQueue() async {
    final id = orgId;
    if (id == null || _flushing) return;
    if (!await _isOnline()) {
      offline.value = true;
      await _refreshPending();
      return;
    }
    _flushing = true;
    var allOk = true;
    try {
      var q = await _store.queue();
      // Abandon poison ops (repeatedly rejected) so they can't block the queue.
      final poison = q.where((o) => o.attempts >= 8).map((o) => o.id).toList();
      if (poison.isNotEmpty) {
        q = q.where((o) => o.attempts < 8).toList();
        await _store.replaceQueue(q);
      }
      q.sort((a, b) => a.ts.compareTo(b.ts));
      for (final op in q) {
        final ok = await _replay(op);
        if (ok) {
          await _store.removeOp(op.id);
        } else {
          await _store.bumpAttempts(op.id);
          allOk = false;
          break;
        }
      }
      if (allOk) offline.value = false;
    } finally {
      _flushing = false;
      await _refreshPending();
    }
  }

  /// Push one queued op to the server. Returns false on failure (keep it queued).
  Future<bool> _replay(PendingOp op) async {
    switch (op.type) {
      case 'drop':
        final pin = await CanvassApi.instance.create(
          op.orgId,
          op.body,
          showErrors: false,
        );
        if (pin == null) return false;
        final i = pins.indexWhere((x) => x.id == op.tempId);
        if (i >= 0) {
          pins[i] = pin;
        } else {
          pins.insert(0, pin);
        }
        pins.refresh();
        _persist();
        return true;
      case 'update':
        if (op.pinId == null) return true; // nothing to target
        final updated = await CanvassApi.instance.update(
          op.pinId!,
          op.body,
          showErrors: false,
        );
        if (updated == null) return false;
        final i = pins.indexWhere((x) => x.id == op.pinId);
        if (i >= 0) pins[i] = updated;
        pins.refresh();
        _persist();
        return true;
      case 'assign':
        if (op.pinId == null) return true;
        final updated = await CanvassApi.instance.assign(
          op.pinId!,
          repId: (op.body['repId'] ?? '').toString(),
          repName: (op.body['repName'] ?? '').toString(),
          showErrors: false,
        );
        if (updated == null) return false;
        final i = pins.indexWhere((x) => x.id == op.pinId);
        if (i >= 0) pins[i] = updated;
        pins.refresh();
        _persist();
        return true;
      case 'delete':
        if (op.pinId == null) return true;
        final ok = await CanvassApi.instance.remove(
          op.pinId!,
          showErrors: false,
        );
        if (!ok) return false;
        pins.removeWhere((x) => x.id == op.pinId);
        _persist();
        return true;
    }
    return true; // unknown op: discard
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
    final status = statusFilter.value;
    return pins.where((p) {
      final repOk = f == null || p.repId == f || p.assignedRepId == f;
      final statusOk =
          status == null ||
          (status == 'worked'
              ? p.status != 'NV'
              : status == 'interested'
              ? const ['SLR', 'SI', 'CB'].contains(p.status)
              : status == 'sale'
              ? CanvassStatus.isSale(p.status)
              : p.status == status);
      return repOk && statusOk;
    }).toList();
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
      final hit =
          ((yi > lat) != (yj > lat)) &&
          (lng < (xj - xi) * (lat - yi) / (yj - yi) + xi);
      if (hit) inside = !inside;
    }
    return inside;
  }

  /// Every loaded door that falls inside [t] (most recently updated first).
  List<CanvassPin> pinsInTerritory(CanvassTerritory t) {
    final list = pins.where((p) => _inPoly(p.lat, p.lng, t.points)).toList();
    list.sort(
      (a, b) =>
          (b.updatedAt ?? DateTime(0)).compareTo(a.updatedAt ?? DateTime(0)),
    );
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
        for (final p in points) {'lat': p.latitude, 'lng': p.longitude},
      ],
      'assignedRepIds': repIds,
      'assignedRepNames': repNames,
    });
    if (t != null) territories.insert(0, t);
    return t;
  }

  Future<void> updateTerritory(
    CanvassTerritory t,
    Map<String, dynamic> body,
  ) async {
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
    if (pin != null) {
      pins.insert(0, pin);
      offline.value = false;
      _persist();
      return pin;
    }
    // Offline: drop a local pin now, queue the create for when signal returns.
    final tempId = _localId();
    final op = PendingOp(
      id: _localId(),
      type: 'drop',
      orgId: id,
      tempId: tempId,
      body: body,
      ts: _now(),
    );
    pins.insert(0, _tempPin(id, op));
    await _store.enqueue(op);
    offline.value = true;
    _persist();
    await _refreshPending();
    return pins.first;
  }

  Future<void> updatePin(CanvassPin p, Map<String, dynamic> body) async {
    // Optimistic local apply so an edit sticks instantly, online or off.
    if (body['status'] is String) p.status = body['status'] as String;
    if (body['homeownerName'] is String) {
      p.homeownerName = body['homeownerName'] as String;
    }
    if (body['phone'] is String) p.phone = body['phone'] as String;
    if (body['notes'] is String) p.notes = body['notes'] as String;
    pins.refresh();

    final id = orgId;
    final updated =
        _isLocal(p.id) ? null : await CanvassApi.instance.update(p.id, body);
    if (updated != null) {
      final i = pins.indexWhere((x) => x.id == p.id);
      if (i >= 0) pins[i] = updated;
      pins.refresh();
      offline.value = false;
      _persist();
      return;
    }
    if (id != null) {
      if (_isLocal(p.id)) {
        // Fold into the not-yet-synced drop so it's created with these values.
        await _store.patchDropBody(p.id, body);
      } else {
        await _store.enqueue(PendingOp(
          id: _localId(),
          type: 'update',
          orgId: id,
          pinId: p.id,
          body: body,
          ts: _now(),
        ));
        offline.value = true;
      }
    }
    _persist();
    await _refreshPending();
    unawaited(flushQueue());
  }

  /// Optimistic one-tap disposition — flips the pin's status (and colour) LOCALLY
  /// and instantly, then syncs in the background, reverting if the save fails.
  /// This is the "no spinner / instant pin colour" requirement.
  Future<void> quickDisposition(CanvassPin p, String code) async {
    if (p.status == code) return;
    p.status = code;
    if (const ['SALE', 'WON', 'CS'].contains(code) && p.stage == 'lead') {
      p.stage = 'sale';
    }
    pins.refresh();
    final id = orgId;
    final updated = _isLocal(p.id)
        ? null
        : await CanvassApi.instance.update(p.id, {'status': code});
    if (updated != null) {
      final i = pins.indexWhere((x) => x.id == p.id);
      if (i >= 0) pins[i] = updated;
      pins.refresh();
      offline.value = false;
      _persist();
      return;
    }
    // Offline: KEEP the new colour (don't revert) and queue the sync.
    if (id != null) {
      if (_isLocal(p.id)) {
        await _store.patchDropBody(p.id, {'status': code});
      } else {
        await _store.enqueue(PendingOp(
          id: _localId(),
          type: 'update',
          orgId: id,
          pinId: p.id,
          body: {'status': code},
          ts: _now(),
        ));
        offline.value = true;
      }
    }
    _persist();
    await _refreshPending();
    unawaited(flushQueue());
  }

  /// On-demand skip-trace for a door — resident name + phone + email, cached on
  /// the pin (one charge per door). Returns (configured, contact). On a hit it
  /// also fills the pin's homeowner/phone so the name shows everywhere.
  Future<({bool configured, PinContact? contact})> getContact(
    CanvassPin p,
  ) async {
    final res = await CanvassApi.instance.contactPin(p.id);
    final configured = res?['configured'] == true;
    PinContact? contact;
    if (res != null && res['data'] is Map) {
      contact = PinContact.fromJson(
        Map<String, dynamic>.from(res['data'] as Map),
      );
    }
    if (contact != null && contact.has) {
      p.contact = contact;
      p.contactAt = DateTime.now();
      if ((p.homeownerName ?? '').isEmpty) p.homeownerName = contact.name;
      final ph = contact.primaryPhone;
      if ((p.phone ?? '').isEmpty && ph != null) p.phone = ph.number;
      if ((p.contactEmail ?? '').isEmpty && contact.emails.isNotEmpty) {
        p.contactEmail = contact.emails.first;
      }
      pins.refresh();
    }
    return (configured: configured, contact: contact);
  }

  // ── Solar (Google "Project Sunroof") ────────────────────────────────────────
  /// When on, doors are coloured by roof solar-fit instead of status.
  final RxBool solarMode = false.obs;
  final Set<String> _solarInFlight = {};

  /// Look up a door's solar potential (cached on the pin, one lookup ever).
  Future<({bool configured, SolarInsight? solar})> getSolar(CanvassPin p) async {
    final res = await CanvassApi.instance.solarPin(p.id);
    final configured = res?['configured'] == true;
    SolarInsight? solar;
    if (res != null && res['data'] is Map) {
      solar = SolarInsight.fromJson(Map<String, dynamic>.from(res['data'] as Map));
    }
    // Mark attempted (even a miss) so we don't re-fetch this door.
    if (configured) {
      p.solarAt = DateTime.now();
      p.solar = solar;
      pins.refresh();
    }
    return (configured: configured, solar: solar);
  }

  /// Auto-fill solar for the doors currently on screen (bounded), colouring
  /// them as results arrive. Skips doors already looked up or in flight.
  void ensureSolarForVisible(List<CanvassPin> visible) {
    if (!solarMode.value) return;
    final todo = visible
        .where((p) => p.solarAt == null && !_solarInFlight.contains(p.id))
        .take(30)
        .toList();
    for (final p in todo) {
      _solarInFlight.add(p.id);
      getSolar(p).whenComplete(() => _solarInFlight.remove(p.id));
    }
  }

  // ── Sunlight (PVGIS — free location sun resource, works US-wide) ─────────────
  final Map<String, SunlightInsight> _sunCache = {};

  /// Location sunlight for a door. Cached in-memory by ~1 km coordinate — the
  /// value barely varies within a neighborhood and PVGIS is free, so one lookup
  /// serves every door on a block.
  Future<SunlightInsight?> getSunlight(CanvassPin p) async {
    final id = orgId;
    if (id == null) return null;
    final key = '${p.lat.toStringAsFixed(2)},${p.lng.toStringAsFixed(2)}';
    final cached = _sunCache[key];
    if (cached != null) return cached;
    final r = await CanvassApi.instance.irradiance(id, p.lat, p.lng);
    if (r != null) _sunCache[key] = r;
    return r;
  }

  /// The live pin for [id] (fresh from the list), or [fallback].
  CanvassPin pinById(String id, CanvassPin fallback) {
    for (final p in pins) {
      if (p.id == id) return p;
    }
    return fallback;
  }

  // ── Route / day breadcrumb ──────────────────────────────────────────────────
  /// Whose route to draw: an admin's selected rep (or their own); a rep sees
  /// only their own.
  String? get breadcrumbRepId {
    final me = OrgController.to.myUserId.value;
    if (isAdmin) return repFilter.value ?? me;
    return me;
  }

  /// Today's stops for [repId], ordered by visit time — derived from each pin's
  /// status history / last visit, so no separate route store is needed.
  List<({CanvassPin pin, DateTime at})> todayRoute(String? repId) {
    final now = DateTime.now();
    bool isToday(DateTime d) {
      final l = d.toLocal();
      return l.year == now.year && l.month == now.month && l.day == now.day;
    }

    final stops = <({CanvassPin pin, DateTime at})>[];
    for (final p in pins) {
      if (p.status == 'NV') continue; // skip un-knocked pre-loaded homes
      if (repId != null && p.repId != repId && p.assignedRepId != repId) {
        continue;
      }
      DateTime? at;
      for (final h in p.statusHistory) {
        final t = DateTime.tryParse('${h['at']}');
        if (t != null && isToday(t) && (at == null || t.isAfter(at))) {
          at = t;
        }
      }
      if (at == null && p.lastVisited != null && isToday(p.lastVisited!)) {
        at = p.lastVisited;
      }
      if (at != null) stops.add((pin: p, at: at));
    }
    stops.sort((a, b) => a.at.compareTo(b.at));
    return stops;
  }

  /// Assign (or reassign) a door to a rep. Pass an empty [repId] to unassign.
  /// Admin only (enforced server-side). Returns the updated pin, or null.
  Future<CanvassPin?> assign(
    CanvassPin p, {
    required String repId,
    String repName = '',
  }) async {
    final updated = _isLocal(p.id)
        ? null
        : await CanvassApi.instance.assign(p.id, repId: repId, repName: repName);
    if (updated != null) {
      final i = pins.indexWhere((x) => x.id == p.id);
      if (i >= 0) pins[i] = updated;
      pins.refresh();
      offline.value = false;
      _persist();
      return updated;
    }
    // Offline: apply locally + queue (an unsynced local drop can't be assigned
    // until it exists on the server).
    p.assignedRepId = repId.isEmpty ? null : repId;
    p.assignedRepName = repName.isEmpty ? null : repName;
    pins.refresh();
    final id = orgId;
    if (id != null && !_isLocal(p.id)) {
      await _store.enqueue(PendingOp(
        id: _localId(),
        type: 'assign',
        orgId: id,
        pinId: p.id,
        body: {'repId': repId, 'repName': repName},
        ts: _now(),
      ));
      offline.value = true;
      await _refreshPending();
      unawaited(flushQueue());
    }
    _persist();
    return p;
  }

  Future<void> deletePin(CanvassPin p) async {
    // Optimistic remove.
    pins.removeWhere((x) => x.id == p.id);
    if (_isLocal(p.id)) {
      // Never synced — just discard the queued drop too.
      final q = await _store.queue();
      q.removeWhere((o) => o.tempId == p.id);
      await _store.replaceQueue(q);
      _persist();
      await _refreshPending();
      return;
    }
    final ok = await CanvassApi.instance.remove(p.id);
    if (ok) {
      offline.value = false;
      _persist();
      return;
    }
    final id = orgId;
    if (id != null) {
      await _store.enqueue(PendingOp(
        id: _localId(),
        type: 'delete',
        orgId: id,
        pinId: p.id,
        body: const {},
        ts: _now(),
      ));
      offline.value = true;
    }
    _persist();
    await _refreshPending();
    unawaited(flushQueue());
  }

  final RxBool seeding = false.obs;

  /// Pre-load a pin on every home around a point (admin). Reloads on success.
  /// Returns how many new homes were added.
  Future<int> seedHomes({
    required double lat,
    required double lng,
    double radius = 0.75,
  }) async {
    final id = orgId;
    if (id == null) return 0;
    seeding.value = true;
    try {
      final n = await CanvassApi.instance.seedArea(
        id,
        lat: lat,
        lng: lng,
        radius: radius,
      );
      if (n > 0) await load();
      return n;
    } finally {
      seeding.value = false;
    }
  }

  Future<SeedResult?> seedTerritory(CanvassTerritory t) async {
    if (orgId == null) return null;
    seeding.value = true;
    try {
      final result = await CanvassApi.instance.seedTerritory(t.id);
      if (result != null) await load();
      return result;
    } finally {
      seeding.value = false;
    }
  }

  /// Deliberately simple: nearest unvisited visible door, not a turn-by-turn route.
  CanvassPin? nextDoor({LatLng? from}) {
    final origin = from;
    final candidates = visiblePins.where((p) => p.status == 'NV').toList();
    if (candidates.isEmpty) return null;
    if (origin == null) return candidates.first;
    candidates.sort((a, b) {
      final da =
          (a.lat - origin.latitude) * (a.lat - origin.latitude) +
          (a.lng - origin.longitude) * (a.lng - origin.longitude);
      final db =
          (b.lat - origin.latitude) * (b.lat - origin.latitude) +
          (b.lng - origin.longitude) * (b.lng - origin.longitude);
      return da.compareTo(db);
    });
    return candidates.first;
  }

  /// On-demand home + owner lookup for a door, cached on the pin so it's only
  /// ever charged once. [estimate] adds the market-value call. Returns the
  /// detail (or null on failure / not-configured).
  Future<PropertyDetail?> enrichPin(
    CanvassPin p, {
    bool estimate = false,
  }) async {
    final detail = await CanvassApi.instance.enrichPin(
      p.id,
      estimate: estimate,
    );
    if (detail != null && detail.found) {
      p.enrichment = detail;
      p.enrichedAt = DateTime.now();
      final i = pins.indexWhere((x) => x.id == p.id);
      if (i >= 0) pins.refresh();
    }
    return detail;
  }

  // ── Stats (pre-loaded "Not Visited" homes don't count as worked doors) ──────
  bool _isToday(DateTime? d) =>
      d != null && DateUtils.isSameDay(d, DateTime.now());
  bool _worked(CanvassPin p) => p.status != 'NV';

  int get doorsToday => visiblePins
      .where((p) => _worked(p) && _isToday(p.lastVisited ?? p.createdAt))
      .length;
  int get apptsTotal =>
      visiblePins.where((p) => CanvassStatus.isAppt(p.status)).length;
  int get salesTotal =>
      visiblePins.where((p) => CanvassStatus.isSale(p.status)).length;
  int get totalPins => visiblePins.where(_worked).length;

  /// Per-rep tallies for the admin leaderboard, ranked by sales then doors.
  List<({String name, int doors, int appts, int sales})> get leaderboard {
    final by = <String, ({String name, int doors, int appts, int sales})>{};
    for (final p in pins) {
      if (!_worked(p)) continue; // skip un-knocked pre-loaded homes
      final cur =
          by[p.repId] ?? (name: p.repName, doors: 0, appts: 0, sales: 0);
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
