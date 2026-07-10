import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../local/local_data.dart';
import '../../features/leads/model/lead.dart';

/// Local (on-device) reminder notifications.
///
/// Deliberately NOT "random": we schedule at most three meaningful, opt-in
/// nudges a day, each driven by the user's own data (daily goal, streak, cold
/// leads). Everything is local — no backend, no push service, no cost. Nothing
/// fires until the user turns reminders on in Settings, so we never burn the
/// one-time iOS permission prompt on spam.
///
/// Re-scheduling happens on every app launch and whenever a toggle changes, so
/// the copy (streak count, goal, stale-lead count) stays fresh. Repeating daily
/// reminders use [DateTimeComponents.time] so they keep firing even if the app
/// is never reopened.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final LocalService _local = LocalService();
  bool _initialized = false;

  // Fixed IDs so re-scheduling REPLACES the existing reminder instead of piling
  // up duplicates.
  static const int _idMorning = 8001;
  static const int _idEvening = 8002;
  static const int _idLeads = 8003;
  static const int _idTest = 8009;

  // Sensible, non-spammy fixed times.
  static const int _morningHour = 8, _morningMin = 0; // 8:00 AM
  static const int _eveningHour = 19, _eveningMin = 0; // 7:00 PM
  static const int _leadsHour = 17, _leadsMin = 0; // 5:00 PM

  static const String _leadsBoxName = 'leads_v1';

  /// Idempotent. Safe to call multiple times; only the first does work.
  /// Never throws — a notification setup failure must not crash startup.
  Future<void> init() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();
      try {
        final name = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(name));
      } catch (_) {
        // Couldn't resolve the device zone — leave the default. Times could be
        // off, but that's far better than crashing the app on launch.
      }

      const android = AndroidInitializationSettings('launcher_icon');
      const ios = DarwinInitializationSettings(
        // We request permission explicitly when the user opts in, not on launch.
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService.init failed: $e');
    }
  }

  /// Ask the OS for permission. Returns whether it was granted. Call this the
  /// moment the user flips the master toggle on — never at startup.
  Future<bool> requestPermission() async {
    await init();
    try {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? true;
      }
    } catch (e) {
      debugPrint('requestPermission failed: $e');
    }
    return true;
  }

  /// Called on app launch: reschedule if the user has reminders on, otherwise
  /// make sure nothing is lingering.
  Future<void> rescheduleIfEnabled() async {
    final enabled = await _local.getNotificationsEnabled();
    if (!enabled) {
      await cancelAll();
      return;
    }
    await refreshSchedule();
  }

  /// Cancel + reschedule every enabled reminder with fresh, personalized copy.
  Future<void> refreshSchedule() async {
    await init();
    try {
      await cancelAll();
      final prefs = await SharedPreferences.getInstance();

      if (await _local.getNotifyMorningGoal()) {
        final goal = prefs.getInt('daily_goal') ?? 10;
        await _scheduleDaily(
          id: _idMorning,
          hour: _morningHour,
          minute: _morningMin,
          channelId: 'daily_goal',
          channelName: 'Daily Goal',
          title: 'Time to hit the doors 🚪',
          body:
              "Today's target: $goal knocks. Every \"no\" gets you closer to a \"yes\" — let's go.",
        );
      }

      if (await _local.getNotifyEveningStreak()) {
        final streak = prefs.getInt('ach_streak') ?? 0;
        final body = streak > 0
            ? "🔥 $streak-day streak on the line. Log today's knocks before midnight to keep it alive."
            : 'Start a streak today 🔥 Log your knocks and don\'t break the chain.';
        await _scheduleDaily(
          id: _idEvening,
          hour: _eveningHour,
          minute: _eveningMin,
          channelId: 'streak',
          channelName: 'Streak Reminders',
          title: 'Keep your streak alive',
          body: body,
        );
      }

      if (await _local.getNotifyLeadFollowup()) {
        final stale = await _staleLeadCount();
        if (stale > 0) {
          await _scheduleDaily(
            id: _idLeads,
            hour: _leadsHour,
            minute: _leadsMin,
            channelId: 'leads',
            channelName: 'Lead Follow-ups',
            title: 'Follow-ups waiting 📞',
            body: stale == 1
                ? "1 lead hasn't heard from you in a while. A quick call could close it."
                : "$stale leads haven't heard from you in a while. A few quick calls could close one.",
          );
        }
      }
    } catch (e) {
      debugPrint('refreshSchedule failed: $e');
    }
  }

  /// Fire an immediate notification so the user can confirm it works.
  Future<void> showTest() async {
    await init();
    try {
      await _plugin.show(
        _idTest,
        "You're all set 🎉",
        "This is how GoalShare will nudge you to keep your momentum going.",
        _details('test', 'Test'),
      );
    } catch (e) {
      debugPrint('showTest failed: $e');
    }
  }

  Future<void> cancelAll() async {
    // Only touch our own IDs — never nuke notifications we didn't create.
    try {
      await _plugin.cancel(_idMorning);
      await _plugin.cancel(_idEvening);
      await _plugin.cancel(_idLeads);
    } catch (_) {}
  }

  // ── internals ──────────────────────────────────────────────────────────────

  Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String channelId,
    required String channelName,
    required String title,
    required String body,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOf(hour, minute),
      _details(channelId, channelName),
      // Inexact avoids needing the SCHEDULE_EXACT_ALARM permission on Android 12+.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // Repeat every day at this time until we reschedule.
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  NotificationDetails _details(String channelId, String channelName) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'GoalShare reminders',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Count active leads (not Won/Lost) whose last update is older than [days].
  /// Opens the Hive box read-only if it isn't already open; never closes it.
  Future<int> _staleLeadCount({int days = 3}) async {
    try {
      final box = Hive.isBoxOpen(_leadsBoxName)
          ? Hive.box<String>(_leadsBoxName)
          : await Hive.openBox<String>(_leadsBoxName);
      final cutoff = DateTime.now().subtract(Duration(days: days));
      var count = 0;
      for (final raw in box.values) {
        try {
          final lead = Lead.fromJsonString(raw);
          if (lead.status == 'Won' || lead.status == 'Lost') continue;
          if (lead.updatedAt.isBefore(cutoff)) count++;
        } catch (_) {
          // Skip a single malformed record; never let it break scheduling.
        }
      }
      return count;
    } catch (_) {
      return 0;
    }
  }
}
