import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// The last working view of a Sales Ranch map for one organization.
///
/// This is intentionally separate from the ranch data cache: the map view is
/// personal device state, while pins and territories are shared org data.
class CanvassMapSession {
  final double latitude;
  final double longitude;
  final double zoom;
  final double rotation;
  final String layer;
  final bool following;
  final bool solarMode;
  final String? statusFilter;
  final String? repFilter;

  const CanvassMapSession({
    required this.latitude,
    required this.longitude,
    required this.zoom,
    required this.rotation,
    required this.layer,
    required this.following,
    required this.solarMode,
    required this.statusFilter,
    required this.repFilter,
  });

  static const _prefix = 'canvass_map_session_';
  static Future<void> _writeQueue = Future<void>.value();

  static Future<CanvassMapSession?> load(String orgId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$orgId');
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final latitude = (decoded['latitude'] as num?)?.toDouble();
      final longitude = (decoded['longitude'] as num?)?.toDouble();
      final zoom = (decoded['zoom'] as num?)?.toDouble();
      final rotation = (decoded['rotation'] as num?)?.toDouble();
      if (latitude == null ||
          latitude < -90 ||
          latitude > 90 ||
          longitude == null ||
          longitude < -180 ||
          longitude > 180 ||
          zoom == null ||
          zoom < 4 ||
          zoom > 18 ||
          rotation == null ||
          !latitude.isFinite ||
          !longitude.isFinite ||
          !zoom.isFinite ||
          !rotation.isFinite) {
        return null;
      }
      return CanvassMapSession(
        latitude: latitude,
        longitude: longitude,
        zoom: zoom,
        rotation: rotation,
        layer: decoded['layer'] is String
            ? decoded['layer'] as String
            : 'hybrid',
        following: decoded['following'] == true,
        solarMode: decoded['solarMode'] == true,
        statusFilter: decoded['statusFilter'] as String?,
        repFilter: decoded['repFilter'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(
    String orgId, {
    required double latitude,
    required double longitude,
    required double zoom,
    required double rotation,
    required String layer,
    required bool following,
    required bool solarMode,
    required String? statusFilter,
    required String? repFilter,
  }) async {
    final raw = jsonEncode({
      'latitude': latitude,
      'longitude': longitude,
      'zoom': zoom,
      'rotation': rotation,
      'layer': layer,
      'following': following,
      'solarMode': solarMode,
      'statusFilter': statusFilter,
      'repFilter': repFilter,
    });
    _writeQueue = _writeQueue.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('$_prefix$orgId', raw);
      } catch (_) {
        // View persistence is best-effort and must never block the map.
      }
    });
    await _writeQueue;
  }
}
