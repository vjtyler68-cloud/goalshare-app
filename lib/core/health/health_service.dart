import 'dart:io';

import 'package:health/health.dart';

/// LIVE Apple Health / HealthKit integration.
///
/// Enabled once all three prerequisites were met:
///   1. HealthKit capability is on the com.goal.share App ID (Apple Developer
///      portal), and
///   2. `ios/Runner/Runner.entitlements` declares `com.apple.developer.healthkit`
///      (Codemagic's automatic signing regenerates the profile on build), and
///   3. Info.plist carries the NSHealth{Share,Update}UsageDescription strings.
///
/// To fully disable again (e.g. to ship a build without HealthKit), set this
/// back to `false` — every call then no-ops safely — AND remove the entitlement
/// line above so signing doesn't demand a capability the build won't use.
const bool kHealthKitEnabled = true;

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

  // Types the app touches. READ powers the nutrition/activity dashboard; WRITE
  // lets finished runs, walks and strength sessions land in Apple Health — so
  // they show in the Health app and count toward the Apple Watch Activity rings.
  // HEART_RATE is read-only: a run's average/peak BPM, pulled from the Watch.
  static const List<HealthDataType> _types = [
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.WORKOUT,
  ];

  // Parallel to [_types]. Active energy + distance + workout are READ_WRITE so
  // we can both read the day's totals and write our own workouts.
  static const List<HealthDataAccess> _access = [
    HealthDataAccess.READ_WRITE, // ACTIVE_ENERGY_BURNED
    HealthDataAccess.READ, // STEPS
    HealthDataAccess.READ, // HEART_RATE
    HealthDataAccess.READ_WRITE, // DISTANCE_WALKING_RUNNING
    HealthDataAccess.READ_WRITE, // WORKOUT
  ];

  bool _authorized = false;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Ask the user to grant access (read + write). Returns false if denied or
  /// unavailable. On iOS the sheet only appears once; later calls are silent.
  Future<bool> requestPermissions() async {
    if (!isEnabled) return false;
    try {
      await _ensureConfigured();
      _authorized = await _health.requestAuthorization(
        _types,
        permissions: _access,
      );
      return _authorized;
    } catch (_) {
      return false;
    }
  }

  /// Request authorization lazily, the first time we actually read or write.
  Future<bool> _ensureAuthorized() async {
    if (_authorized) return true;
    return requestPermissions();
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

  /// Write a finished run/walk into Apple Health as a Workout — so it appears in
  /// the Health app and contributes to the Apple Watch Activity rings. Distance
  /// comes straight from our GPS track; energy is a rough distance-based
  /// estimate (we have no body weight), which beats a blank ring. Safe no-op
  /// unless [isEnabled]. Returns true on success.
  Future<bool> saveRun({
    required String kind,
    required DateTime start,
    required DateTime end,
    required double distanceMeters,
  }) async {
    if (!isEnabled) return false;
    if (!end.isAfter(start) || end.difference(start).inSeconds < 5) return false;
    try {
      if (!await _ensureAuthorized()) return false;
      final isWalk = kind == 'walk';
      final km = distanceMeters / 1000.0;
      // ~62 kcal/km running, ~50 kcal/km walking for an average adult.
      final kcal = (km * (isWalk ? 50 : 62)).round();
      return await _health.writeWorkoutData(
        activityType: isWalk
            ? HealthWorkoutActivityType.WALKING
            : HealthWorkoutActivityType.RUNNING,
        start: start,
        end: end,
        totalDistance: distanceMeters > 0 ? distanceMeters.round() : null,
        totalDistanceUnit: HealthDataUnit.METER,
        totalEnergyBurned: kcal > 0 ? kcal : null,
        totalEnergyBurnedUnit: HealthDataUnit.KILOCALORIE,
      );
    } catch (_) {
      return false;
    }
  }

  /// Write a finished strength session into Apple Health as a strength-training
  /// Workout. Safe no-op unless [isEnabled]. Returns true on success.
  Future<bool> saveStrengthSession({
    required DateTime start,
    required DateTime end,
    int? energyKcal,
  }) async {
    if (!isEnabled) return false;
    if (!end.isAfter(start) || end.difference(start).inSeconds < 5) return false;
    try {
      if (!await _ensureAuthorized()) return false;
      return await _health.writeWorkoutData(
        activityType: HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING,
        start: start,
        end: end,
        totalEnergyBurned:
            (energyKcal != null && energyKcal > 0) ? energyKcal : null,
        totalEnergyBurnedUnit: HealthDataUnit.KILOCALORIE,
      );
    } catch (_) {
      return false;
    }
  }

  /// Average & peak heart rate over a window (e.g. a run), read from the Apple
  /// Watch's samples. Returns null if unavailable / not permitted / no Watch.
  Future<({int avg, int max})?> readHeartRateStats(
      DateTime start, DateTime end) async {
    if (!isEnabled) return null;
    try {
      if (!await _ensureAuthorized()) return null;
      final points = await _health.getHealthDataFromTypes(
        types: [HealthDataType.HEART_RATE],
        startTime: start,
        endTime: end,
      );
      final unique = _health.removeDuplicates(points);
      final bpms = <double>[];
      for (final p in unique) {
        final v = p.value;
        if (v is NumericHealthValue) bpms.add(v.numericValue.toDouble());
      }
      if (bpms.isEmpty) return null;
      final avg = (bpms.reduce((a, b) => a + b) / bpms.length).round();
      final max = bpms.reduce((a, b) => a > b ? a : b).round();
      return (avg: avg, max: max);
    } catch (_) {
      return null;
    }
  }
}
