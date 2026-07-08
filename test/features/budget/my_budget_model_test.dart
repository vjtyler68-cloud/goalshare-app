import 'package:flutter_test/flutter_test.dart';
import 'package:spanx/features/mybudget/model/my_budget_model.dart';

void main() {
  // ── MyBudgetModel.fromJson ────────────────────────────────────────────────

  group('MyBudgetModel.fromJson', () {
    final Map<String, dynamic> fullJson = {
      'id': 'budget-1',
      'targetAmount': 5000,
      'month': 7,
      'year': 2026,
      'totalIncome': 4000,
      'totalExpenseTarget': 3000,
      'totalSpent': 1500,
      'expensePercentage': 50,
      'incomeSources': [
        {'id': 'inc-1', 'name': 'Salary', 'amount': 4000},
      ],
      'expenseItems': [
        {
          'id': 'exp-1',
          'name': 'Rent',
          'totalAmount': 1500,
          'spentAmount': 1500
        },
      ],
    };

    test('parses all scalar fields correctly', () {
      final model = MyBudgetModel.fromJson(fullJson);
      expect(model.id, 'budget-1');
      expect(model.targetAmount, 5000);
      expect(model.month, 7);
      expect(model.year, 2026);
      expect(model.totalIncome, 4000);
      expect(model.totalExpenseTarget, 3000);
      expect(model.totalSpent, 1500);
      expect(model.expensePercentage, 50);
    });

    test('parses incomeSources list', () {
      final model = MyBudgetModel.fromJson(fullJson);
      expect(model.incomeSources, hasLength(1));
      final src = model.incomeSources!.first;
      expect(src.id, 'inc-1');
      expect(src.name, 'Salary');
      expect(src.amount, 4000);
    });

    test('parses expenseItems list', () {
      final model = MyBudgetModel.fromJson(fullJson);
      expect(model.expenseItems, hasLength(1));
      final item = model.expenseItems!.first;
      expect(item.id, 'exp-1');
      expect(item.name, 'Rent');
      expect(item.totalAmount, 1500);
      expect(item.spentAmount, 1500);
    });

    test('returns empty lists when incomeSources/expenseItems are null', () {
      final json = Map<String, dynamic>.from(fullJson);
      json['incomeSources'] = null;
      json['expenseItems'] = null;
      final model = MyBudgetModel.fromJson(json);
      expect(model.incomeSources, isEmpty);
      expect(model.expenseItems, isEmpty);
    });

    test('handles all-null optional fields gracefully', () {
      final model = MyBudgetModel.fromJson({});
      expect(model.id, isNull);
      expect(model.targetAmount, isNull);
      expect(model.totalSpent, isNull);
    });
  });

  // ── MyBudgetModel.toJson ──────────────────────────────────────────────────

  group('MyBudgetModel.toJson', () {
    test('round-trips through fromJson → toJson', () {
      final original = {
        'id': 'budget-2',
        'targetAmount': 2000,
        'month': 1,
        'year': 2025,
        'totalIncome': 1800,
        'totalExpenseTarget': 1200,
        'totalSpent': 600,
        'expensePercentage': 33,
        'incomeSources': [
          {'id': 'i1', 'name': 'Freelance', 'amount': 1800},
        ],
        'expenseItems': [
          {'id': 'e1', 'name': 'Food', 'totalAmount': 600, 'spentAmount': 400},
        ],
      };

      final model = MyBudgetModel.fromJson(original);
      final json = model.toJson();

      expect(json['id'], 'budget-2');
      expect(json['targetAmount'], 2000);
      expect(json['totalSpent'], 600);
      expect((json['incomeSources'] as List).length, 1);
      expect((json['expenseItems'] as List).length, 1);
    });

    test('serialises null lists as empty lists', () {
      final model = MyBudgetModel(id: 'x');
      final json = model.toJson();
      expect(json['incomeSources'], isEmpty);
      expect(json['expenseItems'], isEmpty);
    });
  });

  // ── IncomeSource ─────────────────────────────────────────────────────────

  group('IncomeSource', () {
    test('fromJson / toJson round-trip', () {
      final json = {'id': 'i1', 'name': 'Bonus', 'amount': 500};
      final src = IncomeSource.fromJson(json);
      expect(src.id, 'i1');
      expect(src.name, 'Bonus');
      expect(src.amount, 500);
      expect(src.toJson(), equals(json));
    });

    test('handles null fields', () {
      final src = IncomeSource.fromJson({});
      expect(src.id, isNull);
      expect(src.name, isNull);
      expect(src.amount, isNull);
    });
  });

  // ── ExpenseItem ──────────────────────────────────────────────────────────

  group('ExpenseItem', () {
    test('fromJson / toJson round-trip', () {
      final json = {
        'id': 'e1',
        'name': 'Utilities',
        'totalAmount': 200,
        'spentAmount': 150
      };
      final item = ExpenseItem.fromJson(json);
      expect(item.id, 'e1');
      expect(item.name, 'Utilities');
      expect(item.totalAmount, 200);
      expect(item.spentAmount, 150);
      expect(item.toJson(), equals(json));
    });

    test('handles null fields', () {
      final item = ExpenseItem.fromJson({});
      expect(item.id, isNull);
      expect(item.totalAmount, isNull);
      expect(item.spentAmount, isNull);
    });
  });
}
