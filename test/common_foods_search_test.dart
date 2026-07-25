import 'package:flutter_test/flutter_test.dart';
import 'package:spanx/features/nutrition/data/common_foods.dart';

void main() {
  test('database is substantial', () {
    expect(CommonFoods.count, greaterThan(200));
  });

  test('short queries return nothing (avoids noise)', () {
    expect(CommonFoods.search('a'), isEmpty);
    expect(CommonFoods.search(''), isEmpty);
  });

  test('common single-word searches surface the obvious staple first', () {
    expect(CommonFoods.search('egg').first.name, 'Egg, large');
    expect(CommonFoods.search('banana').first.name, 'Banana');
    expect(CommonFoods.search('apple').first.name, 'Apple');
    expect(CommonFoods.search('pizza').first.name.toLowerCase(), contains('pizza'));
  });

  test('plural / singular is forgiving', () {
    expect(CommonFoods.search('eggs').any((f) => f.name == 'Egg, large'), isTrue);
    expect(CommonFoods.search('bananas').any((f) => f.name == 'Banana'), isTrue);
    expect(CommonFoods.search('almonds').any((f) => f.name == 'Almonds'), isTrue);
  });

  test('multi-word searches require every word', () {
    final r = CommonFoods.search('chicken breast');
    expect(r.first.name, 'Chicken breast, cooked');
    expect(r.every((f) => f.name.toLowerCase().contains('chicken')), isTrue);
  });

  test('every returned food has real calories and a serving size', () {
    // Spot-check a spread of queries covers real data.
    for (final q in ['chicken', 'rice', 'milk', 'coffee', 'beef', 'yogurt']) {
      for (final f in CommonFoods.search(q)) {
        expect(f.calories, greaterThan(0), reason: '${f.name} has 0 cal');
        expect(f.servingSize.trim(), isNotEmpty, reason: '${f.name} has no serving');
      }
    }
  });
}
