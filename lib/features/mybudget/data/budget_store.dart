import 'dart:developer';

import 'package:hive_flutter/hive_flutter.dart';

import 'budget_models.dart';

/// On-device persistence for the budget, keyed by month ("YYYY-MM").
///
/// Follows the same readiness pattern as [LeadsController]: box opening is
/// wrapped so a storage failure degrades to an in-memory no-op instead of
/// throwing. Months are stored as JSON strings (no Hive adapters / codegen).
class BudgetStore {
  static const String _boxName = 'budget_v1';

  Box<String>? _box;
  bool _ready = false;
  bool get isReady => _ready;

  Future<void> open() async {
    try {
      // main() calls Hive.initFlutter(); calling again is a safe no-op.
      await Hive.initFlutter();
      _box = Hive.isBoxOpen(_boxName)
          ? Hive.box<String>(_boxName)
          : await Hive.openBox<String>(_boxName);
      _ready = true;
    } catch (e) {
      log('BudgetStore: failed to open box — $e');
      _ready = false;
    }
  }

  BudgetMonth? getMonth(String key) {
    if (!_ready || _box == null) return null;
    final raw = _box!.get(key);
    if (raw == null) return null;
    try {
      return BudgetMonth.fromJsonString(raw);
    } catch (e) {
      log('BudgetStore: unreadable month $key — $e');
      return null;
    }
  }

  Future<bool> saveMonth(BudgetMonth month) async {
    if (!_ready || _box == null) return false;
    try {
      await _box!.put(month.key, month.toJsonString());
      return true;
    } catch (e) {
      log('BudgetStore: save failed for ${month.key} — $e');
      return false;
    }
  }

  Future<bool> deleteMonth(String key) async {
    if (!_ready || _box == null) return false;
    try {
      await _box!.delete(key);
      return true;
    } catch (e) {
      log('BudgetStore: delete failed for $key — $e');
      return false;
    }
  }

  /// Sorted list of stored month keys, newest first.
  List<String> monthKeys() {
    if (!_ready || _box == null) return <String>[];
    final keys = _box!.keys.map((e) => e.toString()).toList();
    keys.sort((a, b) => b.compareTo(a));
    return keys;
  }

  /// Most recent stored month key strictly before [key], if any.
  String? previousKeyBefore(String key) {
    for (final k in monthKeys()) {
      if (k.compareTo(key) < 0) return k;
    }
    return null;
  }
}
