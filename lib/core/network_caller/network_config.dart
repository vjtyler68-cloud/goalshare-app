import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/retry_policy.dart';
import 'package:spanx/routes/app_routes.dart';

enum RequestMethod { GET, POST, PUT, DELETE, PATCH }

/// Result of a token-renewal attempt. Distinguishes a genuinely dead session
/// (log out) from a transient blip (keep the user signed in).
enum _RenewOutcome { renewed, authDead, transient }

class NetworkConfig {
  NetworkConfig._privateConstructor();
  static final NetworkConfig _instance = NetworkConfig._privateConstructor();
  static NetworkConfig get instance => _instance;

  final _storage = const FlutterSecureStorage();
  static const Duration _timeout = Duration(seconds: 20);

  /// Fire-and-forget request to wake a sleeping backend (e.g. a Railway dyno
  /// cold start) so the user's first real request isn't the one that pays the
  /// wake-up cost. All errors are intentionally ignored.
  static Future<void> warmUp(String url) async {
    try {
      await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
    } catch (_) {
      // best effort — we only care about waking the server, not the result.
    }
  }

  Future<Map<String, dynamic>?> ApiRequestHandler(
    RequestMethod method,
    String url,
    dynamic jsonBody, {
    bool is_auth = false,
  }) async {
    // Connectivity probe is best-effort only. On iOS it can be slow / hang, so
    // cap it and FAIL-OPEN (assume connected) on timeout — the real HTTP call
    // below has its own timeout and SocketException handling for true outages.
    // On web the socket-based connectivity probe can't run (browsers block it
    // with CORS), so skip it and let the real HTTP call below report failures.
    bool hasConnection = true;
    if (!kIsWeb) {
      try {
        hasConnection = await InternetConnectionChecker.createInstance()
            .hasConnection
            .timeout(const Duration(seconds: 4), onTimeout: () => true);
      } catch (_) {
        hasConnection = true;
      }
    }
    if (!hasConnection) {
      AppSnackBar.error('No internet connection. Please check your network.');
      return null;
    }

    try {
      final headers = <String, String>{'Content-Type': 'application/json'};

      if (is_auth) {
        final token = await _storage.read(key: 'token');
        if (token != null && token.isNotEmpty) {
          // Backend expects the raw JWT with NO "Bearer " prefix — adding the
          // prefix makes every authenticated request fail with "invalid token".
          headers['Authorization'] = token;
        }
      }

      final body = jsonBody is String ? jsonBody : jsonEncode(jsonBody);
      final uri = Uri.parse(url);

      log('[${method.name}] $url');

      Future<http.Response> send() {
        switch (method) {
          case RequestMethod.GET:
            return http.get(uri, headers: headers).timeout(_timeout);
          case RequestMethod.POST:
            return http.post(uri, headers: headers, body: body).timeout(_timeout);
          case RequestMethod.PUT:
            return http.put(uri, headers: headers, body: body).timeout(_timeout);
          case RequestMethod.PATCH:
            return http.patch(uri, headers: headers, body: body).timeout(_timeout);
          case RequestMethod.DELETE:
            return http.delete(uri, headers: headers).timeout(_timeout);
        }
      }

      // Retry transient failures (cold-start 5xx, dropped connections) with
      // backoff. Only GET is retried on ambiguous failures; writes are retried
      // solely on connection errors that never reached the server.
      final response = await RetryPolicy.run(
        send,
        idempotent: method == RequestMethod.GET,
      );

      log('Response [${response.statusCode}] $url');

      var decoded = _decodeResponse(response);

      if (is_auth && _isAuthFailure(response.statusCode, decoded)) {
        // Don't nuke the session on a single auth-looking failure. First try to
        // renew the token (slides the 21-day expiry forward). Only a renewal
        // that itself fails auth means the session is truly dead → log out.
        // A transient failure keeps the user logged in and just fails this call.
        final outcome = await _tryRenew();
        if (outcome == _RenewOutcome.renewed) {
          // Retry the original request once with the fresh token.
          final fresh = await _storage.read(key: 'token');
          if (fresh != null && fresh.isNotEmpty) {
            headers['Authorization'] = fresh;
          }
          final retry = await RetryPolicy.run(
            send,
            idempotent: method == RequestMethod.GET,
          );
          decoded = _decodeResponse(retry);
          if (_isAuthFailure(retry.statusCode, decoded)) {
            await _forceReauth();
            return null;
          }
          return decoded;
        } else if (outcome == _RenewOutcome.authDead) {
          await _forceReauth();
          return null;
        }
        // transient — keep the session; this one request just failed.
        return null;
      }

      return decoded;
    } on SocketException {
      AppSnackBar.error('Connection failed. Please check your internet.');
    } on http.ClientException {
      AppSnackBar.error('Network error. Please try again.');
    } catch (e) {
      log('Network error: $e');
      AppSnackBar.error('Something went wrong. Please try again.');
    }
    return null;
  }

  // Dedupe concurrent renew calls: a burst of requests that all hit an expired
  // token should trigger exactly one network renewal, not one per request.
  static Future<_RenewOutcome>? _renewInFlight;

  /// Ask the backend for a fresh token using the current (hopefully still-valid)
  /// one. `renewed` = got a new token (stored); `authDead` = the token is truly
  /// invalid/expired → the caller should log out; `transient` = a network/server
  /// blip → keep the session and just fail the current request.
  Future<_RenewOutcome> _tryRenew() {
    return _renewInFlight ??= _doRenew()
      ..whenComplete(() => _renewInFlight = null);
  }

  Future<_RenewOutcome> _doRenew() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null || token.isEmpty) return _RenewOutcome.authDead;
      final res = await http.post(
        Uri.parse(Urls.authRenew),
        headers: {'Content-Type': 'application/json', 'Authorization': token},
      ).timeout(_timeout);
      final body = _decodeResponse(res);
      if (res.statusCode == 200) {
        final data = body?['data'];
        final newToken =
            (data is Map) ? (data['accessToken'] ?? '').toString() : '';
        if (newToken.isNotEmpty) {
          await _storage.write(key: 'token', value: newToken);
          return _RenewOutcome.renewed;
        }
        return _RenewOutcome.transient; // 200 but no token — don't log out
      }
      // A real auth failure on renew means the session is genuinely dead.
      if (_isAuthFailure(res.statusCode, body)) return _RenewOutcome.authDead;
      return _RenewOutcome.transient; // 5xx / other — keep the session
    } catch (_) {
      return _RenewOutcome.transient; // network blip — keep the session
    }
  }

  /// Proactively slide the session forward (called on app launch / resume) so an
  /// active user's token never reaches its expiry. Best-effort and silent: it
  /// never logs the user out on its own — a genuinely dead token is handled when
  /// the next real request runs.
  Future<void> renewSession() async {
    try {
      final token = await _storage.read(key: 'token');
      if (token == null || token.isEmpty) return;
      await _tryRenew();
    } catch (_) {
      // best effort only
    }
  }

  /// Detects an authentication failure regardless of HTTP status code.
  ///
  /// The backend does NOT return a clean 401 for an expired/invalid JWT — it
  /// returns HTTP 500 with {"success": false, "message": "invalid token"} (a
  /// missing token gives 401 "You are not authorized!"). If we only checked for
  /// 401, an expired token would surface the raw "invalid token" message and
  /// strand the user on a logged-in screen, forcing a manual sign-out/in loop.
  /// So we also match auth-failure messages on any status code.
  // JWT-verification errors produced by the token library itself. These strings
  // never appear in normal business errors, so matching them (even on a 500)
  // won't misfire. Generic words like "unauthorized"/"invalid signature" are
  // intentionally excluded: 401 covers unauthenticated, and "invalid signature"
  // can legitimately come from payment/webhook signature checks.
  static const List<String> _jwtErrors = [
    'invalid token',
    'jwt expired',
    'token expired',
    'jwt malformed',
  ];

  bool _isAuthFailure(int statusCode, Map<String, dynamic>? body) {
    // 401 = unauthenticated → re-login. NOT 403: forbidden means the token is
    // valid but lacks permission, so logging out would be wrong.
    if (statusCode == 401) return true;
    if (body != null && body['success'] == false) {
      final msg = (body['message'] ?? '').toString().toLowerCase();
      return _jwtErrors.any(msg.contains);
    }
    return false;
  }

  // Shared across all requests so a burst of simultaneous failures triggers the
  // clear+redirect exactly once instead of stacking snackbars/navigations.
  static bool _reauthInProgress = false;

  Future<void> _forceReauth() async {
    if (_reauthInProgress) return;
    _reauthInProgress = true;
    await LocalService().clearUserData();
    if (Get.currentRoute != AppRoutes.loginScreen) {
      AppSnackBar.error('Your session has expired. Please log in again.');
      Get.offAllNamed(AppRoutes.loginScreen);
    }
    // Release the latch after the redirect settles so a future genuine expiry
    // can trigger it again.
    Future.delayed(const Duration(seconds: 2), () => _reauthInProgress = false);
  }

  Map<String, dynamic>? _decodeResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'success': false, 'message': 'Unexpected response format'};
    } catch (_) {
      return {'success': false, 'message': 'Failed to read server response'};
    }
  }
}
