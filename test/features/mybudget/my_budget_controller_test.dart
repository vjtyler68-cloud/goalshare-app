import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:spanx/features/mybudget/controller/my_budget_controller.dart';
import 'package:spanx/features/mybudget/data/budget_models.dart';
import 'package:spanx/features/mybudget/data/budget_store.dart';

/// Controller-mutation tests for MyBudgetController.
///
/// Task #15's model tests proved a month round-trips to the cent; these tests
/// prove the *mutations that produce those states* are correct: which week a
/// spend lands in, the at/under-budget celebration result, debt pay-off
/// detection, goal/txn targeting, and the daily log-streak. All state lives in
/// an in-memory fake store so no live Hive box (or device) is needed — safe
/// for plain `flutter test` in CI.

/// In-memory BudgetStore: same contract, no Hive.
class FakeBudgetStore extends BudgetStore {
  final Map<String, String> data = <String, String>{};

  @override
  bool get isReady => true;

  @override
  Future<void> open() async {}

  @override
  BudgetMonth? getMonth(String key) {
    final raw = data[key];
    if (raw == null) return null;
    return BudgetMonth.fromJsonString(raw);
  }

  @override
  Future<bool> saveMonth(BudgetMonth month) async {
    data[month.key] = month.toJsonString();
    return true;
  }

  @override
  Future<bool> deleteMonth(String key) async => data.remove(key) != null;

  @override
  List<String> monthKeys() {
    final keys = data.keys.toList();
    keys.sort((a, b) => b.compareTo(a));
    return keys;
  }
}

void main() {
  final now = DateTime.now();

  late FakeBudgetStore store;

  setUp(() {
    Get.testMode = true;
    store = FakeBudgetStore();
  });

  tearDown(() {
    Get.reset();
  });

  /// Boots a controller against [store] (Get.put fires onInit -> _load).
  Future<MyBudgetController> boot() async {
    final c = Get.put(MyBudgetController(store: store));
    while (!c.isReady.value) {
      await Future<void>.delayed(Duration.zero);
    }
    return c;
  }

  /// Seeds the *currently viewed* month (the real current month, since the
  /// controller's cursor starts there) and boots the controller on it.
  Future<MyBudgetController> bootWith({
    List<BudgetCategory>? categories,
    List<BudgetGoal>? goals,
    List<BudgetDebt>? debts,
    List<BudgetIncome>? incomes,
  }) async {
    await store.saveMonth(BudgetMonth(
      year: now.year,
      month: now.month,
      categories: categories,
      goals: goals,
      debts: debts,
      incomes: incomes,
    ));
    return boot();
  }

  BudgetTxn txnOn(DateTime date, {int cents = 100, String? id}) => BudgetTxn(
        id: id ?? 't_${date.millisecondsSinceEpoch}_$cents',
        amountCents: cents,
        date: date,
      );

  // ── logSpend ───────────────────────────────────────────────────────────────

  group('logSpend', () {
    test('weekly category: spend lands in the explicitly given week only',
        () async {
      final c = await bootWith(categories: [
        BudgetCategory(
          id: 'food',
          name: 'Food',
          isWeekly: true,
          weeklyBudgetsCents: [10000, 10000, 10000, 10000],
        ),
      ]);

      final under = await c.logSpend(categoryId: 'food', cents: 4500, week: 2);

      expect(under, isTrue);
      final cat = c.categoryById('food')!;
      expect(cat.spentForWeek(2), 4500);
      expect(cat.spentForWeek(0), 0);
      expect(cat.spentForWeek(1), 0);
      expect(cat.spentForWeek(3), 0);
      expect(cat.transactions.single.weekIndex, 2);
    });

    test('weekly category: omitted week resolves to the current date bucket',
        () async {
      final c = await bootWith(categories: [
        BudgetCategory(
          id: 'food',
          name: 'Food',
          isWeekly: true,
          weeklyBudgetsCents: [10000, 10000, 10000, 10000],
        ),
      ]);

      await c.logSpend(categoryId: 'food', cents: 100);

      final expectedWeek = weekIndexForDate(DateTime.now());
      final cat = c.categoryById('food')!;
      expect(cat.transactions.single.weekIndex, expectedWeek);
      expect(cat.spentForWeek(expectedWeek), 100);
    });

    test(
        'weekly category: result reflects the resolved week envelope, '
        'not the month total', () async {
      final c = await bootWith(categories: [
        BudgetCategory(
          id: 'food',
          name: 'Food',
          isWeekly: true,
          weeklyBudgetsCents: [10000, 5000, 10000, 10000],
        ),
      ]);

      // Exactly at the week-1 budget: still a celebration.
      expect(
          await c.logSpend(categoryId: 'food', cents: 5000, week: 1), isTrue);
      // One more cent in week 1 blows the week envelope even though the
      // month total (35000 budget) is far from spent.
      expect(await c.logSpend(categoryId: 'food', cents: 1, week: 1), isFalse);
      // A different week's envelope is unaffected.
      expect(
          await c.logSpend(categoryId: 'food', cents: 9999, week: 3), isTrue);
    });

    test('monthly category: txn has weekIndex -1 and result uses month total',
        () async {
      final c = await bootWith(categories: [
        BudgetCategory(id: 'rent', name: 'Rent', budgetCents: 100000),
      ]);

      // Even with a week passed, monthly categories ignore it.
      expect(await c.logSpend(categoryId: 'rent', cents: 99999, week: 2),
          isTrue);
      expect(c.categoryById('rent')!.transactions.single.weekIndex, -1);

      // Exactly at budget is still "under" (isOver requires strictly over).
      expect(await c.logSpend(categoryId: 'rent', cents: 1), isTrue);
      // One cent over flips it.
      expect(await c.logSpend(categoryId: 'rent', cents: 1), isFalse);
      expect(c.categoryById('rent')!.spentCents, 100001);
    });

    test('rejects non-positive amounts and unknown categories without mutating',
        () async {
      final c = await bootWith(categories: [
        BudgetCategory(id: 'rent', name: 'Rent', budgetCents: 100000),
      ]);

      expect(await c.logSpend(categoryId: 'rent', cents: 0), isFalse);
      expect(await c.logSpend(categoryId: 'rent', cents: -500), isFalse);
      expect(await c.logSpend(categoryId: 'nope', cents: 100), isFalse);
      expect(c.categoryById('rent')!.transactions, isEmpty);
    });

    test('spend only touches the target category and persists to the store',
        () async {
      final c = await bootWith(categories: [
        BudgetCategory(id: 'a', name: 'A', budgetCents: 5000),
        BudgetCategory(id: 'b', name: 'B', budgetCents: 5000),
      ]);

      await c.logSpend(categoryId: 'b', cents: 1234, note: 'coffee');

      expect(c.categoryById('a')!.transactions, isEmpty);
      final bTxn = c.categoryById('b')!.transactions.single;
      expect(bTxn.amountCents, 1234);
      expect(bTxn.note, 'coffee');

      // Persisted state matches in-memory state, to the cent.
      final saved = store.getMonth(c.monthKey)!;
      expect(saved.categories.firstWhere((x) => x.id == 'b').spentCents, 1234);
      expect(saved.categories.firstWhere((x) => x.id == 'a').spentCents, 0);
    });
  });

  // ── deleteTxn / updateTxn ──────────────────────────────────────────────────

  group('transaction edit/delete', () {
    test('deleteTxn removes exactly one txn from exactly one category',
        () async {
      final c = await bootWith(categories: [
        BudgetCategory(id: 'a', name: 'A', budgetCents: 5000, transactions: [
          txnOn(now, cents: 100, id: 'a1'),
          txnOn(now, cents: 200, id: 'a2'),
        ]),
        BudgetCategory(id: 'b', name: 'B', budgetCents: 5000, transactions: [
          txnOn(now, cents: 300, id: 'b1'),
        ]),
      ]);

      await c.deleteTxn('a', 'a2');

      expect(c.categoryById('a')!.transactions.map((t) => t.id), ['a1']);
      expect(c.categoryById('a')!.spentCents, 100);
      expect(c.categoryById('b')!.spentCents, 300);
    });

    test('deleteTxn with a wrong id is a harmless no-op', () async {
      final c = await bootWith(categories: [
        BudgetCategory(id: 'a', name: 'A', budgetCents: 5000, transactions: [
          txnOn(now, cents: 100, id: 'a1'),
        ]),
      ]);

      await c.deleteTxn('a', 'ghost');
      await c.deleteTxn('ghost', 'a1');

      expect(c.categoryById('a')!.transactions.map((t) => t.id), ['a1']);
    });

    test('updateTxn edits amount/note/week of only the target txn', () async {
      final c = await bootWith(categories: [
        BudgetCategory(
          id: 'food',
          name: 'Food',
          isWeekly: true,
          weeklyBudgetsCents: [10000, 10000, 10000, 10000],
          transactions: [
            BudgetTxn(id: 'x1', amountCents: 500, date: now, weekIndex: 0),
            BudgetTxn(id: 'x2', amountCents: 700, date: now, weekIndex: 0),
          ],
        ),
      ]);

      await c.updateTxn('food', 'x1', cents: 900, note: 'edited', week: 3);

      final cat = c.categoryById('food')!;
      final x1 = cat.transactions.firstWhere((t) => t.id == 'x1');
      expect(x1.amountCents, 900);
      expect(x1.note, 'edited');
      expect(x1.weekIndex, 3);
      // Moving the txn moved the spend between week envelopes.
      expect(cat.spentForWeek(0), 700);
      expect(cat.spentForWeek(3), 900);
      final x2 = cat.transactions.firstWhere((t) => t.id == 'x2');
      expect(x2.amountCents, 700);
      expect(x2.weekIndex, 0);
    });
  });

  // ── payDebt ────────────────────────────────────────────────────────────────

  group('payDebt', () {
    test('returns true exactly when the payment reaches the balance',
        () async {
      final c = await bootWith(debts: [
        BudgetDebt(id: 'loan', name: 'Loan', startingBalanceCents: 10000),
      ]);

      // Partial payments: not paid off yet.
      expect(await c.payDebt('loan', 4000), isFalse);
      expect(await c.payDebt('loan', 5999), isFalse);

      // The exact remaining cent flips it.
      expect(await c.payDebt('loan', 1), isTrue);

      final d = c.month.value!.debts.single;
      expect(d.paidCents, 10000);
      expect(d.remainingCents, 0);
      expect(d.isPaidOff, isTrue);
    });

    test('overpaying in one go also reports paid off', () async {
      final c = await bootWith(debts: [
        BudgetDebt(id: 'loan', name: 'Loan', startingBalanceCents: 10000),
      ]);

      expect(await c.payDebt('loan', 12345), isTrue);
      expect(c.month.value!.debts.single.remainingCents, 0);
    });

    test('rejects non-positive amounts and unknown debts', () async {
      final c = await bootWith(debts: [
        BudgetDebt(id: 'loan', name: 'Loan', startingBalanceCents: 10000),
      ]);

      expect(await c.payDebt('loan', 0), isFalse);
      expect(await c.payDebt('loan', -100), isFalse);
      expect(await c.payDebt('ghost', 5000), isFalse);
      expect(c.month.value!.debts.single.payments, isEmpty);
    });

    test('deleteDebtTxn removes only the target payment', () async {
      final c = await bootWith(debts: [
        BudgetDebt(id: 'loan', name: 'Loan', startingBalanceCents: 10000,
            payments: [
              txnOn(now, cents: 3000, id: 'p1'),
              txnOn(now, cents: 2000, id: 'p2'),
            ]),
      ]);

      await c.deleteDebtTxn('loan', 'p1');

      final d = c.month.value!.debts.single;
      expect(d.payments.map((t) => t.id), ['p2']);
      expect(d.paidCents, 2000);
    });
  });

  // ── goals ──────────────────────────────────────────────────────────────────

  group('contributeToGoal', () {
    test('adds a contribution to only the target goal', () async {
      final c = await bootWith(goals: [
        BudgetGoal(id: 'g1', name: 'Emergency', targetCents: 100000),
        BudgetGoal(id: 'g2', name: 'Vacation', targetCents: 50000),
      ]);

      await c.contributeToGoal('g1', 2500, note: 'payday');

      final g1 = c.month.value!.goals.firstWhere((g) => g.id == 'g1');
      final g2 = c.month.value!.goals.firstWhere((g) => g.id == 'g2');
      expect(g1.savedCents, 2500);
      expect(g1.contributions.single.note, 'payday');
      expect(g2.savedCents, 0);
      expect(g2.contributions, isEmpty);
    });

    test('ignores non-positive amounts', () async {
      final c = await bootWith(goals: [
        BudgetGoal(id: 'g1', name: 'Emergency', targetCents: 100000),
      ]);

      await c.contributeToGoal('g1', 0);
      await c.contributeToGoal('g1', -1);

      expect(c.month.value!.goals.single.contributions, isEmpty);
    });

    test('deleteGoalTxn removes only the target contribution', () async {
      final c = await bootWith(goals: [
        BudgetGoal(id: 'g1', name: 'Emergency', targetCents: 100000,
            contributions: [
              txnOn(now, cents: 1000, id: 'c1'),
              txnOn(now, cents: 2000, id: 'c2'),
            ]),
      ]);

      await c.deleteGoalTxn('g1', 'c2');

      final g = c.month.value!.goals.single;
      expect(g.contributions.map((t) => t.id), ['c1']);
      expect(g.savedCents, 1000);
    });
  });

  // ── logStreak ──────────────────────────────────────────────────────────────

  group('logStreak', () {
    DateTime daysAgo(int n) {
      final t = DateTime.now();
      return DateTime(t.year, t.month, t.day).subtract(Duration(days: n));
    }

    Future<MyBudgetController> bootWithSpendDays(List<int> agos) =>
        bootWith(categories: [
          BudgetCategory(
            id: 'c',
            name: 'C',
            budgetCents: 100000,
            transactions: [for (final n in agos) txnOn(daysAgo(n))],
          ),
        ]);

    test('0 with no transactions', () async {
      final c = await bootWithSpendDays([]);
      expect(c.logStreak, 0);
    });

    test('1 when only today has a spend', () async {
      final c = await bootWithSpendDays([0]);
      expect(c.logStreak, 1);
    });

    test('streak still alive when the last spend was yesterday', () async {
      final c = await bootWithSpendDays([1, 2, 3]);
      expect(c.logStreak, 3);
    });

    test('counts consecutive days ending today', () async {
      final c = await bootWithSpendDays([0, 1, 2, 3]);
      expect(c.logStreak, 4);
    });

    test('a gap resets the count to the recent run only', () async {
      // Spends today, yesterday, then a gap, then older days.
      final c = await bootWithSpendDays([0, 1, 3, 4, 5]);
      expect(c.logStreak, 2);
    });

    test('0 when the last spend was 2+ days ago', () async {
      final c = await bootWithSpendDays([2, 3, 4]);
      expect(c.logStreak, 0);
    });

    test('multiple spends on the same day count as one day', () async {
      final c = await bootWith(categories: [
        BudgetCategory(id: 'c', name: 'C', budgetCents: 100000, transactions: [
          txnOn(daysAgo(0), cents: 100),
          txnOn(daysAgo(0), cents: 200),
          txnOn(daysAgo(1), cents: 300),
        ]),
      ]);
      expect(c.logStreak, 2);
    });

    test('spends across categories merge into one day timeline', () async {
      final c = await bootWith(categories: [
        BudgetCategory(id: 'a', name: 'A', budgetCents: 100000,
            transactions: [txnOn(daysAgo(0))]),
        BudgetCategory(id: 'b', name: 'B', budgetCents: 100000,
            transactions: [txnOn(daysAgo(1))]),
      ]);
      expect(c.logStreak, 2);
    });
  });

  // ── statusLabel ────────────────────────────────────────────────────────────

  group('statusLabel', () {
    test('"Getting started" when there is no month or no budget set',
        () async {
      final c = await boot(); // nothing stored -> month is null
      expect(c.statusLabel, 'Getting started');

      final c2Store = FakeBudgetStore();
      await c2Store.saveMonth(BudgetMonth(
        year: now.year,
        month: now.month,
        categories: [BudgetCategory(id: 'z', name: 'Zero', budgetCents: 0)],
      ));
      Get.reset();
      Get.testMode = true;
      final c2 = Get.put(MyBudgetController(store: c2Store));
      while (!c2.isReady.value) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(c2.statusLabel, 'Getting started');
    });

    test('"On track" below 85% spent', () async {
      final c = await bootWith(categories: [
        BudgetCategory(id: 'c', name: 'C', budgetCents: 10000,
            transactions: [txnOn(now, cents: 8499)]),
      ]);
      expect(c.statusLabel, 'On track');
    });

    test('"Cutting it close" from 85% up to and including 100%', () async {
      final c = await bootWith(categories: [
        BudgetCategory(id: 'c', name: 'C', budgetCents: 10000,
            transactions: [txnOn(now, cents: 8500)]),
      ]);
      expect(c.statusLabel, 'Cutting it close');

      // Exactly at budget is still "close", not "over".
      await c.logSpend(categoryId: 'c', cents: 1500);
      expect(c.month.value!.totalSpentCents, 10000);
      expect(c.statusLabel, 'Cutting it close');
    });

    test('"Over budget" past 100%', () async {
      final c = await bootWith(categories: [
        BudgetCategory(id: 'c', name: 'C', budgetCents: 10000,
            transactions: [txnOn(now, cents: 10001)]),
      ]);
      expect(c.statusLabel, 'Over budget');
    });

    test('label reacts as spends are logged', () async {
      final c = await bootWith(categories: [
        BudgetCategory(id: 'c', name: 'C', budgetCents: 10000),
      ]);
      expect(c.statusLabel, 'On track');
      await c.logSpend(categoryId: 'c', cents: 9000);
      expect(c.statusLabel, 'Cutting it close');
      await c.logSpend(categoryId: 'c', cents: 2000);
      expect(c.statusLabel, 'Over budget');
    });
  });
}
