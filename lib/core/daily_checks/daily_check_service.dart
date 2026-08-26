import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/achievements/achievements_controller.dart';

/// Feature ids for the home-screen daily green checks.
class DailyCheckFeature {
  DailyCheckFeature._();
  static const String priming = 'priming';
  static const String vision = 'vision';
  static const String bible = 'bible';
  static const String nutrition = 'nutrition';
  static const String budget = 'budget';
  static const String gratitude = 'gratitude';
  static const String workout = 'workout';
  static const String goflow = 'goflow';
  static const String dailySpark = 'daily_spark';
  static const String affirmations = 'affirmations';
  static const String myWhy = 'my_why';
  static const String ritual = 'ritual';
}

/// Tracks "did I do this today?" per feature so the Home grid can show a green
/// check for the day (VJ: Priming, Vision Board, Bible, My Nutrition,
/// My Budget). Local-first (Hive), reactive (RxMap), resets naturally at
/// midnight because checks are stored as the completion DATE and compared to
/// today at read time.
class DailyCheckService extends GetxService {
  static DailyCheckService get to => Get.isRegistered<DailyCheckService>()
      ? Get.find<DailyCheckService>()
      : Get.put(DailyCheckService(), permanent: true);

  static const String _boxName = 'daily_feature_checks_v1';
  Box<String>? _box;

  /// feature id -> yyyy-MM-dd of last completion (reactive).
  final RxMap<String, String> _lastDone = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _open();
  }

  Future<void> _open() async {
    try {
      _box = Hive.isBoxOpen(_boxName)
          ? Hive.box<String>(_boxName)
          : await Hive.openBox<String>(_boxName);
      _lastDone.assignAll({
        for (final k in _box!.keys) k.toString(): _box!.get(k) ?? '',
      });
    } catch (_) {
      // Checks are cosmetic; storage failure just means no green checks.
    }
  }

  static String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  /// Mark [feature] as done today (idempotent). The first time a feature is
  /// completed on a given day it also awards that feature's once-a-day XP.
  void markDoneToday(String feature) {
    final today = _todayKey();
    if (_lastDone[feature] == today) return;
    _lastDone[feature] = today;
    _box?.put(feature, today);
    // First completion of the day → award the feature's daily XP bonus (also
    // keeps the app-wide streak alive). Fire-and-forget; never block the check.
    if (Get.isRegistered<AchievementsController>()) {
      Get.find<AchievementsController>().awardDailyFeature(feature);
    }
  }

  /// Reactive when read inside Obx.
  bool isDoneToday(String feature) => _lastDone[feature] == _todayKey();
}
