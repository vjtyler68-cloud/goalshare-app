import 'package:flutter_test/flutter_test.dart';
import 'package:spanx/features/nutrition/service/food_api_service.dart';

/// Locks in the fix for the scan bug: a scanned product must log per its real
/// serving, not a raw 100 g (which forced a manual "0.46" quantity).
void main() {
  test('uses the API per-serving values when present', () {
    final product = {
      'product_name': 'Potato Chips',
      'brands': 'Brand',
      'serving_size': '28 g',
      'serving_quantity': 28,
      'nutriments': {
        'energy-kcal_100g': 536,
        'proteins_100g': 7,
        'carbohydrates_100g': 53,
        'fat_100g': 33,
        'energy-kcal_serving': 150,
        'proteins_serving': 2,
        'carbohydrates_serving': 15,
        'fat_serving': 9,
      },
    };
    final f = FoodApiService.fromOpenFoodFacts('123', product)!;
    expect(f.servingSize, '28 g'); // the real serving, not "100 g"
    expect(f.calories, 150);
    expect(f.carbs, 15);
    expect(f.fat, 9);
  });

  test('scales the 100 g values down to the serving when only 100 g exists', () {
    final product = {
      'product_name': 'Greek Yogurt',
      'serving_quantity': 150,
      'nutriments': {
        'energy-kcal_100g': 100,
        'proteins_100g': 10,
        'carbohydrates_100g': 4,
        'fat_100g': 0,
      },
    };
    final f = FoodApiService.fromOpenFoodFacts('9', product)!;
    expect(f.servingSize, '150 g');
    expect(f.calories, closeTo(150, 0.001)); // 100 * 150/100
    expect(f.protein, closeTo(15, 0.001));
    expect(f.carbs, closeTo(6, 0.001));
  });

  test('keeps 100 g only when there is no serving info at all', () {
    final product = {
      'product_name': 'Bulk Flour',
      'nutriments': {'energy-kcal_100g': 364, 'proteins_100g': 10},
    };
    final f = FoodApiService.fromOpenFoodFacts('7', product)!;
    expect(f.servingSize, '100 g');
    expect(f.calories, 364);
  });

  test('sodium is per-serving when reported per-serving (grams to mg)', () {
    final product = {
      'product_name': 'Crackers',
      'serving_size': '30 g',
      'serving_quantity': 30,
      'nutriments': {
        'energy-kcal_serving': 130,
        'sodium_serving': 0.25, // grams -> 250 mg
      },
    };
    final f = FoodApiService.fromOpenFoodFacts('5', product)!;
    expect(f.servingSize, '30 g');
    expect(f.sodiumMg, closeTo(250, 0.001));
  });
}
