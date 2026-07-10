import 'dart:convert';

/// ─────────────────────────────────────────────────────────────────────────
/// Local-first budget models.
///
/// Everything here is plain Dart + JSON (no Hive TypeAdapters / codegen) so it
/// mirrors the safe, proven Leads persistence pattern. All money is stored as
/// integer **cents** for exact, to-the-cent accuracy — never doubles.
/// Every `fromMap` is tolerant: a missing or malformed field falls back to a
/// safe default so one bad record can never crash the whole screen.
/// ─────────────────────────────────────────────────────────────────────────

/// Max sane amount guard: $1,000,000,000.00 in cents.
const int kMaxCents = 100000000000;

int _asCents(dynamic v) {
  if (v is int) return v.clamp(-kMaxCents, kMaxCents).toInt();
  if (v is double && v.isFinite) {
    return v.round().clamp(-kMaxCents, kMaxCents).toInt();
  }
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

int _asInt(dynamic v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is double && v.isFinite) return v.round();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

String _asStr(dynamic v, [String fallback = '']) => (v ?? fallback).toString();

DateTime _asDate(dynamic v) =>
    DateTime.tryParse((v ?? '').toString()) ?? DateTime.now();

/// Parse a user-typed dollar string ("1,234.56", "$40", "40.5") into cents.
/// Returns null for empty/invalid/negative/oversized input.
int? parseDollarsToCents(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return null;
  s = s.replaceAll(',', '').replaceAll(r'$', '').replaceAll(' ', '');
  if (s.isEmpty) return null;
  final d = double.tryParse(s);
  if (d == null || d.isNaN || d.isInfinite || d < 0) return null;
  final cents = (d * 100).round();
  if (cents > kMaxCents) return null;
  return cents;
}

String _newId([String prefix = 'b']) {
  final now = DateTime.now();
  return '${prefix}_${now.microsecondsSinceEpoch}';
}

/// Which week (0-3) of the month a date falls in (days 1-7,8-14,15-21,22+).
int weekIndexForDate(DateTime d) => ((d.day - 1) ~/ 7).clamp(0, 3).toInt();

// ── Transaction ────────────────────────────────────────────────────────────

/// A single logged spend / contribution / payment, to the cent.
class BudgetTxn {
  final String id;
  final int amountCents;
  final String note;
  final DateTime date;

  /// For weekly categories: 0-3. Otherwise -1.
  final int weekIndex;

  BudgetTxn({
    required this.id,
    required this.amountCents,
    this.note = '',
    required this.date,
    this.weekIndex = -1,
  });

  factory BudgetTxn.create({
    required int amountCents,
    String note = '',
    DateTime? date,
    int weekIndex = -1,
  }) {
    final d = date ?? DateTime.now();
    return BudgetTxn(
      id: _newId('txn'),
      amountCents: amountCents,
      note: note,
      date: d,
      weekIndex: weekIndex,
    );
  }

  BudgetTxn copyWith({int? amountCents, String? note, DateTime? date, int? weekIndex}) =>
      BudgetTxn(
        id: id,
        amountCents: amountCents ?? this.amountCents,
        note: note ?? this.note,
        date: date ?? this.date,
        weekIndex: weekIndex ?? this.weekIndex,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'amountCents': amountCents,
        'note': note,
        'date': date.toIso8601String(),
        'weekIndex': weekIndex,
      };

  factory BudgetTxn.fromMap(Map<dynamic, dynamic> m) => BudgetTxn(
        id: _asStr(m['id'], _newId('txn')),
        amountCents: _asCents(m['amountCents']),
        note: _asStr(m['note']),
        date: _asDate(m['date']),
        weekIndex: _asInt(m['weekIndex'], -1),
      );
}

int _sumTxns(Iterable<BudgetTxn> txns) {
  var t = 0;
  for (final x in txns) {
    t += x.amountCents;
  }
  return t;
}

List<BudgetTxn> _txnsFrom(dynamic list) {
  if (list is! List) return <BudgetTxn>[];
  final out = <BudgetTxn>[];
  for (final e in list) {
    if (e is Map) {
      try {
        out.add(BudgetTxn.fromMap(e));
      } catch (_) {}
    }
  }
  return out;
}

// ── Category (envelope) ──────────────────────────────────────────────────────

/// A spending envelope. Either a flat monthly budget (`isWeekly == false`) or a
/// 4-week envelope (`isWeekly == true`, one limit per week).
class BudgetCategory {
  final String id;
  final String name;
  final String iconKey;
  final int colorValue;

  /// 'bill' (fixed recurring) or 'spending' (variable).
  final String section;

  final bool isWeekly;

  /// Used when [isWeekly] is false.
  final int budgetCents;

  /// Length-4 list of weekly limits, used when [isWeekly] is true.
  final List<int> weeklyBudgetsCents;

  final List<BudgetTxn> transactions;

  BudgetCategory({
    required this.id,
    required this.name,
    this.iconKey = 'category',
    this.colorValue = 0xff64748B,
    this.section = 'spending',
    this.isWeekly = false,
    this.budgetCents = 0,
    List<int>? weeklyBudgetsCents,
    List<BudgetTxn>? transactions,
  })  : weeklyBudgetsCents =
            _normalizeWeekly(weeklyBudgetsCents),
        transactions = transactions ?? <BudgetTxn>[];

  static List<int> _normalizeWeekly(List<int>? w) {
    final base = List<int>.filled(4, 0);
    if (w != null) {
      for (var i = 0; i < 4 && i < w.length; i++) {
        base[i] = w[i];
      }
    }
    return base;
  }

  factory BudgetCategory.create({
    required String name,
    String iconKey = 'category',
    int colorValue = 0xff64748B,
    String section = 'spending',
    bool isWeekly = false,
    int budgetCents = 0,
    List<int>? weeklyBudgetsCents,
  }) =>
      BudgetCategory(
        id: _newId('cat'),
        name: name,
        iconKey: iconKey,
        colorValue: colorValue,
        section: section,
        isWeekly: isWeekly,
        budgetCents: budgetCents,
        weeklyBudgetsCents: weeklyBudgetsCents,
      );

  int get totalBudgetCents => isWeekly
      ? weeklyBudgetsCents.fold(0, (p, e) => p + e)
      : budgetCents;

  int get spentCents => _sumTxns(transactions);

  int spentForWeek(int week) =>
      _sumTxns(transactions.where((t) => t.weekIndex == week));

  int budgetForWeek(int week) =>
      (week >= 0 && week < 4) ? weeklyBudgetsCents[week] : 0;

  int get remainingCents => totalBudgetCents - spentCents;

  /// 0.0-1.0 fill ratio (can be clamped by callers for display).
  double get progress =>
      totalBudgetCents <= 0 ? 0.0 : spentCents / totalBudgetCents;

  bool get isOver => spentCents > totalBudgetCents;

  BudgetCategory copyWith({
    String? name,
    String? iconKey,
    int? colorValue,
    String? section,
    bool? isWeekly,
    int? budgetCents,
    List<int>? weeklyBudgetsCents,
    List<BudgetTxn>? transactions,
  }) =>
      BudgetCategory(
        id: id,
        name: name ?? this.name,
        iconKey: iconKey ?? this.iconKey,
        colorValue: colorValue ?? this.colorValue,
        section: section ?? this.section,
        isWeekly: isWeekly ?? this.isWeekly,
        budgetCents: budgetCents ?? this.budgetCents,
        weeklyBudgetsCents: weeklyBudgetsCents ?? this.weeklyBudgetsCents,
        transactions: transactions ?? this.transactions,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'iconKey': iconKey,
        'colorValue': colorValue,
        'section': section,
        'isWeekly': isWeekly,
        'budgetCents': budgetCents,
        'weeklyBudgetsCents': weeklyBudgetsCents,
        'transactions': transactions.map((t) => t.toMap()).toList(),
      };

  factory BudgetCategory.fromMap(Map<dynamic, dynamic> m) {
    final weekly = (m['weeklyBudgetsCents'] is List)
        ? (m['weeklyBudgetsCents'] as List).map((e) => _asCents(e)).toList()
        : <int>[];
    return BudgetCategory(
      id: _asStr(m['id'], _newId('cat')),
      name: _asStr(m['name'], 'Category'),
      iconKey: _asStr(m['iconKey'], 'category'),
      colorValue: _asInt(m['colorValue'], 0xff64748B),
      section: _asStr(m['section'], 'spending'),
      isWeekly: m['isWeekly'] == true,
      budgetCents: _asCents(m['budgetCents']),
      weeklyBudgetsCents: weekly,
      transactions: _txnsFrom(m['transactions']),
    );
  }
}

// ── Goal (savings / investing / crypto) ──────────────────────────────────────

class BudgetGoal {
  final String id;
  final String name;

  /// 'savings' | 'investing' | 'crypto'
  final String type;
  final int targetCents;
  final int colorValue;
  final String iconKey;
  final List<BudgetTxn> contributions;

  BudgetGoal({
    required this.id,
    required this.name,
    this.type = 'savings',
    this.targetCents = 0,
    this.colorValue = 0xff3B82F6,
    this.iconKey = 'savings',
    List<BudgetTxn>? contributions,
  }) : contributions = contributions ?? <BudgetTxn>[];

  factory BudgetGoal.create({
    required String name,
    String type = 'savings',
    int targetCents = 0,
    int colorValue = 0xff3B82F6,
    String iconKey = 'savings',
  }) =>
      BudgetGoal(
        id: _newId('goal'),
        name: name,
        type: type,
        targetCents: targetCents,
        colorValue: colorValue,
        iconKey: iconKey,
      );

  int get savedCents => _sumTxns(contributions);
  double get progress => targetCents <= 0 ? 0.0 : savedCents / targetCents;
  int get remainingCents => (targetCents - savedCents);

  BudgetGoal copyWith({
    String? name,
    String? type,
    int? targetCents,
    int? colorValue,
    String? iconKey,
    List<BudgetTxn>? contributions,
  }) =>
      BudgetGoal(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        targetCents: targetCents ?? this.targetCents,
        colorValue: colorValue ?? this.colorValue,
        iconKey: iconKey ?? this.iconKey,
        contributions: contributions ?? this.contributions,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'targetCents': targetCents,
        'colorValue': colorValue,
        'iconKey': iconKey,
        'contributions': contributions.map((t) => t.toMap()).toList(),
      };

  factory BudgetGoal.fromMap(Map<dynamic, dynamic> m) => BudgetGoal(
        id: _asStr(m['id'], _newId('goal')),
        name: _asStr(m['name'], 'Goal'),
        type: _asStr(m['type'], 'savings'),
        targetCents: _asCents(m['targetCents']),
        colorValue: _asInt(m['colorValue'], 0xff3B82F6),
        iconKey: _asStr(m['iconKey'], 'savings'),
        contributions: _txnsFrom(m['contributions']),
      );
}

// ── Debt ─────────────────────────────────────────────────────────────────────

class BudgetDebt {
  final String id;
  final String name;
  final int startingBalanceCents;
  final int colorValue;
  final String iconKey;
  final List<BudgetTxn> payments;

  BudgetDebt({
    required this.id,
    required this.name,
    this.startingBalanceCents = 0,
    this.colorValue = 0xffF97316,
    this.iconKey = 'debt',
    List<BudgetTxn>? payments,
  }) : payments = payments ?? <BudgetTxn>[];

  factory BudgetDebt.create({
    required String name,
    int startingBalanceCents = 0,
    int colorValue = 0xffF97316,
    String iconKey = 'debt',
  }) =>
      BudgetDebt(
        id: _newId('debt'),
        name: name,
        startingBalanceCents: startingBalanceCents,
        colorValue: colorValue,
        iconKey: iconKey,
      );

  int get paidCents => _sumTxns(payments);
  int get remainingCents {
    final r = startingBalanceCents - paidCents;
    return r < 0 ? 0 : r;
  }

  double get progress =>
      startingBalanceCents <= 0 ? 0.0 : (paidCents / startingBalanceCents);
  bool get isPaidOff => startingBalanceCents > 0 && paidCents >= startingBalanceCents;

  BudgetDebt copyWith({
    String? name,
    int? startingBalanceCents,
    int? colorValue,
    String? iconKey,
    List<BudgetTxn>? payments,
  }) =>
      BudgetDebt(
        id: id,
        name: name ?? this.name,
        startingBalanceCents: startingBalanceCents ?? this.startingBalanceCents,
        colorValue: colorValue ?? this.colorValue,
        iconKey: iconKey ?? this.iconKey,
        payments: payments ?? this.payments,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'startingBalanceCents': startingBalanceCents,
        'colorValue': colorValue,
        'iconKey': iconKey,
        'payments': payments.map((t) => t.toMap()).toList(),
      };

  factory BudgetDebt.fromMap(Map<dynamic, dynamic> m) => BudgetDebt(
        id: _asStr(m['id'], _newId('debt')),
        name: _asStr(m['name'], 'Debt'),
        startingBalanceCents: _asCents(m['startingBalanceCents']),
        colorValue: _asInt(m['colorValue'], 0xffF97316),
        iconKey: _asStr(m['iconKey'], 'debt'),
        payments: _txnsFrom(m['payments']),
      );
}

// ── Income ───────────────────────────────────────────────────────────────────

class BudgetIncome {
  final String id;
  final String name;
  final int amountCents;

  BudgetIncome({required this.id, required this.name, this.amountCents = 0});

  factory BudgetIncome.create({required String name, int amountCents = 0}) =>
      BudgetIncome(id: _newId('inc'), name: name, amountCents: amountCents);

  BudgetIncome copyWith({String? name, int? amountCents}) => BudgetIncome(
        id: id,
        name: name ?? this.name,
        amountCents: amountCents ?? this.amountCents,
      );

  Map<String, dynamic> toMap() =>
      {'id': id, 'name': name, 'amountCents': amountCents};

  factory BudgetIncome.fromMap(Map<dynamic, dynamic> m) => BudgetIncome(
        id: _asStr(m['id'], _newId('inc')),
        name: _asStr(m['name'], 'Income'),
        amountCents: _asCents(m['amountCents']),
      );
}

// ── Month ────────────────────────────────────────────────────────────────────

class BudgetMonth {
  final int year;
  final int month; // 1-12
  final List<BudgetIncome> incomes;
  final List<BudgetGoal> goals;
  final List<BudgetDebt> debts;
  final List<BudgetCategory> categories;

  BudgetMonth({
    required this.year,
    required this.month,
    List<BudgetIncome>? incomes,
    List<BudgetGoal>? goals,
    List<BudgetDebt>? debts,
    List<BudgetCategory>? categories,
  })  : incomes = incomes ?? <BudgetIncome>[],
        goals = goals ?? <BudgetGoal>[],
        debts = debts ?? <BudgetDebt>[],
        categories = categories ?? <BudgetCategory>[];

  String get key => keyFor(year, month);

  static String keyFor(int y, int m) =>
      '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}';

  // ── summary ────────────────────────────────────────────────────────────────
  int get totalIncomeCents => incomes.fold(0, (p, e) => p + e.amountCents);
  int get totalGoalContribCents => goals.fold(0, (p, e) => p + e.savedCents);
  int get totalDebtPaidCents => debts.fold(0, (p, e) => p + e.paidCents);
  int get totalAllocatedCents => totalGoalContribCents + totalDebtPaidCents;

  int get totalBudgetedCents =>
      categories.fold(0, (p, e) => p + e.totalBudgetCents);
  int get totalSpentCents => categories.fold(0, (p, e) => p + e.spentCents);

  /// Money still available: income minus what was moved to goals/debt minus
  /// what was actually spent.
  int get leftoverCents => totalIncomeCents - totalAllocatedCents - totalSpentCents;

  /// Planned outflow the user set up (envelopes + goal targets + debt balances
  /// aren't included; this is the envelope plan they must fund).
  int get totalPlannedCents => totalBudgetedCents;

  bool get isEmpty =>
      incomes.isEmpty && goals.isEmpty && debts.isEmpty && categories.isEmpty;

  double get spentProgress =>
      totalBudgetedCents <= 0 ? 0.0 : totalSpentCents / totalBudgetedCents;

  List<BudgetCategory> get bills =>
      categories.where((c) => c.section == 'bill').toList();
  List<BudgetCategory> get spending =>
      categories.where((c) => c.section != 'bill').toList();

  BudgetMonth copyWith({
    List<BudgetIncome>? incomes,
    List<BudgetGoal>? goals,
    List<BudgetDebt>? debts,
    List<BudgetCategory>? categories,
  }) =>
      BudgetMonth(
        year: year,
        month: month,
        incomes: incomes ?? this.incomes,
        goals: goals ?? this.goals,
        debts: debts ?? this.debts,
        categories: categories ?? this.categories,
      );

  /// Carry the *structure* into a new month: keep income sources, category
  /// budgets and goal targets, roll unpaid debt balances forward, but clear all
  /// logged transactions so the new month starts fresh.
  BudgetMonth carryForwardTo(int y, int m) => BudgetMonth(
        year: y,
        month: m,
        incomes: incomes.map((i) => i.copyWith()).toList(),
        goals: goals
            .map((g) => g.copyWith(contributions: <BudgetTxn>[]))
            .toList(),
        debts: debts
            .where((d) => d.remainingCents > 0)
            .map((d) => BudgetDebt.create(
                  name: d.name,
                  startingBalanceCents: d.remainingCents,
                  colorValue: d.colorValue,
                  iconKey: d.iconKey,
                ))
            .toList(),
        categories: categories
            .map((c) => c.copyWith(transactions: <BudgetTxn>[]))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'year': year,
        'month': month,
        'incomes': incomes.map((e) => e.toMap()).toList(),
        'goals': goals.map((e) => e.toMap()).toList(),
        'debts': debts.map((e) => e.toMap()).toList(),
        'categories': categories.map((e) => e.toMap()).toList(),
      };

  String toJsonString() => json.encode(toMap());

  factory BudgetMonth.fromMap(Map<dynamic, dynamic> m) {
    List<T> list<T>(dynamic raw, T Function(Map<dynamic, dynamic>) f) {
      if (raw is! List) return <T>[];
      final out = <T>[];
      for (final e in raw) {
        if (e is Map) {
          try {
            out.add(f(e));
          } catch (_) {}
        }
      }
      return out;
    }

    final now = DateTime.now();
    return BudgetMonth(
      year: _asInt(m['year'], now.year),
      month: _asInt(m['month'], now.month),
      incomes: list(m['incomes'], BudgetIncome.fromMap),
      goals: list(m['goals'], BudgetGoal.fromMap),
      debts: list(m['debts'], BudgetDebt.fromMap),
      categories: list(m['categories'], BudgetCategory.fromMap),
    );
  }

  factory BudgetMonth.fromJsonString(String s) =>
      BudgetMonth.fromMap(json.decode(s) as Map<dynamic, dynamic>);

  /// A blank month with no envelopes.
  factory BudgetMonth.blank(int y, int m) => BudgetMonth(year: y, month: m);

  /// The "everyone would love it" starter, modeled on the reference sheet.
  /// All amounts are sensible defaults the user edits to their real numbers.
  factory BudgetMonth.preset(int y, int m) {
    const c = _presetColors;
    return BudgetMonth(
      year: y,
      month: m,
      incomes: [
        BudgetIncome.create(name: 'Paycheck', amountCents: 0),
      ],
      goals: [
        BudgetGoal.create(
            name: 'Emergency Fund',
            type: 'savings',
            targetCents: 100000,
            colorValue: 0xff3B82F6,
            iconKey: 'savings'),
        BudgetGoal.create(
            name: 'Investing',
            type: 'investing',
            targetCents: 50000,
            colorValue: 0xff8B5CF6,
            iconKey: 'invest'),
        BudgetGoal.create(
            name: 'Crypto',
            type: 'crypto',
            targetCents: 25000,
            colorValue: 0xffF59E0B,
            iconKey: 'crypto'),
      ],
      debts: [
        BudgetDebt.create(
            name: 'Student Loan',
            startingBalanceCents: 2300000,
            colorValue: 0xffF97316,
            iconKey: 'debt'),
      ],
      categories: [
        // ── Fixed monthly bills ──
        BudgetCategory.create(
            name: 'Insurance',
            iconKey: 'insurance',
            colorValue: c[0],
            section: 'bill',
            budgetCents: 40000),
        BudgetCategory.create(
            name: 'Phone',
            iconKey: 'phone',
            colorValue: c[1],
            section: 'bill',
            budgetCents: 6500),
        BudgetCategory.create(
            name: 'Gym',
            iconKey: 'gym',
            colorValue: c[2],
            section: 'bill',
            budgetCents: 6000),
        BudgetCategory.create(
            name: 'Subscriptions',
            iconKey: 'subs',
            colorValue: c[3],
            section: 'bill',
            budgetCents: 10000),
        BudgetCategory.create(
            name: 'Donations',
            iconKey: 'donation',
            colorValue: c[4],
            section: 'bill',
            budgetCents: 10000),
        BudgetCategory.create(
            name: 'Gas',
            iconKey: 'gas',
            colorValue: c[5],
            section: 'bill',
            budgetCents: 40000),
        BudgetCategory.create(
            name: 'Dates',
            iconKey: 'dates',
            colorValue: c[6],
            section: 'bill',
            budgetCents: 10000),
        BudgetCategory.create(
            name: 'Travel',
            iconKey: 'travel',
            colorValue: c[7],
            section: 'bill',
            budgetCents: 30000),
        BudgetCategory.create(
            name: 'Medical / HBA',
            iconKey: 'medical',
            colorValue: c[8],
            section: 'bill',
            budgetCents: 12500),
        BudgetCategory.create(
            name: 'Car Care',
            iconKey: 'car',
            colorValue: c[9],
            section: 'bill',
            budgetCents: 10000),
        // ── Variable weekly envelopes ──
        BudgetCategory.create(
            name: 'Food',
            iconKey: 'food',
            colorValue: 0xff22C55E,
            section: 'spending',
            isWeekly: true,
            weeklyBudgetsCents: [12500, 12500, 12500, 12500]),
        BudgetCategory.create(
            name: 'Entertainment / Misc',
            iconKey: 'fun',
            colorValue: 0xffEC4899,
            section: 'spending',
            isWeekly: true,
            weeklyBudgetsCents: [12500, 12500, 12500, 12500]),
        BudgetCategory.create(
            name: 'Eating Out',
            iconKey: 'eatingout',
            colorValue: 0xff06B6D4,
            section: 'spending',
            budgetCents: 50000),
      ],
    );
  }
}

const List<int> _presetColors = [
  0xff3B82F6,
  0xff8B5CF6,
  0xff22C55E,
  0xffEC4899,
  0xffF59E0B,
  0xffEF4444,
  0xff14B8A6,
  0xff6366F1,
  0xff0EA5E9,
  0xffF97316,
];

/// Palette offered when the user creates a custom category/goal.
const List<int> kBudgetPalette = _presetColors;
