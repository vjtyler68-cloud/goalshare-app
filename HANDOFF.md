# GoalShare — Developer Handoff

_Last updated: June 2026_

## TL;DR
GoalShare is a **Flutter** goal-tracking app (iOS + Android) backed by a **Node/Prisma (MongoDB)** API and a **Next.js** admin dashboard. The app currently **builds and uploads to TestFlight** (latest upload: `1.4.0 (31)`). All known **App Store code blockers are fixed**. The remaining work is mostly **infrastructure/account setup** (resume the database, configure in-app-purchase products) plus optional code cleanup. This document tells you everything you need to take over.

## 1. The system (3 parts)
| Part | Tech | Where |
|---|---|---|
| Mobile app | Flutter (Dart), GetX, Hive | `github.com/vjtyler68-cloud/goalshare-app` (this repo) |
| Backend API | Node.js + Prisma (MongoDB) | Hosted on Railway → `https://goalshare-backend-production.up.railway.app/api/v1` |
| Admin dashboard | Next.js | separate repo (ask the owner) |

App identity: bundle id **`com.goal.share`**, display name **GoalShare**, internal package name `spanx`. Targets **iOS 26** (iPhone) and Android.

## 2. Current status
- ✅ Compiles clean — `flutter analyze` reports **0 errors**.
- ✅ CI builds + uploads to TestFlight via **Codemagic** (`codemagic.yaml`, workflow **"GoalShare iOS TestFlight"**), triggered on push to `main`. Latest successful upload: **build `1.4.0 (31)`**.
- ✅ The long-running **iOS 26 / ProMotion launch crash + freeze** was fixed via an explicit `FlutterEngine` + `FlutterSceneDelegate` (see `ios/Runner/SceneDelegate.swift` and `AppDelegate.swift`).
- 🔴 **Login is currently down** — the MongoDB Atlas cluster is **paused** (owner action, see §5).
- 🔴 **In-app purchases** won't function until the subscription products exist in App Store Connect (see §5).

## 3. Build & run
```bash
flutter pub get
flutter run            # on a connected device / simulator
flutter analyze        # static analysis (currently 0 errors)
```
**iOS / TestFlight:** push to `main` → Codemagic runs `flutter build ipa --release` and uploads to App Store Connect.
**Build number:** bump the `+NN` suffix on `version:` in `pubspec.yaml`. It **must be higher than the last number uploaded** to App Store Connect, or the upload is rejected with *"bundle version already used"* (this is exactly why 30 → 31 was needed).

## 4. Recent work (see `git log` for detail)
Newest first:
- **Bump build number to 31** (30 was already uploaded).
- **Harden user-info parsing** — `DateTime.tryParse` + guarded nested access so malformed server data can't crash/misroute.
- **Make signup Terms/Privacy tappable** + de-template (version string, pubspec description).
- **IAP/subscription App Store compliance** — runtime iOS platform detection (was hardcoded `android`), Restore Purchases button, auto-renewal disclosure, tappable Terms/Privacy on the paywall.
- **Replace wrong-app template copy (P0)** — onboarding/splash/login/subscription had leftover "barber/cleaning/sales" copy (a 2.3.1/4.0 rejection); + stopped logging passwords and auth tokens.
- **Remove hardcoded admin auto-login backdoor** + prune 9 unused dependencies.
- (earlier) **Build 30** — iOS launch root-fix via `FlutterSceneDelegate`.

## 5. Outstanding — OWNER / infra actions (these block a working launch)
1. **Resume MongoDB Atlas** — cluster `goalshare` (host `…qduect0.mongodb.net`) is paused, so backend login times out (~30s). Resume it (free M0 tier is fine), and ensure **Network Access** allows the backend (`0.0.0.0/0`). Quick verify: `POST {backendBase}/auth/login` should answer in ~1s instead of hanging.
2. **App Store Connect — in-app purchases:** create the auto-renewable subscription products (`com.goal.monthly`, `com.goal.yearly`), optionally an introductory offer, and set the app's **Privacy Policy URL**. The app code is already wired for these.
3. **Rotate secrets:** a GitHub Personal Access Token was previously exposed in the git remote URL — **rotate it.** Backend `.env` secrets (DB URL, JWT, Stripe, Cloudinary, DigitalOcean Spaces) should be rotated. The Android signing keystore password lives in `android/key.properties` (**not** included in this package) — keep it secure; rotate if it has ever been shared.

## 6. Outstanding — code cleanup (optional, non-blocking)
A 30-finding pre-submission audit was run. Non-blocking items deliberately deferred:
- **Dead code (~530 lines):** unused `core/data/repositories/user_repository.dart`, `core/utils/result.dart`, `core/error/failures.dart`, `core/config/env_config.dart` (has a stale backend URL), `core/network_caller/network_config_v2.dart`, plus ~6 orphan widgets in `core/global_widgets/`.
- **~4.4 MB unused assets** — `pubspec.yaml` declares assets at folder level, so unreferenced images/icons still ship.
- **Obsolete `ios/Runner/Base.lproj/Main.storyboard`** — the app uses an explicit engine; keep only `LaunchScreen.storyboard`.
- **20s login network timeout** could be shortened for snappier offline feedback.
- **Splash fires the user-info fetch 3×** (splash + `UserInfoController.onInit`), and there's a launch navigation race between the connectivity and splash controllers.
- **Verbose auth logging** ships in release (`login_controller`).

## 7. Access the new developer will need (share SECURELY — never plaintext email)
- **GitHub** — repo collaborator on `vjtyler68-cloud/goalshare-app`.
- **Codemagic** — CI/CD team access.
- **Apple Developer / App Store Connect** — signing, TestFlight, IAP.
- **MongoDB Atlas** (database) and **Railway** (backend hosting).
- **Backend `.env`** values and the **Android keystore + `key.properties`** — via a password manager or other secure channel.

## 8. What's in this package
The accompanying zip is a **clean source snapshot**. Excluded for safety and size: `.git`, `build/`, `.dart_tool/`, `ios/Pods/`, `lib/graphify-out/`, any `.env`, `android/key.properties`, and the signing keystore. The new developer should run `flutter pub get` (and `pod install` for iOS) to regenerate the rest, and get GitHub access for full history and to push.
