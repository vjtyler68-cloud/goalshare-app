import 'dart:developer';

import 'package:device_calendar/device_calendar.dart' as dc;
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/goalendar_models.dart';

/// Two-way bridge between Goalendar and the native iPhone Calendar (EventKit).
///
/// WRITE side: Goalendar events are mirrored into a dedicated "Goalshare"
/// calendar (never the user's default), so they're easy to isolate/delete.
/// READ side: events from the user's OTHER calendars are pulled in read-only so
/// the user sees their whole schedule in one place. Everything is best-effort:
/// any failure (permission denied, no calendar) leaves Goalendar fully working
/// local-only.
class EventKitSyncService {
  EventKitSyncService._();
  static final EventKitSyncService instance = EventKitSyncService._();

  final dc.DeviceCalendarPlugin _plugin = dc.DeviceCalendarPlugin();
  static const String _calName = 'Goalshare';
  String? _calendarId;
  bool _tzReady = false;

  Future<void> _ensureTz() async {
    if (_tzReady) return;
    try {
      tzdata.initializeTimeZones();
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // tz.local falls back to UTC; times could shift but sync still works.
    }
    _tzReady = true;
  }

  /// Ask for calendar access (returns true if granted). Safe to call repeatedly.
  Future<bool> ensureAccess() async {
    try {
      final has = await _plugin.hasPermissions();
      if (has.isSuccess && has.data == true) return true;
      final req = await _plugin.requestPermissions();
      return req.isSuccess && req.data == true;
    } catch (e) {
      log('EventKit access: $e');
      return false;
    }
  }

  /// Find (or create) the dedicated Goalshare calendar; null if unavailable.
  Future<String?> _ensureCalendar() async {
    if (_calendarId != null) return _calendarId;
    try {
      final res = await _plugin.retrieveCalendars();
      if (res.isSuccess && res.data != null) {
        for (final c in res.data!) {
          if (c.name == _calName && c.isReadOnly != true) {
            _calendarId = c.id;
            return _calendarId;
          }
        }
      }
      final created = await _plugin.createCalendar(_calName,
          calendarColor: const Color(0xff7C3AED));
      if (created.isSuccess) {
        _calendarId = created.data;
        return _calendarId;
      }
    } catch (e) {
      log('EventKit ensureCalendar: $e');
    }
    return null;
  }

  /// Mirror a Goalendar event into the device calendar. Returns the EventKit id
  /// (store it on the event so future edits update the same one).
  Future<String?> push(GoalendarEvent e) async {
    if (e.deviceReadOnly) return null; // never write back a pulled event
    await _ensureTz();
    final calId = await _ensureCalendar();
    if (calId == null) return null;
    try {
      final ev = dc.Event(
        calId,
        eventId: e.eventKitId,
        title: e.title,
        description: e.notes,
        location: e.location,
        start: tz.TZDateTime.from(e.start, tz.local),
        end: tz.TZDateTime.from(e.end, tz.local),
        allDay: e.allDay,
        reminders:
            e.reminderMinutes.map((m) => dc.Reminder(minutes: m)).toList(),
      );
      final res = await _plugin.createOrUpdateEvent(ev);
      if (res != null && res.isSuccess) return res.data;
    } catch (e2) {
      log('EventKit push: $e2');
    }
    return null;
  }

  Future<void> remove(GoalendarEvent e) async {
    final calId = _calendarId ?? await _ensureCalendar();
    final ekId = e.eventKitId;
    if (calId == null || ekId == null) return;
    try {
      await _plugin.deleteEvent(calId, ekId);
    } catch (e2) {
      log('EventKit remove: $e2');
    }
  }

  /// Read events from the user's OTHER calendars in [start]..[end], as
  /// read-only Goalendar events for display.
  Future<List<GoalendarEvent>> pull(DateTime start, DateTime end) async {
    await _ensureTz();
    final out = <GoalendarEvent>[];
    try {
      final cals = await _plugin.retrieveCalendars();
      if (!cals.isSuccess || cals.data == null) return out;
      final goalCalId = await _ensureCalendar();
      for (final cal in cals.data!) {
        final id = cal.id;
        if (id == null || id == goalCalId) continue; // ours is already local
        final evRes = await _plugin.retrieveEvents(
            id, dc.RetrieveEventsParams(startDate: start, endDate: end));
        if (!evRes.isSuccess || evRes.data == null) continue;
        for (final ev in evRes.data!) {
          final s = ev.start;
          final en = ev.end;
          if (s == null) continue;
          final now = DateTime.now();
          out.add(GoalendarEvent(
            id: 'ek_${ev.eventId ?? '${id}_${s.millisecondsSinceEpoch}'}',
            title: (ev.title ?? '').trim().isEmpty ? '(No title)' : ev.title!,
            start: DateTime.fromMillisecondsSinceEpoch(s.millisecondsSinceEpoch),
            end: DateTime.fromMillisecondsSinceEpoch(
                (en ?? s).millisecondsSinceEpoch),
            allDay: ev.allDay ?? false,
            location: ev.location,
            notes: ev.description,
            category: GoalCategory.other,
            createdAt: now,
            updatedAt: now,
          )..deviceReadOnly = true);
        }
      }
    } catch (e) {
      log('EventKit pull: $e');
    }
    return out;
  }
}
