import 'package:flutter_test/flutter_test.dart';
import 'package:spanx/features/mybudget/data/budget_models.dart';

/// Persistence-correctness tests for the local-first budget.
///
/// The whole feature is local-first (Hive JSON) and money is integer **cents**
/// with tolerant parsing. A serialization or clamp-typing regression would
/// silently corrupt or drop data, so these tests lock down:
///   1. A month round-trips through toJsonString/fromJsonString with every
///      amount intact to the cent.
///   2. Weekly <-> monthly envelope shapes persist correctly.
///   3. Malformed / old / partial records degrade gracefully (never throw).
void main() {
  // ── Helpers ────────────────────────────────────────────────────────────────

  BudgetTxn txn(int cents, {String id = 't1', int week = -1, String note = ''}) =>
      BudgetTxn(
        id: id,
        amountCents: cents,
        note: note,
        date: DateTime.utc(2026, 3, 14, 9, 30),
        weekIndex: week,
      );

  BudgetMonth richMonth() => BudgetMonth(
        year: 2026,
        month: 7,
        incomes: [
          BudgetIncome(id: 'inc1', name: 'Paycheck', amountCents: 512345),
          BudgetIncome(id: 'inc2', name: 'Side gig', amountCents: 9999),
        ],
        goals: [
          BudgetGoal(
            id: 'g1',
            name: 'Emergency Fund',
            type: 'savings',
            targetCents: 100000,
            colorValue: 0xff3B82F6,
            iconKey: 'savings',
            contributions: [
              txn(2500, id: 'gc1'),
              txn(7501, id: 'gc2'),
            ],
          ),
        ],
        debts: [
          BudgetDebt(
            id: 'd1',
            name: 'Student Loan',
            startingBalanceCents: 2300000,
            colorValue: 0xffF97316,
            iconKey: 'debt',
            payments: [txn(50000, id: 'dp1')],
          ),
        ],
        categories: [
          // Flat monthly bill envelope.
          BudgetCategory(
            id: 'cMonthly',
            name: 'Insurance',
            iconKey: 'insurance',
            colorValue: 0xff3B82F6,
            section: 'bill',
            isWeekly: false,
            budgetCents: 40000,
            transactions: [txn(12345, id: 'm-txn1')],
          ),
          // Weekly (4-envelope) spending category.
          BudgetCategory(
            id: 'cWeekly',
            name: 'Food',
            iconKey: 'food',
            colorValue: 0xff22C55E,
            section: 'spending',
            isWeekly: true,
            weeklyBudgetsCents: [12500, 12000, 13000, 11999],
            transactions: [
              txn(4500, id: 'w0', week: 0),
              txn(3300, id: 'w1', week: 1),
              txn(999, id: 'w3', week: 3),
            ],
          ),
        ],
      );

  // ── 1. Full round-trip, amounts intact to the cent ──────────────────────────

  group('BudgetMonth JSON round-trip', () {
    test('every field and amount survives toJsonString -> fromJsonString', () {
      final original = richMonth();
      final restored = BudgetMonth.fromJsonString(original.toJsonString());

      expect(restored.year, 2026);
      expect(restored.month, 7);

      // Incomes
      expect(restored.incomes, hasLength(2));
      expect(restored.incomes[0].id, 'inc1');
      expect(restored.incomes[0].name, 'Paycheck');
      expect(restored.incomes[0].amountCents, 512345);
      expect(restored.incomes[1].amountCents, 9999);
      expect(restored.totalIncomeCents, 512345 + 9999);

      // Goals + contributions
      expect(restored.goals, hasLength(1));
      final g = restored.goals.single;
      expect(g.id, 'g1');
      expect(g.targetCents, 100000);
      expect(g.contributions.map((c) => c.amountCents), [2500, 7501]);
      expect(g.savedCents, 10001);

      // Debts + payments
      final d = restored.debts.single;
      expect(d.startingBalanceCents, 2300000);
      expect(d.paidCents, 50000);
      expect(d.remainingCents, 2250000);

      // Monthly category + txns
      final mCat = restored.categories.firstWhere((c) => c.id == 'cMonthly');
      expect(mCat.isWeekly, isFalse);
      expect(mCat.budgetCents, 40000);
      expect(mCat.totalBudgetCents, 40000);
      expect(mCat.spentCents, 12345);

      // Weekly category preserves per-week envelopes and per-week spend
      final wCat = restored.categories.firstWhere((c) => c.id == 'cWeekly');
      expect(wCat.isWeekly, isTrue);
      expect(wCat.weeklyBudgetsCents, [12500, 12000, 13000, 11999]);
      expect(wCat.totalBudgetCents, 12500 + 12000 + 13000 + 11999);
      expect(wCat.spentForWeek(0), 4500);
      expect(wCat.spentForWeek(1), 3300);
      expect(wCat.spentForWeek(2), 0);
      expect(wCat.spentForWeek(3), 999);
      expect(wCat.spentCents, 4500 + 3300 + 999);
    });

    test('transaction metadata (id, note, date, weekIndex) survives', () {
      final original = richMonth();
      final restored = BudgetMonth.fromJsonString(original.toJsonString());
      final t = restored.categories
          .firstWhere((c) => c.id == 'cWeekly')
          .transactions
          .firstWhere((t) => t.id == 'w1');
      expect(t.amountCents, 3300);
      expect(t.weekIndex, 1);
      expect(t.date.toUtc(), DateTime.utc(2026, 3, 14, 9, 30));
    });

    test('double round-trip is stable (idempotent serialization)', () {
      final once = BudgetMonth.fromJsonString(richMonth().toJsonString());
      final twice = BudgetMonth.fromJsonString(once.toJsonString());
      expect(twice.toJsonString(), once.toJsonString());
    });

    test('empty / blank month round-trips', () {
      final blank = BudgetMonth.blank(2026, 1);
      final restored = BudgetMonth.fromJsonString(blank.toJsonString());
      expect(restored.isEmpty, isTrue);
      expect(restored.year, 2026);
      expect(restored.month, 1);
    });

    test('preset month round-trips with amounts intact', () {
      final preset = BudgetMonth.preset(2026, 7);
      final restored = BudgetMonth.fromJsonString(preset.toJsonString());
      expect(restored.categories, hasLength(preset.categories.length));
      expect(restored.totalBudgetedCents, preset.totalBudgetedCents);
      expect(restored.goals.map((g) => g.targetCents),
          preset.goals.map((g) => g.targetCents));
    });

    test('large amounts within guard survive exactly', () {
      final m = BudgetMonth(
        year: 2026,
        month: 5,
        incomes: [BudgetIncome(id: 'x', name: 'Big', amountCents: kMaxCents)],
      );
      final restored = BudgetMonth.fromJsonString(m.toJsonString());
      expect(restored.incomes.single.amountCents, kMaxCents);
    });
  });

  // ── 2. Weekly <-> monthly envelope conversion persists ──────────────────────

  group('weekly/monthly envelope conversion', () {
    test('monthly -> weekly conversion persists both shapes', () {
      final monthly = BudgetCategory.create(
        name: 'Groceries',
        isWeekly: false,
        budgetCents: 40000,
      );
      // Convert to weekly (the pattern used by updateCategoryMeta).
      final weekly = monthly.copyWith(
        isWeekly: true,
        weeklyBudgetsCents: [10000, 10000, 10000, 10000],
      );
      final wrapped = BudgetMonth(year: 2026, month: 2, categories: [weekly]);
      final restored =
          BudgetMonth.fromJsonString(wrapped.toJsonString()).categories.single;

      expect(restored.isWeekly, isTrue);
      expect(restored.weeklyBudgetsCents, [10000, 10000, 10000, 10000]);
      expect(restored.totalBudgetCents, 40000);
    });

    test('weekly -> monthly conversion persists both shapes', () {
      final weekly = BudgetCategory.create(
        name: 'Fun',
        isWeekly: true,
        weeklyBudgetsCents: [5000, 5000, 5000, 5000],
      );
      final monthly = weekly.copyWith(isWeekly: false, budgetCents: 18000);
      final wrapped = BudgetMonth(year: 2026, month: 2, categories: [monthly]);
      final restored =
          BudgetMonth.fromJsonString(wrapped.toJsonString()).categories.single;

      expect(restored.isWeekly, isFalse);
      expect(restored.budgetCents, 18000);
      expect(restored.totalBudgetCents, 18000);
    });

    test('weeklyBudgetsCents is always normalized to length 4 after reload', () {
      // Old record with a short/long weekly list.
      final short = BudgetMonth.fromJsonString(
        '{"year":2026,"month":4,"categories":[{"id":"c","name":"X",'
        '"isWeekly":true,"weeklyBudgetsCents":[100,200]}]}',
      ).categories.single;
      expect(short.weeklyBudgetsCents, [100, 200, 0, 0]);
      expect(short.budgetForWeek(3), 0);

      final long = BudgetMonth.fromJsonString(
        '{"year":2026,"month":4,"categories":[{"id":"c","name":"X",'
        '"isWeekly":true,"weeklyBudgetsCents":[1,2,3,4,5,6]}]}',
      ).categories.single;
      expect(long.weeklyBudgetsCents, [1, 2, 3, 4]);
    });

    test('carryForwardTo clears txns, keeps envelopes, rolls unpaid debt', () {
      final src = richMonth();
      final next = src.carryForwardTo(2026, 8);
      final restored = BudgetMonth.fromJsonString(next.toJsonString());

      expect(restored.year, 2026);
      expect(restored.month, 8);
      // Envelopes kept.
      final wCat = restored.categories.firstWhere((c) => c.name == 'Food');
      expect(wCat.weeklyBudgetsCents, [12500, 12000, 13000, 11999]);
      // Spending cleared everywhere.
      expect(
        restored.categories.every((c) => c.transactions.isEmpty),
        isTrue,
      );
      expect(restored.goals.every((g) => g.contributions.isEmpty), isTrue);
      // Debt rolled forward at remaining balance, payments cleared.
      final debt = restored.debts.single;
      expect(debt.startingBalanceCents, 2250000);
      expect(debt.payments, isEmpty);
    });

    test('carryForwardTo drops fully-paid debts', () {
      final src = BudgetMonth(
        year: 2026,
        month: 6,
        debts: [
          BudgetDebt(
            id: 'd',
            name: 'Card',
            startingBalanceCents: 10000,
            payments: [txn(10000, id: 'p')],
          ),
        ],
      );
      final next = src.carryForwardTo(2026, 7);
      expect(next.debts, isEmpty);
    });
  });

  // ── 3. Malformed / old / partial records degrade gracefully ─────────────────

  group('tolerant parsing (never throws on bad data)', () {
    test('completely empty json object yields an empty month', () {
      final m = BudgetMonth.fromJsonString('{}');
      expect(m.isEmpty, isTrue);
      expect(m.incomes, isEmpty);
      expect(m.categories, isEmpty);
    });

    test('missing year/month fall back without throwing', () {
      final m = BudgetMonth.fromJsonString('{"incomes":[]}');
      expect(m.year, isA<int>());
      expect(m.month, inInclusiveRange(1, 12));
    });

    test('amounts stored as strings or doubles are coerced to int cents', () {
      final m = BudgetMonth.fromJsonString(
        '{"year":2026,"month":1,"incomes":['
        '{"id":"a","name":"Str","amountCents":"4200"},'
        '{"id":"b","name":"Dbl","amountCents":6000.0}]}',
      );
      expect(m.incomes[0].amountCents, 4200);
      expect(m.incomes[1].amountCents, 6000);
    });

    test('non-map entries inside lists are skipped, valid ones kept', () {
      final m = BudgetMonth.fromJsonString(
        '{"year":2026,"month":1,"categories":['
        '"garbage",42,null,'
        '{"id":"ok","name":"Real","budgetCents":100}]}',
      );
      expect(m.categories, hasLength(1));
      expect(m.categories.single.id, 'ok');
    });

    test('a list field arriving as a non-list becomes empty, not a crash', () {
      final m = BudgetMonth.fromJsonString(
        '{"year":2026,"month":1,"categories":"nope","incomes":5}',
      );
      expect(m.categories, isEmpty);
      expect(m.incomes, isEmpty);
    });

    test('transactions with bad nested data degrade gracefully', () {
      final m = BudgetMonth.fromJsonString(
        '{"year":2026,"month":1,"categories":[{"id":"c","name":"X",'
        '"budgetCents":100,"transactions":["bad",null,'
        '{"amountCents":250,"weekIndex":"1"}]}]}',
      );
      final txns = m.categories.single.transactions;
      expect(txns, hasLength(1));
      expect(txns.single.amountCents, 250);
      expect(txns.single.weekIndex, 1); // string "1" coerced
    });

    test('missing amount / id fields fall back to safe defaults', () {
      final m = BudgetMonth.fromJsonString(
        '{"year":2026,"month":1,"categories":[{"name":"NoId"}]}',
      );
      final c = m.categories.single;
      expect(c.id, isNotEmpty); // synthesized id
      expect(c.name, 'NoId');
      expect(c.budgetCents, 0);
      expect(c.transactions, isEmpty);
    });

    test('oversized amounts are clamped to the guard', () {
      final m = BudgetMonth.fromJsonString(
        '{"year":2026,"month":1,"incomes":['
        '{"id":"a","name":"Huge","amountCents":999999999999999}]}',
      );
      expect(m.incomes.single.amountCents, kMaxCents);
    });

    test('outright invalid JSON throws (caught by BudgetStore, not here)', () {
      expect(() => BudgetMonth.fromJsonString('not json'), throwsA(anything));
    });
  });

  // ── parseDollarsToCents (user input -> cents) ───────────────────────────────

  group('parseDollarsToCents', () {
    test('parses common formats to exact cents', () {
      expect(parseDollarsToCents('40'), 4000);
      expect(parseDollarsToCents('40.5'), 4050);
      expect(parseDollarsToCents('1,234.56'), 123456);
      expect(parseDollarsToCents(r'$40'), 4000);
      expect(parseDollarsToCents(' 12.99 '), 1299);
    });

    test('rejects empty, negative, and non-numeric input', () {
      expect(parseDollarsToCents(''), isNull);
      expect(parseDollarsToCents('   '), isNull);
      expect(parseDollarsToCents('-5'), isNull);
      expect(parseDollarsToCents('abc'), isNull);
    });

    test('rejects oversized input', () {
      expect(parseDollarsToCents('99999999999'), isNull);
    });
  });

  // ── weekIndexForDate ────────────────────────────────────────────────────────

  group('weekIndexForDate', () {
    test('maps day-of-month into 0-3 buckets', () {
      expect(weekIndexForDate(DateTime(2026, 7, 1)), 0);
      expect(weekIndexForDate(DateTime(2026, 7, 7)), 0);
      expect(weekIndexForDate(DateTime(2026, 7, 8)), 1);
      expect(weekIndexForDate(DateTime(2026, 7, 14)), 1);
      expect(weekIndexForDate(DateTime(2026, 7, 15)), 2);
      expect(weekIndexForDate(DateTime(2026, 7, 22)), 3);
      expect(weekIndexForDate(DateTime(2026, 7, 31)), 3); // clamped
    });
  });
}
