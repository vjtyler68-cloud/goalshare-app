import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:spanx/core/error/exceptions.dart';
import 'package:spanx/core/local/local_data.dart';

enum RequestMethod { GET, POST, PUT, DELETE, PATCH }

/// Improved network configuration with proper error handling
class NetworkConfigV2 {
  NetworkConfigV2._privateConstructor();

  static final NetworkConfigV2 _instance =
      NetworkConfigV2._privateConstructor();

  static NetworkConfigV2 get instance => _instance;

  final LocalService _localService = LocalService();
  final Duration defaultTimeout = const Duration(seconds: 15);

  /// Main API request handler with proper exception handling
  Future<Map<String, dynamic>> apiRequest({
    required RequestMethod method,
    required String url,
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    Duration? timeout,
  }) async {
    // Check internet connectivity first
    if (!await InternetConnectionChecker.createInstance().hasConnection) {
      throw NoInternetException();
    }

    try {
      // Prepare headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      if (requiresAuth) {
        final token = await _localService.getToken();
        if (token == null || token.isEmpty) {
          _forceReauth();
          throw UnauthorizedException('No authentication token found');
        }
        // Backend expects the raw JWT with NO "Bearer " prefix.
        headers['Authorization'] = token;
      }

      // Prepare body
      final jsonBody = body != null ? jsonEncode(body) : null;

      // Execute request based on method
      final response = await _executeRequest(
        method: method,
        url: url,
        headers: headers,
        body: jsonBody,
        timeout: timeout ?? defaultTimeout,
      );

      // Handle response
      return _handleResponse(response);
    } on SocketException catch (e) {
      log('SocketException: $e');
      throw NetworkException(
        message: 'Network error. Please check your connection.',
        originalError: e,
      );
    } on HttpException catch (e) {
      log('HttpException: $e');
      throw NetworkException(
        message: 'HTTP error occurred.',
        originalError: e,
      );
    } on FormatException catch (e) {
      log('FormatException: $e');
      throw NetworkException(
        message: 'Invalid response format from server.',
        originalError: e,
      );
    } on NetworkException {
      rethrow; // Re-throw our custom exceptions
    } catch (e) {
      log('Unexpected error: $e');
      throw NetworkException(
        message: 'An unexpected error occurred: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Execute HTTP request based on method
  Future<http.Response> _executeRequest({
    required RequestMethod method,
    required String url,
    required Map<String, String> headers,
    String? body,
    required Duration timeout,
  }) async {
    final uri = Uri.parse(url);

    log('[$method] $url');
    // Only log request bodies in debug builds — they can contain passwords
    // during login/signup and JWTs during auth, which must never reach
    // production device logs (logcat / Console).
    if (kDebugMode && body != null) log('Body: $body');

    switch (method) {
      case RequestMethod.GET:
        return await http.get(uri, headers: headers).timeout(timeout);

      case RequestMethod.POST:
        return await http
            .post(uri, headers: headers, body: body)
            .timeout(timeout);

      case RequestMethod.PUT:
        return await http
            .put(uri, headers: headers, body: body)
            .timeout(timeout);

      case RequestMethod.PATCH:
        return await http
            .patch(uri, headers: headers, body: body)
            .timeout(timeout);

      case RequestMethod.DELETE:
        return await http.delete(uri, headers: headers).timeout(timeout);
    }
  }

  /// True when the response body indicates an auth failure (expired/invalid
  /// token) regardless of the HTTP status code.
  // JWT-verification errors only (see NetworkConfig for rationale). Excludes
  // generic terms so business errors don't force a logout.
  static const List<String> _jwtErrors = [
    'invalid token',
    'jwt expired',
    'token expired',
    'jwt malformed',
  ];

  bool _isAuthFailureBody(Map<String, dynamic> body) {
    if (body['success'] != false) return false;
    final msg = (body['message'] ?? '').toString().toLowerCase();
    return _jwtErrors.any(msg.contains);
  }

  // Shared latch so a burst of simultaneous auth failures triggers the
  // clear+redirect exactly once instead of stacking navigations.
  static bool _reauthInProgress = false;

  void _forceReauth() {
    if (_reauthInProgress) return;
    _reauthInProgress = true;
    Future.microtask(() async {
      await _localService.clearUserData();
      if (Get.currentRoute != '/login') {
        Get.offAllNamed('/login');
      }
    });
    Future.delayed(const Duration(seconds: 2), () => _reauthInProgress = false);
  }

  /// Handle HTTP response and throw appropriate exceptions
  Map<String, dynamic> _handleResponse(http.Response response) {
    log('Response Status: ${response.statusCode}');
    // Debug-only: response bodies can contain tokens/PII.
    if (kDebugMode) log('Response Body: ${response.body}');

    // Try to decode response
    Map<String, dynamic> decodedBody;
    try {
      decodedBody = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      log('Failed to decode response: $e');
      throw NetworkException(
        message: 'Invalid response format',
        statusCode: response.statusCode,
        originalError: e,
      );
    }

    // The backend returns HTTP 500 with {"success": false, "message":
    // "invalid token"} for an expired/invalid JWT instead of a clean 401. Catch
    // that (and any other auth-failure message) on ANY status so an expired
    // session forces a clean re-login instead of stranding the user.
    if (_isAuthFailureBody(decodedBody)) {
      final message = decodedBody['message'] ?? 'Session expired';
      _forceReauth();
      throw UnauthorizedException(message);
    }

    // Handle status codes
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Success (200-299)
      return decodedBody;
    } else if (response.statusCode == 400) {
      // Bad Request
      final message = decodedBody['message'] ?? 'Bad request';
      throw ServerException(
        message: message,
        statusCode: 400,
        originalError: decodedBody,
      );
    } else if (response.statusCode == 401) {
      // Unauthenticated — clear session and force re-login.
      final message = decodedBody['message'] ?? 'Unauthorized';
      _forceReauth();
      throw UnauthorizedException(message);
    } else if (response.statusCode == 403) {
      // Forbidden
      final message = decodedBody['message'] ?? 'Access forbidden';
      throw ServerException(
        message: message,
        statusCode: 403,
        originalError: decodedBody,
      );
    } else if (response.statusCode == 404) {
      // Not Found
      final message = decodedBody['message'] ?? 'Resource not found';
      throw ServerException(
        message: message,
        statusCode: 404,
        originalError: decodedBody,
      );
    } else if (response.statusCode == 409) {
      // Conflict
      final message = decodedBody['message'] ?? 'Resource conflict';
      throw ServerException(
        message: message,
        statusCode: 409,
        originalError: decodedBody,
      );
    } else if (response.statusCode >= 500) {
      // Server Error (500+)
      final message = decodedBody['message'] ?? 'Internal server error';
      throw ServerException(
        message: message,
        statusCode: response.statusCode,
        originalError: decodedBody,
      );
    } else {
      // Other status codes
      final message = decodedBody['message'] ?? 'Request failed';
      throw ServerException(
        message: message,
        statusCode: response.statusCode,
        originalError: decodedBody,
      );
    }
  }

  /// Multipart request for file uploads
  Future<Map<String, dynamic>> multipartRequest({
    required String url,
    required Map<String, String> fields,
    required Map<String, String> files,
    bool requiresAuth = false,
    Duration? timeout,
  }) async {
    if (!await InternetConnectionChecker.createInstance().hasConnection) {
      throw NoInternetException();
    }

    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));

      // Add headers
      if (requiresAuth) {
        final token = await _localService.getToken();
        if (token != null && token.isNotEmpty) {
          // Backend expects the raw JWT with NO "Bearer " prefix.
          request.headers['Authorization'] = token;
        }
      }

      // Add fields
      request.fields.addAll(fields);

      // Add files
      for (final entry in files.entries) {
        final file = await http.MultipartFile.fromPath(
          entry.key,
          entry.value,
        );
        request.files.add(file);
      }

      log('Multipart POST: $url');

      final streamedResponse =
          await request.send().timeout(timeout ?? defaultTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      log('Multipart request error: $e');
      if (e is NetworkException) rethrow;
      throw NetworkException(
        message: 'File upload failed',
        originalError: e,
      );
    }
  }
}
