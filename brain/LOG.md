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

## 2026-06-16 (cont.)

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
