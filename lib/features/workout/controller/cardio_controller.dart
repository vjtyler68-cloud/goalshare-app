import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../data/cardio_run.dart';
import 'workout_controller.dart';

/// Owns the live run/walk tracking so it survives leaving the screen AND the app
/// being backgrounded — the tracking screen is only a viewport onto this state.
///
/// - GPS keeps streaming in the background (iOS `allowBackgroundLocationUpdates`
///   + `activityType: fitness` + `bestForNavigation`), so you can check another
///   feature mid-run and nothing is lost.
/// - Elapsed time is WALL-CLOCK based (now - start - paused), not a tick count,
///   so a suspended timer in the background never loses seconds.
/// - Distance is filtered for GPS jitter/glitches so it stays accurate.
class CardioController extends GetxController {
  static CardioController get to => Get.isRegistered<CardioController>()
      ? Get.find<CardioController>()
      : Get.put(CardioController(), permanent: true);

  final RxBool tracking = false.obs;
  final RxBool paused = false.obs;
  final RxString kind = 'run'.obs; // 'run' | 'walk'
  final RxList<LatLng> route = <LatLng>[].obs;
  final Rxn<LatLng> current = Rxn<LatLng>();
  final RxDouble distanceMeters = 0.0.obs;
  final RxInt elapsedSec = 0.obs;
  final RxString status = ''.obs;

  /// True only while the full tracking screen is on top. The global mini-bar
  /// watches this so it hides on the tracker (no need to double up) and shows
  /// on every OTHER screen — Bible, budget, nutrition, wherever you wander
  /// mid-run — with a tap to jump straight back.
  final RxBool viewing = false.obs;

  int _startMs = 0;
  int _pausedAccumMs = 0;
  int? _pausedAtMs;
  LatLng? _lastPoint;
  StreamSubscription<Position>? _sub;
  Timer? _ticker;

  bool get isActive => tracking.value;
  String get emoji => kind.value == 'walk' ? '🚶' : '🏃';
  String get label => kind.value == 'walk' ? 'Walk' : 'Run';

  int _now() => DateTime.now().millisecondsSinceEpoch;

  // High-accuracy, fitness-tuned, background-capable location settings.
  LocationSettings _settings() {
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.fitness,
        distanceFilter: 4,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 4,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'GoalShare',
          notificationText: 'Tracking your route',
          enableWakeLock: true,
        ),
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 4,
    );
  }

  /// Ensure permission + a first fix so the map can center. Returns true when we
  /// have (or can get) a location.
  Future<bool> prepare() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        status.value =
            'Location is off — turn it on in Settings to track your route.';
        return false;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        status.value =
            'Location permission is needed to map your run. Enable it in Settings.';
        return false;
      }
      status.value = '';
      if (!tracking.value) {
        final pos = await Geolocator.getCurrentPosition();
        current.value = LatLng(pos.latitude, pos.longitude);
      }
      return true;
    } catch (_) {
      status.value = 'Could not get your location yet.';
      return false;
    }
  }

  Future<void> start(String k) async {
    if (tracking.value) return;
    kind.value = k;
    final ok = await prepare();
    if (!ok) return;
    _startMs = _now();
    _pausedAccumMs = 0;
    _pausedAtMs = null;
    distanceMeters.value = 0;
    elapsedSec.value = 0;
    route.clear();
    _lastPoint = null;
    paused.value = false;
    tracking.value = true;
    _sub?.cancel();
    _sub = Geolocator.getPositionStream(locationSettings: _settings())
        .listen(_onPosition);
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!tracking.value) return;
    final end = paused.value ? (_pausedAtMs ?? _now()) : _now();
    final ms = end - _startMs - _pausedAccumMs;
    elapsedSec.value = ms <= 0 ? 0 : ms ~/ 1000;
  }

  void _onPosition(Position p) {
    final ll = LatLng(p.latitude, p.longitude);
    current.value = ll;
    _tick(); // keep elapsed fresh even if the 1s timer is suspended in background
    if (paused.value) return;
    // Accuracy gate — drop low-quality fixes (they add phantom distance).
    if (p.accuracy > 25) return;
    if (_lastPoint == null) {
      route.add(ll);
      _lastPoint = ll;
      return;
    }
    final d = Geolocator.distanceBetween(
        _lastPoint!.latitude, _lastPoint!.longitude, ll.latitude, ll.longitude);
    // >=3 m filters standing-still jitter; <250 m rejects a single GPS glitch.
    if (d >= 3 && d < 250) {
      distanceMeters.value += d;
      route.add(ll);
      _lastPoint = ll;
    }
  }

  void pause() {
    if (!tracking.value || paused.value) return;
    _pausedAtMs = _now();
    paused.value = true;
  }

  void resume() {
    if (!paused.value) return;
    _pausedAccumMs += _now() - (_pausedAtMs ?? _now());
    _pausedAtMs = null;
    paused.value = false;
  }

  /// Stop, save, and return the completed run (for the summary screen). Returns
  /// null if there was nothing to finish.
  Future<CardioRun?> finish() async {
    if (!tracking.value) return null;
    _tick();
    await _sub?.cancel();
    _sub = null;
    _ticker?.cancel();
    _ticker = null;
    final run = CardioRun(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      kind: kind.value,
      startedAtMs: _startMs == 0 ? _now() : _startMs,
      endedAtMs: _now(),
      distanceMeters: distanceMeters.value,
      movingSeconds: elapsedSec.value,
      points: route.map((l) => GeoPoint(l.latitude, l.longitude)).toList(),
    );
    await WorkoutController.to.saveRun(run);
    _reset();
    return run;
  }

  void discard() {
    _sub?.cancel();
    _sub = null;
    _ticker?.cancel();
    _ticker = null;
    _reset();
  }

  void _reset() {
    tracking.value = false;
    paused.value = false;
    route.clear();
    distanceMeters.value = 0;
    elapsedSec.value = 0;
    _lastPoint = null;
    _startMs = 0;
    _pausedAccumMs = 0;
    _pausedAtMs = null;
    // `current` is kept so a reopened map still has a center.
  }

  @override
  void onClose() {
    _sub?.cancel();
    _ticker?.cancel();
    super.onClose();
  }
}
