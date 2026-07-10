import 'package:hive/hive.dart';

import 'food_item.dart';

part 'food_combo.g.dart';

/// A user-saved bundle of foods (e.g. "my usual smoothie" = banana +
/// protein powder + almond milk) that logs all its [items] in one tap.
@HiveType(typeId: 18)
class FoodCombo {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<FoodItem> items;

  @HiveField(3)
  final DateTime createdAt;

  const FoodCombo({
    required this.id,
    required this.name,
    required this.items,
    required this.createdAt,
  });

  /// Total calories across every item (each at one serving).
  double get calories => items.fold(0.0, (p, e) => p + e.calories);
}
