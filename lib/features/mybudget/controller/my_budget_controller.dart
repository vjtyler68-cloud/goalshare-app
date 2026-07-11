import 'package:get/get.dart';

import '../data/budget_models.dart';
import '../data/budget_store.dart';

/// Local-first budget controller. All data lives on-device (Hive, JSON) so the
/// rich envelope model has no backend limits. Money is handled in integer cents
/// end-to-end for exact accuracy.
class MyBudgetController extends GetxController {
  final BudgetStore _store = BudgetStore();

  final RxBool isReady = false.obs;

  /// The currently viewed month (may be null if that month has no budget yet).
  final Rxn<BudgetMonth> month = Rxn<BudgetMonth>();

  /// Snapshot of the most recently reset/deleted month, kept so the user can
  /// undo an accidental "reset this month" before it becomes permanent.
  BudgetMonth? _lastDeletedMonth;

  /// First-of-month marker for the month being viewed.
  final Rx<DateTime> cursor = DateTime(DateTime.now().year, DateTime.now().month).obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    await _store.open();
    _loadCursorMonth();
    isReady.value = true;
  }

  void _loadCursorMonth() {
    final key = BudgetMonth.keyFor(cursor.value.year, cursor.value.month);
    month.value = _store.getMonth(key);
  }

  // ── month navigation ─────────────────────────────────────────────────────
  String get monthKey => BudgetMonth.keyFor(cursor.value.year, cursor.value.month);

  bool get hasBudget => month.value != null;

  bool get isCurrentRealMonth {
    final now = DateTime.now();
    return cursor.value.year == now.year && cursor.value.month == now.month;
  }

  void goToPrevMonth() {
    final c = cursor.value;
    cursor.value = DateTime(c.year, c.month - 1);
    _loadCursorMonth();
  }

  void goToNextMonth() {
    final c = cursor.value;
    cursor.value = DateTime(c.year, c.month + 1);
    _loadCursorMonth();
  }

  // ── creation ─────────────────────────────────────────────────────────────
  Future<void> createPreset() async {
    final m = BudgetMonth.preset(cursor.value.year, cursor.value.month);
    await _commit(m);
  }

  Future<void> createBlank() async {
    final m = BudgetMonth.blank(cursor.value.year, cursor.value.month);
    await _commit(m);
  }

  /// Start the viewed month by carrying the previous stored month's structure
  /// forward (budgets, goal targets, unpaid debt), with all spending cleared.
  /// Falls back to the preset when there is nothing to carry.
  Future<void> startFromPrevious() async {
    final prevKey = _store.previousKeyBefore(monthKey);
    final prev = prevKey == null ? null : _store.getMonth(prevKey);
    if (prev == null) {
      await createPreset();
      return;
    }
    await _commit(prev.carryForwardTo(cursor.value.year, cursor.value.month));
  }

  bool get canCarryForward => _store.previousKeyBefore(monthKey) != null;

  /// Wipe the entire viewed month (envelopes, goals, debts, income, logged
  /// spends). A snapshot is kept in memory so [undoDeleteMonth] can restore it.
  /// Returns true when the month existed and was removed.
  Future<bool> deleteMonth() async {
    final cur = month.value;
    if (cur == null) return false;
    _lastDeletedMonth = cur;
    final ok = await _store.deleteMonth(monthKey);
    if (ok) {
      month.value = null;
      month.refresh();
    } else {
      _lastDeletedMonth = null;
    }
    return ok;
  }

  bool get canUndoDelete => _lastDeletedMonth != null;

  /// Restore the month wiped by the most recent [deleteMonth].
  Future<bool> undoDeleteMonth() async {
    final snapshot = _lastDeletedMonth;
    if (snapshot == null) return false;
    _lastDeletedMonth = null;
    // Only restore if we're still viewing the month that was deleted.
    if (snapshot.key != monthKey) return false;
    await _commit(snapshot);
    return true;
  }

  Future<void> _commit(BudgetMonth m) async {
    month.value = m;
    month.refresh();
    await _store.saveMonth(m);
  }

  Future<void> _mutate(BudgetMonth Function(BudgetMonth m) f) async {
    final cur = month.value;
    if (cur == null) return;
    await _commit(f(cur));
  }

  // ── income ───────────────────────────────────────────────────────────────
  Future<void> addIncome(String name, int amountCents) => _mutate((m) =>
      m.copyWith(incomes: [
        ...m.incomes,
        BudgetIncome.create(name: name, amountCents: amountCents),
      ]));

  Future<void> updateIncome(String id, String name, int amountCents) =>
      _mutate((m) => m.copyWith(
            incomes: m.incomes
                .map((i) => i.id == id
                    ? i.copyWith(name: name, amountCents: amountCents)
                    : i)
                .toList(),
          ));

  Future<void> deleteIncome(String id) => _mutate(
      (m) => m.copyWith(incomes: m.incomes.where((i) => i.id != id).toList()));

  // ── categories ───────────────────────────────────────────────────────────
  Future<void> addCategory(BudgetCategory c) =>
      _mutate((m) => m.copyWith(categories: [...m.categories, c]));

  Future<void> updateCategoryMeta(
    String id, {
    String? name,
    String? iconKey,
    int? colorValue,
    bool? isWeekly,
    int? budgetCents,
    List<int>? weeklyBudgetsCents,
  }) =>
      _mutate((m) => m.copyWith(
            categories: m.categories
                .map((c) => c.id == id
                    ? c.copyWith(
                        name: name,
                        iconKey: iconKey,
                        colorValue: colorValue,
                        isWeekly: isWeekly,
                        budgetCents: budgetCents,
                        weeklyBudgetsCents: weeklyBudgetsCents,
                      )
                    : c)
                .toList(),
          ));

  Future<void> deleteCategory(String id) => _mutate((m) =>
      m.copyWith(categories: m.categories.where((c) => c.id != id).toList()));

  BudgetCategory? categoryById(String id) {
    final m = month.value;
    if (m == null) return null;
    for (final c in m.categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Log a spend against a category. Returns true if, after logging, the
  /// relevant envelope (the week for weekly categories, else the whole
  /// category) is still at or under budget — used to trigger a celebration.
  Future<bool> logSpend({
    required String categoryId,
    required int cents,
    String note = '',
    int week = -1,
  }) async {
    if (cents <= 0) return false;
    final cat = categoryById(categoryId);
    if (cat == null) return false;

    final resolvedWeek =
        cat.isWeekly ? (week >= 0 ? week : weekIndexForDate(DateTime.now())) : -1;
    final txn = BudgetTxn.create(
      amountCents: cents,
      note: note,
      weekIndex: resolvedWeek,
    );
    final updated = cat.copyWith(transactions: [...cat.transactions, txn]);

    await _mutate((m) => m.copyWith(
          categories:
              m.categories.map((c) => c.id == categoryId ? updated : c).toList(),
        ));

    if (cat.isWeekly) {
      return updated.spentForWeek(resolvedWeek) <=
          updated.budgetForWeek(resolvedWeek);
    }
    return !updated.isOver;
  }

  Future<void> deleteTxn(String categoryId, String txnId) => _mutate((m) =>
      m.copyWith(
        categories: m.categories.map((c) {
          if (c.id != categoryId) return c;
          return c.copyWith(
              transactions:
                  c.transactions.where((t) => t.id != txnId).toList());
        }).toList(),
      ));

  Future<void> updateTxn(
    String categoryId,
    String txnId, {
    int? cents,
    String? note,
    int? week,
  }) =>
      _mutate((m) => m.copyWith(
            categories: m.categories.map((c) {
              if (c.id != categoryId) return c;
              return c.copyWith(
                transactions: c.transactions
                    .map((t) => t.id == txnId
                        ? t.copyWith(
                            amountCents: cents, note: note, weekIndex: week)
                        : t)
                    .toList(),
              );
            }).toList(),
          ));

  // ── goals ────────────────────────────────────────────────────────────────
  Future<void> addGoal(BudgetGoal g) =>
      _mutate((m) => m.copyWith(goals: [...m.goals, g]));

  Future<void> updateGoalMeta(String id,
          {String? name, int? targetCents, int? colorValue, String? iconKey}) =>
      _mutate((m) => m.copyWith(
            goals: m.goals
                .map((g) => g.id == id
                    ? g.copyWith(
                        name: name,
                        targetCents: targetCents,
                        colorValue: colorValue,
                        iconKey: iconKey)
                    : g)
                .toList(),
          ));

  Future<void> deleteGoal(String id) =>
      _mutate((m) => m.copyWith(goals: m.goals.where((g) => g.id != id).toList()));

  Future<void> contributeToGoal(String goalId, int cents, {String note = ''}) {
    if (cents <= 0) return Future.value();
    return _mutate((m) => m.copyWith(
          goals: m.goals.map((g) {
            if (g.id != goalId) return g;
            return g.copyWith(contributions: [
              ...g.contributions,
              BudgetTxn.create(amountCents: cents, note: note),
            ]);
          }).toList(),
        ));
  }

  Future<void> deleteGoalTxn(String goalId, String txnId) => _mutate((m) =>
      m.copyWith(
        goals: m.goals.map((g) {
          if (g.id != goalId) return g;
          return g.copyWith(
              contributions:
                  g.contributions.where((t) => t.id != txnId).toList());
        }).toList(),
      ));

  // ── debts ────────────────────────────────────────────────────────────────
  Future<void> addDebt(BudgetDebt d) =>
      _mutate((m) => m.copyWith(debts: [...m.debts, d]));

  Future<void> updateDebtMeta(String id,
          {String? name, int? startingBalanceCents, int? colorValue}) =>
      _mutate((m) => m.copyWith(
            debts: m.debts
                .map((d) => d.id == id
                    ? d.copyWith(
                        name: name,
                        startingBalanceCents: startingBalanceCents,
                        colorValue: colorValue)
                    : d)
                .toList(),
          ));

  Future<void> deleteDebt(String id) =>
      _mutate((m) => m.copyWith(debts: m.debts.where((d) => d.id != id).toList()));

  Future<bool> payDebt(String debtId, int cents, {String note = ''}) async {
    if (cents <= 0) return false;
    bool paidOff = false;
    await _mutate((m) => m.copyWith(
          debts: m.debts.map((d) {
            if (d.id != debtId) return d;
            final updated = d.copyWith(
                payments: [...d.payments, BudgetTxn.create(amountCents: cents, note: note)]);
            paidOff = updated.isPaidOff;
            return updated;
          }).toList(),
        ));
    return paidOff;
  }

  Future<void> deleteDebtTxn(String debtId, String txnId) => _mutate((m) =>
      m.copyWith(
        debts: m.debts.map((d) {
          if (d.id != debtId) return d;
          return d.copyWith(
              payments: d.payments.where((t) => t.id != txnId).toList());
        }).toList(),
      ));

  // ── gamification ───────────────────────────────────────────────────────────
  List<DateTime> _spendDays() {
    final m = month.value;
    if (m == null) return <DateTime>[];
    final seen = <String>{};
    final days = <DateTime>[];
    for (final c in m.categories) {
      for (final t in c.transactions) {
        final d = DateTime(t.date.year, t.date.month, t.date.day);
        final k = '${d.year}-${d.month}-${d.day}';
        if (seen.add(k)) days.add(d);
      }
    }
    days.sort();
    return days;
  }

  /// Consecutive days (ending today/yesterday) with at least one logged spend.
  int get logStreak {
    final days = _spendDays();
    if (days.isEmpty) return 0;
    final today = DateTime.now();
    final t0 = DateTime(today.year, today.month, today.day);
    final last = days.last;
    if (t0.difference(last).inDays > 1) return 0;
    var streak = 1;
    for (var i = days.length - 1; i > 0; i--) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Overall month health label from spend vs. budget.
  String get statusLabel {
    final m = month.value;
    if (m == null || m.totalBudgetedCents <= 0) return 'Getting started';
    final r = m.spentProgress;
    if (r > 1.0) return 'Over budget';
    if (r >= 0.85) return 'Cutting it close';
    return 'On track';
  }
}
