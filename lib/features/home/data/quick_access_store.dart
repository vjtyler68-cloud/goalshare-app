import 'dart:convert';
import 'dart:developer';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'quick_access_config.dart';

/// On-device persistence for the home "Quick Access" grid layout.
///
/// Mirrors [BudgetStore]: a plain `Box<String>` holding JSON (no Hive adapters
/// / codegen), and a readiness flag so a storage failure degrades to an
/// in-memory-only layout instead of throwing.
///
/// This stores ONLY visibility + order. Hiding a card never touches that
/// feature's own box, so re-adding it brings all its data back untouched.
class QuickAccessStore {
  static const String _boxName = 'quick_access_v1';
  static const String _cardsKey = 'cards';

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
      log('QuickAccessStore: failed to open box — $e');
      _ready = false;
    }
  }

  /// Empty when nothing has been saved yet (first run) or on a read error —
  /// the controller then falls back to the registry defaults.
  List<QuickAccessCardConfig> load() {
    if (!_ready || _box == null) return <QuickAccessCardConfig>[];
    final raw = _box!.get(_cardsKey);
    if (raw == null || raw.isEmpty) return <QuickAccessCardConfig>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <QuickAccessCardConfig>[];
      final out = <QuickAccessCardConfig>[];
      for (final e in decoded) {
        if (e is! Map) continue;
        final cfg =
            QuickAccessCardConfig.fromJson(Map<String, dynamic>.from(e));
        if (cfg != null) out.add(cfg);
      }
      return out;
    } catch (e) {
      log('QuickAccessStore: unreadable layout — $e');
      return <QuickAccessCardConfig>[];
    }
  }

  Future<bool> save(List<QuickAccessCardConfig> cards) async {
    if (!_ready || _box == null) return false;
    try {
      await _box!.put(
        _cardsKey,
        jsonEncode(cards.map((c) => c.toJson()).toList()),
      );
      return true;
    } catch (e) {
      log('QuickAccessStore: save failed — $e');
      return false;
    }
  }
}
