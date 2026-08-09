import 'package:flutter_test/flutter_test.dart';
import 'package:spanx/features/goflow/data/goflow_pregnancy.dart';

void main() {
  test('gestational week + due date from LMP', () {
    final lmp = DateTime(2026, 1, 1);
    // 8 weeks + 3 days after LMP → 59 days → week 9 (day 3 of week).
    final st = GoFlowPregnancy.statusFrom(lmp, on: DateTime(2026, 3, 1));
    expect(st.week, 9);
    expect(st.trimester, 1);
    expect(st.dueDate, DateTime(2026, 1, 1).add(const Duration(days: 280)));
  });

  test('trimesters split at weeks 14 and 28', () {
    final lmp = DateTime(2026, 1, 1);
    // ~week 20 → second trimester.
    final t2 = GoFlowPregnancy.statusFrom(lmp, on: lmp.add(const Duration(days: 140)));
    expect(t2.trimester, 2);
    // ~week 30 → third trimester.
    final t3 = GoFlowPregnancy.statusFrom(lmp, on: lmp.add(const Duration(days: 210)));
    expect(t3.trimester, 3);
  });

  test('week content is available across 4..40', () {
    for (var w = 4; w <= 40; w++) {
      final wk = GoFlowPregnancy.forWeek(w);
      expect(wk.size.isNotEmpty, isTrue);
      expect(wk.development.isNotEmpty, isTrue);
    }
  });
}
