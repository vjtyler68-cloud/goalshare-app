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

  // ── Cloud backup (JSON) ─────────────────────────────────────────────────────
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': items.map((e) => e.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory FoodCombo.fromJson(Map<String, dynamic> j) => FoodCombo(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        items: ((j['items'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => FoodItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        createdAt:
            DateTime.tryParse('${j['createdAt'] ?? ''}') ?? DateTime.now(),
      );
}
