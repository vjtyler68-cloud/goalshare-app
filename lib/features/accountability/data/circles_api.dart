import 'dart:convert';
import 'dart:developer';

import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';

import 'circle_models.dart';

/// Best-effort backend client for Goal Circles.
class CirclesApi {
  CirclesApi._();
  static final CirclesApi instance = CirclesApi._();

  Future<dynamic> _req(RequestMethod method, String url,
      [Map<String, dynamic> body = const {}]) async {
    try {
      final res = await NetworkConfig.instance
          .ApiRequestHandler(method, url, jsonEncode(body), is_auth: true);
      if (res != null && res['success'] == true) return res['data'];
    } catch (e) {
      log('CirclesApi $url: $e');
    }
    return null;
  }

  Future<bool> createCircle(String name, List<String> memberIds) async {
    final data = await _req(RequestMethod.POST, Urls.circleCreate,
        {'name': name, 'memberIds': memberIds});
    return data != null;
  }

  Future<CircleData?> getMyCircle() async {
    final data = await _req(RequestMethod.GET, Urls.circleMine);
    if (data is Map) {
      return CircleData.fromResponse(Map<String, dynamic>.from(data));
    }
    return null;
  }

  Future<void> checkin({String? proofUrl, String? note, String? date}) =>
      _req(RequestMethod.POST, Urls.circleCheckin, {
        if (date != null) 'date': date,
        if (proofUrl != null) 'proofUrl': proofUrl,
        if (note != null) 'note': note,
      });

  Future<int?> burnShield({String? date}) async {
    final data = await _req(RequestMethod.POST, Urls.circleShield,
        {if (date != null) 'date': date});
    if (data is Map) return (data['shields'] as num?)?.toInt();
    return null;
  }

  Future<void> leave() => _req(RequestMethod.POST, Urls.circleLeave);
}
