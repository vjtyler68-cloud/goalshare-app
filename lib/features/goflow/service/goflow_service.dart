import '../data/goflow_models.dart';

/// How trustworthy the next-period prediction is, based on how many complete
/// cycles have been observed.
enum GoFlowConfidence {
  /// No period anchor at all — nothing to predict from.
  none,

  /// Have an anchor but fewer than 3 measured cycles — too rough to show a
  /// date (never surface a false-precise single day).
  low,

  /// 3+ measured cycles — confident enough to show a ±2-day window.
  ready,
}

/// The computed cycle picture for a given day: where you are, what phase, and
/// when the next period is expected.
class GoFlowStatus {
  final DateTime? cycleStart;
  final int? cycleDay; // 1-based; null when there's no anchor
  final GoFlowPhase? phase;
  final int cycleLength;
  final int periodLength;
  final int measuredCycles;
  final GoFlowConfidence confidence;

  /// Predicted next-period start and its ±2 window (only meaningful when
  /// [confidence] == ready).
  final DateTime? nextPeriodStart;
  final DateTime? nextWindowStart;
  final DateTime? nextWindowEnd;
  final int? daysUntilNext;

  const GoFlowStatus({
    this.cycleStart,
    this.cycleDay,
    this.phase,
    this.cycleLength = 28,
    this.periodLength = 5,
    this.measuredCycles = 0,
    this.confidence = GoFlowConfidence.none,
    this.nextPeriodStart,
    this.nextWindowStart,
    this.nextWindowEnd,
    this.daysUntilNext,
  });

  bool get hasAnchor => cycleStart != null && cycleDay != null;
}

/// Pure, testable cycle math. No storage, no state — feed it the logged entries
/// plus settings and it returns predictions and phase.
class GoFlowService {
  GoFlowService._();

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static int _daysBetween(DateTime a, DateTime b) =>
      _dayOnly(b).difference(_dayOnly(a)).inDays;

  /// Period START days derived from the logs: a bleeding day whose previous day
  /// was NOT a bleeding day. Returned oldest→newest.
  static List<DateTime> periodStarts(List<GoFlowEntry> entries) {
    final bleeding = <String, DateTime>{};
    for (final e in entries) {
      if (e.flow.isBleeding) bleeding[GoFlowEntry.keyFor(e.date)] = _dayOnly(e.date);
    }
    final days = bleeding.values.toList()..sort();
    final starts = <DateTime>[];
    for (final d in days) {
      final prev = d.subtract(const Duration(days: 1));
      if (!bleeding.containsKey(GoFlowEntry.keyFor(prev))) starts.add(d);
    }
    return starts;
  }

  /// Gaps (in days) between consecutive period starts, filtered to a plausible
  /// human range so a mis-log can't wreck the average.
  static List<int> cycleLengths(List<DateTime> starts) {
    final out = <int>[];
    for (int i = 1; i < starts.length; i++) {
      final len = _daysBetween(starts[i - 1], starts[i]);
      if (len >= 15 && len <= 60) out.add(len);
    }
    return out;
  }

  /// Rolling average of the last up to 6 measured cycles; falls back to the
  /// user's configured [GoFlowSettings.avgCycleLength] when none are measured.
  static int averageCycleLength(
      List<GoFlowEntry> entries, GoFlowSettings settings) {
    final lens = cycleLengths(periodStarts(entries));
    if (lens.isEmpty) return settings.avgCycleLength;
    final recent = lens.length <= 6 ? lens : lens.sublist(lens.length - 6);
    final sum = recent.fold<int>(0, (a, b) => a + b);
    return (sum / recent.length).round();
  }

  /// The most recent cycle anchor: latest logged period start, else the user's
  /// manually-set [GoFlowSettings.lastPeriodStart].
  static DateTime? lastCycleStart(
      List<GoFlowEntry> entries, GoFlowSettings settings) {
    final starts = periodStarts(entries);
    if (starts.isNotEmpty) return starts.last;
    return settings.lastPeriodStart == null
        ? null
        : _dayOnly(settings.lastPeriodStart!);
  }

  /// Phase from a 1-based cycle day, using a fixed ~14-day luteal length to
  /// place ovulation relative to the *next* expected period.
  static GoFlowPhase phaseForDay(int cycleDay, int cycleLength, int periodLength) {
    final ovulation = (cycleLength - 14).clamp(periodLength + 1, cycleLength);
    if (cycleDay <= periodLength) return GoFlowPhase.menstrual;
    if (cycleDay >= ovulation - 1 && cycleDay <= ovulation + 1) {
      return GoFlowPhase.ovulatory;
    }
    if (cycleDay < ovulation - 1) return GoFlowPhase.follicular;
    return GoFlowPhase.luteal;
  }

  /// The full status for [on] (defaults to today).
  static GoFlowStatus status(
    List<GoFlowEntry> entries,
    GoFlowSettings settings, {
    DateTime? on,
  }) {
    final today = _dayOnly(on ?? DateTime.now());
    final cycleLen = averageCycleLength(entries, settings);
    final periodLen = settings.avgPeriodLength.clamp(1, cycleLen - 1);
    final measured = cycleLengths(periodStarts(entries)).length;
    final start = lastCycleStart(entries, settings);

    if (start == null) {
      return GoFlowStatus(
        cycleLength: cycleLen,
        periodLength: periodLen,
        measuredCycles: measured,
        confidence: GoFlowConfidence.none,
      );
    }

    // Day 1 = the period start. If "today" is somehow before the anchor, clamp
    // to day 1 rather than showing a negative day.
    final rawDay = _daysBetween(start, today) + 1;
    final cycleDay = rawDay < 1 ? 1 : rawDay;
    final phase = phaseForDay(cycleDay, cycleLen, periodLen);

    final nextStart = start.add(Duration(days: cycleLen));
    final confidence =
        measured >= 3 ? GoFlowConfidence.ready : GoFlowConfidence.low;

    return GoFlowStatus(
      cycleStart: start,
      cycleDay: cycleDay,
      phase: phase,
      cycleLength: cycleLen,
      periodLength: periodLen,
      measuredCycles: measured,
      confidence: confidence,
      nextPeriodStart: nextStart,
      nextWindowStart: nextStart.subtract(const Duration(days: 2)),
      nextWindowEnd: nextStart.add(const Duration(days: 2)),
      daysUntilNext: _daysBetween(today, nextStart),
    );
  }
}
