import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One saved day of field stats. [custom] holds user-defined metrics by name
/// (e.g. {"Doors Hung": 12}) so added columns flow into history too.
class DayStat {
  final String date; // yyyy-MM-dd
  final int homes;
  final int people;
  final int sales;
  final Map<String, int> custom;

  const DayStat({
    required this.date,
    required this.homes,
    required this.people,
    required this.sales,
    this.custom = const {},
  });

  Map<String, dynamic> toMap() => {
        'date': date,
        'homes': homes,
        'people': people,
        'sales': sales,
        'custom': custom,
      };

  factory DayStat.fromMap(Map<String, dynamic> m) => DayStat(
        date: (m['date'] ?? '').toString(),
        homes: (m['homes'] as num?)?.toInt() ?? 0,
        people: (m['people'] as num?)?.toInt() ?? 0,
        sales: (m['sales'] as num?)?.toInt() ?? 0,
        custom: (m['custom'] is Map)
            ? (m['custom'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0))
            : const {},
      );
}

/// A week's aggregated totals for the breakdown card.
class WeekStat {
  final DateTime weekStart; // Monday
  final int homes;
  final int people;
  final int sales;
  final int daysLogged;

  const WeekStat({
    required this.weekStart,
    required this.homes,
    required this.people,
    required this.sales,
    required this.daysLogged,
  });
}

/// Local, per-day stats history behind the "End of Day" save. Enables the
/// week-by-week breakdown VJ asked for ("show breakdown of stats by week so
/// users can see where they are at"). SharedPreferences JSON, capped at ~400
/// days; saving the same date twice replaces that day (no double counting).
class StatsHistoryService extends GetxService {
  static StatsHistoryService get to =>
      Get.isRegistered<StatsHistoryService>()
          ? Get.find<StatsHistoryService>()
          : Get.put(StatsHistoryService(), permanent: true);

  static const String _kKey = 'stats_day_history_v1';
  static const int _maxDays = 400;

  final RxList<DayStat> days = <DayStat>[].obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kKey);
      if (raw == null || raw.isEmpty) return;
      final list = (jsonDecode(raw) as List)
          .whereType<Map>()
          .map((m) => DayStat.fromMap(m.cast<String, dynamic>()))
          .toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      days.assignAll(list);
    } catch (_) {
      // History is additive/cosmetic — never break the mission screen over it.
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _kKey, jsonEncode(days.map((d) => d.toMap()).toList()));
    } catch (_) {}
  }

  /// Record (or overwrite) one day's stats.
  Future<void> recordDay(DayStat stat) async {
    days.removeWhere((d) => d.date == stat.date);
    days.add(stat);
    days.sort((a, b) => a.date.compareTo(b.date));
    if (days.length > _maxDays) {
      days.removeRange(0, days.length - _maxDays);
    }
    await _persist();
  }

  static DateTime _mondayOf(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  /// Totals for the last [count] weeks, newest first (index 0 = this week).
  /// Weeks with nothing logged still appear (all zeros) so the rhythm of the
  /// list is stable and easy to read.
  List<WeekStat> lastWeeks({int count = 4}) {
    final thisMonday = _mondayOf(DateTime.now());
    return List.generate(count, (i) {
      final start = thisMonday.subtract(Duration(days: 7 * i));
      final end = start.add(const Duration(days: 7));
      var homes = 0, people = 0, sales = 0, logged = 0;
      for (final d in days) {
        final dt = DateTime.tryParse(d.date);
        if (dt == null) continue;
        if (!dt.isBefore(start) && dt.isBefore(end)) {
          homes += d.homes;
          people += d.people;
          sales += d.sales;
          logged++;
        }
      }
      return WeekStat(
          weekStart: start,
          homes: homes,
          people: people,
          sales: sales,
          daysLogged: logged);
    });
  }
}
