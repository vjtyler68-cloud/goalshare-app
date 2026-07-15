import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:spanx/core/daily_checks/daily_check_service.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

const String kPrimingVideoId = 'faTGTgid8Uc';

/// Local-first (Hive) priming streak: keys are plain strings so no adapter is
/// needed. lastDate = yyyy-MM-dd of the last completed prime.
const String kPrimingStreakBox = 'priming_streak';

class PrimingController extends GetxController {
  var isCompleted = false.obs;

  /// Consecutive days primed (today counts once marked complete).
  var streak = 0.obs;

  /// All-time best streak.
  var best = 0.obs;

  /// The YoutubePlayer is a native platform view (WKWebView). It must be
  /// removed from the widget tree BEFORE the route pops, otherwise iOS leaves
  /// its gray "ghost" texture floating over whatever screen comes next.
  /// [closeScreen] flips this off, waits a frame, then pops.
  var isPlayerVisible = true.obs;

  late final YoutubePlayerController ytController;
  Box<String>? _box;

  @override
  void onInit() {
    super.onInit();

    // Use the dedicated YouTube IFrame player. Earlier hand-rolled WKWebView
    // attempts both failed:
    //   * loadHtmlString + baseUrl  -> Error 152 (WKWebView doesn't grant the
    //     content a real network origin, so the IFrame API rejected it).
    //   * loadRequest to the embed URL as the top-level document -> Error 153
    //     ("Video player configuration error") because a top-level embed load
    //     sends no HTTP referrer, which YouTube's player requires.
    // This package embeds the player inside a proper iframe with a valid origin
    // and manages iOS inline playback, so neither error occurs.
    ytController = YoutubePlayerController.fromVideoId(
      videoId: kPrimingVideoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        // No YoutubePlayerScaffold here, so the fullscreen toggle has nothing
        // to drive — hide it and rely on the "Watch on YouTube" button for the
        // full-screen experience.
        showFullscreenButton: false,
        playsInline: true,
        strictRelatedVideos: true,
      ),
    );

    _loadStreak();
  }

  @override
  void onClose() {
    ytController.close();
    super.onClose();
  }

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadStreak() async {
    try {
      _box = Hive.isBoxOpen(kPrimingStreakBox)
          ? Hive.box<String>(kPrimingStreakBox)
          : await Hive.openBox<String>(kPrimingStreakBox);
      final last = _box!.get('lastDate');
      final stored = int.tryParse(_box!.get('streak') ?? '') ?? 0;
      best.value = int.tryParse(_box!.get('best') ?? '') ?? 0;

      final now = DateTime.now();
      if (last == _dayKey(now)) {
        // Already primed today.
        isCompleted.value = true;
        streak.value = stored;
      } else if (last == _dayKey(now.subtract(const Duration(days: 1)))) {
        // Primed yesterday — streak is alive, today keeps it going.
        streak.value = stored;
      } else {
        // Chain broken (or first ever visit) — display 0 until they prime.
        streak.value = 0;
      }
    } catch (_) {
      // Streak is a nice-to-have; never let storage problems break priming.
    }
  }

  void markCompleted() {
    if (!isCompleted.value) {
      final now = DateTime.now();
      final today = _dayKey(now);
      final yesterday = _dayKey(now.subtract(const Duration(days: 1)));
      final last = _box?.get('lastDate');
      final stored = int.tryParse(_box?.get('streak') ?? '') ?? 0;

      // Continue the chain only if the previous prime was yesterday.
      streak.value = (last == yesterday) ? stored + 1 : 1;
      if (streak.value > best.value) best.value = streak.value;

      _box?.put('lastDate', today);
      _box?.put('streak', streak.value.toString());
      _box?.put('best', best.value.toString());

      _celebrate();
    }
    isCompleted.value = true;
    // Home-screen daily green check.
    DailyCheckService.to.markDoneToday(DailyCheckFeature.priming);
  }

  void _celebrate() {
    final s = streak.value;
    final String msg;
    if (s == 1 && best.value <= 1) {
      msg = '🔥 Day 1 — your streak starts now!';
    } else if (s == 1) {
      msg = '🔥 Back at it — day 1 of a new streak!';
    } else if (s == 3) {
      msg = '🔥🔥 3 days in a row — momentum!';
    } else if (s == 7) {
      msg = '🔥 A FULL WEEK of priming — unstoppable!';
    } else if (s == 14) {
      msg = '🔥 14 days straight — this is who you are now!';
    } else if (s == 30) {
      msg = '👑 30-DAY STREAK — absolute legend!';
    } else if (s == best.value && s > 1) {
      msg = '🔥 $s days — new personal best!';
    } else {
      msg = '🔥 $s days in a row — keep the fire alive!';
    }
    AppSnackBar.success(msg, title: 'Primed!');
  }

  /// Hide the native player, give Flutter a frame to dispose it, then pop.
  /// Prevents the iOS platform-view ghost texture (gray rectangle) from
  /// haunting the next screen.
  Future<void> closeScreen({bool complete = false}) async {
    if (complete) markCompleted();
    isPlayerVisible.value = false;
    await Future<void>.delayed(const Duration(milliseconds: 80));
    Get.back();
  }
}
