import 'dart:developer';

import 'package:hive_flutter/hive_flutter.dart';

import 'accountability_match.dart';
import 'accountability_profile.dart';

/// On-device persistence for Accountability Buddies.
///
/// Two `Box<String>` boxes of JSON (same graceful-degrade pattern as
/// [WorkoutStore]/[BudgetStore] — a storage hiccup degrades to an in-memory
/// no-op instead of throwing):
///  • `accountability_profiles_v1` — profiles, keyed by userId.
///  • `accountability_matches_v1`  — matches, keyed by match id.
class AccountabilityStore {
  static const String _profilesBox = 'accountability_profiles_v1';
  static const String _matchesBox = 'accountability_matches_v1';

  Box<String>? _profiles;
  Box<String>? _matches;
  bool _ready = false;
  bool get isReady => _ready;

  Future<void> open() async {
    try {
      await Hive.initFlutter(); // safe no-op if main() already did it
      _profiles = Hive.isBoxOpen(_profilesBox)
          ? Hive.box<String>(_profilesBox)
          : await Hive.openBox<String>(_profilesBox);
      _matches = Hive.isBoxOpen(_matchesBox)
          ? Hive.box<String>(_matchesBox)
          : await Hive.openBox<String>(_matchesBox);
      _ready = true;
    } catch (e) {
      log('AccountabilityStore: failed to open boxes — $e');
      _ready = false;
    }
  }

  // ── Profiles ────────────────────────────────────────────────────────────
  AccountabilityProfile? getProfile(String userId) {
    if (userId.isEmpty) return null;
    final raw = _profiles?.get(userId);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AccountabilityProfile.fromJsonString(raw);
    } catch (e) {
      log('AccountabilityStore: profile corrupt — $e');
      return null;
    }
  }

  Future<void> saveProfile(AccountabilityProfile p) async {
    if (!_ready || _profiles == null || p.userId.isEmpty) return;
    try {
      await _profiles!.put(p.userId, p.toJsonString());
    } catch (e) {
      log('AccountabilityStore: saveProfile failed — $e');
    }
  }

  // ── Matches ─────────────────────────────────────────────────────────────
  AccountabilityMatch? getMatch(String id) {
    if (id.isEmpty) return null;
    final raw = _matches?.get(id);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AccountabilityMatch.fromJsonString(raw);
    } catch (e) {
      log('AccountabilityStore: match corrupt — $e');
      return null;
    }
  }

  Future<void> saveMatch(AccountabilityMatch m) async {
    if (!_ready || _matches == null || m.id.isEmpty) return;
    try {
      await _matches!.put(m.id, m.toJsonString());
    } catch (e) {
      log('AccountabilityStore: saveMatch failed — $e');
    }
  }

  Future<void> deleteMatch(String id) async {
    if (!_ready || _matches == null) return;
    try {
      await _matches!.delete(id);
    } catch (_) {}
  }

  /// All matches this user has ever been part of, newest cycle first.
  List<AccountabilityMatch> matchesFor(String userId) {
    if (!_ready || _matches == null || userId.isEmpty) {
      return <AccountabilityMatch>[];
    }
    final out = <AccountabilityMatch>[];
    for (final raw in _matches!.values) {
      try {
        final m = AccountabilityMatch.fromJsonString(raw);
        if (m.involves(userId)) out.add(m);
      } catch (e) {
        log('AccountabilityStore: unreadable match — $e');
      }
    }
    out.sort((a, b) => b.weekStartDate.compareTo(a.weekStartDate));
    return out;
  }
}
