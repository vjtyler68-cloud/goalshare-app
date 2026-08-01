import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../data/cardio_run.dart';
import '../data/workout_store.dart';
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

  // Crash-recovery: the in-progress run is snapshotted to disk as it tracks, so
  // an OS process-kill mid-run RESUMES instead of losing the whole thing.
  final WorkoutStore _store = WorkoutStore();
  bool _restarting = false;
  int _lastPersistMs = 0;

  @override
  void onInit() {
    super.onInit();
    _recoverActiveRun();
  }

  /// On app launch, if a run was still in progress when the app was last killed,
  /// restore its state and seamlessly resume tracking (elapsed time is
  /// wall-clock so nothing is lost; the route just has a gap for the dead time).
  Future<void> _recoverActiveRun() async {
    try {
      await _store.open();
      if (tracking.value) return; // a fresh run already started
      final snap = _store.getActiveRun();
      if (snap == null) return;
      final startMs = (snap['startMs'] as num?)?.toInt() ?? 0;
      if (startMs <= 0) {
        await _store.setActiveRun(null);
        return;
      }
      // Don't resurrect an ancient run (app not opened for half a day).
      if (_now() - startMs > const Duration(hours: 12).inMilliseconds) {
        await _store.setActiveRun(null);
        return;
      }
      kind.value = (snap['kind'] ?? 'run').toString();
      _startMs = startMs;
      _pausedAccumMs = (snap['pausedAccumMs'] as num?)?.toInt() ?? 0;
      final wasPaused = snap['paused'] == true;
      _pausedAtMs =
          wasPaused ? ((snap['pausedAtMs'] as num?)?.toInt() ?? _now()) : null;
      paused.value = wasPaused;
      distanceMeters.value = (snap['dist'] as num?)?.toDouble() ?? 0;
      elapsedSec.value = (snap['elapsed'] as num?)?.toInt() ?? 0;
      route.assignAll(((snap['pts'] as List?) ?? [])
          .whereType<Map>()
          .map((m) => LatLng((m['a'] as num?)?.toDouble() ?? 0,
              (m['o'] as num?)?.toDouble() ?? 0)));
      _lastPoint = route.isNotEmpty ? route.last : null;
      current.value = _lastPoint;
      tracking.value = true;
      _tick();
      status.value = 'Resumed your run.';
      _startStream();
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    } catch (_) {
      // Recovery is best-effort and must never block app start.
    }
  }

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
    _startStream();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _persistActiveRun(force: true);
  }

  /// (Re)subscribe to the GPS stream with resilient error handling. A transient
  /// location error or an unexpected stream close must NOT silently end the run
  /// — we log it and rebuild the stream so tracking self-heals.
  void _startStream() {
    _sub?.cancel();
    _sub = Geolocator.getPositionStream(locationSettings: _settings()).listen(
      _onPosition,
      onError: (Object e, StackTrace _) {
        status.value = 'GPS hiccup — reconnecting…';
        _scheduleStreamRestart();
      },
      onDone: () {
        // The position stream shouldn't complete while a run is live; if it
        // does, bring it back.
        if (tracking.value) _scheduleStreamRestart();
      },
      cancelOnError: false,
    );
  }

  void _scheduleStreamRestart() {
    if (!tracking.value || _restarting) return;
    _restarting = true;
    Future.delayed(const Duration(seconds: 2), () {
      _restarting = false;
      if (tracking.value) _startStream();
    });
  }

  /// Snapshot the live run to disk for crash recovery. Throttled so a fast GPS
  /// stream doesn't hammer storage; [force] writes immediately (start/pause/
  /// resume) so those state changes are never lost.
  void _persistActiveRun({bool force = false}) {
    if (!tracking.value) return;
    final now = _now();
    if (!force && now - _lastPersistMs < 3000) return;
    _lastPersistMs = now;
    _store.setActiveRun({
      'kind': kind.value,
      'startMs': _startMs,
      'pausedAccumMs': _pausedAccumMs,
      'pausedAtMs': _pausedAtMs,
      'paused': paused.value,
      'dist': distanceMeters.value,
      'elapsed': elapsedSec.value,
      'pts': route.map((l) => {'a': l.latitude, 'o': l.longitude}).toList(),
      'savedAtMs': now,
    });
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
      _persistActiveRun();
      return;
    }
    final d = Geolocator.distanceBetween(
        _lastPoint!.latitude, _lastPoint!.longitude, ll.latitude, ll.longitude);
    // >=3 m filters standing-still jitter; <250 m rejects a single GPS glitch.
    if (d >= 3 && d < 250) {
      distanceMeters.value += d;
      route.add(ll);
      _lastPoint = ll;
      _persistActiveRun();
    }
  }

  void pause() {
    if (!tracking.value || paused.value) return;
    _pausedAtMs = _now();
    paused.value = true;
    _persistActiveRun(force: true);
  }

  void resume() {
    if (!paused.value) return;
    _pausedAccumMs += _now() - (_pausedAtMs ?? _now());
    _pausedAtMs = null;
    paused.value = false;
    _persistActiveRun(force: true);
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
    // A finished/discarded run must never be recovered on the next launch.
    _store.setActiveRun(null);
    _restarting = false;
    _lastPersistMs = 0;
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
