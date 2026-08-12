// Firebase configuration for the Goalshare project (project id: goalshare-966d1).
//
// The iOS values below are REAL (pulled from GoogleService-Info.plist on
// 2026-07-22) so [isConfigured] is now true and the app uses Firestore for
// live, cross-device chat via Firebase.initializeApp(options: currentPlatform).
//
// Both the iOS and Android apps are registered in the Firebase console
// (package/bundle id com.goal.share). Each platform has its own real options
// below and [currentPlatform] returns the matching set.
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
        return android;
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDqu_dNhSrR3S8oI8JLrTs_xDHs7X79qCY',
    appId: '1:507202934710:android:c7ce776f37bf0552151317',
    messagingSenderId: '507202934710',
    projectId: 'goalshare-966d1',
    storageBucket: 'goalshare-966d1.firebasestorage.app',
  );
}
