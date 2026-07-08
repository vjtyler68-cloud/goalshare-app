---
name: Chat Architecture
description: How chat is structured — Firebase-first with local fallback, identity model, and the known security limitation.
---

# Chat Architecture

## The rule
Chat is **Firebase Firestore-first with an on-device fallback**. Controllers branch on `FirebaseService.instance.isReady`: ready → Firestore real-time streams; not ready → the original SharedPreferences logic. Never remove the fallback branch.

**Why:** The Railway backend has no messaging endpoints. Firestore gives real-time + push-ready chat without backend work; the fallback keeps the shipped TestFlight build working while Firebase is being connected.

## Decisions worth keeping consistent
- **Identity = app user id** (Railway account id from `LocalService.getUserId()`), NOT the Firebase UID. All Firestore participant/sender fields use the app user id.
- **Firebase auth is anonymous** — gates DB access only. It does NOT prove which app user you are.
- **Known security limitation (deliberate MVP tradeoff):** because the anon UID ≠ app user id, `firestore.rules` can enforce "must be signed in" but not "must be a participant." The production fix is Railway minting Firebase **custom tokens** so `request.auth.uid == appUserId`; the tightened rules are stubbed as TODO in `firestore.rules`. Acceptable for closed beta only.
- **Deletes are soft, never hard.** A participant deleting a conversation adds themselves to a `hiddenFor` array (an update); the other user keeps history. New messages clear `hiddenFor`. Hard delete is blocked in the rules. Do not reintroduce client-side hard delete of shared docs.
- All Firestore reads/writes live in one repository; controllers must not talk to Firestore directly.

## iOS crash gotcha — never call Firebase.initializeApp with placeholder options
`FirebaseService.init` MUST check `DefaultFirebaseOptions.isConfigured` and skip `Firebase.initializeApp` when only placeholder options are present.

**Why:** On iOS the native Firebase SDK **hard-crashes** on an invalid/placeholder appId before Dart's `try/catch` can run — so a Dart-level catch is NOT enough to protect startup. The app crashed immediately on launch in a TestFlight build that shipped with placeholder options for exactly this reason.

**How to apply:** Keep the `isConfigured` guard (placeholder apiKey starts with `PLACEHOLDER`). Once `flutterfire configure` writes real options, `isConfigured` becomes true and init proceeds normally.

## Setup
Operational setup (flutterfire configure, placeholder options, composite index, iOS 13 target) is documented in `docs/FIREBASE_SETUP.md` — consult it rather than duplicating here.
