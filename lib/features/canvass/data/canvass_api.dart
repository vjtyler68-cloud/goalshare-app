import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';

import 'canvass_pin.dart';
import 'canvass_territory.dart';
import 'property_detail.dart';

class SeedResult {
  final int created;
  final int matched;
  final int skipped;
  final bool truncated;
  const SeedResult({
    this.created = 0,
    this.matched = 0,
    this.skipped = 0,
    this.truncated = false,
  });
  factory SeedResult.fromJson(Map<String, dynamic> j) => SeedResult(
    created: (j['created'] as num?)?.toInt() ?? 0,
    matched: (j['matched'] as num?)?.toInt() ?? 0,
    skipped: (j['skipped'] as num?)?.toInt() ?? 0,
    truncated: j['truncated'] == true,
  );
}

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
        showErrors: false,
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
      throw StateError('Unexpected pins response.');
    } catch (e) {
      log('CanvassApi.pins: $e');
      rethrow;
    }
  }

  Future<CanvassPin?> create(
    String orgId,
    Map<String, dynamic> body, {
    bool showErrors = true,
  }) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.canvassCreatePin(orgId),
        jsonEncode(body),
        is_auth: true,
        showErrors: showErrors,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        return CanvassPin.fromJson(
          Map<String, dynamic>.from(res['data'] as Map),
        );
      }
    } catch (e) {
      log('CanvassApi.create: $e');
    }
    return null;
  }

  /// Pre-load a pin on every home within [radius] miles of a point (admin).
  /// Returns how many new homes were added.
  Future<int> seedArea(
    String orgId, {
    required double lat,
    required double lng,
    double radius = 0.75,
  }) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.canvassSeedArea(orgId),
        jsonEncode({'lat': lat, 'lng': lng, 'radius': radius}),
        is_auth: true,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        return ((res['data'] as Map)['created'] as num?)?.toInt() ?? 0;
      }
    } catch (e) {
      log('CanvassApi.seedArea: $e');
    }
    return 0;
  }

  /// Populate address pins inside a saved territory's authoritative polygon.
  Future<SeedResult?> seedTerritory(String territoryId) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.canvassPopulateTerritory(territoryId),
        jsonEncode({}),
        is_auth: true,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        return SeedResult.fromJson(
          Map<String, dynamic>.from(res['data'] as Map),
        );
      }
    } catch (e) {
      log('CanvassApi.seedTerritory: $e');
    }
    return null;
  }

  Future<CanvassPin?> update(
    String pinId,
    Map<String, dynamic> body, {
    bool showErrors = true,
  }) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.PATCH,
        Urls.canvassUpdatePin(pinId),
        jsonEncode(body),
        is_auth: true,
        showErrors: showErrors,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        return CanvassPin.fromJson(
          Map<String, dynamic>.from(res['data'] as Map),
        );
      }
    } catch (e) {
      log('CanvassApi.update: $e');
    }
    return null;
  }

  /// Assign (or reassign) a pin to a rep — admin only, enforced server-side.
  /// Pass an empty [repId] to clear the assignment.
  Future<CanvassPin?> assign(
    String pinId, {
    required String repId,
    String repName = '',
    bool showErrors = true,
  }) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.PATCH,
        Urls.canvassAssignPin(pinId),
        jsonEncode({'repId': repId, 'repName': repName}),
        is_auth: true,
        showErrors: showErrors,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        return CanvassPin.fromJson(
          Map<String, dynamic>.from(res['data'] as Map),
        );
      }
    } catch (e) {
      log('CanvassApi.assign: $e');
    }
    return null;
  }

  Future<bool> remove(String pinId, {bool showErrors = true}) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.DELETE,
        Urls.canvassDeletePin(pinId),
        jsonEncode({}),
        is_auth: true,
        showErrors: showErrors,
      );
      return res != null && res['success'] == true;
    } catch (e) {
      log('CanvassApi.remove: $e');
      return false;
    }
  }

  // ── Territories ─────────────────────────────────────────────────────────────
  Future<List<CanvassTerritory>> territories(String orgId) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.canvassTerritories(orgId),
        jsonEncode({}),
        is_auth: true,
        showErrors: false,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        final list = (res['data'] as Map)['territories'];
        if (list is List) {
          return [
            for (final t in list)
              if (t is Map)
                CanvassTerritory.fromJson(Map<String, dynamic>.from(t)),
          ];
        }
      }
      throw StateError('Unexpected territories response.');
    } catch (e) {
      log('CanvassApi.territories: $e');
      rethrow;
    }
  }

  Future<CanvassTerritory?> createTerritory(
    String orgId,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.canvassCreateTerritory(orgId),
        jsonEncode(body),
        is_auth: true,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        return CanvassTerritory.fromJson(
          Map<String, dynamic>.from(res['data'] as Map),
        );
      }
    } catch (e) {
      log('CanvassApi.createTerritory: $e');
    }
    return null;
  }

  Future<CanvassTerritory?> updateTerritory(
    String tId,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.PATCH,
        Urls.canvassUpdateTerritory(tId),
        jsonEncode(body),
        is_auth: true,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        return CanvassTerritory.fromJson(
          Map<String, dynamic>.from(res['data'] as Map),
        );
      }
    } catch (e) {
      log('CanvassApi.updateTerritory: $e');
    }
    return null;
  }

  Future<bool> removeTerritory(String tId) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.DELETE,
        Urls.canvassDeleteTerritory(tId),
        jsonEncode({}),
        is_auth: true,
      );
      return res != null && res['success'] == true;
    } catch (e) {
      log('CanvassApi.removeTerritory: $e');
      return false;
    }
  }

  /// Look up home + owner detail for an address (via the backend proxy, which
  /// holds the provider key). Returns a PropertyDetail whose [configured] flag
  /// is false until a key is set on the server.
  Future<PropertyDetail?> enrich(String orgId, String address) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.canvassEnrich(orgId, address),
        jsonEncode({}),
        is_auth: true,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        return PropertyDetail.fromResponse(
          Map<String, dynamic>.from(res['data'] as Map),
        );
      }
    } catch (e) {
      log('CanvassApi.enrich: $e');
    }
    return null;
  }

  /// Cached, on-demand enrichment for a saved pin. The backend only calls the
  /// paid provider the first time (and only adds the market estimate when
  /// [estimate] is true); repeat calls are served from cache for free.
  Future<PropertyDetail?> enrichPin(
    String pinId, {
    bool estimate = false,
  }) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.canvassEnrichPin(pinId, estimate),
        jsonEncode({}),
        is_auth: true,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        return PropertyDetail.fromResponse(
          Map<String, dynamic>.from(res['data'] as Map),
        );
      }
    } catch (e) {
      log('CanvassApi.enrichPin: $e');
    }
    return null;
  }

  /// Cached, on-demand skip-trace for a door — resident name + phone + email.
  /// Returns the raw {configured, found, data} map (or null on failure).
  Future<Map<String, dynamic>?> contactPin(String pinId) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.canvassContactPin(pinId),
        jsonEncode({}),
        is_auth: true,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        return Map<String, dynamic>.from(res['data'] as Map);
      }
    } catch (e) {
      log('CanvassApi.contactPin: $e');
    }
    return null;
  }

  /// Cached Google Solar potential for a door. Returns the raw
  /// {configured, found, data} map (or null on failure).
  Future<Map<String, dynamic>?> solarPin(String pinId) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.canvassSolarPin(pinId),
        jsonEncode({}),
        is_auth: true,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        return Map<String, dynamic>.from(res['data'] as Map);
      }
    } catch (e) {
      log('CanvassApi.solarPin: $e');
    }
    return null;
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
      final res = await http
          .get(
            uri,
            headers: {
              'User-Agent': 'GoalShare-SolarCowboys/1.0 (canvassing)',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));
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
