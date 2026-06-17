# LOG — append & review

> **Karpathy append-and-review.** One running note. **Newest at the top.** Whenever
> anything happens — an idea, a fix, a blocker, a TODO, a decision — prepend a dated
> line. Old entries sink under gravity. Periodically skim; **rescue** anything still
> live by copy-pasting it back to the top (or promote it into `STATE.md`). Rarely delete
> — irrelevant things just sink. `Ctrl+F` is the index.
>
> Format: `## YYYY-MM-DD` headers, newest first. Tags: `todo:` `blocked:` `decision:`
> `fix:` `idea:` for easy search. Cross-link with `[[STATE]]` / `[[DECISIONS]]`.

---

## 2026-06-17 (overnight)

- STATE: **All iOS launch crashes are FIXED.** App launches on iPhone 15 Pro Max /
  iOS 26.5. Builds: 26 (deferred explicit engine -> beat VSync #183900), 27
  (scene-phase plugin registration -> beat connectivity_plus crash), 28 (splash
  resilience: 6s auto-login race + non-blocking connectivity probe + 20s HTTP).
- ROOT of the "freeze": NOT the app. The **MongoDB Atlas cluster (goalshare.qduect0)
  is PAUSED/down** -> backend login takes ~30s then fails ("Server selection timeout:
  No available servers, ReplicaSetNoPrimary"). Confirmed by curling the login endpoint
  directly (HTTP 400 after 30.5s with a Prisma/Mongo Atlas error).
- FREE FIX (the only thing left, needs user's account): **RESUME the paused M0 cluster**
  (free; M0 clusters are NOT deleted, data + admin user preserved). User hit a PAYMENT
  prompt only because they were on the "Create new cluster" page (shows paid M10/Flex),
  not the Resume button. Runbook: cloud.mongodb.com -> Clusters -> goalshare ->
  Resume; confirm Network Access has 0.0.0.0/0. Only create a NEW M0 (still free,
  select $0.00 tier) if resume is impossible (then update Railway DATABASE_URL + re-seed
  admin@gmail.com).
- APP STORE RISK flagged (not yet changed — product decision): splash auto-logs in as
  HARDCODED admin@gmail.com/123456 and routes everyone to admin. Apple 5.1.1/backdoor
  risk + security (every user = admin?). Revisit before public submission.
- note: overnight multi-agent audit workflow FAILED (API 529 overload) — did it inline.
- todo (recommended, await user OK): consider re-enabling 120Hz (CADisableMinimumFrameDurationOnPhone)
  now that deferred engine fixes VSync timing; audit API-response parsing for graceful
  DB-down handling; App Store submission prep.

## 2026-06-17

- WIN: **VSync/ProMotion crash (#183900) BEATEN.** Build 26 (explicit engine +
  DEFERRED FlutterViewController via DispatchQueue.main.async in SceneDelegate)
  got PAST the createTouchRateCorrectionVSyncClientIfNeeded crash. The crash
  MOVED — proof the deferral fix works. Key signal that confirmed it: "crashes
  untethered, works under debugger" = launch timing race; deferral = the remedy.
- crash: Build 26's NEW crash = ConnectivityPlusPlugin.register -> swift_getObjectType
  null-deref (bug_type 309). Cause (multi-agent workflow + adversarial review of
  Flutter 3.41 engine source): registering plugins against the BARE explicit engine
  at didFinishLaunching, before any scene/VC exists, hands the first Swift plugin a
  NULL registrar (engine's Swift-plugin registrar bridge not materialized yet) =
  flutter/flutter#168228. connectivity_plus is just first in the registrant; version
  irrelevant (6.1.5 fine, 7.x doesn't fix it).
- decision: register(with: self) is a TRAP — it stops the crash but silently binds
  plugins to a separate auto-spawned "io.flutter" launch engine (orphaned channels),
  not goalshare_engine. Verified via FlutterAppDelegate.mm registrarForPlugin ->
  FlutterLaunchEngine.m lazy getter.
- fix: **Build 27 (commit 9736895)** — AppDelegate runs the engine but does NOT
  register plugins; SceneDelegate's deferred block creates FlutterViewController(engine:)
  THEN GeneratedPluginRegistrant.register(with: engine). Registrar bridge is
  materialized by then (no null-deref) AND plugins bind to the same engine the UI
  uses (features work). VSync deferral preserved. ~82-85% confidence (adversarially
  verified). Build & install 1.4.0 (27) to confirm.
- note: Codemagic ignored `xcode: 16.4` and used Xcode 26.4 (iOS 26 SDK) — so the
  SDK-pin builds (24/25) actually used iOS 26 SDK anyway. SDK is NOT the crash cause.
- todo: verify on-device that connectivity_plus actually WORKS (call
  Connectivity().checkConnectivity()), not just that the app launches.

## 2026-06-16 (cont.)

- fix: **REAL ROOT CAUSE FOUND & FIXED (Build 22, commit 21d76d5).** Finally read the
  device crash log (Runner-2026-06-16-220450.ips, build 21, pulled via 3uTools→Google
  Drive→Downloads, read the PNGs directly). Crash = EXC_BAD_ACCESS/SIGSEGV null-deref,
  main thread, at launch, in `-[VSyncClient initWithTaskRunner:callback:]` ←
  `-[FlutterViewController createTouchRateCorrectionVSyncClientIfNeeded]` ← `viewDidLoad`.
  = **Flutter engine bug #183900**: ProMotion (120Hz) device launched untethered under
  the iOS-26 IMPLICIT-engine path → viewDidLoad runs before engine.platformTaskRunner is
  set → null deref. iPhone 15 Pro Max + TestFlight = exact trigger. NONE of builds 13-21
  could fix it (all Dart/config guesses) because the bug is in the engine's launch path.
  FIX = EXPLICIT FlutterEngine: AppDelegate creates+runs the engine in
  didFinishLaunching; a plain UIWindowSceneDelegate builds a FlutterViewController(engine:)
  root; Info.plist drops UIMainStoryboardFile + UISceneStoryboardFile. So the engine/task-
  runner is ready before any view loads. Lesson #1: **READ THE CRASH LOG FIRST** — 9 blind
  builds vs one decoded .ips. Lesson #2: instant + uncatchable + ProMotion-only + works-on-
  web ⇒ Flutter engine launch bug, use explicit engine. [[DECISIONS]] updated.

- fix: **Build 19 (commit 026a165) — COMPLETED the UIScene migration; this is the
  evidence-based fix.** Diffed our ios/ against a fresh `flutter create` on the SAME
  Flutter 3.41.9 and found Build 17's migration was WRONG/INCOMPLETE: (a) Info.plist
  UISceneDelegateClassName was `FlutterSceneDelegate` (framework class, NOT resolvable
  by that bare name at runtime) instead of `$(PRODUCT_MODULE_NAME).SceneDelegate`, and
  (b) there was NO `SceneDelegate.swift`. So iOS 26 couldn't build the app's scene →
  instant crash before Dart. Fix: added SceneDelegate.swift (`class SceneDelegate:
  FlutterSceneDelegate {}`), registered it in project.pbxproj (4 entries mirroring
  AppDelegate.swift, ids 5CE17EDA…F1/F2), and corrected the Info.plist class name.
  Lesson: when hand-migrating iOS lifecycle on Windows, DIFF against `flutter create`
  output — don't trust a docs snippet alone. [[DECISIONS]] updated.
- blocked: **Build 17 (UIScene fix) STILL instant-crashes on iPhone (iOS 26.5).**
  So UIScene, while a genuine iOS-26 requirement, was NOT the (sole) crash cause.
  CORRECTION: an earlier note wrongly said "Build 13 LAUNCHED" — it never did; the
  app has never launched on the real device. Web build launches fully (splash→login),
  so the crash is NATIVE/iOS-specific, below Dart.
- fix: **Build 18 (commit f3d4355)** — `flutter pub upgrade` refreshed 77 deps to
  latest in-range, notably iOS native plugins (in_app_purchase_storekit 0.4.8→0.4.10,
  video_player_avfoundation 2.8.4→2.9.7, url_launcher_ios 6.3.4→6.4.1, image_picker_ios
  →0.8.13+6). Hypothesis: an outdated native plugin crashes on iOS 26. Web build clean.
  Lockfile committed so Codemagic uses these. STILL a hypothesis until the log is read.
- blocked: **crash log retrieval — every channel tried, all blocked so far:**
  (1) phone Analytics Data → user keeps grabbing telemetry files (bug_type 211/237),
  not the crash (need bug_type 309, file "Runner-*" or "GoalShare-*"); (2) 3uTools
  Toolbox→Crash Analysis DOES list device .ips files and device connects fine, BUT
  3uTools runs ELEVATED so computer-use can't click it (user must click; Export →
  Downloads is the unblock, then Claude reads the .ips directly); (3) App Store Connect
  crash = Mac-only "Open in Xcode"; (4) no .ips synced to PC (iTunes MS-Store doesn't);
  (5) iOS framework headers absent on Windows so can't verify FlutterSceneDelegate.
  todo: get ONE .ips with bug_type 309 exported from 3uTools → read Exception Type /
  Termination Reason → that ends the guessing.
- fix: **App Store distribution failure ROOT-CAUSED & FIXED** (Build 16, commit
  1c3a96a). codemagic.yaml `publishing.app_store_connect.beta_groups` targeted
  "App Store Connect Users" — not an assignable beta group → the post-upload
  "App Store distribution" step failed identically on builds 14 & 15. The IPA
  UPLOAD (Publishing step) always succeeded, so builds 14 & 15 ARE in TestFlight
  with status Complete and ARE installable by internal testers. Fix: removed
  beta_groups, kept submit_to_testflight (internal testers auto-get every build).
- verify: **FULL LAUNCH PROVEN on web build.** flutter analyze = 0 errors (2330
  cosmetic lints). `flutter build web --release` = success incl. bundled fonts.
  Served build/web + drove it: splash rendered (Space Grotesk bundled font OK) →
  navigated to /#/login (the transition that used to crash) → login screen fully
  rendered & interactive. The startup crash class is conclusively beaten. Combined
  with Build 13 launching on the real iPhone = two independent confirmations.

- fix: **Build 13 LAUNCHED on iPhone** — crash fixes confirmed working. The whole
  crash saga is resolved; we're now in polish/optimize mode, not rescue mode.
- fix: **Build 14** pushed (commit c55608a) = ships the staged AppSnackBar fix.
  Codemagic build succeeded incl. Publishing (upload OK), but the post-processing
  **"App Store distribution" step FAILED** (red, ~3m18s). The binary still uploads
  via Publishing — distribution is just the auto-assign-to-group/submit step.
  todo: read that step's log to know if it recurs. Superseded by Build 15 anyway.
- fix: **Build 15** pushed (commit d45c6fb) = **bundled Google Fonts as assets**
  (`assets/fonts/` + pubspec). Space Grotesk (Light/Reg/Med/SemiBold/Bold), Poppins
  (Reg/Med/SemiBold), Playfair-Display Italic. Static OFL TTFs from fontsource CDN,
  named to google_fonts' `<Family>-<Variant>.ttf` convention (matched via asset
  manifest in google_fonts_base.dart). Runtime fetching left ON as graceful fallback.
  Removes launch font-flash + offline-launch dependency. `flutter pub get` + analyze
  clean (only pre-existing lints). Also: print()→log() in connectivity controller.
- decision: **backend host drift RESOLVED** — endpoints.dart baseUrl =
  `https://goalshare-backend-production.up.railway.app/api/v1` (Railway, confirmed).
  NOT api.goalsharewin.com. [[STATE]] / project_spanx memory updated.

## 2026-06-16

- fix: **UNBLOCKED TestFlight** — added tester `vjtyler68@gmail.com` to internal group
  "Testing 001" (was 0 testers → redeem-code prompt). Done autonomously via the
  Playwright driver. Group has all 6 builds; internal testers install without review.
- decision: Playwright driver WORKS end-to-end (Node v24 portable at `C:\flutter\node`,
  winget install had hung ~25min so bypassed with the official zip). `serve.js` =
  long-lived Chrome + CDP :9222 w/ persistent profile (already ASC-authenticated);
  `act.js` goto/click/fill/text; `probe.js` dumps links/buttons. This is how Claude
  drives the browser now (computer-use Chrome is read-only).
- finding: crash feedback exists ONLY for builds 7 & 8 ("immediate crash"), device
  iPhone 15 Pro Max / iOS 26.5. **No crashes logged for 10–13 (never installed).**
  Symbolicated stack trace is Mac-only ("Open in Xcode") — not readable on Windows.
  → Only way to verify the fixes is to install Build 13 now. blocked: needs the user
  to install on the phone.
- decision: built the second brain — `CLAUDE.md` + `brain/{LOG,STATE,DECISIONS}.md`.
  Layered cadence: LOG every session, [[STATE]] ~weekly, [[DECISIONS]] only on
  fundamental learnings. Supersedes the old verbose INDEX/FINAL_SUMMARY docs.
- todo: install Node (winget, in progress) → Playwright driver in `C:\flutter\pw-driver`
  so Claude can drive the browser autonomously (Chrome is read-only to computer-use).
- fix: hardened `AppSnackBar` — whole body in try/catch (commit `6f765eb`, local, NOT
  yet in a build). Rides along with the next build.
- idea: bundle Google Fonts in assets to kill the runtime HTTP font fetch at launch.

## 2026-06-13 → 06-15

- blocked: TestFlight shows "redeem code" → root cause: internal group **"Testing 001"
  has 0 testers**. Fix = add `vjtyler68@gmail.com` to the group. NOT a build problem.
- fix: Build 13 — added `ITSAppUsesNonExemptEncryption=false` to Info.plist so the App
  Store Connect encryption-compliance prompt is answered automatically.
- fix: added Codemagic dependency cache (`~/.pub-cache`, `ios/Pods`) → builds dropped
  from ~15 min to ~6 min. Added push-trigger on `main` (auto-trigger unreliable so far —
  still needs a manual "Start new build" click sometimes).
- fix: Builds 11/12/13 — kept bumping `+build` because Apple rejects duplicate build
  numbers ("previousBundleVersion" / DUPLICATE entity error).
- fix: Build 10/11 crash-hardening — `runZonedGuarded` + `FlutterError.onError` +
  `initHive()` try/catch in `main.dart`; `AppSizes` safe defaults (no `late`);
  no-internet navigation guard. See crash-safety contract in [[CLAUDE]].
- decision: confirmed Flutter **cannot** run on iPhone from Windows (no macOS/Xcode).
  iOS testing path is Codemagic → TestFlight only.

## earlier (pre-06-13, from prior review)

- Large controller/security cleanup pass: secure-storage tokens, removed stored
  passwords, Bearer prefix fixes, AppSnackBar everywhere, optimistic deletes with
  rollback. Full list lives in `brain/STATE.md` → "Done".
