import 'dart:async';
// dart:developer is prefixed because both it and dart:math export `log`,
// which makes a bare `log(...)` call ambiguous and fails compilation.
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

/// Centralised transient-failure retry for every backend call.
///
/// A hosted backend (Railway here) periodically produces *transient* failures
/// that are NOT the user's fault and almost always succeed on a second try:
///   * cold-start / dyno wake-up  -> HTTP 502 / 503 / 504 (often an HTML page)
///   * brief connection resets    -> SocketException
///   * momentary overload         -> HTTP 429
/// Without retries each of these surfaces as a hard error and makes the whole
/// app feel unreliable. This policy retries them with exponential backoff +
/// jitter so they recover silently, while being careful never to duplicate a
/// write.
class RetryPolicy {
  RetryPolicy._();

  /// 1 initial attempt + up to 2 retries.
  static const int maxAttempts = 3;
  static const Duration _baseDelay = Duration(milliseconds: 600);
  static const Duration _maxDelay = Duration(seconds: 4);

  /// Gateway/transient server states that are safe to retry.
  static bool isTransientStatus(int code) =>
      code == 502 || code == 503 || code == 504 || code == 429;

  /// Runs [action] with retries.
  ///
  /// [idempotent] MUST be true only for requests that are safe to repeat (GET).
  /// Non-idempotent requests (POST/PUT/PATCH/DELETE) are NEVER auto-retried:
  /// even a [SocketException] can occur *after* the request reached the server,
  /// so without a server-side idempotency key any retry risks duplicating a
  /// write. Writes therefore fail fast and let the caller/user decide.
  static Future<http.Response> run(
    Future<http.Response> Function() action, {
    required bool idempotent,
  }) async {
    var attempt = 0;
    while (true) {
      attempt++;
      try {
        final res = await action();
        if (idempotent &&
            isTransientStatus(res.statusCode) &&
            attempt < maxAttempts) {
          await _wait(attempt, 'HTTP ${res.statusCode}');
          continue;
        }
        return res;
      } on SocketException {
        // A reset can occur AFTER the request reached the server, so retrying a
        // write could duplicate it. Only retry idempotent (GET) requests.
        if (idempotent && attempt < maxAttempts) {
          await _wait(attempt, 'SocketException');
          continue;
        }
        rethrow;
      } on TimeoutException {
        // A timed-out write may already have been applied server-side, so only
        // retry idempotent (GET) requests.
        if (idempotent && attempt < maxAttempts) {
          await _wait(attempt, 'timeout');
          continue;
        }
        rethrow;
      } on http.ClientException {
        // Low-level client/connection error. Ambiguous for writes, so retry
        // only idempotent requests.
        if (idempotent && attempt < maxAttempts) {
          await _wait(attempt, 'ClientException');
          continue;
        }
        rethrow;
      }
    }
  }

  static Future<void> _wait(int attempt, String reason) async {
    // Exponential backoff (600ms, 1200ms, ...) capped, plus random jitter to
    // avoid a thundering herd when many requests fail at once.
    final expMs = (_baseDelay.inMilliseconds * pow(2, attempt - 1)).toInt();
    final cappedMs = min(expMs, _maxDelay.inMilliseconds);
    final delayMs = cappedMs + Random().nextInt(250);
    dev.log('[retry] attempt $attempt failed ($reason) — retrying in ${delayMs}ms');
    await Future<void>.delayed(Duration(milliseconds: delayMs));
  }
}
