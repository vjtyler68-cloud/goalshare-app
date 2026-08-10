import 'dart:convert';

/// Selectable pipeline stages for a lead. Kept as plain strings so the model
/// can be persisted as JSON without any Hive TypeAdapter / codegen.
const List<String> kLeadStatuses = <String>[
  'New',
  'Contacted',
  'Appointment',
  'Won',
  'Lost',
];

/// One logged touch with a lead — a call, text, email, meeting, or a note.
class LeadActivity {
  final String type; // 'call' | 'text' | 'email' | 'meeting' | 'note'
  final String note;
  final DateTime at;

  const LeadActivity({required this.type, this.note = '', required this.at});

  Map<String, dynamic> toMap() =>
      {'type': type, 'note': note, 'at': at.toIso8601String()};

  factory LeadActivity.fromMap(Map<dynamic, dynamic> m) => LeadActivity(
        type: (m['type'] ?? 'note').toString(),
        note: (m['note'] ?? '').toString(),
        at: DateTime.tryParse((m['at'] ?? '').toString()) ?? DateTime.now(),
      );
}

class Lead {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String company;
  final String status;
  final String notes;

  /// File name (NOT full path) of the lead's photo saved in the app documents
  /// directory. Only the name is stored because iOS rewrites the app container
  /// path on every install/update — the absolute path is rebuilt at read time.
  final String photoFileName;

  /// When the user wants to be reminded to reach out. Null = no reminder set.
  final DateTime? reminderAt;

  /// The deal size in dollars — powers pipeline value, production, commission.
  final double dealValue;

  /// When the deal closed (status became Won or Lost). Drives "this month"
  /// production and close-rate math. Null while the lead is still open.
  final DateTime? closedAt;

  /// Chronological touch history (calls, texts, emails, meetings, notes),
  /// oldest → newest.
  final List<LeadActivity> activities;

  final DateTime createdAt;
  final DateTime updatedAt;

  Lead({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.company = '',
    this.status = 'New',
    this.notes = '',
    this.photoFileName = '',
    this.reminderAt,
    this.dealValue = 0,
    this.closedAt,
    this.activities = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// The most recent moment this lead was touched — latest activity, else the
  /// last edit. Powers stale-lead detection.
  DateTime get lastTouchAt {
    if (activities.isEmpty) return updatedAt;
    return activities
        .map((a) => a.at)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  int get daysSinceTouch =>
      DateTime.now().difference(lastTouchAt).inDays;

  bool get hasPhoto => photoFileName.trim().isNotEmpty;
  bool get hasReminder => reminderAt != null;

  bool get isWon => status == 'Won';
  bool get isLost => status == 'Lost';
  bool get isOpen => !isWon && !isLost;

  /// Build a brand-new lead with a generated id and timestamps.
  factory Lead.create({
    required String name,
    String phone = '',
    String email = '',
    String address = '',
    String company = '',
    String status = 'New',
    String notes = '',
    String photoFileName = '',
    DateTime? reminderAt,
    double dealValue = 0,
  }) {
    final now = DateTime.now();
    final st = kLeadStatuses.contains(status) ? status : 'New';
    return Lead(
      id: '${now.microsecondsSinceEpoch}_${now.hashCode}',
      name: name,
      phone: phone,
      email: email,
      address: address,
      company: company,
      status: st,
      notes: notes,
      photoFileName: photoFileName,
      reminderAt: reminderAt,
      dealValue: dealValue,
      closedAt: (st == 'Won' || st == 'Lost') ? now : null,
      createdAt: now,
      updatedAt: now,
    );
  }

  Lead copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? company,
    String? status,
    String? notes,
    String? photoFileName,
    DateTime? reminderAt,
    bool clearReminder = false,
    double? dealValue,
    DateTime? closedAt,
    bool clearClosedAt = false,
    List<LeadActivity>? activities,
    DateTime? updatedAt,
  }) {
    return Lead(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      company: company ?? this.company,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      photoFileName: photoFileName ?? this.photoFileName,
      reminderAt: clearReminder ? null : (reminderAt ?? this.reminderAt),
      dealValue: dealValue ?? this.dealValue,
      closedAt: clearClosedAt ? null : (closedAt ?? this.closedAt),
      activities: activities ?? this.activities,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'company': company,
        'status': status,
        'notes': notes,
        'photoFileName': photoFileName,
        'reminderAt': reminderAt?.toIso8601String(),
        'dealValue': dealValue,
        'closedAt': closedAt?.toIso8601String(),
        'activities': activities.map((a) => a.toMap()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Tolerant parse: any missing/mistyped field falls back to a safe default
  /// so one bad record can never blank the whole list.
  factory Lead.fromMap(Map<dynamic, dynamic> map) {
    final now = DateTime.now();
    final reminderRaw = (map['reminderAt'] ?? '').toString();
    return Lead(
      id: (map['id'] ?? '${now.microsecondsSinceEpoch}').toString(),
      name: (map['name'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      address: (map['address'] ?? '').toString(),
      company: (map['company'] ?? '').toString(),
      status: kLeadStatuses.contains(map['status']) ? map['status'].toString() : 'New',
      notes: (map['notes'] ?? '').toString(),
      photoFileName: (map['photoFileName'] ?? '').toString(),
      reminderAt: reminderRaw.isEmpty ? null : DateTime.tryParse(reminderRaw),
      dealValue: (map['dealValue'] is num)
          ? (map['dealValue'] as num).toDouble()
          : double.tryParse('${map['dealValue'] ?? ''}') ?? 0,
      closedAt: (map['closedAt'] ?? '').toString().isEmpty
          ? null
          : DateTime.tryParse('${map['closedAt']}'),
      activities: (map['activities'] is List)
          ? (map['activities'] as List)
              .whereType<Map>()
              .map((m) => LeadActivity.fromMap(m))
              .toList()
          : const [],
      createdAt: DateTime.tryParse((map['createdAt'] ?? '').toString()) ?? now,
      updatedAt: DateTime.tryParse((map['updatedAt'] ?? '').toString()) ?? now,
    );
  }

  String toJsonString() => json.encode(toMap());

  factory Lead.fromJsonString(String source) {
    final decoded = json.decode(source);
    return Lead.fromMap(decoded as Map<dynamic, dynamic>);
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}
