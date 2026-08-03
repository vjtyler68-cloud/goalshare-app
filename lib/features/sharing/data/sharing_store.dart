import 'dart:convert';
import 'dart:developer';

import 'package:hive_flutter/hive_flutter.dart';

/// Local mirror of who I've granted access to, per category. Empty = fully
/// private (the default). The backend enforces access; this is the fast local
/// copy the settings screen reads and writes. Shape: friendId → {nutrition,
/// workout}.
class SharingStore {
  static const String _box = 'sharing_grants_v1';
  static const String _key = 'grants';

  Box<String>? _b;
  bool _ready = false;
  bool get isReady => _ready;

  Future<void> open() async {
    try {
      await Hive.initFlutter(); // safe no-op if main() already did it
      _b = Hive.isBoxOpen(_box)
          ? Hive.box<String>(_box)
          : await Hive.openBox<String>(_box);
      _ready = true;
    } catch (e) {
      log('SharingStore: open failed — $e');
      _ready = false;
    }
  }

  Map<String, Map<String, bool>> load() {
    final raw = _b?.get(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final m = jsonDecode(raw) as Map;
      final out = <String, Map<String, bool>>{};
      m.forEach((k, v) {
        if (v is Map) {
          out[k.toString()] = {
            'nutrition': v['nutrition'] == true,
            'workout': v['workout'] == true,
          };
        }
      });
      return out;
    } catch (e) {
      log('SharingStore: load failed — $e');
      return {};
    }
  }

  Future<void> save(Map<String, Map<String, bool>> grants) async {
    if (!_ready || _b == null) return;
    try {
      await _b!.put(_key, jsonEncode(grants));
    } catch (e) {
      log('SharingStore: save failed — $e');
    }
  }
}
