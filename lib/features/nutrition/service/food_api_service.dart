import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../data/food_item.dart';

/// Optional free key for the USDA FoodData Central API — the best free food
/// database there is (~2 million foods: accurate generic/whole foods AND
/// 250k+ branded products, far better than Open Food Facts for everyday foods).
///
/// It's free and takes ~1 minute: sign up at
/// https://fdc.nal.usda.gov/api-key-signup.html and paste the emailed key here.
///
/// When this is empty the app quietly uses the bundled offline foods
/// (see `CommonFoods`) + Open Food Facts, so search works with no key at all.
/// When set, USDA becomes the primary online source with Open Food Facts as a
/// fallback. Nothing else needs to change.
const String kUsdaApiKey = '';

/// Free nutrition lookups — no API key required out of the box:
///   * Text search  -> USDA FoodData Central (if [kUsdaApiKey] is set),
///                     otherwise Open Food Facts
///   * Barcode/UPC  -> Open Food Facts product
///
/// Results are cached in a Hive box (JSON) so repeat searches / scans are
/// instant and don't burn rate limits. No paid AI/vision services are used.
class FoodApiService {
  FoodApiService([this.cacheBox]);

  /// Cache of API responses (JSON strings), keyed by "search:<q>" / "barcode:<code>".
  Box<String>? cacheBox;

  static const Duration _timeout = Duration(seconds: 12);

  // ── Text search (dispatcher) ────────────────────────────────────────────────
  /// Uses USDA FoodData Central when a key is configured (far richer results),
  /// and always falls back to Open Food Facts so search never comes up empty.
  Future<List<FoodItem>> searchFoods(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    if (kUsdaApiKey.isNotEmpty) {
      final usda = await _searchUsda(q);
      if (usda.isNotEmpty) return usda;
    }
    return _searchOpenFoodFacts(q);
  }

  // ── Text search (Open Food Facts — no API key required) ─────────────────────
  Future<List<FoodItem>> _searchOpenFoodFacts(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final cacheKey = 'search:${q.toLowerCase()}';
    final cached = _readListCache(cacheKey);
    if (cached != null) return cached;

    final uri = Uri.https('world.openfoodfacts.org', '/cgi/search.pl', {
      'search_terms': q,
      'search_simple': '1',
      'action': 'process',
      'json': '1',
      'page_size': '25',
      // `nutriments` already carries fiber/sugar/sodium/salt. `serving_quantity`
      // (+ `serving_size`) lets us log the product's real serving, not 100 g.
      'fields': 'code,product_name,brands,nutriments,serving_size,serving_quantity',
    });

    try {
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final products = (body['products'] as List? ?? []);
      final items = products
          .whereType<Map<String, dynamic>>()
          .map((p) => fromOpenFoodFacts((p['code'] ?? '').toString(), p))
          .where((f) => f != null && f.calories > 0)
          .cast<FoodItem>()
          .toList();
      _writeListCache(cacheKey, items);
      return items;
    } catch (_) {
      return [];
    }
  }

  // ── Text search (USDA FoodData Central — needs the free [kUsdaApiKey]) ──────
  Future<List<FoodItem>> _searchUsda(String query) async {
    final q = query.trim();
    if (q.isEmpty || kUsdaApiKey.isEmpty) return [];

    final cacheKey = 'usda:${q.toLowerCase()}';
    final cached = _readListCache(cacheKey);
    if (cached != null) return cached;

    final uri = Uri.https('api.nal.usda.gov', '/fdc/v1/foods/search', {
      'api_key': kUsdaApiKey,
      'query': q,
      'pageSize': '25',
      // Whole/generic foods first, then survey (prepared) foods, then branded.
      'dataType': 'Foundation,SR Legacy,Survey (FNDDS),Branded',
    });

    try {
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final foods = (body['foods'] as List? ?? []);
      final items = foods
          .whereType<Map<String, dynamic>>()
          .map(_fromUsda)
          .where((f) => f != null && f.calories > 0)
          .cast<FoodItem>()
          .toList();
      _writeListCache(cacheKey, items);
      return items;
    } catch (_) {
      return [];
    }
  }

  /// Parse one USDA FoodData Central search hit. Nutrients are per 100 g for
  /// Foundation/SR foods; we keep the "100 g" serving to match the OFF path so
  /// the quantity adjuster behaves the same for every online result.
  FoodItem? _fromUsda(Map<String, dynamic> product) {
    final name = (product['description'] ?? '').toString().trim();
    if (name.isEmpty) return null;
    final brand =
        (product['brandName'] ?? product['brandOwner'] ?? '').toString().trim();
    final label = brand.isEmpty ? name : '$name · $brand';

    final nutrients = (product['foodNutrients'] as List? ?? []);
    double? byId(int id) {
      for (final n in nutrients) {
        if (n is! Map) continue;
        final nid = n['nutrientId'] ?? (n['nutrient'] is Map ? n['nutrient']['id'] : null);
        if (nid == id) return _optNum(n['value'] ?? n['amount']);
      }
      return null;
    }

    final kcal = byId(1008) ?? byId(2048) ?? byId(2047) ?? 0;
    if (kcal == 0) return null;

    return FoodItem(
      id: 'usda_${product['fdcId'] ?? name.hashCode}',
      name: _titleCase(label),
      servingSize: '100 g',
      calories: kcal,
      protein: byId(1003) ?? 0,
      carbs: byId(1005) ?? 0,
      fat: byId(1004) ?? 0,
      source: 'usda',
      fiberG: byId(1079),
      sugarG: byId(2000) ?? byId(1063),
      sodiumMgValue: byId(1093),
    );
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
      'fields': 'product_name,brands,nutriments,serving_size,serving_quantity',
    });

    try {
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['status'] != 1 && body['product'] == null) return null;
      final item = fromOpenFoodFacts(c, body['product'] as Map<String, dynamic>?);
      if (item != null) {
        cacheBox?.put(cacheKey, jsonEncode(item.toJson()));
      }
      return item;
    } catch (_) {
      return null;
    }
  }

  // ── Parser ─────────────────────────────────────────────────────────────────
  /// Builds a food from an Open Food Facts product, expressed **per the
  /// product's real serving** (e.g. one 46 g bag) rather than a raw 100 g — so
  /// a scan defaults to the actual amount, with no manual "0.46" fudging. When
  /// the API gives no per-serving values it scales the 100 g values down to the
  /// serving size; only when there's no serving info at all does it keep 100 g.
  @visibleForTesting
  /// Calories for a basis ('serving' | '100g'), tolerant of the many ways Open
  /// Food Facts reports energy. Falls back to kJ→kcal (÷4.184) when only the
  /// kilojoule field exists — otherwise those (very common, esp. non-US)
  /// products scan as a wrong 0 calories.
  static double? _kcal(Map nut, String suffix) {
    final kcal = _optNum(nut['energy-kcal_$suffix']) ??
        (suffix == '100g' ? _optNum(nut['energy-kcal']) : null);
    if (kcal != null && kcal > 0) return kcal;
    final kj = _optNum(nut['energy-kj_$suffix']) ??
        _optNum(nut['energy_$suffix']) ??
        (suffix == '100g' ? _optNum(nut['energy']) : null);
    if (kj != null && kj > 0) return kj / 4.184;
    return null;
  }

  static FoodItem? fromOpenFoodFacts(String code, Map<String, dynamic>? product) {
    if (product == null) return null;
    final name = (product['product_name'] ?? '').toString().trim();
    if (name.isEmpty) return null;
    final nut = (product['nutriments'] as Map<String, dynamic>? ?? {});
    final brand = (product['brands'] ?? '').toString().split(',').first.trim();
    final label = brand.isEmpty ? name : '$name · $brand';

    final servingLabel = (product['serving_size'] ?? '').toString().trim();
    final servingQty = _optNum(product['serving_quantity']); // grams per serving

    double calories, protein, carbs, fat;
    double? fiber, sugar, sodium;
    String serving;

    final kcalServing = _kcal(nut, 'serving');
    final kcal100 = _kcal(nut, '100g');

    if (kcalServing != null && kcalServing > 0) {
      // The API reported the label's per-serving ENERGY. Use the per-serving
      // macros when present, but BACK-FILL any macro the API left off the
      // serving from its per-100 g value scaled to this serving — otherwise a
      // product with per-serving calories but only per-100 g macros logs
      // calories with 0 protein/carbs/fat (the "macros don't match" bug).
      // The scale factor comes from the real serving grams, or is inferred from
      // the serving/100 g energy ratio when grams aren't given.
      final sf = (servingQty != null && servingQty > 0)
          ? servingQty / 100.0
          : (kcal100 != null && kcal100 > 0 ? kcalServing / kcal100 : null);
      double perServ(String key) {
        final s = _optNum(nut['${key}_serving']);
        if (s != null) return s;
        if (sf != null) return (_optNum(nut['${key}_100g']) ?? 0) * sf;
        return 0;
      }

      serving = servingLabel.isNotEmpty
          ? servingLabel
          : (servingQty != null ? _gramsLabel(servingQty) : '1 serving');
      calories = kcalServing;
      protein = perServ('proteins');
      carbs = perServ('carbohydrates');
      fat = perServ('fat');
      fiber = _optNum(nut['fiber_serving']) ??
          (sf != null ? _scale(_optNum(nut['fiber_100g']), sf) : null);
      sugar = _optNum(nut['sugars_serving']) ??
          (sf != null ? _scale(_optNum(nut['sugars_100g']), sf) : null);
      sodium = _sodiumMg(nut, suffix: 'serving') ??
          (sf != null ? _scale(_sodiumMg(nut), sf) : null);
    } else if (servingQty != null && servingQty > 0 && kcal100 != null && kcal100 > 0) {
      // Only per-100 g values exist — scale them down to the real serving.
      final f = servingQty / 100.0;
      serving = servingLabel.isNotEmpty ? servingLabel : _gramsLabel(servingQty);
      calories = kcal100 * f;
      protein = (_optNum(nut['proteins_100g']) ?? 0) * f;
      carbs = (_optNum(nut['carbohydrates_100g']) ?? 0) * f;
      fat = (_optNum(nut['fat_100g']) ?? 0) * f;
      fiber = _scale(_optNum(nut['fiber_100g']), f);
      sugar = _scale(_optNum(nut['sugars_100g']), f);
      sodium = _scale(_sodiumMg(nut), f);
    } else {
      // No serving info at all — keep the 100 g basis (previous behavior).
      serving = '100 g';
      calories = _kcal(nut, '100g') ?? 0;
      protein = _num(nut['proteins_100g']);
      carbs = _num(nut['carbohydrates_100g']);
      fat = _num(nut['fat_100g']);
      fiber = _optNum(nut['fiber_100g']);
      sugar = _optNum(nut['sugars_100g']);
      sodium = _sodiumMg(nut);
    }

    return FoodItem(
      id: code.isNotEmpty ? 'off_$code' : 'off_${name.hashCode}',
      name: _titleCase(label),
      servingSize: serving,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      source: 'openfoodfacts',
      // Detailed fields are auto-mapped when Open Food Facts reports them and
      // left null otherwise, so the user can fill them in by hand instead of
      // the food falsely claiming zero.
      fiberG: fiber,
      sugarG: sugar,
      sodiumMgValue: sodium,
    );
  }

  /// A tidy grams label like "46 g" (drops a trailing ".0").
  static String _gramsLabel(double g) {
    final s = g == g.roundToDouble() ? g.toInt().toString() : g.toStringAsFixed(1);
    return '$s g';
  }

  static double? _scale(double? v, double f) => v == null ? null : v * f;

  /// Open Food Facts reports sodium in **grams**; convert to mg. Many products
  /// only carry salt, so fall back to the standard salt→sodium (÷2.5). [suffix]
  /// selects the per-serving (`serving`) or per-100 g (`100g`) variant.
  static double? _sodiumMg(Map<String, dynamic> nut, {String suffix = '100g'}) {
    final sodiumG = _optNum(nut['sodium_$suffix']);
    if (sodiumG != null) return sodiumG * 1000;
    final saltG = _optNum(nut['salt_$suffix']);
    if (saltG != null) return saltG / 2.5 * 1000;
    return null;
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

  /// Like [_num] but keeps "the API didn't report this" as null.
  static double? _optNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  }

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
