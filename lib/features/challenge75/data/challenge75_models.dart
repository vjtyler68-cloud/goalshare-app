import 'package:flutter/material.dart';

/// 75 Challenge — the SINGLE source of truth for the challenge model: its
/// variants (Hard / Medium / Soft / Custom), the daily config a user picks at
/// the start, one day's logged entry, and the completion rules that decide
/// whether a day "counts".
///
/// Pure data — no Flutter state, no storage, no backend. The controller owns
/// persistence; the UI only reads/derives from these.

/// Stable variant ids — PERSISTED on device, never rename.
class Challenge75VariantId {
  Challenge75VariantId._();
  static const String hard = 'hard';
  static const String medium = 'medium';
  static const String soft = 'soft';
  static const String custom = 'custom';
}

/// Total length of the challenge.
const int kChallenge75Length = 75;

// ── Water unit conversion ──────────────────────────────────────────────────
// Water is stored canonically in millilitres so the goal + consumed amount are
// unit-independent; the chosen unit only affects display + quick-add steps.
class WaterUnit {
  WaterUnit._();
  static const String litre = 'L';
  static const String ounce = 'oz';
  static const String gallon = 'gal';

  static const double mlPerL = 1000.0;
  static const double mlPerOz = 29.5735295625; // US fluid ounce
  static const double mlPerGal = 3785.411784; // US gallon

  // Flexible goal range — a quarter litre up to 8 litres, so anyone can dial in
  // their own target (1 L, 3 L, a gallon, whatever) in any unit.
  static const double minGoalMl = 250.0;
  static const double maxGoalMl = 8000.0;

  /// Slider bounds in the chosen DISPLAY unit (min, max, step) so the value and
  /// label stay clean no matter the unit (e.g. 0.25 L steps, 8 oz steps).
  static ({double min, double max, double step}) sliderSpec(String unit) {
    switch (unit) {
      case ounce:
        return (min: 16, max: 256, step: 8); // 16 oz … 2 gal
      case gallon:
        return (min: 0.25, max: 2.0, step: 0.125);
      case litre:
      default:
        return (min: 0.5, max: 8.0, step: 0.25);
    }
  }

  static double perUnit(String unit) {
    switch (unit) {
      case ounce:
        return mlPerOz;
      case gallon:
        return mlPerGal;
      case litre:
      default:
        return mlPerL;
    }
  }

  static double toMl(double value, String unit) => value * perUnit(unit);
  static double fromMl(double ml, String unit) => ml / perUnit(unit);

  /// Short display like "1.0 gal", "128 oz", "2.5 L".
  static String label(double ml, String unit) {
    final v = fromMl(ml, unit);
    switch (unit) {
      case ounce:
        return '${v.round()} oz';
      case gallon:
        return '${_trim(v)} gal';
      case litre:
      default:
        return '${_trim(v)} L';
    }
  }

  /// Quick-add steps (in ml) appropriate to the chosen unit.
  static List<({String label, double ml})> quickAdds(String unit) {
    switch (unit) {
      case ounce:
        return [
          (label: '+8 oz', ml: 8 * mlPerOz),
          (label: '+16 oz', ml: 16 * mlPerOz),
          (label: '+32 oz', ml: 32 * mlPerOz),
        ];
      case gallon:
        return [
          (label: '+8 oz', ml: 8 * mlPerOz),
          (label: '+16 oz', ml: 16 * mlPerOz),
          (label: '+½ gal', ml: 0.5 * mlPerGal),
        ];
      case litre:
      default:
        return [
          (label: '+250 ml', ml: 250),
          (label: '+500 ml', ml: 500),
          (label: '+1 L', ml: 1000),
        ];
    }
  }

  static String _trim(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(
          RegExp(r'\.$'),
          '',
        );
  }
}

/// A ready-made challenge preset. It only PRE-FILLS the setup screen — every
/// field stays editable there, so "Custom" just starts from a neutral preset.
class Challenge75Variant {
  final String id;
  final String name;
  final String tagline;
  final Color color;
  final int workoutsPerDay; // 1 or 2
  final bool requireOneOutdoor;
  final int readingPages; // 5..10
  final double waterGoalMl;
  final String waterUnit;
  final String dietName;
  final bool requireFollowedDiet;
  final bool requireNoCheatMeals;
  final bool requireNoAlcohol;
  final bool requireProgressPhoto;
  final bool restartOnMiss;

  const Challenge75Variant({
    required this.id,
    required this.name,
    required this.tagline,
    required this.color,
    required this.workoutsPerDay,
    required this.requireOneOutdoor,
    required this.readingPages,
    required this.waterGoalMl,
    required this.waterUnit,
    required this.dietName,
    required this.requireFollowedDiet,
    required this.requireNoCheatMeals,
    required this.requireNoAlcohol,
    required this.requireProgressPhoto,
    required this.restartOnMiss,
  });

  static const List<Challenge75Variant> all = [
    Challenge75Variant(
      id: Challenge75VariantId.hard,
      name: '75 Hard',
      tagline: 'The original. No compromises — miss once, start over.',
      color: Color(0xffEF4444),
      workoutsPerDay: 2,
      requireOneOutdoor: true,
      readingPages: 10,
      waterGoalMl: WaterUnit.mlPerGal, // 1 gallon
      waterUnit: WaterUnit.gallon,
      dietName: 'A diet of your choice — strict',
      requireFollowedDiet: true,
      requireNoCheatMeals: true,
      requireNoAlcohol: true,
      requireProgressPhoto: true,
      restartOnMiss: true,
    ),
    Challenge75Variant(
      id: Challenge75VariantId.medium,
      name: '75 Medium',
      tagline: 'One workout a day, strong habits, a missed day just stays red.',
      color: Color(0xffF97316),
      workoutsPerDay: 1,
      requireOneOutdoor: false,
      readingPages: 10,
      waterGoalMl: 3 * WaterUnit.mlPerL, // 3 L
      waterUnit: WaterUnit.litre,
      dietName: 'Eat clean',
      requireFollowedDiet: true,
      requireNoCheatMeals: false,
      requireNoAlcohol: true,
      requireProgressPhoto: true,
      restartOnMiss: false,
    ),
    Challenge75Variant(
      id: Challenge75VariantId.soft,
      name: '75 Soft',
      tagline: 'Sustainable. One workout, read, hydrate — kind but consistent.',
      color: Color(0xff22C55E),
      workoutsPerDay: 1,
      requireOneOutdoor: false,
      readingPages: 10,
      waterGoalMl: 2 * WaterUnit.mlPerL, // 2 L
      waterUnit: WaterUnit.litre,
      dietName: 'Eat well, drink only socially',
      requireFollowedDiet: true,
      requireNoCheatMeals: false,
      requireNoAlcohol: false,
      requireProgressPhoto: false,
      restartOnMiss: false,
    ),
    Challenge75Variant(
      id: Challenge75VariantId.custom,
      name: 'Custom',
      tagline: 'Build your own 75 — set every rule the way you want it.',
      color: Color(0xff6366F1),
      workoutsPerDay: 1,
      requireOneOutdoor: false,
      readingPages: 5,
      waterGoalMl: 2 * WaterUnit.mlPerL,
      waterUnit: WaterUnit.litre,
      dietName: 'My plan',
      requireFollowedDiet: true,
      requireNoCheatMeals: false,
      requireNoAlcohol: false,
      requireProgressPhoto: true,
      restartOnMiss: false,
    ),
  ];

  static Challenge75Variant byId(String id) =>
      all.firstWhere((v) => v.id == id, orElse: () => all.last);
}

/// The locked-in rules for a user's run. Saved once at the start; editable from
/// the "Edit goals" action (which does not reset progress).
class Challenge75Config {
  final String variantId;
  final DateTime startDate; // date-only
  final int workoutsPerDay;
  final int workoutMinutes; // each workout must last at least this long
  final bool requireOneOutdoor;
  final int readingPages;
  final double waterGoalMl;
  final String waterUnit;
  final String dietName;
  final bool requireFollowedDiet;
  final bool requireNoCheatMeals;
  final bool requireNoAlcohol;
  final bool requireProgressPhoto;
  final bool restartOnMiss; // true = miss restarts; false = day stays incomplete

  const Challenge75Config({
    required this.variantId,
    required this.startDate,
    required this.workoutsPerDay,
    this.workoutMinutes = 45,
    required this.requireOneOutdoor,
    required this.readingPages,
    required this.waterGoalMl,
    required this.waterUnit,
    required this.dietName,
    required this.requireFollowedDiet,
    required this.requireNoCheatMeals,
    required this.requireNoAlcohol,
    required this.requireProgressPhoto,
    required this.restartOnMiss,
  });

  Challenge75Variant get variant => Challenge75Variant.byId(variantId);
  Color get color => variant.color;

  bool get dietRequired =>
      requireFollowedDiet || requireNoCheatMeals || requireNoAlcohol;

  /// Number of required tasks each day given these rules.
  int get requiredTaskCount {
    var n = 3; // workouts + reading + water are always required
    if (dietRequired) n++;
    if (requireProgressPhoto) n++;
    return n;
  }

  factory Challenge75Config.fromVariant(
    Challenge75Variant v, {
    required DateTime startDate,
  }) {
    return Challenge75Config(
      variantId: v.id,
      startDate: DateTime(startDate.year, startDate.month, startDate.day),
      workoutsPerDay: v.workoutsPerDay,
      requireOneOutdoor: v.requireOneOutdoor,
      readingPages: v.readingPages,
      waterGoalMl: v.waterGoalMl,
      waterUnit: v.waterUnit,
      dietName: v.dietName,
      requireFollowedDiet: v.requireFollowedDiet,
      requireNoCheatMeals: v.requireNoCheatMeals,
      requireNoAlcohol: v.requireNoAlcohol,
      requireProgressPhoto: v.requireProgressPhoto,
      restartOnMiss: v.restartOnMiss,
    );
  }

  Challenge75Config copyWith({
    String? variantId,
    DateTime? startDate,
    int? workoutsPerDay,
    int? workoutMinutes,
    bool? requireOneOutdoor,
    int? readingPages,
    double? waterGoalMl,
    String? waterUnit,
    String? dietName,
    bool? requireFollowedDiet,
    bool? requireNoCheatMeals,
    bool? requireNoAlcohol,
    bool? requireProgressPhoto,
    bool? restartOnMiss,
  }) {
    return Challenge75Config(
      variantId: variantId ?? this.variantId,
      startDate: startDate ?? this.startDate,
      workoutsPerDay: workoutsPerDay ?? this.workoutsPerDay,
      workoutMinutes: workoutMinutes ?? this.workoutMinutes,
      requireOneOutdoor: requireOneOutdoor ?? this.requireOneOutdoor,
      readingPages: readingPages ?? this.readingPages,
      waterGoalMl: waterGoalMl ?? this.waterGoalMl,
      waterUnit: waterUnit ?? this.waterUnit,
      dietName: dietName ?? this.dietName,
      requireFollowedDiet: requireFollowedDiet ?? this.requireFollowedDiet,
      requireNoCheatMeals: requireNoCheatMeals ?? this.requireNoCheatMeals,
      requireNoAlcohol: requireNoAlcohol ?? this.requireNoAlcohol,
      requireProgressPhoto: requireProgressPhoto ?? this.requireProgressPhoto,
      restartOnMiss: restartOnMiss ?? this.restartOnMiss,
    );
  }

  Map<String, dynamic> toJson() => {
        'variantId': variantId,
        'startDate': startDate.toIso8601String(),
        'workoutsPerDay': workoutsPerDay,
        'workoutMinutes': workoutMinutes,
        'requireOneOutdoor': requireOneOutdoor,
        'readingPages': readingPages,
        'waterGoalMl': waterGoalMl,
        'waterUnit': waterUnit,
        'dietName': dietName,
        'requireFollowedDiet': requireFollowedDiet,
        'requireNoCheatMeals': requireNoCheatMeals,
        'requireNoAlcohol': requireNoAlcohol,
        'requireProgressPhoto': requireProgressPhoto,
        'restartOnMiss': restartOnMiss,
      };

  factory Challenge75Config.fromJson(Map<String, dynamic> j) {
    DateTime start;
    try {
      start = DateTime.parse(j['startDate'] as String);
    } catch (_) {
      start = DateTime.now();
    }
    return Challenge75Config(
      variantId: (j['variantId'] as String?) ?? Challenge75VariantId.custom,
      startDate: DateTime(start.year, start.month, start.day),
      workoutsPerDay: (j['workoutsPerDay'] as num?)?.toInt() ?? 1,
      workoutMinutes: (j['workoutMinutes'] as num?)?.toInt() ?? 45,
      requireOneOutdoor: j['requireOneOutdoor'] as bool? ?? false,
      readingPages: (j['readingPages'] as num?)?.toInt() ?? 10,
      waterGoalMl: (j['waterGoalMl'] as num?)?.toDouble() ?? 2000,
      waterUnit: (j['waterUnit'] as String?) ?? WaterUnit.litre,
      dietName: (j['dietName'] as String?) ?? '',
      requireFollowedDiet: j['requireFollowedDiet'] as bool? ?? true,
      requireNoCheatMeals: j['requireNoCheatMeals'] as bool? ?? false,
      requireNoAlcohol: j['requireNoAlcohol'] as bool? ?? false,
      requireProgressPhoto: j['requireProgressPhoto'] as bool? ?? true,
      restartOnMiss: j['restartOnMiss'] as bool? ?? false,
    );
  }
}

/// One logged workout within a day.
class WorkoutEntry {
  bool done;
  String type; // "Lift", "Run", "Yoga", …
  int minutes;
  bool outdoor;
  String notes;

  WorkoutEntry({
    this.done = false,
    this.type = '',
    this.minutes = 45,
    this.outdoor = false,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'done': done,
        'type': type,
        'minutes': minutes,
        'outdoor': outdoor,
        'notes': notes,
      };

  factory WorkoutEntry.fromJson(Map<String, dynamic> j) => WorkoutEntry(
        done: j['done'] as bool? ?? false,
        type: (j['type'] as String?) ?? '',
        minutes: (j['minutes'] as num?)?.toInt() ?? 45,
        outdoor: j['outdoor'] as bool? ?? false,
        notes: (j['notes'] as String?) ?? '',
      );

  WorkoutEntry clone() => WorkoutEntry(
        done: done,
        type: type,
        minutes: minutes,
        outdoor: outdoor,
        notes: notes,
      );
}

/// A single day's tracked progress (day 1..75). Mutable — the editor changes it
/// in place and the controller persists a copy.
class Challenge75Day {
  final int day; // 1..75
  final String date; // yyyy-MM-dd this day maps to
  List<WorkoutEntry> workouts;
  double waterMl;
  String bookTitle;
  int pagesRead;
  bool followedDiet;
  bool noCheatMeals;
  bool noAlcohol;
  String dietNotes;
  String? photoPath; // local file path
  bool edited; // changed on a later calendar day than [date]
  String? editedAt;

  Challenge75Day({
    required this.day,
    required this.date,
    List<WorkoutEntry>? workouts,
    this.waterMl = 0,
    this.bookTitle = '',
    this.pagesRead = 0,
    this.followedDiet = false,
    this.noCheatMeals = false,
    this.noAlcohol = false,
    this.dietNotes = '',
    this.photoPath,
    this.edited = false,
    this.editedAt,
  }) : workouts = workouts ?? <WorkoutEntry>[];

  /// A fresh entry sized to the config (one workout slot per required workout).
  factory Challenge75Day.blank({
    required int day,
    required String date,
    required Challenge75Config config,
  }) {
    return Challenge75Day(
      day: day,
      date: date,
      workouts: List.generate(
        config.workoutsPerDay,
        (i) => WorkoutEntry(minutes: config.workoutMinutes),
      ),
      bookTitle: '',
    );
  }

  Challenge75Day clone() => Challenge75Day(
        day: day,
        date: date,
        workouts: workouts.map((w) => w.clone()).toList(),
        waterMl: waterMl,
        bookTitle: bookTitle,
        pagesRead: pagesRead,
        followedDiet: followedDiet,
        noCheatMeals: noCheatMeals,
        noAlcohol: noAlcohol,
        dietNotes: dietNotes,
        photoPath: photoPath,
        edited: edited,
        editedAt: editedAt,
      );

  // ── Completion rules ──────────────────────────────────────────────────────
  bool workoutsDone(Challenge75Config c) {
    final doneCount = workouts.where((w) => w.done).length;
    if (doneCount < c.workoutsPerDay) return false;
    if (c.requireOneOutdoor && !workouts.any((w) => w.done && w.outdoor)) {
      return false;
    }
    return true;
  }

  bool readingDone(Challenge75Config c) => pagesRead >= c.readingPages;

  bool waterDone(Challenge75Config c) => waterMl >= c.waterGoalMl - 0.5;

  bool dietDone(Challenge75Config c) {
    if (c.requireFollowedDiet && !followedDiet) return false;
    if (c.requireNoCheatMeals && !noCheatMeals) return false;
    if (c.requireNoAlcohol && !noAlcohol) return false;
    return true;
  }

  bool photoDone(Challenge75Config c) =>
      !c.requireProgressPhoto ||
      (photoPath != null && photoPath!.trim().isNotEmpty);

  /// How many of the required tasks are complete.
  int requiredDone(Challenge75Config c) {
    var n = 0;
    if (workoutsDone(c)) n++;
    if (readingDone(c)) n++;
    if (waterDone(c)) n++;
    if (c.dietRequired && dietDone(c)) n++;
    if (c.requireProgressPhoto && photoDone(c)) n++;
    return n;
  }

  double completion(Challenge75Config c) {
    final total = c.requiredTaskCount;
    if (total == 0) return 0;
    return (requiredDone(c) / total).clamp(0.0, 1.0);
  }

  bool isComplete(Challenge75Config c) => requiredDone(c) >= c.requiredTaskCount;

  /// Whether the user has put ANY data into the day (so a blank day isn't
  /// mistaken for an edited one, and summaries can ignore untouched days).
  bool get hasActivity =>
      waterMl > 0 ||
      pagesRead > 0 ||
      bookTitle.trim().isNotEmpty ||
      followedDiet ||
      noCheatMeals ||
      noAlcohol ||
      dietNotes.trim().isNotEmpty ||
      (photoPath != null && photoPath!.trim().isNotEmpty) ||
      workouts.any((w) => w.done || w.type.trim().isNotEmpty || w.notes.trim().isNotEmpty);

  Map<String, dynamic> toJson() => {
        'day': day,
        'date': date,
        'workouts': workouts.map((w) => w.toJson()).toList(),
        'waterMl': waterMl,
        'bookTitle': bookTitle,
        'pagesRead': pagesRead,
        'followedDiet': followedDiet,
        'noCheatMeals': noCheatMeals,
        'noAlcohol': noAlcohol,
        'dietNotes': dietNotes,
        'photoPath': photoPath,
        'edited': edited,
        'editedAt': editedAt,
      };

  factory Challenge75Day.fromJson(Map<String, dynamic> j) => Challenge75Day(
        day: (j['day'] as num?)?.toInt() ?? 1,
        date: (j['date'] as String?) ?? '',
        workouts: ((j['workouts'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => WorkoutEntry.fromJson(m.cast<String, dynamic>()))
            .toList(),
        waterMl: (j['waterMl'] as num?)?.toDouble() ?? 0,
        bookTitle: (j['bookTitle'] as String?) ?? '',
        pagesRead: (j['pagesRead'] as num?)?.toInt() ?? 0,
        followedDiet: j['followedDiet'] as bool? ?? false,
        noCheatMeals: j['noCheatMeals'] as bool? ?? false,
        noAlcohol: j['noAlcohol'] as bool? ?? false,
        dietNotes: (j['dietNotes'] as String?) ?? '',
        photoPath: j['photoPath'] as String?,
        edited: j['edited'] as bool? ?? false,
        editedAt: j['editedAt'] as String?,
      );
}
