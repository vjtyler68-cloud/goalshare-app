import 'package:hive/hive.dart';
import 'food_item.dart';

part 'logged_entry.g.dart';

/// A food logged to a specific day + meal, with a serving [quantity]
/// multiplier applied to the underlying [foodItem]'s per-serving values.
@HiveType(typeId: 15)
class LoggedEntry {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  /// "breakfast" | "lunch" | "dinner" | "snacks" | "exercise"
  @HiveField(2)
  final String meal;

  @HiveField(3)
  final FoodItem foodItem;

  @HiveField(4)
  final double quantity;

  @HiveField(5)
  final DateTime loggedAt;

  const LoggedEntry({
    required this.id,
    required this.date,
    required this.meal,
    required this.foodItem,
    required this.quantity,
    required this.loggedAt,
  });

  double get calories => foodItem.calories * quantity;
  double get protein => foodItem.protein * quantity;
  double get carbs => foodItem.carbs * quantity;
  double get fat => foodItem.fat * quantity;

  // Detailed nutrition. Legacy entries report 0 rather than null.
  double get fiber => foodItem.fiber * quantity;
  double get sugar => foodItem.sugar * quantity;
  double get sodiumMg => foodItem.sodiumMg * quantity;

  LoggedEntry copyWith({
    String? meal,
    FoodItem? foodItem,
    double? quantity,
    DateTime? date,
  }) {
    return LoggedEntry(
      id: id,
      date: date ?? this.date,
      meal: meal ?? this.meal,
      foodItem: foodItem ?? this.foodItem,
      quantity: quantity ?? this.quantity,
      loggedAt: loggedAt,
    );
  }
}
