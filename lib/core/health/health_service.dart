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

/// Result of a single Apple Health read for today.
class HealthSyncResult {
  final double calories;
  final int steps;
  const HealthSyncResult({required this.calories, required this.steps});
}

/// Thin wrapper around the `health` plugin. All calls no-op safely (returning
/// null/false) unless [isEnabled] — so callers never need to platform-check.
///
/// Data flows from **both the iPhone and the Apple Watch**: HealthKit merges
/// them. `ACTIVE_ENERGY_BURNED` is the calorie source (Watch contributes most);
/// `STEPS` is read too because an iPhone-only user (no Watch) tracks steps
/// natively but has few/no active-energy samples — so we estimate calories from
/// steps as a fallback.
class HealthService {
  HealthService._();
  static final HealthService instance = HealthService._();

  final Health _health = Health();
  bool _configured = false;

  /// Only true on iOS AND once the feature has been switched on for real.
  bool get isEnabled => kHealthKitEnabled && Platform.isIOS;

  /// Rough calories burned per step for an average adult. Only used to estimate
  /// calories for iPhone-only users who have step data but no Watch-measured
  /// active energy, so it never double-counts real active-energy samples.
  static const double _kCalPerStep = 0.04;

  static const List<HealthDataType> _types = [
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.STEPS,
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

  /// Read today's activity (iPhone + Apple Watch) since local midnight.
  /// Returns null if unavailable / not permitted.
  Future<HealthSyncResult?> readToday() async {
    if (!isEnabled) return null;
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      // Active energy — Apple Watch contributes the bulk; iPhone adds some.
      final points = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: midnight,
        endTime: now,
      );
      final unique = _health.removeDuplicates(points);
      var calories = 0.0;
      for (final p in unique) {
        final v = p.value;
        if (v is NumericHealthValue) {
          calories += v.numericValue.toDouble();
        }
      }

      // Steps — reliable on iPhone alone.
      final steps = await _health.getTotalStepsInInterval(midnight, now) ?? 0;

      // iPhone-only fallback: if there's essentially no measured active energy
      // but we do have steps, estimate calories from steps so the Exercise card
      // still reflects the user's day.
      if (calories < 1 && steps > 0) {
        calories = steps * _kCalPerStep;
      }

      return HealthSyncResult(calories: calories, steps: steps);
    } catch (_) {
      return null;
    }
  }
}
