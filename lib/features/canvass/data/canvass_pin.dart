import 'property_detail.dart';

/// A single door-to-door canvassing pin (server-backed, org-scoped).
class CanvassPin {
  final String id;
  final String orgId;
  final String repId;
  final String repName;
  final double lat;
  final double lng;
  String address;
  String city;
  String state;
  String zip;
  String status;
  String? homeownerName;
  String? notes;
  String? phone;
  // Optional lead assignment (admin hands a door to a specific rep). A rep sees
  // pins they dropped OR ones assigned to them.
  String? assignedRepId;
  String? assignedRepName;
  // Cached home + owner detail (null until this door has been looked up).
  PropertyDetail? enrichment;
  DateTime? enrichedAt;
  int visitCount;
  final DateTime? lastVisited;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CanvassPin({
    required this.id,
    required this.orgId,
    required this.repId,
    required this.repName,
    required this.lat,
    required this.lng,
    this.address = '',
    this.city = '',
    this.state = '',
    this.zip = '',
    this.status = 'NH',
    this.homeownerName,
    this.notes,
    this.phone,
    this.assignedRepId,
    this.assignedRepName,
    this.enrichment,
    this.enrichedAt,
    this.visitCount = 1,
    this.lastVisited,
    this.createdAt,
    this.updatedAt,
  });

  factory CanvassPin.fromJson(Map<String, dynamic> j) => CanvassPin(
        id: (j['id'] ?? '').toString(),
        orgId: (j['orgId'] ?? '').toString(),
        repId: (j['repId'] ?? '').toString(),
        repName: (j['repName'] ?? 'Rep').toString(),
        lat: (j['lat'] as num?)?.toDouble() ?? 0,
        lng: (j['lng'] as num?)?.toDouble() ?? 0,
        address: (j['address'] ?? '').toString(),
        city: (j['city'] ?? '').toString(),
        state: (j['state'] ?? '').toString(),
        zip: (j['zip'] ?? '').toString(),
        status: (j['status'] ?? 'NH').toString(),
        homeownerName: j['homeownerName'] as String?,
        notes: j['notes'] as String?,
        phone: j['phone'] as String?,
        assignedRepId: j['assignedRepId'] as String?,
        assignedRepName: j['assignedRepName'] as String?,
        enrichment: j['enrichment'] is Map
            ? PropertyDetail.fromData(
                Map<String, dynamic>.from(j['enrichment'] as Map))
            : null,
        enrichedAt: DateTime.tryParse('${j['enrichedAt'] ?? ''}'),
        visitCount: (j['visitCount'] as num?)?.toInt() ?? 1,
        lastVisited: DateTime.tryParse('${j['lastVisited'] ?? ''}'),
        createdAt: DateTime.tryParse('${j['createdAt'] ?? ''}'),
        updatedAt: DateTime.tryParse('${j['updatedAt'] ?? ''}'),
      );

  String get shortAddress =>
      address.isNotEmpty ? address : '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';

  bool get isAssigned => (assignedRepId ?? '').isNotEmpty;
}
