import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';

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
          headers['Authorization'] = 'Bearer $token';
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

      if (response.statusCode == 401) {
        AppSnackBar.error('Session expired. Please log in again.');
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
