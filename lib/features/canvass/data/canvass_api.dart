import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';

import 'canvass_pin.dart';

/// Backend client for canvassing pins + free OSM reverse geocoding.
class CanvassApi {
  CanvassApi._();
  static final CanvassApi instance = CanvassApi._();

  Future<List<CanvassPin>> pins(String orgId) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.canvassPins(orgId),
        jsonEncode({}),
        is_auth: true,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        final list = (res['data'] as Map)['pins'];
        if (list is List) {
          return [
            for (final p in list)
              if (p is Map) CanvassPin.fromJson(Map<String, dynamic>.from(p)),
          ];
        }
      }
    } catch (e) {
      log('CanvassApi.pins: $e');
    }
    return const [];
  }

  Future<CanvassPin?> create(String orgId, Map<String, dynamic> body) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.canvassCreatePin(orgId),
        jsonEncode(body),
        is_auth: true,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        return CanvassPin.fromJson(Map<String, dynamic>.from(res['data'] as Map));
      }
    } catch (e) {
      log('CanvassApi.create: $e');
    }
    return null;
  }

  Future<CanvassPin?> update(String pinId, Map<String, dynamic> body) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.PATCH,
        Urls.canvassUpdatePin(pinId),
        jsonEncode(body),
        is_auth: true,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        return CanvassPin.fromJson(Map<String, dynamic>.from(res['data'] as Map));
      }
    } catch (e) {
      log('CanvassApi.update: $e');
    }
    return null;
  }

  /// Assign (or reassign) a pin to a rep — admin only, enforced server-side.
  /// Pass an empty [repId] to clear the assignment.
  Future<CanvassPin?> assign(String pinId,
      {required String repId, String repName = ''}) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.PATCH,
        Urls.canvassAssignPin(pinId),
        jsonEncode({'repId': repId, 'repName': repName}),
        is_auth: true,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        return CanvassPin.fromJson(Map<String, dynamic>.from(res['data'] as Map));
      }
    } catch (e) {
      log('CanvassApi.assign: $e');
    }
    return null;
  }

  Future<bool> remove(String pinId) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.DELETE,
        Urls.canvassDeletePin(pinId),
        jsonEncode({}),
        is_auth: true,
      );
      return res != null && res['success'] == true;
    } catch (e) {
      log('CanvassApi.remove: $e');
      return false;
    }
  }

  /// Free reverse geocode via OpenStreetMap Nominatim (no key). Best-effort —
  /// returns {address, city, state, zip}; empty map on failure. Rate-limited to
  /// ~1/sec, which is fine for manual pin drops.
  Future<Map<String, String>> reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': '$lat',
        'lon': '$lng',
        'zoom': '18',
        'addressdetails': '1',
      });
      final res = await http.get(uri, headers: {
        'User-Agent': 'GoalShare-SolarCowboys/1.0 (canvassing)',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final a = (data['address'] as Map?)?.cast<String, dynamic>() ?? {};
        final house = (a['house_number'] ?? '').toString();
        final road = (a['road'] ?? '').toString();
        final street = [house, road].where((s) => s.isNotEmpty).join(' ');
        return {
          'address': street.isNotEmpty
              ? street
              : (data['display_name'] ?? '').toString().split(',').first,
          'city': (a['city'] ?? a['town'] ?? a['village'] ?? a['hamlet'] ?? '')
              .toString(),
          'state': (a['state'] ?? '').toString(),
          'zip': (a['postcode'] ?? '').toString(),
        };
      }
    } catch (e) {
      log('CanvassApi.reverseGeocode: $e');
    }
    return const {};
  }
}
