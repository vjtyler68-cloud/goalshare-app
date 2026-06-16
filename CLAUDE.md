# CLAUDE.md — GoalShare (internal name: spanx)

> Read `brain/` at the start of every session (see "Second brain" below). It holds
> live state, the running log, and hard-won lessons that are NOT obvious from the code.

## What this is

GoalShare is a goal-tracking + budgeting + motivation mobile app. Flutter front end,
Node backend, Next.js admin dashboard. The owner (VJ) is **non-technical** and is
driving this toward public App Store + Google Play release.

- **Talk plainly.** No jargon unless you define it. When a step needs the user to act
  in a browser/phone, give a **clickable link** and one concrete instruction at a time.
- The user types **`8`** to mean "ok, what's the next step — move on."

## The three repos

| Part | Path | Notes |
|------|------|-------|
| Flutter app | `C:\Users\vjtyl\Downloads\spanx_extracted\spanx\` | this repo |
| Node backend | `C:\Users\vjtyl\Downloads\backend_extracted\` | API host: see `brain/STATE.md` (verify — has drifted) |
| Next.js dashboard | `C:\Users\vjtyl\Downloads\dashboard_extracted\spanx_neworld-dashbaord\` | admin |

## App identity

- Internal package name: `spanx` · Display name: **GoalShare** · Bundle ID: `com.goal.share`
- Version lives in `pubspec.yaml` as `1.3.0+<build>`. **Bump the `+build` number for
  every TestFlight/Play upload** — Apple rejects duplicate build numbers.
- GitHub: `github.com/vjtyler68-cloud/goalshare-app`, default branch **`main`**.

## Release pipeline (iOS)

1. Push to `main`.
2. Build runs on **Codemagic** (app id `6a2c479c589964d832f45931`, config `codemagic.yaml`,
   workflow `ios-testflight`). ~6 min with cache, ~15 min cold.
3. Codemagic auto-submits to **TestFlight** (App Store Connect app id `6779742874`).
4. Testers install via the TestFlight app.

**Claude cannot click in the user's Chrome** (granted read-only). To drive the browser
autonomously use the Playwright driver in `C:\flutter\pw-driver\` (see `brain/STATE.md`).
Never enter the user's Apple ID password or 2FA — the user authenticates; Claude drives
the already-logged-in session.

## Startup crash-safety contract (do not regress)

Release-mode iOS crashed instantly several times. The launch path is now guarded in
three layers — keep them:

- `lib/main.dart` — everything inside `runZonedGuarded`; `FlutterError.onError` set;
  `initHive()` in try/catch; controllers started in `addPostFrameCallback` (navigator
  must exist before any controller navigates).
- `lib/core/const/app_size.dart` — `AppSizes` fields have **safe defaults**, no `late`.
  Never call `MediaQuery.of(context)` at the root widget.
- `lib/core/services/no_internet/controller.dart` — navigation guarded by
  `Get.key?.currentContext == null` check.
- `lib/core/global_widgets/app_snackbar.dart` — whole body wrapped in try/catch; a toast
  must never crash the app (it runs during splash-time network calls).
- `ios/Runner/Info.plist` — `ITSAppUsesNonExemptEncryption = false` (skips the App Store
  Connect compliance prompt automatically).

## Conventions

- State management: **GetX** (`Get.put`/`lazyPut`, `Get.toNamed`). Bindings in
  `lib/bindings/bindings.dart` (mostly `lazyPut` + `fenix: true`).
- Storage: tokens → `flutter_secure_storage`; everything else → `shared_preferences`
  (`lib/core/local/local_data.dart`). **Never store passwords.**
- Network: `lib/core/network_caller/network_config.dart` (singleton, Bearer auth,
  30s timeout, graceful errors). A `network_config_v2.dart` exists as a migration target.
- User-facing messages: `AppSnackBar.success/error` — never raw `Get.snackbar` or `print`.
- Responsive sizing: `AppSizes.h/w/sp` and ScreenUtil `.sp/.w/.h/.r`.

## Known open risks (keep current in `brain/STATE.md`)

- `lib/core/const/app_fonts.dart` fetches Google Fonts over HTTP at launch — network
  dependency + App Store review flag. Fix = bundle the fonts in assets.
- No tests anywhere. No token-refresh flow. Dark mode not implemented.
- Backend `.env` secrets were exposed and still need rotation (Stripe, DB, Cloudinary,
  DO Spaces, JWT). Auth endpoints lack rate limiting.

## Build / quality commands

```bash
flutter pub get
flutter analyze
dart format .
flutter build ipa --release   # iOS (built on Codemagic, not Windows)
flutter build apk --release    # Android
```

> The older `INDEX.md` / `FINAL_SUMMARY.md` / `PROJECT_REVIEW.md` etc. are verbose,
> human-oriented summaries from an earlier review. `CLAUDE.md` + `brain/` supersede them
> as the canonical, Claude-facing source of truth.
