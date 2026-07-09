import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/routes/app_routes.dart';

enum RequestMethod { GET, POST, PUT, DELETE, PATCH }

class NetworkConfig {
  NetworkConfig._privateConstructor();
  static final NetworkConfig _instance = NetworkConfig._privateConstructor();
  static NetworkConfig get instance => _instance;

  final _storage = const FlutterSecureStorage();
  static const Duration _timeout = Duration(seconds: 20);

  Future<Map<String, dynamic>?> ApiRequestHandler(
    RequestMethod method,
    String url,
    dynamic jsonBody, {
    bool is_auth = false,
  }) async {
    // Connectivity probe is best-effort only. On iOS it can be slow / hang, so
    // cap it and FAIL-OPEN (assume connected) on timeout — the real HTTP call
    // below has its own timeout and SocketException handling for true outages.
    bool hasConnection = true;
    try {
      hasConnection = await InternetConnectionChecker.createInstance()
          .hasConnection
          .timeout(const Duration(seconds: 4), onTimeout: () => true);
    } catch (_) {
      hasConnection = true;
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

      http.Response response;
      switch (method) {
        case RequestMethod.GET:
          response = await http.get(uri, headers: headers).timeout(_timeout);
        case RequestMethod.POST:
          response = await http.post(uri, headers: headers, body: body).timeout(_timeout);
        case RequestMethod.PUT:
          response = await http.put(uri, headers: headers, body: body).timeout(_timeout);
        case RequestMethod.PATCH:
          response = await http.patch(uri, headers: headers, body: body).timeout(_timeout);
        case RequestMethod.DELETE:
          response = await http.delete(uri, headers: headers).timeout(_timeout);
      }

      log('Response [${response.statusCode}] $url');

      final decoded = _decodeResponse(response);

      if (is_auth && _isAuthFailure(response.statusCode, decoded)) {
        await _forceReauth();
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
