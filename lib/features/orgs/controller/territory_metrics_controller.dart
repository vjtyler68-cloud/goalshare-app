import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single source of truth for the rep's door-knocking activity — Doors Knocked,
/// People Talked To, Bills. It holds TODAY's tally (persisted per day, resets at
/// midnight, survives restarts). The territory-map bar edits these, and
/// [OrgMetrics] reads them, so the counts roll up to the sales org through the
/// exact same pipeline as every other metric (admin dashboard, leaderboard,
/// team goals) — one aligned system, not a separate island.
class TerritoryMetricsController extends GetxService {
  static TerritoryMetricsController get to =>
      Get.isRegistered<TerritoryMetricsController>()
          ? Get.find<TerritoryMetricsController>()
          : Get.put(TerritoryMetricsController(), permanent: true);

  final RxInt doors = 0.obs;
  final RxInt talked = 0.obs;
  final RxInt bills = 0.obs;

  String _day = '';

  static String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  String _key(String day) => 'territory_metrics_v1_$day';

  @override
  void onInit() {
    super.onInit();
    _loadToday();
  }

  Future<void> _loadToday() async {
    _day = _todayStr();
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_key(_day));
      if (raw != null && raw.isNotEmpty) {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        doors.value = (m['d'] as num?)?.toInt() ?? 0;
        talked.value = (m['t'] as num?)?.toInt() ?? 0;
        bills.value = (m['b'] as num?)?.toInt() ?? 0;
      } else {
        doors.value = 0;
        talked.value = 0;
        bills.value = 0;
      }
    } catch (_) {}
  }

  // Guard against the clock rolling past midnight while the app is open.
  Future<void> _ensureToday() async {
    if (_day != _todayStr()) await _loadToday();
  }

  /// which = 'd' (doors) | 't' (talked) | 'b' (bills). delta is +1 / -1.
  Future<void> bump(String which, int delta) async {
    await _ensureToday();
    switch (which) {
      case 'd':
        doors.value = (doors.value + delta).clamp(0, 99999);
        break;
      case 't':
        talked.value = (talked.value + delta).clamp(0, 99999);
        break;
      case 'b':
        bills.value = (bills.value + delta).clamp(0, 99999);
        break;
    }
    await _save();
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        _key(_day),
        jsonEncode({'d': doors.value, 't': talked.value, 'b': bills.value}),
      );
    } catch (_) {}
  }
}
