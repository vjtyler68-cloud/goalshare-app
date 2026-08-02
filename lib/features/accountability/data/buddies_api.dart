import 'dart:convert';
import 'dart:developer';

import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';

/// Thin, best-effort client for the backend Accountability endpoints.
///
/// Every call is fire-and-forget from the UI's perspective — a network failure
/// returns null and is swallowed, so the fully-local experience never breaks
/// when the server is unreachable. The backend is what makes random pairing and
/// cross-user ratings real; locally the app still works on its own.
class BuddiesApi {
  BuddiesApi._();
  static final BuddiesApi instance = BuddiesApi._();

  Future<dynamic> _req(RequestMethod method, String url,
      [Map<String, dynamic> body = const {}]) async {
    try {
      final res = await NetworkConfig.instance
          .ApiRequestHandler(method, url, jsonEncode(body), is_auth: true);
      if (res != null && res['success'] == true) return res['data'];
    } catch (e) {
      log('BuddiesApi $url: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _reqMap(RequestMethod method, String url,
      [Map<String, dynamic> body = const {}]) async {
    final data = await _req(method, url, body);
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  Future<void> upsertProfile(Map<String, dynamic> profileJson) =>
      _req(RequestMethod.POST, Urls.buddyProfile, profileJson);

  Future<Map<String, dynamic>?> getProfile() =>
      _reqMap(RequestMethod.GET, Urls.buddyProfile);

  Future<void> setOptIn(bool optedIn) =>
      _req(RequestMethod.POST, Urls.buddyOptIn, {'optedIn': optedIn});

  Future<Map<String, dynamic>?> getMatch() =>
      _reqMap(RequestMethod.GET, Urls.buddyMatch);

  Future<void> checkIn() => _req(RequestMethod.POST, Urls.buddyCheckIn);

  Future<void> requestExtend(bool value) =>
      _req(RequestMethod.POST, Urls.buddyExtend, {'value': value});

  Future<void> rate(int stars, String comment) => _req(
      RequestMethod.POST, Urls.buddyRate, {'stars': stars, 'comment': comment});
}
