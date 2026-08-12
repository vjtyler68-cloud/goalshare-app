import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:spanx/features/workout/controller/workout_controller.dart';
import 'package:spanx/features/workout/data/workout_models.dart';

/// Regression for the "previous sets disappear after adding a new exercise" bug:
/// the previous/progress lookups must be keyed by a STABLE exerciseId, never by
/// list position — so inserting another exercise can't shift the reference data.
/// (onInit opens Hive only under Get.put; the bare constructor leaves `history`
/// an empty in-memory list we can populate directly.)
void main() {
  SetEntry workSet(double w, int r) => SetEntry(
        id: '$w-$r-${DateTime.now().microsecondsSinceEpoch}',
        weight: w,
        reps: r,
        done: true,
      );

  WorkoutSession session(String id, int daysAgo, List<ExerciseLog> ex) =>
      WorkoutSession(
        id: id,
        name: 'W',
        startedAtMs: DateTime.now()
            .subtract(Duration(days: daysAgo))
            .millisecondsSinceEpoch,
        endedAtMs: DateTime.now()
            .subtract(Duration(days: daysAgo))
            .millisecondsSinceEpoch,
        exercises: ex,
      );

  ExerciseLog log(String exId, List<SetEntry> sets) => ExerciseLog(
        id: 'log-$exId-${sets.length}',
        exerciseId: exId,
        name: exId,
        muscle: MuscleGroup.chest,
        sets: sets,
      );

  test('previousPerformance is keyed by exerciseId, not position', () {
    final c = WorkoutController();
    // Bench trained yesterday; squat trained today (listed FIRST — different
    // position). The lookup must still return bench data for bench.
    c.history.assignAll([
      session('s-today', 0, [
        log('squat', [workSet(225, 5)]),
        log('bench', [workSet(185, 5), workSet(185, 4)]),
      ]),
      session('s-old', 3, [
        log('bench', [workSet(135, 8)]),
      ]),
    ]);

    final prevBench = c.previousPerformance('bench');
    // Most recent completed session that trained bench = s-today (2 sets).
    expect(prevBench.length, 2);
    expect(prevBench.first.weight, 185);

    final prevSquat = c.previousPerformance('squat');
    expect(prevSquat.length, 1);
    expect(prevSquat.first.weight, 225);

    // A never-trained exercise returns empty, not someone else's data.
    expect(c.previousPerformance('deadlift'), isEmpty);
  });

  test('exerciseProgress returns per-session bests oldest→newest', () {
    final c = WorkoutController();
    c.history.assignAll([
      session('s2', 0, [
        log('bench', [workSet(200, 5)]),
      ]),
      session('s1', 10, [
        log('bench', [workSet(150, 5), workSet(160, 3)]),
      ]),
    ]);
    final prog = c.exerciseProgress('bench');
    expect(prog.length, 2);
    // Oldest first.
    expect(prog.first.topWeight, 160);
    expect(prog.last.topWeight, 200);
    // e1RM increased over time.
    expect(prog.last.bestE1rm > prog.first.bestE1rm, isTrue);
  });

  tearDown(Get.reset);
}
