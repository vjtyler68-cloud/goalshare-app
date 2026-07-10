import 'package:hive/hive.dart';

part 'food_item.g.dart';

/// A single food and its nutrition, expressed **per one serving**
/// ([servingSize] describes what one serving is, e.g. "100 g" or "1 cup").
@HiveType(typeId: 14)
class FoodItem {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String servingSize;

  @HiveField(3)
  final double calories;

  @HiveField(4)
  final double protein;

  @HiveField(5)
  final double carbs;

  @HiveField(6)
  final double fat;

  /// "usda" | "openfoodfacts" | "manual"
  @HiveField(7)
  final String source;

  const FoodItem({
    required this.id,
    required this.name,
    required this.servingSize,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'servingSize': servingSize,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'source': source,
      };

  factory FoodItem.fromJson(Map<String, dynamic> j) => FoodItem(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        servingSize: (j['servingSize'] ?? '1 serving').toString(),
        calories: _d(j['calories']),
        protein: _d(j['protein']),
        carbs: _d(j['carbs']),
        fat: _d(j['fat']),
        source: (j['source'] ?? 'manual').toString(),
      );

  static double _d(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;
}
