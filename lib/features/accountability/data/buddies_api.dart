import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';

import 'checkin_models.dart';

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

  Future<void> checkIn({String? proofUrl, String? note, String? date}) =>
      _req(RequestMethod.POST, Urls.buddyCheckIn, {
        if (date != null) 'date': date,
        if (proofUrl != null) 'proofUrl': proofUrl,
        if (note != null) 'note': note,
      });

  Future<void> requestExtend(bool value) =>
      _req(RequestMethod.POST, Urls.buddyExtend, {'value': value});

  Future<void> rate(int stars, String comment) => _req(
      RequestMethod.POST, Urls.buddyRate, {'stars': stars, 'comment': comment});

  /// Create a backend-backed match with a friend (so daily proof syncs to both).
  Future<Map<String, dynamic>?> createFriendMatch({
    required String buddyId,
    String buddyName = '',
    String buddyAvatar = '',
  }) =>
      _reqMap(RequestMethod.POST, Urls.buddyFriendMatch, {
        'buddyId': buddyId,
        'buddyName': buddyName,
        'buddyAvatar': buddyAvatar,
      });

  Future<void> verifyProof(String checkinId, bool verified) => _req(
      RequestMethod.POST,
      Urls.buddyVerify,
      {'checkinId': checkinId, 'verified': verified});

  Future<CheckinsData> getCheckins() async {
    final d = await _reqMap(RequestMethod.GET, Urls.buddyCheckins);
    return d == null ? const CheckinsData() : CheckinsData.fromJson(d);
  }

  Future<void> syncGoals(List<Map<String, dynamic>> goals) =>
      _req(RequestMethod.POST, Urls.buddyGoalsSync, {'goals': goals});

  Future<List<Map<String, dynamic>>> getBuddyGoals() async {
    final d = await _reqMap(RequestMethod.GET, Urls.buddyGoalsView);
    final list = d?['goals'];
    if (list is List) {
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  Future<void> sendVoice(String audioUrl, int durationMs) => _req(
      RequestMethod.POST,
      Urls.buddyVoiceSend,
      {'audioUrl': audioUrl, 'durationMs': durationMs});

  Future<List<VoiceMessage>> getVoiceMessages() async {
    final d = await _reqMap(RequestMethod.GET, Urls.buddyVoiceList);
    final list = d?['messages'];
    if (list is List) {
      return list
          .whereType<Map>()
          .map((e) => VoiceMessage.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  /// Post a daily status update to the shared thread.
  Future<void> postStatus(String text, {bool? hitGoals}) =>
      _req(RequestMethod.POST, Urls.buddyStatusPost, {
        'text': text,
        if (hitGoals != null) 'hitGoals': hitGoals,
      });

  /// Both sides' status updates for the current match (newest first).
  Future<List<BuddyStatusUpdate>> getStatuses() async {
    final d = await _reqMap(RequestMethod.GET, Urls.buddyStatusList);
    final list = d?['updates'];
    if (list is List) {
      return list
          .whereType<Map>()
          .map((e) =>
              BuddyStatusUpdate.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  /// Upload a proof image; returns its hosted URL, or null on failure.
  Future<String?> uploadProofImage(String filePath) =>
      _uploadFile(filePath, 'proof_${DateTime.now().millisecondsSinceEpoch}.jpg');

  /// Upload a recorded voice clip; returns its hosted URL, or null on failure.
  Future<String?> uploadAudio(String filePath) =>
      _uploadFile(filePath, 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a');

  Future<String?> _uploadFile(String filePath, String filename) async {
    try {
      final token = await LocalService().getToken() ?? '';
      if (token.isEmpty) return null;
      final req = http.MultipartRequest('POST', Uri.parse(Urls.assetUpload));
      req.headers.addAll({
        'Accept': 'application/json',
        'Authorization': token, // raw JWT — backend rejects a "Bearer " prefix
      });
      final bytes = await File(filePath).readAsBytes();
      req.files
          .add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
      final streamed = await req.send().timeout(const Duration(seconds: 60));
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body);
        if (body is Map && body['success'] == true) {
          return (body['data']?['url'] ?? '').toString();
        }
      }
    } catch (e) {
      log('_uploadFile: $e');
    }
    return null;
  }
}
