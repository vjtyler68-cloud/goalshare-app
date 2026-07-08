# Firebase Chat Setup

The app's real-time chat runs on **Firebase Firestore** (messages) with
**Firebase Anonymous Auth** (to gate database access). Until you complete these
steps the app still runs — chat simply falls back to on-device local storage.

Everything below is done **once**, on a machine that has the Flutter SDK
installed (not the Replit container — Flutter isn't installed there).

---

## 1. Create the Firebase project

1. Go to <https://console.firebase.google.com> → **Add project**.
2. Name it (e.g. `spanx-app`), accept defaults, create.
3. In the left nav: **Build → Firestore Database → Create database**.
   - Start in **production mode** (rules are provided below).
   - Pick the region closest to your users.
4. **Build → Authentication → Get started → Sign-in method →** enable
   **Anonymous**.

## 2. Connect the app with FlutterFire

From the project root on your Mac:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

- Select the Firebase project you just created.
- Select platforms: **iOS** and **Android**.

This command:
- **overwrites** `lib/firebase_options.dart` with your real project keys
  (the version committed now is a placeholder), and
- writes the native config files: `android/app/google-services.json` and
  `ios/Runner/GoogleService-Info.plist`.

## 3. Fetch dependencies & build

```bash
flutter pub get
flutter run           # or build ipa / appbundle
```

The Firebase packages are already declared in `pubspec.yaml`:
`firebase_core`, `firebase_auth`, `cloud_firestore`.

> **iOS note:** Firebase requires a minimum iOS deployment target of 13.0.
> If the pod install step complains, set `platform :ios, '13.0'` in
> `ios/Podfile` and run `cd ios && pod install`.

## 4. Publish the security rules

In the Firebase Console → **Firestore Database → Rules**, paste the contents of
[`firestore.rules`](../firestore.rules) from this repo and click **Publish**.

## 5. Add the composite index (first run will prompt this)

The conversation list query filters by participant and orders by time, which
Firestore serves via a composite index. The **first time** the query runs
you'll see an error in the logs with a direct link — click it to auto-create
the index, or add manually:

- Collection: `conversations`
- Fields: `participants` (Arrays) → `lastMessageTime` (Descending)

---

## How it works in the code

| Piece | File |
|---|---|
| Init + anonymous sign-in + `isReady` flag | `lib/core/firebase/firebase_service.dart` |
| All Firestore reads/writes | `lib/features/chat_tab/repository/chat_firestore_repository.dart` |
| Conversation list controller | `lib/features/chat_tab/controller/chat_controller.dart` |
| Single-conversation controller | `lib/features/chat_tab/controller/chat_conversation_controller.dart` |

When `FirebaseService.instance.isReady` is `true`, chat uses Firestore streams
(real-time, cross-device). When it's `false` (Firebase not configured, or no
network at startup), the same controllers use the original on-device storage so
nothing crashes.

### Firestore data model

```
conversations/{conversationId}
  participants: [appUserIdA, appUserIdB]
  participantInfo: { appUserId: {name, email, image} }
  lastMessage, lastMessageTime, lastSenderId
  unread: { appUserId: <int> }
  type: 'personal' | 'community'
conversations/{conversationId}/messages/{messageId}
  text, senderId, timestamp
```

The chat identity is the **app user id** (the Railway backend account id from
`LocalService.getUserId()`).

---

## Security: current state vs. production-grade

**Now (MVP):** the app signs in with Firebase *anonymous* auth. The rules
require an authenticated request, so the database is **not** open to the public
internet. However, an anonymous Firebase UID is per-device and is *not* the same
as the app account id, so the rules can enforce "must be signed in" but cannot
fully enforce "must be a participant of this specific conversation."

This is acceptable for a closed TestFlight beta. **Before a wide public launch**,
upgrade to per-user isolation:

1. Add an endpoint to the Railway backend that mints a **Firebase custom token**
   for the logged-in user (`uid == app user id`), using the Firebase Admin SDK.
2. In `FirebaseService.init()`, replace `signInAnonymously()` with
   `signInWithCustomToken(tokenFromBackend)`.
3. Tighten `firestore.rules` using the `TODO` blocks already written there so
   `request.auth.uid in resource.data.participants` is enforced.

## Push notifications (follow-up)

This setup covers in-app real-time messaging. To notify users of new messages
while the app is closed, add `firebase_messaging` (FCM) plus a Cloud Function
that fires on new message documents. Tracked as a separate task.
