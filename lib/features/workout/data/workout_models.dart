import 'dart:convert';

/// MY WORKOUT — offline-first data models.
///
/// Everything here serialises to plain JSON and is stored in Hive `Box<String>`
/// (see [WorkoutStore]) — the SAME zero-codegen pattern as budget_v1 / leads_v1.
/// No Hive adapters, no build_runner, so it can never break a build over a
/// mismatched typeId. 100% on-device; a Phase-2 sync layer can lift these JSON
/// blobs straight to the backend untouched.

/// Epley estimated 1-rep-max — the industry-standard strength proxy.
double epley1rm(double weight, int reps) {
  if (weight <= 0 || reps <= 0) return 0;
  if (reps == 1) return weight;
  return weight * (1 + reps / 30.0);
}

/// Set intent. Drives the little colour-coded chip on each row.
enum SetType { warmup, working, drop, failure }

extension SetTypeX on SetType {
  String get id => name;
  String get short {
    switch (this) {
      case SetType.warmup:
        return 'W';
      case SetType.working:
        return '';
      case SetType.drop:
        return 'D';
      case SetType.failure:
        return 'F';
    }
  }

  String get label {
    switch (this) {
      case SetType.warmup:
        return 'Warmup';
      case SetType.working:
        return 'Working';
      case SetType.drop:
        return 'Drop set';
      case SetType.failure:
        return 'To failure';
    }
  }

  /// Warmups don't count toward volume/PRs/streak-worthy work.
  bool get countsAsWork => this == SetType.working || this == SetType.failure;

  static SetType fromId(String? s) =>
      SetType.values.firstWhere((e) => e.name == s, orElse: () => SetType.working);
}

/// Muscle targets — powers the weekly heatmap and exercise grouping.
enum MuscleGroup {
  chest,
  back,
  shoulders,
  biceps,
  triceps,
  forearms,
  quads,
  hamstrings,
  glutes,
  calves,
  core,
  fullBody,
  cardio,
  other,
}

extension MuscleGroupX on MuscleGroup {
  String get id => name;

  String get label {
    switch (this) {
      case MuscleGroup.chest:
        return 'Chest';
      case MuscleGroup.back:
        return 'Back';
      case MuscleGroup.shoulders:
        return 'Shoulders';
      case MuscleGroup.biceps:
        return 'Biceps';
      case MuscleGroup.triceps:
        return 'Triceps';
      case MuscleGroup.forearms:
        return 'Forearms';
      case MuscleGroup.quads:
        return 'Quads';
      case MuscleGroup.hamstrings:
        return 'Hamstrings';
      case MuscleGroup.glutes:
        return 'Glutes';
      case MuscleGroup.calves:
        return 'Calves';
      case MuscleGroup.core:
        return 'Core';
      case MuscleGroup.fullBody:
        return 'Full Body';
      case MuscleGroup.cardio:
        return 'Cardio';
      case MuscleGroup.other:
        return 'Other';
    }
  }

  /// Push / Pull / Legs / Core bucket — used for the split-balance ring.
  String get region {
    switch (this) {
      case MuscleGroup.chest:
      case MuscleGroup.shoulders:
      case MuscleGroup.triceps:
        return 'Push';
      case MuscleGroup.back:
      case MuscleGroup.biceps:
      case MuscleGroup.forearms:
        return 'Pull';
      case MuscleGroup.quads:
      case MuscleGroup.hamstrings:
      case MuscleGroup.glutes:
      case MuscleGroup.calves:
        return 'Legs';
      case MuscleGroup.core:
        return 'Core';
      default:
        return 'Other';
    }
  }

  static MuscleGroup fromId(String? s) => MuscleGroup.values
      .firstWhere((e) => e.name == s, orElse: () => MuscleGroup.other);
}

/// A catalogue exercise (built-in or user-created).
class Exercise {
  final String id;
  final String name;
  final MuscleGroup primary;
  final bool bodyweight;
  final bool timed; // planks, cardio — logged by duration not reps
  final bool custom;

  const Exercise({
    required this.id,
    required this.name,
    required this.primary,
    this.bodyweight = false,
    this.timed = false,
    this.custom = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'primary': primary.id,
        'bodyweight': bodyweight,
        'timed': timed,
        'custom': custom,
      };

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        primary: MuscleGroupX.fromId(j['primary'] as String?),
        bodyweight: j['bodyweight'] == true,
        timed: j['timed'] == true,
        custom: j['custom'] == true,
      );
}

/// A single logged set.
class SetEntry {
  String id;
  double? weight;
  int? reps;
  double? rpe; // 1–10
  SetType type;
  bool done;
  bool isPr; // set true the moment it beats the historical e1RM best
  int? durationSec; // timed exercises only

  SetEntry({
    required this.id,
    this.weight,
    this.reps,
    this.rpe,
    this.type = SetType.working,
    this.done = false,
    this.isPr = false,
    this.durationSec,
  });

  double get e1rm =>
      (weight != null && reps != null) ? epley1rm(weight!, reps!) : 0;

  double get volume => (weight ?? 0.0) * (reps ?? 0);

  Map<String, dynamic> toJson() => {
        'id': id,
        'w': weight,
        'r': reps,
        'rpe': rpe,
        't': type.id,
        'done': done,
        'pr': isPr,
        'dur': durationSec,
      };

  factory SetEntry.fromJson(Map<String, dynamic> j) => SetEntry(
        id: (j['id'] ?? '').toString(),
        weight: (j['w'] as num?)?.toDouble(),
        reps: (j['r'] as num?)?.toInt(),
        rpe: (j['rpe'] as num?)?.toDouble(),
        type: SetTypeX.fromId(j['t'] as String?),
        done: j['done'] == true,
        isPr: j['pr'] == true,
        durationSec: (j['dur'] as num?)?.toInt(),
      );

  SetEntry copy() => SetEntry.fromJson(toJson());
}

/// One exercise inside a session, with its sets.
class ExerciseLog {
  String id;
  String exerciseId;
  String name; // snapshot so history renders even if the catalogue changes
  MuscleGroup muscle;
  bool bodyweight;
  bool timed;
  List<SetEntry> sets;
  String? note;

  ExerciseLog({
    required this.id,
    required this.exerciseId,
    required this.name,
    required this.muscle,
    this.bodyweight = false,
    this.timed = false,
    List<SetEntry>? sets,
    this.note,
  }) : sets = sets ?? <SetEntry>[];

  double get volume =>
      sets.where((s) => s.done && s.type.countsAsWork).fold(0.0, (a, s) => a + s.volume);

  int get doneSets => sets.where((s) => s.done).length;

  double get bestE1rm => sets
      .where((s) => s.done && s.type.countsAsWork)
      .fold(0.0, (a, s) => s.e1rm > a ? s.e1rm : a);

  Map<String, dynamic> toJson() => {
        'id': id,
        'exId': exerciseId,
        'name': name,
        'm': muscle.id,
        'bw': bodyweight,
        'timed': timed,
        'sets': sets.map((s) => s.toJson()).toList(),
        'note': note,
      };

  factory ExerciseLog.fromJson(Map<String, dynamic> j) => ExerciseLog(
        id: (j['id'] ?? '').toString(),
        exerciseId: (j['exId'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        muscle: MuscleGroupX.fromId(j['m'] as String?),
        bodyweight: j['bw'] == true,
        timed: j['timed'] == true,
        sets: ((j['sets'] as List?) ?? [])
            .whereType<Map>()
            .map((e) => SetEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        note: j['note'] as String?,
      );
}

/// A workout — active (endedAtMs == null) or completed.
class WorkoutSession {
  String id;
  String name;
  String emoji;
  int startedAtMs;
  int? endedAtMs;
  List<ExerciseLog> exercises;

  WorkoutSession({
    required this.id,
    required this.name,
    this.emoji = '💪',
    required this.startedAtMs,
    this.endedAtMs,
    List<ExerciseLog>? exercises,
  }) : exercises = exercises ?? <ExerciseLog>[];

  bool get isActive => endedAtMs == null;

  DateTime get startedAt => DateTime.fromMillisecondsSinceEpoch(startedAtMs);
  DateTime? get endedAt =>
      endedAtMs == null ? null : DateTime.fromMillisecondsSinceEpoch(endedAtMs!);

  int get durationSec =>
      ((endedAtMs ?? DateTime.now().millisecondsSinceEpoch) - startedAtMs) ~/ 1000;

  double get totalVolume =>
      exercises.fold(0.0, (a, e) => a + e.volume);

  int get totalSets =>
      exercises.fold(0, (a, e) => a + e.doneSets);

  int get prCount =>
      exercises.fold(0, (a, e) => a + e.sets.where((s) => s.isPr && s.done).length);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'start': startedAtMs,
        'end': endedAtMs,
        'ex': exercises.map((e) => e.toJson()).toList(),
      };

  String toJsonString() => jsonEncode(toJson());

  factory WorkoutSession.fromJson(Map<String, dynamic> j) => WorkoutSession(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? 'Workout').toString(),
        emoji: (j['emoji'] ?? '💪').toString(),
        startedAtMs: (j['start'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
        endedAtMs: (j['end'] as num?)?.toInt(),
        exercises: ((j['ex'] as List?) ?? [])
            .whereType<Map>()
            .map((e) => ExerciseLog.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );

  factory WorkoutSession.fromJsonString(String s) =>
      WorkoutSession.fromJson(Map<String, dynamic>.from(jsonDecode(s) as Map));
}

/// A reusable template (Push/Pull/Legs, Upper/Lower, custom …).
class TemplateExercise {
  final String exerciseId;
  final int sets;
  const TemplateExercise(this.exerciseId, this.sets);

  Map<String, dynamic> toJson() => {'exId': exerciseId, 'sets': sets};
  factory TemplateExercise.fromJson(Map<String, dynamic> j) => TemplateExercise(
        (j['exId'] ?? '').toString(),
        (j['sets'] as num?)?.toInt() ?? 3,
      );
}

class WorkoutTemplate {
  final String id;
  final String name;
  final String emoji;
  final String subtitle;
  final List<TemplateExercise> exercises;
  final bool builtIn;

  const WorkoutTemplate({
    required this.id,
    required this.name,
    required this.emoji,
    required this.subtitle,
    required this.exercises,
    this.builtIn = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'subtitle': subtitle,
        'ex': exercises.map((e) => e.toJson()).toList(),
        'builtIn': builtIn,
      };

  factory WorkoutTemplate.fromJson(Map<String, dynamic> j) => WorkoutTemplate(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? 'Template').toString(),
        emoji: (j['emoji'] ?? '🏋️').toString(),
        subtitle: (j['subtitle'] ?? '').toString(),
        exercises: ((j['ex'] as List?) ?? [])
            .whereType<Map>()
            .map((e) => TemplateExercise.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        builtIn: j['builtIn'] == true,
      );
}

/// Goalshare goal.
enum GoalType { lift1rm, bodyweight, streak, volume, reps, custom }

extension GoalTypeX on GoalType {
  String get id => name;
  String get label {
    switch (this) {
      case GoalType.lift1rm:
        return 'Lift 1RM';
      case GoalType.bodyweight:
        return 'Body weight';
      case GoalType.streak:
        return 'Streak';
      case GoalType.volume:
        return 'Weekly volume';
      case GoalType.reps:
        return 'Rep target';
      case GoalType.custom:
        return 'Custom';
    }
  }

  static GoalType fromId(String? s) =>
      GoalType.values.firstWhere((e) => e.name == s, orElse: () => GoalType.custom);
}

class WorkoutGoal {
  String id;
  GoalType type;
  String title;
  String unit;
  double target;
  double current;
  String? exerciseId;
  int createdAtMs;
  int? achievedAtMs;

  WorkoutGoal({
    required this.id,
    required this.type,
    required this.title,
    required this.unit,
    required this.target,
    this.current = 0,
    this.exerciseId,
    required this.createdAtMs,
    this.achievedAtMs,
  });

  double get progress =>
      target <= 0 ? 0 : (current / target).clamp(0.0, 1.0).toDouble();

  bool get achieved => achievedAtMs != null || (target > 0 && current >= target);

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.id,
        'title': title,
        'unit': unit,
        'target': target,
        'current': current,
        'exId': exerciseId,
        'created': createdAtMs,
        'achieved': achievedAtMs,
      };

  factory WorkoutGoal.fromJson(Map<String, dynamic> j) => WorkoutGoal(
        id: (j['id'] ?? '').toString(),
        type: GoalTypeX.fromId(j['type'] as String?),
        title: (j['title'] ?? '').toString(),
        unit: (j['unit'] ?? '').toString(),
        target: (j['target'] as num?)?.toDouble() ?? 0,
        current: (j['current'] as num?)?.toDouble() ?? 0,
        exerciseId: j['exId'] as String?,
        createdAtMs: (j['created'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
        achievedAtMs: (j['achieved'] as num?)?.toInt(),
      );
}

/// The streak record — the app's beating heart.
class StreakState {
  int current;
  int longest;
  String? lastDayKey; // 'YYYY-MM-DD' of the last completed workout
  int totalWorkouts;

  StreakState({
    this.current = 0,
    this.longest = 0,
    this.lastDayKey,
    this.totalWorkouts = 0,
  });

  Map<String, dynamic> toJson() => {
        'current': current,
        'longest': longest,
        'lastDayKey': lastDayKey,
        'total': totalWorkouts,
      };

  factory StreakState.fromJson(Map<String, dynamic> j) => StreakState(
        current: (j['current'] as num?)?.toInt() ?? 0,
        longest: (j['longest'] as num?)?.toInt() ?? 0,
        lastDayKey: j['lastDayKey'] as String?,
        totalWorkouts: (j['total'] as num?)?.toInt() ?? 0,
      );
}
