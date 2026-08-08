import 'package:flutter_test/flutter_test.dart';
import 'package:spanx/features/goflow/data/goflow_models.dart';
import 'package:spanx/features/goflow/service/goflow_service.dart';

/// A bleeding entry on [day].
GoFlowEntry _period(DateTime day) =>
    GoFlowEntry(date: day, flow: GoFlowIntensity.medium);

void main() {
  group('GoFlowService.periodStarts', () {
    test('marks only the first day of each bleeding run', () {
      final base = DateTime(2026, 1, 1);
      // Two runs: Jan 1-4 and Jan 29-31.
      final entries = <GoFlowEntry>[
        for (int i = 0; i < 4; i++) _period(base.add(Duration(days: i))),
        for (int i = 28; i < 31; i++) _period(base.add(Duration(days: i))),
      ];
      final starts = GoFlowService.periodStarts(entries);
      expect(starts.length, 2);
      expect(starts.first, DateTime(2026, 1, 1));
      expect(starts.last, DateTime(2026, 1, 29));
    });
  });

  group('GoFlowService.averageCycleLength', () {
    test('falls back to settings when no cycles measured', () {
      const s = GoFlowSettings(avgCycleLength: 30);
      expect(GoFlowService.averageCycleLength(const [], s), 30);
    });

    test('rolls the last 6 gaps between starts', () {
      final base = DateTime(2026, 1, 1);
      // Starts every 28 days for several cycles.
      final entries = <GoFlowEntry>[
        for (int c = 0; c < 5; c++) _period(base.add(Duration(days: c * 28))),
      ];
      const s = GoFlowSettings();
      expect(GoFlowService.averageCycleLength(entries, s), 28);
    });
  });

  group('GoFlowService.phaseForDay', () {
    test('day 1..periodLength is menstrual', () {
      expect(GoFlowService.phaseForDay(1, 28, 5), GoFlowPhase.menstrual);
      expect(GoFlowService.phaseForDay(5, 28, 5), GoFlowPhase.menstrual);
    });

    test('ovulation window sits ~14 days before next period', () {
      // cycleLength 28 → ovulation day 14, window 13..15.
      expect(GoFlowService.phaseForDay(14, 28, 5), GoFlowPhase.ovulatory);
      expect(GoFlowService.phaseForDay(9, 28, 5), GoFlowPhase.follicular);
      expect(GoFlowService.phaseForDay(20, 28, 5), GoFlowPhase.luteal);
    });
  });

  group('GoFlowService.status', () {
    test('no anchor → confidence none', () {
      final st = GoFlowService.status(const [], const GoFlowSettings());
      expect(st.confidence, GoFlowConfidence.none);
      expect(st.hasAnchor, isFalse);
    });

    test('predicts next period a cycle after the last start (ready at 3+)', () {
      final base = DateTime(2026, 1, 1);
      // 4 starts → 3 measured cycles → ready.
      final entries = <GoFlowEntry>[
        for (int c = 0; c < 4; c++) _period(base.add(Duration(days: c * 28))),
      ];
      final lastStart = base.add(const Duration(days: 3 * 28));
      final st = GoFlowService.status(entries, const GoFlowSettings(),
          on: lastStart);
      expect(st.confidence, GoFlowConfidence.ready);
      expect(st.cycleDay, 1);
      expect(st.phase, GoFlowPhase.menstrual);
      // Next period is one cycle (28 days) after the last start, with a ±2 day
      // window. Compare by day-difference to stay DST-safe.
      expect(st.nextPeriodStart!.difference(st.cycleStart!).inDays, 28);
      expect(st.nextWindowStart!.difference(st.cycleStart!).inDays, 26);
      expect(st.nextWindowEnd!.difference(st.cycleStart!).inDays, 30);
    });

    test('single anchor from settings → low confidence, still gives a day', () {
      final start = DateTime(2026, 3, 1);
      final st = GoFlowService.status(
        const [],
        GoFlowSettings(lastPeriodStart: start),
        on: start.add(const Duration(days: 6)),
      );
      expect(st.confidence, GoFlowConfidence.low);
      expect(st.cycleDay, 7);
      expect(st.phase, GoFlowPhase.follicular);
    });
  });
}
