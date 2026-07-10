import 'package:flutter/material.dart';

/// Brand + budget UI tokens, shared across the budget screens and widgets.
class BudgetTheme {
  BudgetTheme._();

  static const red = Color(0xffE84040);
  static const redDk = Color(0xff9B1414);
  static const bg = Color(0xffF6F4F2);
  static const card = Color(0xffFFFFFF);
  static const text = Color(0xff1A1010);
  static const muted = Color(0xff9E9090);

  static const green = Color(0xff22C55E);
  static const greenDk = Color(0xff16A34A);
  static const amber = Color(0xffF59E0B);
  static const ink = Color(0xff0F172A);
  static const ink2 = Color(0xff1E293B);

  /// Traffic-light fill color for an envelope by its used ratio.
  static Color fillColor(double ratio) {
    if (ratio >= 1.0) return red;
    if (ratio >= 0.85) return amber;
    return green;
  }
}

/// Fixed, tree-shake-safe icon map (const IconData only).
const Map<String, IconData> _kBudgetIcons = {
  'wallet': Icons.account_balance_wallet_rounded,
  'food': Icons.restaurant_rounded,
  'fun': Icons.celebration_rounded,
  'eatingout': Icons.fastfood_rounded,
  'phone': Icons.smartphone_rounded,
  'gym': Icons.fitness_center_rounded,
  'gas': Icons.local_gas_station_rounded,
  'car': Icons.directions_car_rounded,
  'insurance': Icons.shield_rounded,
  'subs': Icons.subscriptions_rounded,
  'donation': Icons.volunteer_activism_rounded,
  'dates': Icons.favorite_rounded,
  'travel': Icons.flight_rounded,
  'medical': Icons.medical_services_rounded,
  'home': Icons.home_rounded,
  'shopping': Icons.shopping_bag_rounded,
  'coffee': Icons.local_cafe_rounded,
  'pet': Icons.pets_rounded,
  'kids': Icons.child_care_rounded,
  'savings': Icons.savings_rounded,
  'invest': Icons.trending_up_rounded,
  'crypto': Icons.currency_bitcoin_rounded,
  'debt': Icons.credit_card_rounded,
  'money': Icons.attach_money_rounded,
  'category': Icons.category_rounded,
};

IconData budgetIcon(String? key) =>
    _kBudgetIcons[key] ?? Icons.category_rounded;

/// Icon keys offered in the category picker UI.
const List<String> kBudgetIconKeys = [
  'food',
  'eatingout',
  'coffee',
  'fun',
  'shopping',
  'home',
  'phone',
  'gym',
  'gas',
  'car',
  'insurance',
  'subs',
  'donation',
  'dates',
  'travel',
  'medical',
  'pet',
  'kids',
  'money',
  'category',
];

/// Format integer cents as "$1,234.56" (drops cents when the amount is whole).
String fmtCents(int cents, {bool alwaysCents = false}) {
  final neg = cents < 0;
  final v = cents.abs();
  final dollars = v ~/ 100;
  final rem = v % 100;
  final ds = _thousands(dollars);
  final body = (!alwaysCents && rem == 0)
      ? ds
      : '$ds.${rem.toString().padLeft(2, '0')}';
  return '${neg ? '-' : ''}\$$body';
}

/// Compact form for large hero numbers: "$1.2k", "$3.4M".
String fmtCentsCompact(int cents) {
  final neg = cents < 0;
  final dollars = cents.abs() / 100.0;
  String out;
  if (dollars >= 1000000) {
    out = '${(dollars / 1000000).toStringAsFixed(dollars >= 10000000 ? 0 : 1)}M';
  } else if (dollars >= 10000) {
    out = '${(dollars / 1000).toStringAsFixed(dollars >= 100000 ? 0 : 1)}k';
  } else {
    return fmtCents(cents);
  }
  return '${neg ? '-' : ''}\$$out';
}

String _thousands(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  var count = 0;
  for (var i = s.length - 1; i >= 0; i--) {
    buf.write(s[i]);
    count++;
    if (count % 3 == 0 && i != 0) buf.write(',');
  }
  return buf.toString().split('').reversed.join();
}

const List<String> _kMonthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String monthName(int m) =>
    (m >= 1 && m <= 12) ? _kMonthNames[m - 1] : 'Month';
