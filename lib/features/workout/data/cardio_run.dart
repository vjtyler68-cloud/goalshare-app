import 'dart:convert';

/// A GPS-tracked run or walk (Strava-style) — distance, duration, pace and the
/// full route so it can be redrawn on a map later. Stored offline as JSON in a
/// Hive Box<String> (same pattern as the rest of MY WORKOUT).

class GeoPoint {
  final double lat;
  final double lng;
  const GeoPoint(this.lat, this.lng);

  Map<String, dynamic> toJson() => {'a': lat, 'o': lng};
  factory GeoPoint.fromJson(Map j) => GeoPoint(
        (j['a'] as num?)?.toDouble() ?? 0,
        (j['o'] as num?)?.toDouble() ?? 0,
      );
}

class CardioRun {
  String id;
  String kind; // 'run' | 'walk'
  int startedAtMs;
  int? endedAtMs;
  double distanceMeters;
  int movingSeconds; // active (unpaused) seconds
  List<GeoPoint> points;

  CardioRun({
    required this.id,
    required this.kind,
    required this.startedAtMs,
    this.endedAtMs,
    this.distanceMeters = 0,
    this.movingSeconds = 0,
    List<GeoPoint>? points,
  }) : points = points ?? <GeoPoint>[];

  String get label => kind == 'walk' ? 'Walk' : 'Run';
  String get emoji => kind == 'walk' ? '🚶' : '🏃';

  DateTime get startedAt => DateTime.fromMillisecondsSinceEpoch(startedAtMs);

  double get km => distanceMeters / 1000.0;
  double get miles => distanceMeters / 1609.34;

  /// Seconds per kilometre (0 when nothing logged).
  double get paceSecPerKm =>
      distanceMeters > 0 ? movingSeconds / (distanceMeters / 1000.0) : 0;

  /// Seconds per mile.
  double get paceSecPerMile =>
      distanceMeters > 0 ? movingSeconds / (distanceMeters / 1609.34) : 0;

  /// Distance-based calorie estimate (no body weight available): a walk burns
  /// ~50 kcal/km, a run ~62 kcal/km for an average adult.
  int get estimatedCalories =>
      (km * (kind == 'walk' ? 50 : 62)).round();

  /// Distance-based step estimate — average stride ~0.72 m walking, ~0.98 m
  /// running. Rough, but fills the Strava-style summary when there's no pedometer.
  int get estimatedSteps =>
      (distanceMeters / (kind == 'walk' ? 0.72 : 0.98)).round();

  /// Average speed in mph / km-h (0 when nothing logged).
  double get avgSpeedMph =>
      movingSeconds > 0 ? miles / (movingSeconds / 3600.0) : 0;
  double get avgSpeedKmh =>
      movingSeconds > 0 ? km / (movingSeconds / 3600.0) : 0;

  /// Strava-style title: time-of-day + activity, e.g. "Morning Walk".
  String get timeOfDayTitle {
    final h = startedAt.hour;
    final part = h < 5
        ? 'Night'
        : h < 12
            ? 'Morning'
            : h < 17
                ? 'Afternoon'
                : h < 21
                    ? 'Evening'
                    : 'Night';
    return '$part $label';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'start': startedAtMs,
        'end': endedAtMs,
        'dist': distanceMeters,
        'secs': movingSeconds,
        'pts': points.map((p) => p.toJson()).toList(),
      };

  String toJsonString() => jsonEncode(toJson());

  factory CardioRun.fromJson(Map<String, dynamic> j) => CardioRun(
        id: (j['id'] ?? '').toString(),
        kind: (j['kind'] ?? 'run').toString(),
        startedAtMs: (j['start'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
        endedAtMs: (j['end'] as num?)?.toInt(),
        distanceMeters: (j['dist'] as num?)?.toDouble() ?? 0,
        movingSeconds: (j['secs'] as num?)?.toInt() ?? 0,
        points: ((j['pts'] as List?) ?? [])
            .whereType<Map>()
            .map((e) => GeoPoint.fromJson(e))
            .toList(),
      );

  factory CardioRun.fromJsonString(String s) =>
      CardioRun.fromJson(Map<String, dynamic>.from(jsonDecode(s) as Map));
}

/// Format seconds as pace "m:ss".
String formatPace(double secPerUnit) {
  if (secPerUnit <= 0 || secPerUnit.isInfinite || secPerUnit.isNaN) return '--:--';
  final m = secPerUnit ~/ 60;
  final s = (secPerUnit % 60).round();
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// Format a duration in seconds as h:mm:ss or m:ss.
String formatDuration(int secs) {
  final h = secs ~/ 3600;
  final m = (secs % 3600) ~/ 60;
  final s = secs % 60;
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '$m:${s.toString().padLeft(2, '0')}';
}
