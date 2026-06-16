# DECISIONS — durable lessons

> Long-cadence memory (touch only when something fundamental is learned). Hard-won
> facts and architecture decisions that should never have to be rediscovered. Each entry:
> the decision/lesson, and *why* — so a future session doesn't undo it.

## Platform / pipeline

- **Flutter cannot build or run iOS from Windows.** No macOS/Xcode → no local iPhone
  run, no `flutter run` to device. iOS path is **Codemagic → TestFlight** only. Don't
  waste time trying iTunes/USB/local device detection — it can't work here.
- **Bump `+build` on every upload.** Apple rejects duplicate `CFBundleVersion`
  ("ENTITY_ERROR ... DUPLICATE", "bundle version must be higher than previously
  uploaded"). Every TestFlight push needs a new build number.
- **Answer encryption compliance in code**, not in the dashboard: set
  `ITSAppUsesNonExemptEncryption=false` in `Info.plist`. Otherwise every build sits at
  "Missing Compliance" and a human has to click through it.
- **TestFlight "redeem code" ≠ a build problem.** It means the device isn't on the tester
  list. Add the Apple ID to the internal group. Don't rebuild to "fix" it.

## Launch stability

- **THE instant-crash root cause (found 2026-06-16): iOS 26 requires the UIScene
  lifecycle.** Apps built with the iOS 26 SDK (Codemagic = Xcode 26.4) that still use
  the legacy UIKit lifecycle are killed by the OS at launch, before the Flutter engine
  starts — instant, device/OS-specific (iOS 26.5), reproducible on EVERY build, and
  UNCATCHABLE by any Dart guard (runZonedGuarded never had a chance). Ran fine on web
  the whole time. Fix = adopt UIScene: AppDelegate conforms to
  `FlutterImplicitEngineDelegate` + registers plugins in
  `didInitializeImplicitFlutterEngine`; Info.plist gets `UIApplicationSceneManifest`
  (FlutterSceneDelegate). Needs Flutter ≥3.38 (on 3.41.9). Build 17, commit 590f191.
  Lesson: launch crash that is device/OS-specific + uncatchable + fine on web ⇒ it's
  the NATIVE layer (lifecycle/plist/plugins), NOT Dart. Stop bumping build numbers.

- **Release mode is unforgiving where debug is silent.** The instant-crash bugs
  (MediaQuery-at-root, `late` field init, premature navigation) all "worked" in debug.
  Test assumptions against release behavior, and keep the three-layer guard in
  [[CLAUDE]]'s crash-safety contract — they are load-bearing, not decoration.
- **A toast must never crash the app.** UI-notification helpers run during splash-time
  network calls before the first screen is mounted; wrap them so they can only no-op,
  never throw. (`AppSnackBar` learned this the hard way.)

## Working with this user

- VJ is non-technical and time-pressed. **One action at a time, with a clickable link.**
  Don't narrate options; give the next concrete step. `8` means "next step."
- Claude's computer-use grant on Chrome is **read-only** (screenshots only, no clicks).
  For real browser automation use the Playwright driver, and **never** type the user's
  Apple ID password or 2FA — the user authenticates, Claude drives the live session.

## Don't-regress list

- Don't reintroduce raw `Get.snackbar`/`print` for user messns — use `AppSnackBar`.
- Don't store passwords anywhere; tokens go to `flutter_secure_storage` only.
- Don't call `MediaQuery.of(context)` at the root widget.
- Don't move controller construction out of `addPostFrameCallback` in `main.dart`.
