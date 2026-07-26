import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../firebase/firebase_service.dart';
import '../local/local_data.dart';
import '../network_caller/endpoints.dart';
import '../network_caller/network_config.dart';
import 'notification_service.dart';

/// Background / terminated-app message handler.
///
/// Must be a top-level function annotated with `vm:entry-point` — it runs in a
/// separate isolate. Messages that carry a `notification` block are shown by
/// iOS/Android automatically, so there's nothing to do here; it exists because
/// [FirebaseMessaging.onBackgroundMessage] requires a handler to be registered.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op: the OS presents notification-type messages on its own.
}

/// Real push notifications via Firebase Cloud Messaging.
///
/// FCM is free on the Firebase Spark plan — no Blaze, no Cloud Functions. The
/// Railway backend does the actual sending (via firebase-admin + the APNs .p8
/// key uploaded to Firebase); this class only:
///   1. registers this device's FCM token against the logged-in account, and
///   2. shows incoming pushes while the app is in the foreground.
///
/// Everything is best-effort and never throws — a push problem must never break
/// login, logout, or sending a message. If Firebase isn't configured, the whole
/// service quietly no-ops (same graceful degradation as chat).
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final LocalService _local = LocalService();
  bool _wired = false;
  String? _lastRegisteredToken;

  FirebaseMessaging get _fm => FirebaseMessaging.instance;

  // Native bridge (see ios/Runner/SceneDelegate.swift). iOS won't issue an APNs
  // token until the app explicitly registers for remote notifications, so we
  // drive that from here on every launch (the plugin's auto-trigger doesn't fire
  // under this app's explicit-engine setup). `getApnsStatus` reads back the OS
  // registration outcome purely for diagnostics.
  static const MethodChannel _pushChannel = MethodChannel('com.goal.share/push');

  /// Wire up messaging and, if the user is already logged in, register this
  /// device's token. Safe to call on every launch — idempotent.
  Future<void> init() async {
    if (!FirebaseService.instance.isReady) return; // no Firebase → no push
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // iOS only prompts on the first call; after that this just returns the
      // current status, so it's safe to call every launch.
      await _fm.requestPermission(alert: true, badge: true, sound: true);

      if (!_wired) {
        // Foreground: iOS won't show a banner on its own, so mirror the push
        // into a local notification.
        FirebaseMessaging.onMessage.listen(_onForegroundMessage);
        // The token can rotate; re-register whenever it does.
        _fm.onTokenRefresh.listen(_registerToken);
        _wired = true;
      }

      await registerToken();
    } catch (e) {
      debugPrint('PushNotificationService.init failed: $e');
    }
  }

  /// Fetch the current FCM token and hand it to the backend. Only does anything
  /// when logged in (the endpoint is authenticated). Call this after login too,
  /// so a fresh sign-in registers without waiting for the next launch.
  Future<void> registerToken() async {
    try {
      if (!FirebaseService.instance.isReady) return;
      final userId = await _local.getUserId();
      if (userId == null || userId.isEmpty) return; // not logged in yet

      // On iOS, FCM only issues a token once APNs has registered the device.
      // That registration must be kicked off explicitly on EVERY launch — the
      // plugin's auto-trigger doesn't fire under this app's explicit-engine
      // setup, which is why getAPNSToken() used to stay null forever and the
      // device never registered. Drive it natively, then poll briefly (APNs can
      // lag a few seconds behind launch) instead of giving up.
      if (Platform.isIOS) {
        try {
          await _pushChannel.invokeMethod('registerForRemoteNotifications');
        } catch (_) {
          // Channel missing (older build / non-iOS): fall through to the poll;
          // the plugin may still have registered on its own.
        }

        var apns = await _fm.getAPNSToken();
        var tries = 0;
        while ((apns == null || apns.isEmpty) && tries < 15) {
          await Future.delayed(const Duration(seconds: 1));
          apns = await _fm.getAPNSToken();
          tries++;
        }
        if (apns == null || apns.isEmpty) {
          // Still no APNs token. Report the OS-level registration outcome so
          // /push/debug can tell us WHY (code vs. Apple-portal/provisioning).
          await _reportDiag('apns_null tries=$tries native=${await _apnsStatus()}');
          return; // retried on next launch / token refresh
        }
      }

      final token = await _fm.getToken();
      if (token == null || token.isEmpty) {
        await _reportDiag('fcm_token_null');
        return;
      }
      await _registerToken(token);
    } catch (e) {
      await _reportDiag('exception ${e.toString()}');
      debugPrint('registerToken failed: $e');
    }
  }

  /// Read the native APNs registration outcome ("ok:32" / "fail:…" / "pending").
  Future<String> _apnsStatus() async {
    try {
      final s = await _pushChannel.invokeMethod('getApnsStatus');
      return s?.toString() ?? 'n/a';
    } catch (_) {
      return 'n/a';
    }
  }

  /// TEMPORARY diagnostic: when registration bails before a real token can be
  /// sent, ping the (authenticated) token endpoint with an EMPTY token plus a
  /// `diag` string. The backend records it (without overwriting any good token),
  /// so /push/debug surfaces exactly where registration failed. Best-effort and
  /// silent. Remove once push is confirmed working.
  Future<void> _reportDiag(String stage) async {
    try {
      final userId = await _local.getUserId();
      if (userId == null || userId.isEmpty) return;
      await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.PUT,
        Urls.registerFcmToken,
        jsonEncode({
          'token': '',
          'platform': Platform.isIOS ? 'ios' : 'android',
          'diag': stage,
        }),
        is_auth: true,
      );
    } catch (_) {
      // best effort only
    }
  }

  Future<void> _registerToken(String token) async {
    if (token == _lastRegisteredToken) return; // already up to date
    final userId = await _local.getUserId();
    if (userId == null || userId.isEmpty) return;
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.PUT,
        Urls.registerFcmToken,
        jsonEncode({
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
        }),
        is_auth: true,
      );
      if (res != null && res['success'] == true) {
        _lastRegisteredToken = token;
      }
    } catch (e) {
      debugPrint('_registerToken network error: $e');
    }
  }

  /// On logout: invalidate this device's token at FCM so a signed-out phone
  /// stops receiving the account's pushes. Deliberately local-only (no backend
  /// call) so it can't race the session teardown — the backend prunes tokens
  /// that FCM reports as unregistered on its next send.
  Future<void> unregister() async {
    try {
      if (FirebaseService.instance.isReady) {
        await _fm.deleteToken();
      }
    } catch (e) {
      debugPrint('unregister failed: $e');
    } finally {
      _lastRegisteredToken = null;
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final n = message.notification;
    final title = n?.title ?? (message.data['title'] as String?) ?? 'GoalShare';
    final body = n?.body ?? (message.data['body'] as String?) ?? '';
    if (body.isEmpty && (n?.title == null)) return;
    NotificationService.instance.showPush(title: title, body: body);
  }

  /// Fire-and-forget a push to another app user. Chat lives in Firestore, so the
  /// backend can't see a new message unless we tell it — the sender's app calls
  /// this right after a successful send. Silent on every failure (a missed push
  /// must never surface an error to the sender), and a no-op until the backend's
  /// /push/notify endpoint exists, so it's safe to ship ahead of the server.
  Future<void> notifyUser({
    required String toUserId,
    required String title,
    required String body,
  }) async {
    if (toUserId.isEmpty) return;
    try {
      await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.pushNotify,
        jsonEncode({'toUserId': toUserId, 'title': title, 'body': body}),
        is_auth: true,
      );
    } catch (_) {
      // best effort only
    }
  }
}
