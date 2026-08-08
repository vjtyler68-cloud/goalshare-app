import 'dart:developer';

import 'package:hive_flutter/hive_flutter.dart';

import 'goflow_models.dart';

/// On-device persistence for GoFlow: one typed box of daily [GoFlowEntry]s
/// (keyed by yyyy-MM-dd so re-logging a day overwrites) and a single-slot box
/// for [GoFlowSettings]. Local only — nothing here ever syncs to the cloud.
class GoFlowStore {
  static const String entriesBox = 'goflow_entries_v1';
  static const String settingsBox = 'goflow_settings_v1';
  static const String _settingsKey = 'settings';

  Box<GoFlowEntry>? _entries;
  Box<GoFlowSettings>? _settings;
  bool _ready = false;
  bool get isReady => _ready;

  /// Registers the hand-written adapters (guarded so a second call is a no-op)
  /// and opens both boxes.
  Future<void> open() async {
    try {
      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(21)) {
        Hive.registerAdapter(GoFlowEntryAdapter());
      }
      if (!Hive.isAdapterRegistered(22)) {
        Hive.registerAdapter(GoFlowSettingsAdapter());
      }
      _entries = Hive.isBoxOpen(entriesBox)
          ? Hive.box<GoFlowEntry>(entriesBox)
          : await Hive.openBox<GoFlowEntry>(entriesBox);
      _settings = Hive.isBoxOpen(settingsBox)
          ? Hive.box<GoFlowSettings>(settingsBox)
          : await Hive.openBox<GoFlowSettings>(settingsBox);
      _ready = true;
    } catch (e) {
      log('GoFlowStore: open failed — $e');
      _ready = false;
    }
  }

  List<GoFlowEntry> loadEntries() {
    if (!_ready || _entries == null) return const [];
    return _entries!.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  GoFlowEntry? entryFor(DateTime day) =>
      _entries?.get(GoFlowEntry.keyFor(day));

  Future<void> putEntry(GoFlowEntry e) async {
    if (!_ready || _entries == null) return;
    try {
      await _entries!.put(e.key, e);
    } catch (err) {
      log('GoFlowStore: putEntry failed — $err');
    }
  }

  Future<void> deleteEntry(DateTime day) async {
    if (!_ready || _entries == null) return;
    try {
      await _entries!.delete(GoFlowEntry.keyFor(day));
    } catch (err) {
      log('GoFlowStore: deleteEntry failed — $err');
    }
  }

  GoFlowSettings loadSettings() {
    if (!_ready || _settings == null) return const GoFlowSettings();
    return _settings!.get(_settingsKey) ?? const GoFlowSettings();
  }

  Future<void> saveSettings(GoFlowSettings s) async {
    if (!_ready || _settings == null) return;
    try {
      await _settings!.put(_settingsKey, s);
    } catch (err) {
      log('GoFlowStore: saveSettings failed — $err');
    }
  }
}
