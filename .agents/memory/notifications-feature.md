---
name: Local notifications / reminders feature
description: On-device retention reminders — how they're scheduled, why opt-in, and the key gotchas.
---

# Local reminder notifications

Retention nudges are **local** (flutter_local_notifications) — no push service, no
backend, no cost. Lives in `lib/core/notifications/notification_service.dart`
(singleton) with a settings screen under `lib/features/notifications/`.

Three opt-in daily reminders, max ~3/day (deliberately NOT "random" — random
notifications get the app muted/deleted and burn the iOS permission prompt):
morning goal nudge, evening streak protection, lead follow-up (only if there are
stale leads). Copy is personalized from the user's own data.

## Key decisions / gotchas
- **Opt-in, master default OFF.** Permission is requested ONLY when the user
  flips the master toggle — never at launch. **Why:** iOS shows the permission
  prompt once; spending it on an unprompted ask (or on spam) loses the channel
  forever. Prefs in `LocalService` (`notif_enabled` etc.; sub-toggles default ON).
- **Reschedule on every launch + every toggle change** (`rescheduleIfEnabled` in
  main.dart post-frame). Reminders are daily-repeating (`matchDateTimeComponents:
  DateTimeComponents.time`), so they keep firing if the app is never reopened;
  rescheduling just refreshes the copy (streak/goal/stale-lead counts).
- **Fixed notification IDs** (8001/8002/8003) so rescheduling REPLACES rather
  than piling up duplicates. `cancelAll()` only cancels our own IDs.
- **Android:** `AndroidScheduleMode.inexactAllowWhileIdle` on purpose — avoids
  needing the SCHEDULE_EXACT_ALARM permission on Android 12+. Added
  POST_NOTIFICATIONS to the manifest.
- **iOS AppDelegate:** set `UNUserNotificationCenter.current().delegate = self as?
  UNUserNotificationCenterDelegate` (the `as?` cast is the official pattern —
  avoids a conformance compile error). Plugin registration itself lives in
  SceneDelegate (iOS-26 UIScene pattern).
- **Timezone:** must `tz.setLocalLocation` from `FlutterTimezone.getLocalTimezone()`
  (returns String in flutter_timezone 3.x — do NOT bump to 4.x which returns an
  object) or daily reminders fire at the wrong local time. Guarded: falls back to
  default zone rather than crashing.
- **Data coupling:** service reads SharedPreferences keys owned by other
  controllers (`daily_goal` from MissionController, `ach_streak` from
  AchievementsController) and the Hive `leads_v1` box directly. If those keys/box
  name change, update the service. All reads are guarded; scheduling never throws.

## Deps added
`flutter_local_notifications ^17.2.4`, `timezone ^0.9.4`, `flutter_timezone ^3.0.1`.
Cannot compile locally — real verification is the Codemagic build.
