import 'package:hive/hive.dart';

/// GoFlow — a private, on-device cycle tracker under Quick Access.
///
/// Adapters are HAND-WRITTEN (no build_runner step in this project's flow) so
/// the module is fully self-contained. typeIds 21 (entry) and 22 (settings) are
/// the next free ids after the nutrition/goal models (max in use = 20).

/// Menstrual-flow intensity for a single day. `none` means "logged, no flow"
/// (spotting/nothing) — distinct from a day with no entry at all.
enum GoFlowIntensity { none, light, medium, heavy }

extension GoFlowIntensityX on GoFlowIntensity {
  String get label {
    switch (this) {
      case GoFlowIntensity.none:
        return 'None';
      case GoFlowIntensity.light:
        return 'Light';
      case GoFlowIntensity.medium:
        return 'Medium';
      case GoFlowIntensity.heavy:
        return 'Heavy';
    }
  }

  /// True when there is actual bleeding — drives period-day detection.
  bool get isBleeding => this != GoFlowIntensity.none;
}

/// Who is using GoFlow. The two roles get very different layouts:
///  • [self] — the full tracker: logging, prediction, phases (the person whose
///    cycle it is).
///  • [partner] — a simple, supportive read-only view of a partner's shared
///    phase, with tips on how to show up for them. No logging.
enum GoFlowRole { self, partner }

extension GoFlowRoleX on GoFlowRole {
  String get id => name;
  static GoFlowRole fromId(String? id) =>
      id == 'partner' ? GoFlowRole.partner : GoFlowRole.self;
}

/// The four cycle phases, derived from the day-count since the last period.
enum GoFlowPhase { menstrual, follicular, ovulatory, luteal }

extension GoFlowPhaseX on GoFlowPhase {
  String get label {
    switch (this) {
      case GoFlowPhase.menstrual:
        return 'Menstrual';
      case GoFlowPhase.follicular:
        return 'Follicular';
      case GoFlowPhase.ovulatory:
        return 'Ovulatory';
      case GoFlowPhase.luteal:
        return 'Luteal';
    }
  }

  String get id => name;

  static GoFlowPhase fromId(String? id) => GoFlowPhase.values.firstWhere(
        (p) => p.name == id,
        orElse: () => GoFlowPhase.follicular,
      );
}

/// One day's log. Keyed by the day string so re-logging the same day overwrites
/// (idempotent daily save).
class GoFlowEntry {
  final DateTime date;
  final GoFlowIntensity flow;

  /// 0 = unset, 1–5 scale otherwise (emoji chips in the logger).
  final int mood;
  final int energy;
  final int cramps;

  /// Extra free-form tags (bloating, headache, …) — capped at 5 in the UI.
  final List<String> symptoms;
  final String notes;

  const GoFlowEntry({
    required this.date,
    this.flow = GoFlowIntensity.none,
    this.mood = 0,
    this.energy = 0,
    this.cramps = 0,
    this.symptoms = const [],
    this.notes = '',
  });

  /// yyyy-MM-dd — the box key and de-dup key for a day.
  static String keyFor(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String get key => keyFor(date);

  GoFlowEntry copyWith({
    DateTime? date,
    GoFlowIntensity? flow,
    int? mood,
    int? energy,
    int? cramps,
    List<String>? symptoms,
    String? notes,
  }) =>
      GoFlowEntry(
        date: date ?? this.date,
        flow: flow ?? this.flow,
        mood: mood ?? this.mood,
        energy: energy ?? this.energy,
        cramps: cramps ?? this.cramps,
        symptoms: symptoms ?? this.symptoms,
        notes: notes ?? this.notes,
      );

  /// An entry carries no signal once every field is cleared — used to prune a
  /// day the user has fully reset.
  bool get isEmpty =>
      flow == GoFlowIntensity.none &&
      mood == 0 &&
      energy == 0 &&
      cramps == 0 &&
      symptoms.isEmpty &&
      notes.trim().isEmpty;

  // ── Cloud backup (JSON) ────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'flow': flow.index,
        'mood': mood,
        'energy': energy,
        'cramps': cramps,
        'symptoms': symptoms,
        'notes': notes,
      };

  factory GoFlowEntry.fromJson(Map<String, dynamic> j) => GoFlowEntry(
        date: DateTime.tryParse('${j['date'] ?? ''}') ?? DateTime.now(),
        flow: GoFlowIntensity
            .values[(((j['flow'] as num?)?.toInt() ?? 0).clamp(0, 3)).toInt()],
        mood: (j['mood'] as num?)?.toInt() ?? 0,
        energy: (j['energy'] as num?)?.toInt() ?? 0,
        cramps: (j['cramps'] as num?)?.toInt() ?? 0,
        symptoms: (j['symptoms'] is List)
            ? (j['symptoms'] as List).map((e) => e.toString()).toList()
            : const [],
        notes: (j['notes'] ?? '').toString(),
      );
}

/// Module-level config: cycle math inputs, enable/share flags, custom status,
/// and the optional GoFlow-specific accent (null = follow the app theme).
class GoFlowSettings {
  final int avgCycleLength;
  final int avgPeriodLength;
  final DateTime? lastPeriodStart;
  final bool moduleEnabled;
  final bool sharedWithFriends;
  final String? customStatusMessage;

  /// Preset id from [GoFlowAccent]; null = "match app theme".
  final String? accentId;

  /// Which experience this user gets. See [GoFlowRole].
  final GoFlowRole role;

  /// For [GoFlowRole.partner]: the friend whose shared phase we follow.
  final String? partnerId;
  final String? partnerName;

  /// True once the intro questionnaire has been completed, so we don't ask
  /// again.
  final bool onboarded;

  const GoFlowSettings({
    this.avgCycleLength = 28,
    this.avgPeriodLength = 5,
    this.lastPeriodStart,
    this.moduleEnabled = true,
    this.sharedWithFriends = false,
    this.customStatusMessage,
    this.accentId,
    this.role = GoFlowRole.self,
    this.partnerId,
    this.partnerName,
    this.onboarded = false,
  });

  GoFlowSettings copyWith({
    int? avgCycleLength,
    int? avgPeriodLength,
    DateTime? lastPeriodStart,
    bool clearLastPeriodStart = false,
    bool? moduleEnabled,
    bool? sharedWithFriends,
    String? customStatusMessage,
    bool clearCustomStatus = false,
    String? accentId,
    bool clearAccent = false,
    GoFlowRole? role,
    String? partnerId,
    String? partnerName,
    bool clearPartner = false,
    bool? onboarded,
  }) =>
      GoFlowSettings(
        avgCycleLength: avgCycleLength ?? this.avgCycleLength,
        avgPeriodLength: avgPeriodLength ?? this.avgPeriodLength,
        lastPeriodStart: clearLastPeriodStart
            ? null
            : (lastPeriodStart ?? this.lastPeriodStart),
        moduleEnabled: moduleEnabled ?? this.moduleEnabled,
        sharedWithFriends: sharedWithFriends ?? this.sharedWithFriends,
        customStatusMessage: clearCustomStatus
            ? null
            : (customStatusMessage ?? this.customStatusMessage),
        accentId: clearAccent ? null : (accentId ?? this.accentId),
        role: role ?? this.role,
        partnerId: clearPartner ? null : (partnerId ?? this.partnerId),
        partnerName: clearPartner ? null : (partnerName ?? this.partnerName),
        onboarded: onboarded ?? this.onboarded,
      );

  Map<String, dynamic> toJson() => {
        'avgCycleLength': avgCycleLength,
        'avgPeriodLength': avgPeriodLength,
        'lastPeriodStart': lastPeriodStart?.toIso8601String(),
        'moduleEnabled': moduleEnabled,
        'sharedWithFriends': sharedWithFriends,
        'customStatusMessage': customStatusMessage,
        'accentId': accentId,
        'role': role.id,
        'partnerId': partnerId,
        'partnerName': partnerName,
        'onboarded': onboarded,
      };

  factory GoFlowSettings.fromJson(Map<String, dynamic> j) => GoFlowSettings(
        avgCycleLength: (j['avgCycleLength'] as num?)?.toInt() ?? 28,
        avgPeriodLength: (j['avgPeriodLength'] as num?)?.toInt() ?? 5,
        lastPeriodStart: (j['lastPeriodStart'] == null)
            ? null
            : DateTime.tryParse('${j['lastPeriodStart']}'),
        moduleEnabled: j['moduleEnabled'] is bool ? j['moduleEnabled'] : true,
        sharedWithFriends:
            j['sharedWithFriends'] is bool ? j['sharedWithFriends'] : false,
        customStatusMessage: (j['customStatusMessage'] as String?)?.trim().isEmpty ?? true
            ? null
            : j['customStatusMessage'] as String?,
        accentId: (j['accentId'] as String?),
        role: GoFlowRoleX.fromId(j['role'] as String?),
        partnerId: (j['partnerId'] as String?),
        partnerName: (j['partnerName'] as String?),
        onboarded: j['onboarded'] is bool ? j['onboarded'] : false,
      );
}

// ── Hand-written Hive adapters ────────────────────────────────────────────────
// Mirror the byte layout hive_generator produces (writeByte(count) then each
// field index + value) so they behave exactly like the generated ones.

class GoFlowEntryAdapter extends TypeAdapter<GoFlowEntry> {
  @override
  final int typeId = 21;

  @override
  GoFlowEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GoFlowEntry(
      date: fields[0] as DateTime? ?? DateTime.now(),
      flow: GoFlowIntensity
          .values[(((fields[1] as int?) ?? 0).clamp(0, 3)).toInt()],
      mood: (fields[2] as int?) ?? 0,
      energy: (fields[3] as int?) ?? 0,
      cramps: (fields[4] as int?) ?? 0,
      symptoms:
          (fields[5] as List?)?.map((e) => e.toString()).toList() ?? const [],
      notes: (fields[6] as String?) ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, GoFlowEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.flow.index)
      ..writeByte(2)
      ..write(obj.mood)
      ..writeByte(3)
      ..write(obj.energy)
      ..writeByte(4)
      ..write(obj.cramps)
      ..writeByte(5)
      ..write(obj.symptoms)
      ..writeByte(6)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoFlowEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GoFlowSettingsAdapter extends TypeAdapter<GoFlowSettings> {
  @override
  final int typeId = 22;

  @override
  GoFlowSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GoFlowSettings(
      avgCycleLength: (fields[0] as int?) ?? 28,
      avgPeriodLength: (fields[1] as int?) ?? 5,
      lastPeriodStart: fields[2] as DateTime?,
      moduleEnabled: (fields[3] as bool?) ?? true,
      sharedWithFriends: (fields[4] as bool?) ?? false,
      customStatusMessage: fields[5] as String?,
      accentId: fields[6] as String?,
      role: GoFlowRoleX.fromId(fields[7] as String?),
      partnerId: fields[8] as String?,
      partnerName: fields[9] as String?,
      onboarded: (fields[10] as bool?) ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, GoFlowSettings obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.avgCycleLength)
      ..writeByte(1)
      ..write(obj.avgPeriodLength)
      ..writeByte(2)
      ..write(obj.lastPeriodStart)
      ..writeByte(3)
      ..write(obj.moduleEnabled)
      ..writeByte(4)
      ..write(obj.sharedWithFriends)
      ..writeByte(5)
      ..write(obj.customStatusMessage)
      ..writeByte(6)
      ..write(obj.accentId)
      ..writeByte(7)
      ..write(obj.role.id)
      ..writeByte(8)
      ..write(obj.partnerId)
      ..writeByte(9)
      ..write(obj.partnerName)
      ..writeByte(10)
      ..write(obj.onboarded);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoFlowSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
