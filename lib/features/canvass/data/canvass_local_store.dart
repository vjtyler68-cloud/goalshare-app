import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'canvass_pin.dart';
import 'canvass_territory.dart';

/// A canvassing change made while offline, waiting to replay when signal is
/// back. Ops carry their own [orgId] so one global queue serves every org.
class PendingOp {
  final String id; // local, unique
  final String type; // 'drop' | 'update' | 'assign' | 'delete'
  final String orgId;
  final String? pinId; // server id (null for a not-yet-synced drop)
  final String? tempId; // local id of an offline-created pin
  final Map<String, dynamic> body;
  final int ts;
  int attempts;

  PendingOp({
    required this.id,
    required this.type,
    required this.orgId,
    this.pinId,
    this.tempId,
    this.body = const {},
    required this.ts,
    this.attempts = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'orgId': orgId,
        'pinId': pinId,
        'tempId': tempId,
        'body': body,
        'ts': ts,
        'attempts': attempts,
      };

  factory PendingOp.fromJson(Map<String, dynamic> j) => PendingOp(
        id: (j['id'] ?? '').toString(),
        type: (j['type'] ?? '').toString(),
        orgId: (j['orgId'] ?? '').toString(),
        pinId: j['pinId'] as String?,
        tempId: j['tempId'] as String?,
        body: j['body'] is Map
            ? Map<String, dynamic>.from(j['body'] as Map)
            : const {},
        ts: (j['ts'] as num?)?.toInt() ?? 0,
        attempts: (j['attempts'] as num?)?.toInt() ?? 0,
      );
}

/// On-device persistence for Sales Ranch: the last-synced doors + territories
/// (so the map isn't blank with no signal) and a queue of offline changes.
class CanvassLocalStore {
  CanvassLocalStore._();
  static final CanvassLocalStore instance = CanvassLocalStore._();

  static const _kPins = 'canvass_pins_';
  static const _kTerr = 'canvass_terr_';
  static const _kQueue = 'canvass_queue_v1';

  Future<SharedPreferences> get _sp => SharedPreferences.getInstance();

  // ── Snapshot (per org) ──────────────────────────────────────────────────────
  Future<void> saveSnapshot(
    String orgId,
    List<CanvassPin> pins,
    List<CanvassTerritory> territories,
  ) async {
    try {
      final sp = await _sp;
      await sp.setString(
          '$_kPins$orgId', jsonEncode([for (final p in pins) p.toJson()]));
      await sp.setString('$_kTerr$orgId',
          jsonEncode([for (final t in territories) t.toJson()]));
    } catch (_) {/* cache is best-effort */}
  }

  Future<List<CanvassPin>> loadPins(String orgId) async {
    try {
      final s = (await _sp).getString('$_kPins$orgId');
      if (s == null) return [];
      final list = jsonDecode(s);
      if (list is List) {
        return [
          for (final p in list)
            if (p is Map) CanvassPin.fromJson(Map<String, dynamic>.from(p)),
        ];
      }
    } catch (_) {}
    return [];
  }

  Future<List<CanvassTerritory>> loadTerritories(String orgId) async {
    try {
      final s = (await _sp).getString('$_kTerr$orgId');
      if (s == null) return [];
      final list = jsonDecode(s);
      if (list is List) {
        return [
          for (final t in list)
            if (t is Map)
              CanvassTerritory.fromJson(Map<String, dynamic>.from(t)),
        ];
      }
    } catch (_) {}
    return [];
  }

  // ── Offline queue (global) ──────────────────────────────────────────────────
  Future<List<PendingOp>> queue() async {
    try {
      final s = (await _sp).getString(_kQueue);
      if (s == null) return [];
      final list = jsonDecode(s);
      if (list is List) {
        return [
          for (final e in list)
            if (e is Map) PendingOp.fromJson(Map<String, dynamic>.from(e)),
        ];
      }
    } catch (_) {}
    return [];
  }

  Future<void> replaceQueue(List<PendingOp> q) async {
    try {
      await (await _sp)
          .setString(_kQueue, jsonEncode([for (final o in q) o.toJson()]));
    } catch (_) {}
  }

  Future<void> enqueue(PendingOp op) async {
    final q = await queue();
    q.add(op);
    await replaceQueue(q);
  }

  Future<void> removeOp(String id) async {
    final q = await queue();
    q.removeWhere((o) => o.id == id);
    await replaceQueue(q);
  }

  /// Bump the retry counter of one queued op (so a poison op can't loop forever).
  Future<void> bumpAttempts(String id) async {
    final q = await queue();
    for (final o in q) {
      if (o.id == id) o.attempts++;
    }
    await replaceQueue(q);
  }

  /// Fold a new status into a not-yet-synced offline drop, so when it finally
  /// syncs it's created with the rep's latest disposition.
  Future<void> patchDropBody(String tempId, Map<String, dynamic> patch) async {
    final q = await queue();
    for (final o in q) {
      if (o.type == 'drop' && o.tempId == tempId) {
        o.body.addAll(patch);
      }
    }
    await replaceQueue(q);
  }
}
