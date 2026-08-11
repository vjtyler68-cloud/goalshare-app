import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/goalendar_models.dart';

/// Owns the calendar's events + settings. Local-first: events live in a Hive
/// `Box<String>` (JSON), settings in SharedPreferences. Everyone can read it via
/// [GoalendarController.to]; it's cheap and permanent so the Quick Access tile
/// and profile icon can show today's count without racing an async open.
class GoalendarController extends GetxController {
  static GoalendarController get to => Get.isRegistered<GoalendarController>()
      ? Get.find<GoalendarController>()
      : Get.put(GoalendarController(), permanent: true);

  static const String _boxName = 'goalendar_events_v1';
  static const String _kSettings = 'goalendar_settings_v1';

  Box<String>? _box;

  final RxList<GoalendarEvent> events = <GoalendarEvent>[].obs;
  final Rx<GoalendarSettings> settings = GoalendarSettings().obs;
  final RxBool ready = false.obs;

  /// The month currently shown in the grid, and the selected day.
  final Rx<DateTime> focusedMonth = DateTime.now().obs;
  final Rx<DateTime> selectedDay = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    _boot();
  }

  Future<void> _boot() async {
    try {
      _box = await Hive.openBox<String>(_boxName);
      _reloadFromBox();
      await _loadSettings();
    } catch (e) {
      log('Goalendar boot failed: $e');
    } finally {
      ready.value = true;
    }
  }

  void _reloadFromBox() {
    final box = _box;
    if (box == null) return;
    final list = <GoalendarEvent>[];
    for (final raw in box.values) {
      try {
        list.add(GoalendarEvent.fromJsonString(raw));
      } catch (_) {}
    }
    list.sort((a, b) => a.start.compareTo(b.start));
    events.assignAll(list);
  }

  Future<void> _loadSettings() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_kSettings);
      if (raw != null && raw.isNotEmpty) {
        settings.value = GoalendarSettings.fromJson(
            Map<String, dynamic>.from(jsonDecode(raw) as Map));
      }
    } catch (_) {}
  }

  Future<void> saveSettings(GoalendarSettings s) async {
    settings.value = s;
    settings.refresh();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_kSettings, jsonEncode(s.toJson()));
    } catch (_) {}
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────
  Future<void> upsert(GoalendarEvent e) async {
    e.updatedAt = DateTime.now();
    await _box?.put(e.id, e.toJsonString());
    final i = events.indexWhere((x) => x.id == e.id);
    if (i >= 0) {
      events[i] = e;
    } else {
      events.add(e);
    }
    events.sort((a, b) => a.start.compareTo(b.start));
    events.refresh();
  }

  Future<void> delete(String id) async {
    await _box?.delete(id);
    events.removeWhere((e) => e.id == id);
  }

  Future<void> toggleComplete(GoalendarEvent e) async {
    e.isCompleted = !e.isCompleted;
    e.completedAt = e.isCompleted ? DateTime.now() : null;
    await upsert(e);
  }

  String newId() =>
      'gcal_${DateTime.now().microsecondsSinceEpoch}_${events.length}';

  // ── Queries (with simple recurrence expansion) ─────────────────────────────
  bool occursOn(GoalendarEvent e, DateTime day) {
    final d = DateUtils.dateOnly(day);
    final s = DateUtils.dateOnly(e.start);
    if (d.isBefore(s)) return false;
    if (e.recurrence != GoalRecur.none &&
        e.recurEnd != null &&
        d.isAfter(DateUtils.dateOnly(e.recurEnd!))) {
      return false;
    }
    switch (e.recurrence) {
      case GoalRecur.none:
        return d == s;
      case GoalRecur.daily:
        return true;
      case GoalRecur.weekly:
        final days =
            e.recurDaysOfWeek.isEmpty ? [e.start.weekday] : e.recurDaysOfWeek;
        return days.contains(d.weekday);
      case GoalRecur.monthly:
        return d.day == e.start.day;
    }
  }

  /// Events occurring on [day], all-day first, then by start time.
  List<GoalendarEvent> eventsForDay(DateTime day) {
    final list = events.where((e) => occursOn(e, day)).toList();
    list.sort((a, b) {
      if (a.allDay != b.allDay) return a.allDay ? -1 : 1;
      final at = a.start.hour * 60 + a.start.minute;
      final bt = b.start.hour * 60 + b.start.minute;
      return at.compareTo(bt);
    });
    return list;
  }

  int countForDay(DateTime day) => eventsForDay(day).length;

  /// Up to 3 distinct category colours on a day, for the month-grid dots.
  List<Color> dotColorsForDay(DateTime day) {
    final seen = <int>{};
    final out = <Color>[];
    for (final e in eventsForDay(day)) {
      if (seen.add(e.category.colorValue)) out.add(e.color);
      if (out.length == 3) break;
    }
    return out;
  }

  int get todayCount => countForDay(DateTime.now());

  /// The next N upcoming occurrences from now, for the agenda view.
  List<({DateTime day, GoalendarEvent event})> upcoming({int days = 30}) {
    final out = <({DateTime day, GoalendarEvent event})>[];
    final today = DateUtils.dateOnly(DateTime.now());
    for (int i = 0; i < days; i++) {
      final day = today.add(Duration(days: i));
      for (final e in eventsForDay(day)) {
        out.add((day: day, event: e));
      }
    }
    return out;
  }
}
