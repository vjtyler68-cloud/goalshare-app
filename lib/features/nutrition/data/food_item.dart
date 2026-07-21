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

  // ── Detailed nutrition (shown only in "Detailed" entry mode) ────────────────
  // Deliberately **nullable**: entries saved before these fields existed read
  // back as null, and a null stays null through a hive_generator re-run (a
  // non-nullable `double` would regenerate as `fields[8] as double` and throw
  // on every pre-existing entry). Read them through the zero-defaulted getters
  // below rather than touching the raw fields.
  @HiveField(8)
  final double? fiberG;

  @HiveField(9)
  final double? sugarG;

  /// Sodium in **milligrams** (every other macro on this class is grams).
  @HiveField(10)
  final double? sodiumMgValue;

  const FoodItem({
    required this.id,
    required this.name,
    required this.servingSize,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    required this.source,
    this.fiberG,
    this.sugarG,
    this.sodiumMgValue,
  });

  /// Zero-defaulted views of the detailed fields — safe on legacy entries.
  double get fiber => fiberG ?? 0;
  double get sugar => sugarG ?? 0;
  double get sodiumMg => sodiumMgValue ?? 0;

  /// True when any detailed field carries real data — used to decide whether a
  /// breakdown row is worth showing on a log/detail view.
  bool get hasDetailedNutrition => fiber > 0 || sugar > 0 || sodiumMg > 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'servingSize': servingSize,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'source': source,
        'fiber': fiberG,
        'sugar': sugarG,
        'sodiumMg': sodiumMgValue,
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
        fiberG: _optD(j['fiber']),
        sugarG: _optD(j['sugar']),
        sodiumMgValue: _optD(j['sodiumMg']),
      );

  static double _d(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;

  /// Like [_d] but preserves "not recorded" as null instead of collapsing to 0,
  /// so a cached food doesn't claim it has 0 g of fiber when it simply never
  /// carried a fiber value.
  static double? _optD(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }
}
