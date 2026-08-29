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
  // Cached skip-trace contact (resident name + phones + emails).
  PinContact? contact;
  DateTime? contactAt;
  // Cached Google Solar potential (null until looked up).
  SolarInsight? solar;
  DateTime? solarAt;
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
    this.contact,
    this.solar,
    this.solarAt,
    this.contactAt,
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
        contact: j['contact'] is Map
            ? PinContact.fromJson(Map<String, dynamic>.from(j['contact'] as Map))
            : null,
        contactAt: DateTime.tryParse('${j['contactAt'] ?? ''}'),
        solar: j['solar'] is Map
            ? SolarInsight.fromJson(Map<String, dynamic>.from(j['solar'] as Map))
            : null,
        solarAt: DateTime.tryParse('${j['solarAt'] ?? ''}'),
        visitCount: (j['visitCount'] as num?)?.toInt() ?? 1,
        lastVisited: DateTime.tryParse('${j['lastVisited'] ?? ''}'),
        createdAt: DateTime.tryParse('${j['createdAt'] ?? ''}'),
        updatedAt: DateTime.tryParse('${j['updatedAt'] ?? ''}'),
      );

  /// Serialize the whole door (incl. cached home/contact/solar detail) for the
  /// offline pin cache. Round-trips through [CanvassPin.fromJson].
  Map<String, dynamic> toJson() => {
        'id': id,
        'orgId': orgId,
        'repId': repId,
        'repName': repName,
        'lat': lat,
        'lng': lng,
        'address': address,
        'city': city,
        'state': state,
        'zip': zip,
        'status': status,
        'stage': stage,
        'seeded': seeded,
        if (homeownerName != null) 'homeownerName': homeownerName,
        if (contactEmail != null) 'contactEmail': contactEmail,
        if (notes != null) 'notes': notes,
        if (phone != null) 'phone': phone,
        if (assignedRepId != null) 'assignedRepId': assignedRepId,
        if (assignedRepName != null) 'assignedRepName': assignedRepName,
        'actionItems': actionItems,
        if (systemSizeKw != null) 'systemSizeKw': systemSizeKw,
        if (leaseRatePerMonth != null) 'leaseRatePerMonth': leaseRatePerMonth,
        if (leaseRatePerKwh != null) 'leaseRatePerKwh': leaseRatePerKwh,
        'statusHistory': statusHistory,
        'notesLog': notesLog,
        if (enrichment != null) 'enrichment': enrichment!.toData(),
        if (enrichedAt != null) 'enrichedAt': enrichedAt!.toIso8601String(),
        if (contact != null) 'contact': contact!.toJson(),
        if (contactAt != null) 'contactAt': contactAt!.toIso8601String(),
        if (solar != null) 'solar': solar!.toJson(),
        if (solarAt != null) 'solarAt': solarAt!.toIso8601String(),
        'visitCount': visitCount,
        if (lastVisited != null) 'lastVisited': lastVisited!.toIso8601String(),
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

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

/// A skip-traced phone number.
class PinPhone {
  final String number;
  final String type; // mobile | landline
  final bool dnc; // Do-Not-Call flagged
  const PinPhone({required this.number, this.type = 'mobile', this.dnc = false});
  bool get isMobile => type == 'mobile';
  Map<String, dynamic> toJson() => {'number': number, 'type': type, 'dnc': dnc};
}

/// Resident contact detail from a skip-trace lookup.
class PinContact {
  final String name;
  final List<PinPhone> phones;
  final List<String> emails;
  const PinContact(
      {this.name = '', this.phones = const [], this.emails = const []});

  factory PinContact.fromJson(Map<String, dynamic> j) => PinContact(
        name: (j['name'] ?? '').toString(),
        phones: [
          for (final p in (j['phones'] is List ? j['phones'] as List : const []))
            if (p is Map)
              PinPhone(
                number: (p['number'] ?? '').toString(),
                type: (p['type'] ?? 'mobile').toString(),
                dnc: p['dnc'] == true,
              ),
        ],
        emails: [
          for (final e in (j['emails'] is List ? j['emails'] as List : const []))
            e.toString(),
        ],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'phones': [for (final p in phones) p.toJson()],
        'emails': emails,
      };

  bool get has => name.isNotEmpty || phones.isNotEmpty || emails.isNotEmpty;
  PinPhone? get primaryPhone => phones.isEmpty
      ? null
      : phones.firstWhere((p) => p.isMobile, orElse: () => phones.first);
}

/// Google Solar (Project Sunroof) potential for a roof.
class SolarInsight {
  final String fit; // good | ok | poor
  final num? sunshineHours;
  final int? maxPanels;
  final num? roofAreaM2;
  final num? yearlyKwh;
  final num? panelCapacityWatts;
  final String? imageryQuality;
  const SolarInsight({
    this.fit = 'poor',
    this.sunshineHours,
    this.maxPanels,
    this.roofAreaM2,
    this.yearlyKwh,
    this.panelCapacityWatts,
    this.imageryQuality,
  });

  factory SolarInsight.fromJson(Map<String, dynamic> j) => SolarInsight(
        fit: (j['fit'] ?? 'poor').toString(),
        sunshineHours: j['sunshineHours'] as num?,
        maxPanels: (j['maxPanels'] as num?)?.toInt(),
        roofAreaM2: j['roofAreaM2'] as num?,
        yearlyKwh: j['yearlyKwh'] as num?,
        panelCapacityWatts: j['panelCapacityWatts'] as num?,
        imageryQuality: j['imageryQuality']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'fit': fit,
        if (sunshineHours != null) 'sunshineHours': sunshineHours,
        if (maxPanels != null) 'maxPanels': maxPanels,
        if (roofAreaM2 != null) 'roofAreaM2': roofAreaM2,
        if (yearlyKwh != null) 'yearlyKwh': yearlyKwh,
        if (panelCapacityWatts != null) 'panelCapacityWatts': panelCapacityWatts,
        if (imageryQuality != null) 'imageryQuality': imageryQuality,
      };

  int? get roofSqft =>
      roofAreaM2 == null ? null : (roofAreaM2! * 10.7639).round();
  bool get isGood => fit == 'good';
}

/// One month of sun for the location (from PVGIS).
class MonthSun {
  final int month; // 1..12
  final num irradiance; // kWh/m² that month
  final num kwh; // kWh a 1 kWp system makes that month
  const MonthSun({required this.month, this.irradiance = 0, this.kwh = 0});
  factory MonthSun.fromJson(Map<String, dynamic> j) => MonthSun(
        month: (j['month'] as num?)?.toInt() ?? 0,
        irradiance: (j['irradiance'] as num?) ?? 0,
        kwh: (j['kwh'] as num?) ?? 0,
      );
}

/// Location sunlight from PVGIS (free, global). Peak sun hours + annual
/// irradiance + a per-kW production estimate + a monthly breakdown. Answers
/// "is this area good for solar?" everywhere, incl. where Google Solar is blank.
class SunlightInsight {
  final double peakSunHours; // per day, in-plane
  final num annualIrradiance; // kWh/m²/yr
  final num? annualKwhPerKw; // kWh/yr a 1 kWp system makes here
  final num? optimalTilt; // degrees
  final String rating; // excellent | good | fair | low
  final int score; // 0..100 for the meter
  final List<MonthSun> monthly;

  const SunlightInsight({
    this.peakSunHours = 0,
    this.annualIrradiance = 0,
    this.annualKwhPerKw,
    this.optimalTilt,
    this.rating = 'low',
    this.score = 0,
    this.monthly = const [],
  });

  factory SunlightInsight.fromJson(Map<String, dynamic> j) => SunlightInsight(
        peakSunHours: (j['peakSunHours'] as num?)?.toDouble() ?? 0,
        annualIrradiance: (j['annualIrradiance'] as num?) ?? 0,
        annualKwhPerKw: j['annualKwhPerKw'] as num?,
        optimalTilt: j['optimalTilt'] as num?,
        rating: (j['rating'] ?? 'low').toString(),
        score: (j['score'] as num?)?.toInt() ?? 0,
        monthly: [
          for (final m
              in (j['monthly'] is List ? j['monthly'] as List : const []))
            if (m is Map) MonthSun.fromJson(Map<String, dynamic>.from(m)),
        ],
      );

  /// Estimated annual production (kWh) for a [kw]-kilowatt system.
  int systemKwh(double kw) =>
      annualKwhPerKw == null ? 0 : (annualKwhPerKw! * kw).round();
}
