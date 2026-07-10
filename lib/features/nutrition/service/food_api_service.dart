import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../data/food_item.dart';

/// Free-tier nutrition lookups:
///   * Text search  -> USDA FoodData Central   (needs a free api key)
///   * Barcode/UPC  -> Open Food Facts         (no key required)
///
/// Results are cached in a Hive box (JSON) so repeat searches / scans are
/// instant and don't burn rate limits. No paid AI/vision services are used.
class FoodApiService {
  FoodApiService([this.cacheBox]);

  /// Cache of API responses (JSON strings), keyed by "search:<q>" / "barcode:<code>".
  Box<String>? cacheBox;

  /// USDA FoodData Central API key. `DEMO_KEY` works out of the box but is
  /// heavily rate-limited (a few requests/hour). Get a free key in seconds at
  /// https://fdc.nal.usda.gov/api-key-signup.html and drop it in here (or wire
  /// it through a --dart-define at build time).
  static const String usdaApiKey = 'DEMO_KEY';

  static const Duration _timeout = Duration(seconds: 12);

  // ── Text search (USDA) ─────────────────────────────────────────────────────
  Future<List<FoodItem>> searchFoods(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final cacheKey = 'search:${q.toLowerCase()}';
    final cached = _readListCache(cacheKey);
    if (cached != null) return cached;

    final uri = Uri.https('api.nal.usda.gov', '/fdc/v1/foods/search', {
      'api_key': usdaApiKey,
      'query': q,
      'pageSize': '25',
      'dataType': 'Foundation,SR Legacy,Branded',
    });

    try {
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final foods = (body['foods'] as List? ?? []);
      final items = foods
          .whereType<Map<String, dynamic>>()
          .map(_fromUsda)
          .where((f) => f != null)
          .cast<FoodItem>()
          .toList();
      _writeListCache(cacheKey, items);
      return items;
    } catch (_) {
      return [];
    }
  }

  // ── Barcode lookup (Open Food Facts) ───────────────────────────────────────
  Future<FoodItem?> lookupBarcode(String code) async {
    final c = code.trim();
    if (c.isEmpty) return null;

    final cacheKey = 'barcode:$c';
    final cachedRaw = cacheBox?.get(cacheKey);
    if (cachedRaw != null) {
      try {
        return FoodItem.fromJson(jsonDecode(cachedRaw) as Map<String, dynamic>);
      } catch (_) {/* fall through to network */}
    }

    final uri = Uri.https('world.openfoodfacts.org', '/api/v2/product/$c.json', {
      'fields': 'product_name,brands,nutriments,serving_size',
    });

    try {
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['status'] != 1 && body['product'] == null) return null;
      final item = _fromOpenFoodFacts(c, body['product'] as Map<String, dynamic>?);
      if (item != null) {
        cacheBox?.put(cacheKey, jsonEncode(item.toJson()));
      }
      return item;
    } catch (_) {
      return null;
    }
  }

  // ── Parsers ────────────────────────────────────────────────────────────────
  FoodItem? _fromUsda(Map<String, dynamic> j) {
    final name = (j['description'] ?? '').toString().trim();
    if (name.isEmpty) return null;
    final nutrients = (j['foodNutrients'] as List? ?? []);

    double byName(List<String> names) {
      for (final n in nutrients.whereType<Map<String, dynamic>>()) {
        final nn = (n['nutrientName'] ?? '').toString().toLowerCase();
        if (names.any((t) => nn.contains(t))) {
          return _num(n['value']);
        }
      }
      return 0;
    }

    final brand = (j['brandOwner'] ?? j['brandName'] ?? '').toString().trim();
    final label = brand.isEmpty ? name : '$name · $brand';
    return FoodItem(
      id: 'usda_${j['fdcId'] ?? name.hashCode}',
      name: _titleCase(label),
      // USDA foodNutrients in the search index are per 100 g.
      servingSize: '100 g',
      calories: byName(['energy']),
      protein: byName(['protein']),
      carbs: byName(['carbohydrate']),
      fat: byName(['total lipid', 'fat']),
      source: 'usda',
    );
  }

  FoodItem? _fromOpenFoodFacts(String code, Map<String, dynamic>? product) {
    if (product == null) return null;
    final name = (product['product_name'] ?? '').toString().trim();
    if (name.isEmpty) return null;
    final nut = (product['nutriments'] as Map<String, dynamic>? ?? {});
    final brand = (product['brands'] ?? '').toString().split(',').first.trim();
    final label = brand.isEmpty ? name : '$name · $brand';

    return FoodItem(
      id: 'off_$code',
      name: _titleCase(label),
      servingSize: '100 g',
      calories: _num(nut['energy-kcal_100g'] ?? nut['energy-kcal']),
      protein: _num(nut['proteins_100g']),
      carbs: _num(nut['carbohydrates_100g']),
      fat: _num(nut['fat_100g']),
      source: 'openfoodfacts',
    );
  }

  // ── Cache helpers ───────────────────────────────────────────────────────────
  List<FoodItem>? _readListCache(String key) {
    final raw = cacheBox?.get(key);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(FoodItem.fromJson)
          .toList();
    } catch (_) {
      return null;
    }
  }

  void _writeListCache(String key, List<FoodItem> items) {
    try {
      cacheBox?.put(key, jsonEncode(items.map((e) => e.toJson()).toList()));
    } catch (_) {/* cache write is best-effort */}
  }

  static double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;

  static String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s
        .split(' ')
        .map((w) => w.isEmpty
            ? w
            : (w.length == 1
                ? w.toUpperCase()
                : w[0].toUpperCase() + w.substring(1).toLowerCase()))
        .join(' ');
  }
}
