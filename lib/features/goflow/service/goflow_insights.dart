import '../data/goflow_models.dart';
import 'goflow_service.dart';

/// One derived insight — a short, plain-language line plus an icon hint the UI
/// maps to a Material icon name.
class GoFlowInsight {
  final String text;
  final String icon; // 'trend' | 'mood' | 'energy' | 'cramp' | 'heart' | 'note'
  const GoFlowInsight(this.text, this.icon);
}

/// Turns logged history into simple, honest patterns. No medical claims — just
/// "here's what your own data tends to show." All local, all derived on demand.
class GoFlowInsights {
  GoFlowInsights._();

  /// The phase a given [day] fell in, using the most recent period start on or
  /// before it. Null when there's no anchor before that day.
  static GoFlowPhase? _phaseForDate(
    DateTime day,
    List<DateTime> starts,
    int cycleLen,
    int periodLen,
  ) {
    DateTime? anchor;
    for (final s in starts) {
      if (!s.isAfter(day)) anchor = s; // latest start <= day
    }
    if (anchor == null) return null;
    final dayNum = day.difference(anchor).inDays + 1;
    if (dayNum < 1 || dayNum > cycleLen + 7) return null; // stale/no data
    return GoFlowService.phaseForDay(dayNum, cycleLen, periodLen);
  }

  static String _phaseLabel(GoFlowPhase p) => p.label.toLowerCase();

  /// Build up to a handful of insights from [entries]. Returns an empty list
  /// until there's enough logged to say anything meaningful.
  static List<GoFlowInsight> build(
      List<GoFlowEntry> entries, GoFlowSettings settings) {
    final out = <GoFlowInsight>[];
    if (entries.length < 3) return out;

    final cycleLen = GoFlowService.averageCycleLength(entries, settings);
    final periodLen = settings.avgPeriodLength.clamp(1, cycleLen - 1);
    final starts = GoFlowService.periodStarts(entries);

    // Bucket cramps/energy/mood by phase.
    final crampsByPhase = <GoFlowPhase, List<int>>{};
    final energyByPhase = <GoFlowPhase, List<int>>{};
    final symptomCounts = <String, int>{};
    var intimacyCount = 0;

    for (final e in entries) {
      if (e.intercourse) intimacyCount++;
      for (final s in e.symptoms) {
        symptomCounts[s] = (symptomCounts[s] ?? 0) + 1;
      }
      final phase = _phaseForDate(e.date, starts, cycleLen, periodLen);
      if (phase == null) continue;
      if (e.cramps > 0) (crampsByPhase[phase] ??= []).add(e.cramps);
      if (e.energy > 0) (energyByPhase[phase] ??= []).add(e.energy);
    }

    double avg(List<int> xs) =>
        xs.isEmpty ? 0 : xs.reduce((a, b) => a + b) / xs.length;

    // Cramps: which phase is worst?
    if (crampsByPhase.length >= 1) {
      GoFlowPhase? worst;
      double worstAvg = 0;
      crampsByPhase.forEach((p, xs) {
        final a = avg(xs);
        if (a > worstAvg) {
          worstAvg = a;
          worst = p;
        }
      });
      if (worst != null && worstAvg >= 2.5) {
        out.add(GoFlowInsight(
            'Your cramps tend to be strongest in your ${_phaseLabel(worst!)} phase.',
            'cramp'));
      }
    }

    // Energy: which phase dips lowest?
    if (energyByPhase.length >= 2) {
      GoFlowPhase? lowest;
      double lowAvg = 6;
      energyByPhase.forEach((p, xs) {
        final a = avg(xs);
        if (a < lowAvg) {
          lowAvg = a;
          lowest = p;
        }
      });
      if (lowest != null && lowAvg <= 2.5) {
        out.add(GoFlowInsight(
            'Your energy tends to dip during your ${_phaseLabel(lowest!)} phase — plan lighter days.',
            'energy'));
      }
    }

    // Most common symptom.
    if (symptomCounts.isNotEmpty) {
      final top =
          symptomCounts.entries.reduce((a, b) => a.value >= b.value ? a : b);
      if (top.value >= 3) {
        out.add(GoFlowInsight(
            '${top.key} is your most-logged symptom (${top.value} days).', 'note'));
      }
    }

    // Fertility / TTC nudge.
    if (intimacyCount > 0) {
      out.add(GoFlowInsight(
          'You\'ve logged intimacy on $intimacyCount ${intimacyCount == 1 ? 'day' : 'days'}.',
          'heart'));
    }

    // Consistency.
    out.add(GoFlowInsight(
        'You\'ve logged ${entries.length} days — the more you log, the sharper your patterns get.',
        'trend'));

    return out;
  }
}
