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
  // Pipeline stage: lead | sale | approved | installed.
  String stage;
  // A pre-loaded prospect pin (every home in an area), shared across the team.
  bool seeded;
  String? homeownerName;
  String? contactEmail;
  String? notes;
  String? phone;
  // Optional lead assignment (admin hands a door to a specific rep). A rep sees
  // pins they dropped OR ones assigned to them.
  String? assignedRepId;
  String? assignedRepName;
  // Deal / account detail.
  Map<String, bool> actionItems;
  num? systemSizeKw;
  num? leaseRatePerMonth;
  num? leaseRatePerKwh;
  // Audit trail: status changes + notes.
  List<Map<String, dynamic>> statusHistory;
  List<Map<String, dynamic>> notesLog;
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
    this.stage = 'lead',
    this.seeded = false,
    this.homeownerName,
    this.contactEmail,
    this.notes,
    this.phone,
    this.assignedRepId,
    this.assignedRepName,
    this.actionItems = const {},
    this.systemSizeKw,
    this.leaseRatePerMonth,
    this.leaseRatePerKwh,
    this.statusHistory = const [],
    this.notesLog = const [],
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
        stage: (j['stage'] ?? 'lead').toString(),
        seeded: j['seeded'] == true,
        homeownerName: j['homeownerName'] as String?,
        contactEmail: j['contactEmail'] as String?,
        notes: j['notes'] as String?,
        phone: j['phone'] as String?,
        assignedRepId: j['assignedRepId'] as String?,
        assignedRepName: j['assignedRepName'] as String?,
        actionItems: j['actionItems'] is Map
            ? {
                for (final e in (j['actionItems'] as Map).entries)
                  e.key.toString(): e.value == true
              }
            : const {},
        systemSizeKw: j['systemSizeKw'] as num?,
        leaseRatePerMonth: j['leaseRatePerMonth'] as num?,
        leaseRatePerKwh: j['leaseRatePerKwh'] as num?,
        statusHistory: j['statusHistory'] is List
            ? [
                for (final e in (j['statusHistory'] as List))
                  if (e is Map) Map<String, dynamic>.from(e)
              ]
            : const [],
        notesLog: j['notesLog'] is List
            ? [
                for (final e in (j['notesLog'] as List))
                  if (e is Map) Map<String, dynamic>.from(e)
              ]
            : const [],
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

  static const List<String> stages = ['lead', 'sale', 'approved', 'installed'];
  static const Map<String, String> stageLabels = {
    'lead': 'Lead',
    'sale': 'Sale',
    'approved': 'Approved',
    'installed': 'Installed',
  };
  String get stageLabel => stageLabels[stage] ?? 'Lead';
  int get stageIndex {
    final i = stages.indexOf(stage);
    return i < 0 ? 0 : i;
  }

  /// The 4 standard action items with their done-state (defaults false).
  static const Map<String, String> actionItemLabels = {
    'creditScore': 'Credit Score',
    'equipment': 'Equipment',
    'pricing': 'Pricing',
    'siteAudit': 'Site Audit',
  };
  bool actionDone(String key) => actionItems[key] == true;

  /// A door "needs attention" when it's progressed past Lead but still has an
  /// unchecked action item.
  bool get needsAttention =>
      stage != 'lead' &&
      actionItemLabels.keys.any((k) => actionItems[k] != true);
}
