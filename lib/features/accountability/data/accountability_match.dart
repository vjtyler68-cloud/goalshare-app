import 'dart:convert';

const Object _unset = Object();

/// A 7-day accountability pairing between two users.
///
/// Stored as JSON in Hive and (for random pairing) mirrored from the backend.
/// Buddy identity + icebreaker context are denormalised onto the match so the
/// Match screen renders fully even when the other person's profile isn't on this
/// device (which is always the case for a random cross-user pairing).
///
/// Ratings unlock only after a side logs at least [minCheckInsToRate] check-ins,
/// so nobody can drive-by rate a buddy they never engaged with.
class AccountabilityMatch {
  static const int minCheckInsToRate = 2;

  final String id;
  final String userAId;
  final String userBId;
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final String status; // pending, active, completed, expired
  final int? userARating; // 1-5, null until submitted
  final int? userBRating;
  final DateTime? userARatedAt;
  final DateTime? userBRatedAt;
  // Optional private note left with a rating — for the rater's own review /
  // moderation only, never shown to the buddy publicly.
  final String userAComment;
  final String userBComment;
  final bool extendRequestedByA;
  final bool extendRequestedByB;
  final int checkInCountA;
  final int checkInCountB;

  // ── Denormalised buddy identity + icebreaker ──────────────────────────────
  final String userAName;
  final String userBName;
  final String userAAvatar;
  final String userBAvatar;
  final String userAFocus;
  final String userBFocus;
  final String userAGoal;
  final String userBGoal;
  final String userAFunFact;
  final String userBFunFact;
  final double userARatingAvg; // the person's shown star average
  final double userBRatingAvg;
  final int userACycles;
  final int userBCycles;

  const AccountabilityMatch({
    required this.id,
    required this.userAId,
    required this.userBId,
    required this.weekStartDate,
    required this.weekEndDate,
    this.status = 'active',
    this.userARating,
    this.userBRating,
    this.userARatedAt,
    this.userBRatedAt,
    this.userAComment = '',
    this.userBComment = '',
    this.extendRequestedByA = false,
    this.extendRequestedByB = false,
    this.checkInCountA = 0,
    this.checkInCountB = 0,
    this.userAName = '',
    this.userBName = '',
    this.userAAvatar = '',
    this.userBAvatar = '',
    this.userAFocus = '',
    this.userBFocus = '',
    this.userAGoal = '',
    this.userBGoal = '',
    this.userAFunFact = '',
    this.userBFunFact = '',
    this.userARatingAvg = 0.0,
    this.userBRatingAvg = 0.0,
    this.userACycles = 0,
    this.userBCycles = 0,
  });

  bool involves(String uid) => uid == userAId || uid == userBId;
  bool isA(String uid) => uid == userAId;

  /// Whole days left in the cycle (0 once the end date has passed).
  int daysRemaining() {
    final now = DateTime.now();
    final end = DateTime(weekEndDate.year, weekEndDate.month, weekEndDate.day);
    final today = DateTime(now.year, now.month, now.day);
    final d = end.difference(today).inDays;
    return d < 0 ? 0 : d;
  }

  /// True once we're past the cycle's end — the app flips [status] to completed
  /// and surfaces the rating prompt on the next launch.
  bool get isOver => DateTime.now().isAfter(weekEndDate);

  // ── Per-current-user accessors ────────────────────────────────────────────
  String buddyIdFor(String uid) => isA(uid) ? userBId : userAId;
  String buddyNameFor(String uid) => isA(uid) ? userBName : userAName;
  String buddyAvatarFor(String uid) => isA(uid) ? userBAvatar : userAAvatar;
  String buddyFocusFor(String uid) => isA(uid) ? userBFocus : userAFocus;
  String buddyGoalFor(String uid) => isA(uid) ? userBGoal : userAGoal;
  String buddyFunFactFor(String uid) => isA(uid) ? userBFunFact : userAFunFact;
  double buddyRatingAvgFor(String uid) =>
      isA(uid) ? userBRatingAvg : userARatingAvg;
  int buddyCyclesFor(String uid) => isA(uid) ? userBCycles : userACycles;

  int myCheckIns(String uid) => isA(uid) ? checkInCountA : checkInCountB;
  int? myRating(String uid) => isA(uid) ? userARating : userBRating;

  /// The current user may rate once they've logged enough check-ins and haven't
  /// already rated.
  bool canRate(String uid) =>
      myCheckIns(uid) >= minCheckInsToRate && myRating(uid) == null;

  bool extendRequestedByMe(String uid) =>
      isA(uid) ? extendRequestedByA : extendRequestedByB;
  bool get bothWantExtend => extendRequestedByA && extendRequestedByB;

  AccountabilityMatch copyWith({
    String? id,
    String? userAId,
    String? userBId,
    DateTime? weekStartDate,
    DateTime? weekEndDate,
    String? status,
    Object? userARating = _unset,
    Object? userBRating = _unset,
    Object? userARatedAt = _unset,
    Object? userBRatedAt = _unset,
    String? userAComment,
    String? userBComment,
    bool? extendRequestedByA,
    bool? extendRequestedByB,
    int? checkInCountA,
    int? checkInCountB,
    String? userAName,
    String? userBName,
    String? userAAvatar,
    String? userBAvatar,
    String? userAFocus,
    String? userBFocus,
    String? userAGoal,
    String? userBGoal,
    String? userAFunFact,
    String? userBFunFact,
    double? userARatingAvg,
    double? userBRatingAvg,
    int? userACycles,
    int? userBCycles,
  }) {
    return AccountabilityMatch(
      id: id ?? this.id,
      userAId: userAId ?? this.userAId,
      userBId: userBId ?? this.userBId,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      weekEndDate: weekEndDate ?? this.weekEndDate,
      status: status ?? this.status,
      userARating: identical(userARating, _unset)
          ? this.userARating
          : userARating as int?,
      userBRating: identical(userBRating, _unset)
          ? this.userBRating
          : userBRating as int?,
      userARatedAt: identical(userARatedAt, _unset)
          ? this.userARatedAt
          : userARatedAt as DateTime?,
      userBRatedAt: identical(userBRatedAt, _unset)
          ? this.userBRatedAt
          : userBRatedAt as DateTime?,
      userAComment: userAComment ?? this.userAComment,
      userBComment: userBComment ?? this.userBComment,
      extendRequestedByA: extendRequestedByA ?? this.extendRequestedByA,
      extendRequestedByB: extendRequestedByB ?? this.extendRequestedByB,
      checkInCountA: checkInCountA ?? this.checkInCountA,
      checkInCountB: checkInCountB ?? this.checkInCountB,
      userAName: userAName ?? this.userAName,
      userBName: userBName ?? this.userBName,
      userAAvatar: userAAvatar ?? this.userAAvatar,
      userBAvatar: userBAvatar ?? this.userBAvatar,
      userAFocus: userAFocus ?? this.userAFocus,
      userBFocus: userBFocus ?? this.userBFocus,
      userAGoal: userAGoal ?? this.userAGoal,
      userBGoal: userBGoal ?? this.userBGoal,
      userAFunFact: userAFunFact ?? this.userAFunFact,
      userBFunFact: userBFunFact ?? this.userBFunFact,
      userARatingAvg: userARatingAvg ?? this.userARatingAvg,
      userBRatingAvg: userBRatingAvg ?? this.userBRatingAvg,
      userACycles: userACycles ?? this.userACycles,
      userBCycles: userBCycles ?? this.userBCycles,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userAId': userAId,
        'userBId': userBId,
        'weekStartDate': weekStartDate.toIso8601String(),
        'weekEndDate': weekEndDate.toIso8601String(),
        'status': status,
        'userARating': userARating,
        'userBRating': userBRating,
        'userARatedAt': userARatedAt?.toIso8601String(),
        'userBRatedAt': userBRatedAt?.toIso8601String(),
        'userAComment': userAComment,
        'userBComment': userBComment,
        'extendRequestedByA': extendRequestedByA,
        'extendRequestedByB': extendRequestedByB,
        'checkInCountA': checkInCountA,
        'checkInCountB': checkInCountB,
        'userAName': userAName,
        'userBName': userBName,
        'userAAvatar': userAAvatar,
        'userBAvatar': userBAvatar,
        'userAFocus': userAFocus,
        'userBFocus': userBFocus,
        'userAGoal': userAGoal,
        'userBGoal': userBGoal,
        'userAFunFact': userAFunFact,
        'userBFunFact': userBFunFact,
        'userARatingAvg': userARatingAvg,
        'userBRatingAvg': userBRatingAvg,
        'userACycles': userACycles,
        'userBCycles': userBCycles,
      };

  factory AccountabilityMatch.fromJson(Map<String, dynamic> j) {
    DateTime parse(dynamic v, DateTime fallback) =>
        v == null ? fallback : (DateTime.tryParse(v.toString()) ?? fallback);
    final now = DateTime.now();
    return AccountabilityMatch(
      id: (j['id'] ?? '').toString(),
      userAId: (j['userAId'] ?? '').toString(),
      userBId: (j['userBId'] ?? '').toString(),
      weekStartDate: parse(j['weekStartDate'], now),
      weekEndDate: parse(j['weekEndDate'], now.add(const Duration(days: 7))),
      status: (j['status'] ?? 'active').toString(),
      userARating: (j['userARating'] as num?)?.toInt(),
      userBRating: (j['userBRating'] as num?)?.toInt(),
      userARatedAt: j['userARatedAt'] == null
          ? null
          : DateTime.tryParse(j['userARatedAt'].toString()),
      userBRatedAt: j['userBRatedAt'] == null
          ? null
          : DateTime.tryParse(j['userBRatedAt'].toString()),
      userAComment: (j['userAComment'] ?? '').toString(),
      userBComment: (j['userBComment'] ?? '').toString(),
      extendRequestedByA: j['extendRequestedByA'] as bool? ?? false,
      extendRequestedByB: j['extendRequestedByB'] as bool? ?? false,
      checkInCountA: (j['checkInCountA'] as num?)?.toInt() ?? 0,
      checkInCountB: (j['checkInCountB'] as num?)?.toInt() ?? 0,
      userAName: (j['userAName'] ?? '').toString(),
      userBName: (j['userBName'] ?? '').toString(),
      userAAvatar: (j['userAAvatar'] ?? '').toString(),
      userBAvatar: (j['userBAvatar'] ?? '').toString(),
      userAFocus: (j['userAFocus'] ?? '').toString(),
      userBFocus: (j['userBFocus'] ?? '').toString(),
      userAGoal: (j['userAGoal'] ?? '').toString(),
      userBGoal: (j['userBGoal'] ?? '').toString(),
      userAFunFact: (j['userAFunFact'] ?? '').toString(),
      userBFunFact: (j['userBFunFact'] ?? '').toString(),
      userARatingAvg: (j['userARatingAvg'] as num?)?.toDouble() ?? 0.0,
      userBRatingAvg: (j['userBRatingAvg'] as num?)?.toDouble() ?? 0.0,
      userACycles: (j['userACycles'] as num?)?.toInt() ?? 0,
      userBCycles: (j['userBCycles'] as num?)?.toInt() ?? 0,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory AccountabilityMatch.fromJsonString(String s) =>
      AccountabilityMatch.fromJson(
          Map<String, dynamic>.from(jsonDecode(s) as Map));
}
