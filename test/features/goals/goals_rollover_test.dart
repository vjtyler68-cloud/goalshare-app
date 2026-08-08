import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:spanx/features/goals/controller/goals_controller.dart';
import 'package:spanx/features/goals/data/goal.dart';

/// rolloverRepeats() operates on the in-memory [goals] list and is null-safe on
/// the Hive box, so it can be exercised without opening Hive.
void main() {
  Goal make({
    required String id,
    required String timeframe,
    required bool repeats,
    required DateTime lastReset,
    int progress = 3,
    int target = 3,
  }) =>
      Goal(
        id: id,
        title: id,
        timeframe: timeframe,
        target: target,
        progress: progress,
        createdAt: lastReset,
        completedAt: progress >= target ? lastReset : null,
        repeats: repeats,
        lastReset: lastReset,
      );

  test('Today (Daily) goals reset at the new day even without repeats',
      () async {
    final c = GoalsController();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    c.goals.assignAll([
      make(id: 'daily-noRepeat', timeframe: 'Daily', repeats: false, lastReset: yesterday),
    ]);

    await c.rolloverRepeats();

    final g = c.goals.firstWhere((x) => x.id == 'daily-noRepeat');
    expect(g.progress, 0, reason: 'a Today goal should reset at midnight');
    expect(g.isCompleted, isFalse);
  });

  test('Today goals logged today are left alone', () async {
    final c = GoalsController();
    final now = DateTime.now();
    c.goals.assignAll([
      make(id: 'daily-today', timeframe: 'Daily', repeats: false, lastReset: now),
    ]);

    await c.rolloverRepeats();

    expect(c.goals.first.progress, 3, reason: 'same day → no reset');
  });

  test('Non-daily goals without repeats do NOT reset', () async {
    final c = GoalsController();
    final lastWeek = DateTime.now().subtract(const Duration(days: 8));
    c.goals.assignAll([
      make(id: 'weekly-noRepeat', timeframe: 'Weekly', repeats: false, lastReset: lastWeek),
    ]);

    await c.rolloverRepeats();

    expect(c.goals.first.progress, 3,
        reason: 'only Today auto-resets; Weekly needs repeats');
  });

  test('Non-daily goals WITH repeats still reset on a new period', () async {
    final c = GoalsController();
    final lastWeek = DateTime.now().subtract(const Duration(days: 8));
    c.goals.assignAll([
      make(id: 'weekly-repeat', timeframe: 'Weekly', repeats: true, lastReset: lastWeek),
    ]);

    await c.rolloverRepeats();

    expect(c.goals.first.progress, 0);
  });
}
