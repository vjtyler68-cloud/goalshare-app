import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// A drawn canvassing area (polygon) an admin assigns to one or more reps.
/// Reps see the areas assigned to them; the admin sees them all.
class CanvassTerritory {
  final String id;
  final String orgId;
  String name;
  String color; // hex, e.g. "#F59E0B"
  List<LatLng> points;
  List<String> assignedRepIds;
  List<String> assignedRepNames;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CanvassTerritory({
    required this.id,
    required this.orgId,
    this.name = 'Territory',
    this.color = '#F59E0B',
    this.points = const [],
    this.assignedRepIds = const [],
    this.assignedRepNames = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory CanvassTerritory.fromJson(Map<String, dynamic> j) {
    final pts = <LatLng>[];
    final raw = j['points'];
    if (raw is List) {
      for (final p in raw) {
        if (p is Map) {
          final lat = (p['lat'] as num?)?.toDouble();
          final lng = (p['lng'] as num?)?.toDouble();
          if (lat != null && lng != null) pts.add(LatLng(lat, lng));
        }
      }
    }
    List<String> strs(dynamic v) =>
        v is List ? [for (final e in v) e.toString()] : <String>[];
    return CanvassTerritory(
      id: (j['id'] ?? '').toString(),
      orgId: (j['orgId'] ?? '').toString(),
      name: (j['name'] ?? 'Territory').toString(),
      color: (j['color'] ?? '#F59E0B').toString(),
      points: pts,
      assignedRepIds: strs(j['assignedRepIds']),
      assignedRepNames: strs(j['assignedRepNames']),
      createdAt: DateTime.tryParse('${j['createdAt'] ?? ''}'),
      updatedAt: DateTime.tryParse('${j['updatedAt'] ?? ''}'),
    );
  }

  /// The area's display color, parsed from the stored hex.
  Color get colorValue {
    var h = color.replaceAll('#', '').trim();
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return const Color(0xFFF59E0B);
    return Color(int.tryParse(h, radix: 16) ?? 0xFFF59E0B);
  }

  bool get isAssigned => assignedRepIds.isNotEmpty;

  String get repLabel =>
      assignedRepNames.isEmpty ? 'Unassigned' : assignedRepNames.join(', ');

  /// Rough polygon centroid (average of vertices) — good enough for a label.
  LatLng? get center {
    if (points.isEmpty) return null;
    var lat = 0.0, lng = 0.0;
    for (final p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }

  /// The palette an admin can pick a territory color from.
  static const List<String> palette = [
    '#22C55E', // green
    '#F59E0B', // solar gold
    '#EF4444', // red
    '#8B5CF6', // purple
    '#EC4899', // pink
    '#3B82F6', // blue
    '#14B8A6', // teal
    '#F97316', // orange
  ];
}
