import 'dart:io';

import 'package:health/health.dart';

/// PHASE-1 GATED Apple Health / HealthKit integration.
///
/// Flip [kHealthKitEnabled] to `true` ONLY after:
///   1. The HealthKit capability is enabled on the App ID in the Apple
///      Developer portal, and
///   2. The provisioning profile has been regenerated (so the signed build's
///      entitlements match), and
///   3. `ios/Runner/Runner.entitlements` declares `com.apple.developer.healthkit`.
///
/// While it is `false`, the app links HealthKit (Info.plist usage strings are
/// present so App Store upload validation passes) but NEVER calls it, so the
/// entitlements/signing that the Codemagic build depends on are unaffected.
const bool kHealthKitEnabled = false;

/// Thin wrapper around the `health` plugin. All calls no-op safely (returning
/// null/false) unless [isEnabled] — so callers never need to platform-check.
class HealthService {
  HealthService._();
  static final HealthService instance = HealthService._();

  final Health _health = Health();
  bool _configured = false;

  /// Only true on iOS AND once the feature has been switched on for real.
  bool get isEnabled => kHealthKitEnabled && Platform.isIOS;

  /// We only read active energy burned (the "move" calories an Apple Watch
  /// tracks). Kept minimal so the permission prompt stays focused.
  static const List<HealthDataType> _types = [
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Ask the user to grant read access. Returns false if denied or unavailable.
  Future<bool> requestPermissions() async {
    if (!isEnabled) return false;
    try {
      await _ensureConfigured();
      return await _health.requestAuthorization(
        _types,
        permissions: _types.map((_) => HealthDataAccess.READ).toList(),
      );
    } catch (_) {
      return false;
    }
  }

  /// Total active-energy calories burned since local midnight (Apple Watch +
  /// iPhone), or null if unavailable / not permitted.
  Future<double?> todayActiveCalories() async {
    if (!isEnabled) return null;
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      final points = await _health.getHealthDataFromTypes(
        types: _types,
        startTime: midnight,
        endTime: now,
      );
      final unique = _health.removeDuplicates(points);
      var total = 0.0;
      for (final p in unique) {
        final v = p.value;
        if (v is NumericHealthValue) {
          total += v.numericValue.toDouble();
        }
      }
      return total;
    } catch (_) {
      return null;
    }
  }
}
