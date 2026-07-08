// GENERATED FILE — PLACEHOLDER.
//
// This is a stand-in so the project compiles before Firebase is connected.
// It contains NO real project and will intentionally fail at runtime, causing
// the app to fall back to local (on-device) chat.
//
// To enable real-time chat, run the FlutterFire CLI on a machine with Flutter:
//
//     dart pub global activate flutterfire_cli
//     flutterfire configure
//
// That command OVERWRITES this file with your real project's options and also
// drops the native config files (google-services.json / GoogleService-Info.plist).
// See docs/FIREBASE_SETUP.md for the full walkthrough.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return _placeholder;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _placeholder;
      case TargetPlatform.iOS:
        return _placeholder;
      default:
        return _placeholder;
    }
  }

  // Deliberately invalid placeholder values. Firebase.initializeApp will throw,
  // and FirebaseService.init() catches it to enable local-chat fallback.
  static const FirebaseOptions _placeholder = FirebaseOptions(
    apiKey: 'PLACEHOLDER_NOT_CONFIGURED',
    appId: 'PLACEHOLDER_NOT_CONFIGURED',
    messagingSenderId: 'PLACEHOLDER',
    projectId: 'placeholder-not-configured',
  );
}
