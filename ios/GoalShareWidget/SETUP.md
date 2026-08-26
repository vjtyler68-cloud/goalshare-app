# GoalShare home-screen widget — setup

The Swift widget (streak 🔥 / today's XP ⚡ / ritual ✓) is written and lives in
`ios/GoalShareWidget/`. It is **inert** until it's added as a target in Xcode —
so right now it does **not** affect the app build at all.

To make the widget appear on the home/lock screen, there's a one-time native
setup that has to happen in **Xcode** + your **Apple Developer account**. It
cannot be done from the Flutter code alone, and doing the signing part wrong can
break the whole iOS build — so it's isolated here until you're ready.

Data flow once set up: the Flutter app writes `streak`, `todayXp`, `level`,
`levelTitle`, `ritualDone`, `streakAlive` into a shared **App Group**
(`group.com.goal.share`); the widget reads them from that same App Group.

---

## Step 1 — Apple Developer portal (developer.apple.com → Certificates, IDs & Profiles)

1. **Identifiers → App Groups → +** → create `group.com.goal.share`.
2. Open your app's **App ID** (`com.goal.share`) → enable **App Groups** →
   check `group.com.goal.share` → Save.
3. **Identifiers → App IDs → +** → new App ID `com.goal.share.GoalShareWidget`
   (name "GoalShare Widget") → enable **App Groups** → check
   `group.com.goal.share` → Save.
4. Regenerate / let Codemagic regenerate the provisioning profiles so both the
   app and the widget include the App Group. (If Codemagic uses an App Store
   Connect API key with automatic signing, it will create the widget profile on
   the next build once the target exists.)

## Step 2 — Xcode (open `ios/Runner.xcworkspace`)

1. **File → New → Target… → Widget Extension.** Name it **GoalShareWidget**,
   uncheck "Include Configuration Intent", finish, activate the scheme.
2. Xcode creates a `GoalShareWidget` group with a template `.swift` + `Info.plist`.
   **Replace** the generated `GoalShareWidget.swift` and `Info.plist` with the
   ones already in this folder (`ios/GoalShareWidget/GoalShareWidget.swift`,
   `Info.plist`). (Delete the template Assets/IntentHandler if created.)
3. Add `ios/GoalShareWidget/GoalShareWidget.entitlements` to the widget target:
   select the **GoalShareWidget** target → **Signing & Capabilities → + Capability
   → App Groups** → check `group.com.goal.share`. (This wires the entitlements.)
4. Select the **Runner** target → **Signing & Capabilities → + Capability → App
   Groups** → check `group.com.goal.share`. (This adds the App Group to
   `Runner.entitlements` — do NOT hand-edit that file before the App Group is
   registered in Step 1, or signing fails.)
5. Set the widget target's **iOS Deployment Target** to **15.0** (match Runner)
   and its bundle id to `com.goal.share.GoalShareWidget`.

## Step 3 — Flutter side (the data bridge)

1. In `pubspec.yaml` under `dependencies:` add:

   ```yaml
   home_widget: ^0.6.0
   ```

   then `flutter pub get`.

2. Create `lib/core/widgets/home_widget_service.dart`:

   ```dart
   import 'package:get/get.dart';
   import 'package:home_widget/home_widget.dart';

   import '../daily_checks/daily_check_service.dart';
   import '../../features/achievements/achievements_controller.dart';

   /// Pushes the live streak / XP / level / ritual status into the shared App
   /// Group so the iOS home-screen widget can read them. Safe no-op until the
   /// native widget + App Group are set up (every call is guarded).
   class HomeWidgetService {
     HomeWidgetService._();
     static final HomeWidgetService instance = HomeWidgetService._();

     static const String _appGroup = 'group.com.goal.share';
     static const String _iOSWidget = 'GoalShareWidget';
     bool _init = false;

     Future<void> _ensureInit() async {
       if (_init) return;
       try {
         await HomeWidget.setAppGroupId(_appGroup);
         _init = true;
       } catch (_) {}
     }

     Future<void> refresh() async {
       try {
         await _ensureInit();
         final ach = Get.isRegistered<AchievementsController>()
             ? Get.find<AchievementsController>()
             : null;
         bool ritualDone = false;
         try {
           ritualDone =
               DailyCheckService.to.isDoneToday(DailyCheckFeature.ritual);
         } catch (_) {}
         await HomeWidget.saveWidgetData<int>('streak', ach?.currentStreak.value ?? 0);
         await HomeWidget.saveWidgetData<int>('todayXp', ach?.todayXP.value ?? 0);
         await HomeWidget.saveWidgetData<int>('level', ach?.level ?? 1);
         await HomeWidget.saveWidgetData<String>('levelTitle', ach?.levelTitle ?? '');
         await HomeWidget.saveWidgetData<bool>('ritualDone', ritualDone);
         await HomeWidget.saveWidgetData<bool>('streakAlive', ach?.streakAlive ?? false);
         await HomeWidget.updateWidget(iOSName: _iOSWidget, name: _iOSWidget);
       } catch (_) {
         // Not set up yet (no App Group / no widget) — safe to ignore.
       }
     }
   }
   ```

3. Wire it (three call sites):
   - In `lib/main.dart`, after the notification block:
     `HomeWidgetService.instance.refresh();`
   - In `lib/features/achievements/achievements_controller.dart`, at the end of
     `_save()`: `HomeWidgetService.instance.refresh();`
   - In `lib/core/daily_checks/daily_check_service.dart`, at the end of
     `markDoneToday()`: `HomeWidgetService.instance.refresh();`
   (Add the import `import '../widgets/home_widget_service.dart';` /
   `import '../../core/widgets/home_widget_service.dart';` as appropriate.)

## Step 4 — Codemagic

- If using automatic signing with an App Store Connect API key: the next build
  provisions the widget App ID + App Group automatically once the target exists.
- If using manual signing: add the widget's distribution profile
  (`com.goal.share.GoalShareWidget`) to the Codemagic code-signing settings
  alongside Runner's.

## Verify

Build → install → long-press the home screen → **+** → search **GoalShare** →
add the widget. Check off a task or finish the ritual in the app; the tile
updates within a few seconds (and on its periodic refresh).
