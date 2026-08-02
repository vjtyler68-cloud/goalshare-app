import 'dart:convert';

/// Sentinel so [AccountabilityProfile.copyWith] can tell "leave unchanged" apart
/// from "explicitly set to null" for the nullable fields.
const Object _unset = Object();

/// One user's Accountability Buddies profile.
///
/// Filled once through the questionnaire (editable later), stored as JSON in
/// Hive — no adapters, the same graceful-degrade pattern the workout/leads
/// stores use — and keyed by [userId]. The stats block ([avgRating] …) is
/// computed by the app on each rating, never entered by the user.
class AccountabilityProfile {
  final String userId;

  // Identity — denormalised so a buddy card can render without a second lookup.
  final String displayName;
  final String avatarUrl;

  /// Male / Female / Unspecified. Needed for the "Same gender only" preference
  /// to actually work — the spec references same-gender matching but only stores
  /// the *preference*, so we also keep the user's own gender here.
  final String gender;

  // ── Goals & Focus ─────────────────────────────────────────────────────────
  final String focusArea; // Fitness, Finances, Faith, Career/Sales, Mindset, Relationships
  final String monthlyGoal;
  final List<String> topModules;
  final int consistencyRating; // 1-5
  final String biggestObstacle;
  final bool prefersSingleGoalFocus;

  // ── Accountability Style ──────────────────────────────────────────────────
  final String checkInFrequency; // Daily, EveryOtherDay, TwoToThreeWeek
  final String checkInFormat; // Text, VoiceNotes, PhotoProof, AppActivityOnly
  final String motivationStyle; // Encouragement, ToughLove, Competition
  final String activeTimeOfDay; // Morning, Afternoon, Evening, NightOwl
  final bool hasDoneAccountabilityBefore;
  final String missedCheckInPreference; // GentleNudge, DirectCallOut, DontMind, RatherNotPushed

  // ── Logistics / Comfort ───────────────────────────────────────────────────
  final String timezone;
  final String genderPreference; // NoPreference, SameGenderOnly
  final bool openToOtherGoalAreas;
  final String extendPreference; // Yes, No, LetsSee

  // ── Icebreaker ────────────────────────────────────────────────────────────
  final String earlyBirdOrNightOwl; // EarlyBird, NightOwl
  final String funFact;

  // ── Stats (computed, not user-entered) ────────────────────────────────────
  final double avgRating;
  final int totalRatings;
  final int cyclesCompleted;
  final bool optedInForNextCycle;
  final String? currentMatchId;
  final DateTime? lastUpdated;

  const AccountabilityProfile({
    required this.userId,
    this.displayName = '',
    this.avatarUrl = '',
    this.gender = 'Unspecified',
    this.focusArea = '',
    this.monthlyGoal = '',
    this.topModules = const <String>[],
    this.consistencyRating = 3,
    this.biggestObstacle = '',
    this.prefersSingleGoalFocus = true,
    this.checkInFrequency = 'Daily',
    this.checkInFormat = 'Text',
    this.motivationStyle = 'Encouragement',
    this.activeTimeOfDay = 'Morning',
    this.hasDoneAccountabilityBefore = false,
    this.missedCheckInPreference = 'GentleNudge',
    this.timezone = '',
    this.genderPreference = 'NoPreference',
    this.openToOtherGoalAreas = true,
    this.extendPreference = 'LetsSee',
    this.earlyBirdOrNightOwl = 'EarlyBird',
    this.funFact = '',
    this.avgRating = 0.0,
    this.totalRatings = 0,
    this.cyclesCompleted = 0,
    this.optedInForNextCycle = false,
    this.currentMatchId,
    this.lastUpdated,
  });

  /// The questionnaire's minimum "this profile is usable" bar.
  bool get isComplete => focusArea.isNotEmpty && monthlyGoal.trim().isNotEmpty;

  /// "Reliable Buddy" tier — a strong average across enough real cycles.
  bool get isReliableBuddy => avgRating >= 4.5 && cyclesCompleted >= 5;

  /// "★ 4.8" style label, or null when nobody has rated this user yet (so we
  /// never show a misleading 0.0).
  String? get starLabel =>
      totalRatings == 0 ? null : '★ ${avgRating.toStringAsFixed(1)}';

  AccountabilityProfile copyWith({
    String? userId,
    String? displayName,
    String? avatarUrl,
    String? gender,
    String? focusArea,
    String? monthlyGoal,
    List<String>? topModules,
    int? consistencyRating,
    String? biggestObstacle,
    bool? prefersSingleGoalFocus,
    String? checkInFrequency,
    String? checkInFormat,
    String? motivationStyle,
    String? activeTimeOfDay,
    bool? hasDoneAccountabilityBefore,
    String? missedCheckInPreference,
    String? timezone,
    String? genderPreference,
    bool? openToOtherGoalAreas,
    String? extendPreference,
    String? earlyBirdOrNightOwl,
    String? funFact,
    double? avgRating,
    int? totalRatings,
    int? cyclesCompleted,
    bool? optedInForNextCycle,
    Object? currentMatchId = _unset,
    Object? lastUpdated = _unset,
  }) {
    return AccountabilityProfile(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gender: gender ?? this.gender,
      focusArea: focusArea ?? this.focusArea,
      monthlyGoal: monthlyGoal ?? this.monthlyGoal,
      topModules: topModules ?? this.topModules,
      consistencyRating: consistencyRating ?? this.consistencyRating,
      biggestObstacle: biggestObstacle ?? this.biggestObstacle,
      prefersSingleGoalFocus:
          prefersSingleGoalFocus ?? this.prefersSingleGoalFocus,
      checkInFrequency: checkInFrequency ?? this.checkInFrequency,
      checkInFormat: checkInFormat ?? this.checkInFormat,
      motivationStyle: motivationStyle ?? this.motivationStyle,
      activeTimeOfDay: activeTimeOfDay ?? this.activeTimeOfDay,
      hasDoneAccountabilityBefore:
          hasDoneAccountabilityBefore ?? this.hasDoneAccountabilityBefore,
      missedCheckInPreference:
          missedCheckInPreference ?? this.missedCheckInPreference,
      timezone: timezone ?? this.timezone,
      genderPreference: genderPreference ?? this.genderPreference,
      openToOtherGoalAreas: openToOtherGoalAreas ?? this.openToOtherGoalAreas,
      extendPreference: extendPreference ?? this.extendPreference,
      earlyBirdOrNightOwl: earlyBirdOrNightOwl ?? this.earlyBirdOrNightOwl,
      funFact: funFact ?? this.funFact,
      avgRating: avgRating ?? this.avgRating,
      totalRatings: totalRatings ?? this.totalRatings,
      cyclesCompleted: cyclesCompleted ?? this.cyclesCompleted,
      optedInForNextCycle: optedInForNextCycle ?? this.optedInForNextCycle,
      currentMatchId: identical(currentMatchId, _unset)
          ? this.currentMatchId
          : currentMatchId as String?,
      lastUpdated: identical(lastUpdated, _unset)
          ? this.lastUpdated
          : lastUpdated as DateTime?,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'gender': gender,
        'focusArea': focusArea,
        'monthlyGoal': monthlyGoal,
        'topModules': topModules,
        'consistencyRating': consistencyRating,
        'biggestObstacle': biggestObstacle,
        'prefersSingleGoalFocus': prefersSingleGoalFocus,
        'checkInFrequency': checkInFrequency,
        'checkInFormat': checkInFormat,
        'motivationStyle': motivationStyle,
        'activeTimeOfDay': activeTimeOfDay,
        'hasDoneAccountabilityBefore': hasDoneAccountabilityBefore,
        'missedCheckInPreference': missedCheckInPreference,
        'timezone': timezone,
        'genderPreference': genderPreference,
        'openToOtherGoalAreas': openToOtherGoalAreas,
        'extendPreference': extendPreference,
        'earlyBirdOrNightOwl': earlyBirdOrNightOwl,
        'funFact': funFact,
        'avgRating': avgRating,
        'totalRatings': totalRatings,
        'cyclesCompleted': cyclesCompleted,
        'optedInForNextCycle': optedInForNextCycle,
        'currentMatchId': currentMatchId,
        'lastUpdated': lastUpdated?.toIso8601String(),
      };

  factory AccountabilityProfile.fromJson(Map<String, dynamic> j) {
    return AccountabilityProfile(
      userId: (j['userId'] ?? '').toString(),
      displayName: (j['displayName'] ?? '').toString(),
      avatarUrl: (j['avatarUrl'] ?? '').toString(),
      gender: (j['gender'] ?? 'Unspecified').toString(),
      focusArea: (j['focusArea'] ?? '').toString(),
      monthlyGoal: (j['monthlyGoal'] ?? '').toString(),
      topModules: (j['topModules'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      consistencyRating: (j['consistencyRating'] as num?)?.toInt() ?? 3,
      biggestObstacle: (j['biggestObstacle'] ?? '').toString(),
      prefersSingleGoalFocus: j['prefersSingleGoalFocus'] as bool? ?? true,
      checkInFrequency: (j['checkInFrequency'] ?? 'Daily').toString(),
      checkInFormat: (j['checkInFormat'] ?? 'Text').toString(),
      motivationStyle: (j['motivationStyle'] ?? 'Encouragement').toString(),
      activeTimeOfDay: (j['activeTimeOfDay'] ?? 'Morning').toString(),
      hasDoneAccountabilityBefore:
          j['hasDoneAccountabilityBefore'] as bool? ?? false,
      missedCheckInPreference:
          (j['missedCheckInPreference'] ?? 'GentleNudge').toString(),
      timezone: (j['timezone'] ?? '').toString(),
      genderPreference: (j['genderPreference'] ?? 'NoPreference').toString(),
      openToOtherGoalAreas: j['openToOtherGoalAreas'] as bool? ?? true,
      extendPreference: (j['extendPreference'] ?? 'LetsSee').toString(),
      earlyBirdOrNightOwl: (j['earlyBirdOrNightOwl'] ?? 'EarlyBird').toString(),
      funFact: (j['funFact'] ?? '').toString(),
      avgRating: (j['avgRating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: (j['totalRatings'] as num?)?.toInt() ?? 0,
      cyclesCompleted: (j['cyclesCompleted'] as num?)?.toInt() ?? 0,
      optedInForNextCycle: j['optedInForNextCycle'] as bool? ?? false,
      currentMatchId: j['currentMatchId'] as String?,
      lastUpdated: j['lastUpdated'] == null
          ? null
          : DateTime.tryParse(j['lastUpdated'].toString()),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory AccountabilityProfile.fromJsonString(String s) =>
      AccountabilityProfile.fromJson(
          Map<String, dynamic>.from(jsonDecode(s) as Map));
}
