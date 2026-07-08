import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../local/local_data.dart';
import '../../firebase_options.dart';

/// Central Firebase entry point for the chat feature.
///
/// The app is designed to work with OR without Firebase configured:
///  - If `flutterfire configure` has been run and a real Firebase project is
///    connected, [isReady] becomes true and chat uses Firestore (real-time,
///    cross-device).
///  - If Firebase is not configured (placeholder options), init fails
///    gracefully, [isReady] stays false, and chat falls back to on-device
///    local storage so the app never crashes.
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  bool _ready = false;
  bool get isReady => _ready;

  FirebaseFirestore get db => FirebaseFirestore.instance;

  /// Call once during app startup. Never throws — failures are swallowed and
  /// leave [isReady] false so the app can degrade to local chat.
  Future<void> init() async {
    // Guard: if Firebase hasn't been connected yet (placeholder options),
    // do NOT call Firebase.initializeApp. On iOS the native SDK hard-crashes
    // on the invalid placeholder appId before Dart can catch it, so we must
    // skip initialization and go straight to local-chat fallback.
    if (!DefaultFirebaseOptions.isConfigured) {
      _ready = false;
      log('FirebaseService: not configured (placeholder options) — '
          'using local chat fallback.');
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Anonymous auth satisfies Firestore security rules that require an
      // authenticated request, without forcing a separate Firebase login.
      // (See docs/FIREBASE_SETUP.md for the production-grade custom-token
      // upgrade path that ties the Firebase user to the app account.)
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }

      _ready = true;
      log('FirebaseService: ready');
    } catch (e) {
      _ready = false;
      log('FirebaseService: not configured / failed to init — '
          'falling back to local chat. ($e)');
    }
  }

  /// The current app-level user id (from the Railway backend session), used as
  /// the stable chat identity. Returns null if the user is not logged in.
  Future<String?> currentUserId() => LocalService().getUserId();
}
