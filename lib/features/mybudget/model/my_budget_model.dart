

class MyBudgetModel {
  final String? id;
  final int? targetAmount;
  final int? month;
  final int? year;
  final List<IncomeSource>? incomeSources;
  final List<ExpenseItem>? expenseItems;
  final int? totalIncome;
  final int? totalExpenseTarget;
  final int? totalSpent;
  final int? expensePercentage;

  MyBudgetModel({
    this.id,
    this.targetAmount,
    this.month,
    this.year,
    this.incomeSources,
    this.expenseItems,
    this.totalIncome,
    this.totalExpenseTarget,
    this.totalSpent,
    this.expensePercentage,
  });

  factory MyBudgetModel.fromJson(Map<String, dynamic> json) => MyBudgetModel(
    id: json["id"],
    targetAmount: json["targetAmount"],
    month: json["month"],
    year: json["year"],
    incomeSources: json["incomeSources"] == null ? [] : List<IncomeSource>.from(json["incomeSources"]!.map((x) => IncomeSource.fromJson(x))),
    expenseItems: json["expenseItems"] == null ? [] : List<ExpenseItem>.from(json["expenseItems"]!.map((x) => ExpenseItem.fromJson(x))),
    totalIncome: json["totalIncome"],
    totalExpenseTarget: json["totalExpenseTarget"],
    totalSpent: json["totalSpent"],
    expensePercentage: json["expensePercentage"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "targetAmount": targetAmount,
    "month": month,
    "year": year,
    "incomeSources": incomeSources == null ? [] : List<dynamic>.from(incomeSources!.map((x) => x.toJson())),
    "expenseItems": expenseItems == null ? [] : List<dynamic>.from(expenseItems!.map((x) => x.toJson())),
    "totalIncome": totalIncome,
    "totalExpenseTarget": totalExpenseTarget,
    "totalSpent": totalSpent,
    "expensePercentage": expensePercentage,
  };
}

class ExpenseItem {
  final String? id;
  final String? name;
  final int? totalAmount;
  final int? spentAmount;

  ExpenseItem({
    this.id,
    this.name,
    this.totalAmount,
    this.spentAmount,
  });

  factory ExpenseItem.fromJson(Map<String, dynamic> json) => ExpenseItem(
    id: json["id"],
    name: json["name"],
    totalAmount: json["totalAmount"],
    spentAmount: json["spentAmount"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "totalAmount": totalAmount,
    "spentAmount": spentAmount,
  };
}

class IncomeSource {
  final String? id;
  final String? name;
  final int? amount;

  IncomeSource({
    this.id,
    this.name,
    this.amount,
  });

  factory IncomeSource.fromJson(Map<String, dynamic> json) => IncomeSource(
    id: json["id"],
    name: json["name"],
    amount: json["amount"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "amount": amount,
  };
}
