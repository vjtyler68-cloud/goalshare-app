// Firebase configuration for the Goalshare project (project id: goalshare-966d1).
//
// The iOS values below are REAL (pulled from GoogleService-Info.plist on
// 2026-07-22) so [isConfigured] is now true and the app uses Firestore for
// live, cross-device chat via Firebase.initializeApp(options: currentPlatform).
//
// NOTE: only the iOS app is registered so far (that's what TestFlight builds).
// Before shipping a native Android build, register an Android app in the
// Firebase console and add its options here (see the `android` TODO below).
//
// Firebase API keys are not secrets — they identify the project and are meant
// to ship inside client apps; access is protected by Firestore security rules.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  /// True once real Firebase options are wired in (they are — see [ios]).
  static bool get isConfigured => !ios.apiKey.startsWith('PLACEHOLDER');

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return ios;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // TODO: register an Android app in Firebase + drop its real options
        // here before building for Android. iOS options are a stopgap.
        return ios;
      case TargetPlatform.iOS:
        return ios;
      default:
        return ios;
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBQ-L9qzBlL98v98dM1KkMLq3Zve6kjjZE',
    appId: '1:507202934710:ios:663afb91086faaed151317',
    messagingSenderId: '507202934710',
    projectId: 'goalshare-966d1',
    storageBucket: 'goalshare-966d1.firebasestorage.app',
    iosBundleId: 'com.goal.share',
  );
}
