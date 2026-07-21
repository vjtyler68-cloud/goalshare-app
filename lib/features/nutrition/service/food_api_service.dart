import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../data/food_item.dart';

/// Free nutrition lookups — no API key required for either path:
///   * Text search  -> Open Food Facts search
///   * Barcode/UPC  -> Open Food Facts product
///
/// Results are cached in a Hive box (JSON) so repeat searches / scans are
/// instant and don't burn rate limits. No paid AI/vision services are used.
class FoodApiService {
  FoodApiService([this.cacheBox]);

  /// Cache of API responses (JSON strings), keyed by "search:<q>" / "barcode:<code>".
  Box<String>? cacheBox;

  static const Duration _timeout = Duration(seconds: 12);

  // ── Text search (Open Food Facts — no API key required) ─────────────────────
  Future<List<FoodItem>> searchFoods(String query) async {
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
