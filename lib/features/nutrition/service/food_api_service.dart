import 'dart:convert';

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
      // `nutriments` already carries fiber/sugar/sodium/salt — no extra field.
      'fields': 'code,product_name,brands,nutriments,serving_size',
    });

    try {
      final res = await http.get(uri).timeout(_timeout);
      if (res.statusCode != 200) return [];
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final products = (body['products'] as List? ?? []);
      final items = products
          .whereType<Map<String, dynamic>>()
          .map((p) => _fromOpenFoodFacts((p['code'] ?? '').toString(), p))
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

  // ── Parser ─────────────────────────────────────────────────────────────────
  FoodItem? _fromOpenFoodFacts(String code, Map<String, dynamic>? product) {
    if (product == null) return null;
    final name = (product['product_name'] ?? '').toString().trim();
    if (name.isEmpty) return null;
    final nut = (product['nutriments'] as Map<String, dynamic>? ?? {});
    final brand = (product['brands'] ?? '').toString().split(',').first.trim();
    final label = brand.isEmpty ? name : '$name · $brand';

    return FoodItem(
      id: code.isNotEmpty ? 'off_$code' : 'off_${name.hashCode}',
      name: _titleCase(label),
      servingSize: '100 g',
      calories: _num(nut['energy-kcal_100g'] ?? nut['energy-kcal']),
      protein: _num(nut['proteins_100g']),
      carbs: _num(nut['carbohydrates_100g']),
      fat: _num(nut['fat_100g']),
      source: 'openfoodfacts',
      // Detailed fields are auto-mapped when Open Food Facts reports them and
      // left null otherwise, so the user can fill them in by hand instead of
      // the food falsely claiming zero.
      fiberG: _optNum(nut['fiber_100g']),
      sugarG: _optNum(nut['sugars_100g']),
      sodiumMgValue: _sodiumMg(nut),
    );
  }

  /// Open Food Facts reports `sodium_100g` in **grams**; convert to mg. Many
  /// products only carry `salt_100g`, so fall back to the standard
  /// salt→sodium conversion (sodium = salt / 2.5).
  static double? _sodiumMg(Map<String, dynamic> nut) {
    final sodiumG = _optNum(nut['sodium_100g']);
    if (sodiumG != null) return sodiumG * 1000;
    final saltG = _optNum(nut['salt_100g']);
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
