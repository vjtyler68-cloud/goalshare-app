/// One person's proof for a day. [verified] is set by the PARTNER — null =
/// awaiting review, true = verified, false = "doesn't count".
class DailyProof {
  final String id;
  final String proofUrl;
  final String note;
  final bool? verified;

  const DailyProof({
    this.id = '',
    this.proofUrl = '',
    this.note = '',
    this.verified,
  });

  bool get hasProof => proofUrl.isNotEmpty;
  bool get isRejected => verified == false;
  bool get isVerified => verified == true;
  bool get isPending => verified == null;

  factory DailyProof.fromJson(Map<String, dynamic> j) => DailyProof(
        id: (j['id'] ?? '').toString(),
        proofUrl: (j['proofUrl'] ?? '').toString(),
        note: (j['note'] ?? '').toString(),
        verified: j['verified'] is bool ? j['verified'] as bool : null,
      );
}

/// A single day in the shared timeline — both sides' proof and whether the day
/// counts toward "Our Streak" (both checked in, neither rejected).
class CheckinDay {
  final String date; // yyyy-mm-dd
  final bool counts;
  final DailyProof? mine;
  final DailyProof? buddy;

  const CheckinDay({
    required this.date,
    this.counts = false,
    this.mine,
    this.buddy,
  });

  factory CheckinDay.fromJson(Map<String, dynamic> j) => CheckinDay(
        date: (j['date'] ?? '').toString(),
        counts: j['counts'] == true,
        mine: j['mine'] is Map
            ? DailyProof.fromJson(Map<String, dynamic>.from(j['mine'] as Map))
            : null,
        buddy: j['buddy'] is Map
            ? DailyProof.fromJson(Map<String, dynamic>.from(j['buddy'] as Map))
            : null,
      );
}

/// The shared check-in timeline + the mutual streak.
class CheckinsData {
  final int ourStreak;
  final List<CheckinDay> days; // newest first

  const CheckinsData({this.ourStreak = 0, this.days = const []});

  factory CheckinsData.fromJson(Map<String, dynamic> j) => CheckinsData(
        ourStreak: (j['ourStreak'] as num?)?.toInt() ?? 0,
        days: (j['days'] as List?)
                ?.whereType<Map>()
                .map((e) => CheckinDay.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
      );

  CheckinDay? dayFor(String date) {
    for (final d in days) {
      if (d.date == date) return d;
    }
    return null;
  }
}
