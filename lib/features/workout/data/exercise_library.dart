import 'workout_models.dart';

/// A training day that AUTO-ROTATES between 2 variants (e.g. Push A / Push B),
/// so revisiting the same day a couple of days later gives a fresh, different
/// session instead of the exact same one. The controller alternates variants
/// and starts each as a clean slate (last time's numbers show as the target).
class WorkoutDayRoutine {
  final String id; // 'push'
  final String name; // 'Push Day'
  final String emoji;
  final String subtitle; // muscles hit
  final List<WorkoutTemplate> variants; // [A, B]
  const WorkoutDayRoutine({
    required this.id,
    required this.name,
    required this.emoji,
    required this.subtitle,
    required this.variants,
  });

  int get variantCount => variants.length;
  String variantLabel(int i) => String.fromCharCode(65 + (i % variantCount));
}

/// Bundled, offline exercise catalogue + built-in splits.
///
/// Same spirit as `common_foods.dart`: ships in the binary so search + templates
/// work with zero network. User-created exercises live in [WorkoutStore] and are
/// merged on top of these at runtime.
class ExerciseLibrary {
  ExerciseLibrary._();

  static const List<Exercise> all = <Exercise>[
    // ---- Chest ----
    Exercise(id: 'bench_press', name: 'Barbell Bench Press', primary: MuscleGroup.chest),
    Exercise(id: 'incline_bench', name: 'Incline Bench Press', primary: MuscleGroup.chest),
    Exercise(id: 'db_bench', name: 'Dumbbell Bench Press', primary: MuscleGroup.chest),
    Exercise(id: 'incline_db_press', name: 'Incline Dumbbell Press', primary: MuscleGroup.chest),
    Exercise(id: 'chest_fly', name: 'Cable Chest Fly', primary: MuscleGroup.chest),
    Exercise(id: 'pushup', name: 'Push-Up', primary: MuscleGroup.chest, bodyweight: true),
    Exercise(id: 'dips', name: 'Chest Dip', primary: MuscleGroup.chest, bodyweight: true),
    // ---- Back ----
    Exercise(id: 'deadlift', name: 'Deadlift', primary: MuscleGroup.back),
    Exercise(id: 'pullup', name: 'Pull-Up', primary: MuscleGroup.back, bodyweight: true),
    Exercise(id: 'chinup', name: 'Chin-Up', primary: MuscleGroup.back, bodyweight: true),
    Exercise(id: 'lat_pulldown', name: 'Lat Pulldown', primary: MuscleGroup.back),
    Exercise(id: 'barbell_row', name: 'Barbell Row', primary: MuscleGroup.back),
    Exercise(id: 'db_row', name: 'Dumbbell Row', primary: MuscleGroup.back),
    Exercise(id: 'seated_row', name: 'Seated Cable Row', primary: MuscleGroup.back),
    Exercise(id: 'face_pull', name: 'Face Pull', primary: MuscleGroup.back),
    // ---- Shoulders ----
    Exercise(id: 'ohp', name: 'Overhead Press', primary: MuscleGroup.shoulders),
    Exercise(id: 'db_shoulder_press', name: 'Dumbbell Shoulder Press', primary: MuscleGroup.shoulders),
    Exercise(id: 'lateral_raise', name: 'Lateral Raise', primary: MuscleGroup.shoulders),
    Exercise(id: 'rear_delt_fly', name: 'Rear Delt Fly', primary: MuscleGroup.shoulders),
    Exercise(id: 'arnold_press', name: 'Arnold Press', primary: MuscleGroup.shoulders),
    // ---- Biceps ----
    Exercise(id: 'barbell_curl', name: 'Barbell Curl', primary: MuscleGroup.biceps),
    Exercise(id: 'db_curl', name: 'Dumbbell Curl', primary: MuscleGroup.biceps),
    Exercise(id: 'hammer_curl', name: 'Hammer Curl', primary: MuscleGroup.biceps),
    Exercise(id: 'preacher_curl', name: 'Preacher Curl', primary: MuscleGroup.biceps),
    // ---- Triceps ----
    Exercise(id: 'tricep_pushdown', name: 'Tricep Pushdown', primary: MuscleGroup.triceps),
    Exercise(id: 'overhead_ext', name: 'Overhead Tricep Extension', primary: MuscleGroup.triceps),
    Exercise(id: 'skullcrusher', name: 'Skullcrusher', primary: MuscleGroup.triceps),
    Exercise(id: 'close_grip_bench', name: 'Close-Grip Bench Press', primary: MuscleGroup.triceps),
    // ---- Quads ----
    Exercise(id: 'back_squat', name: 'Barbell Back Squat', primary: MuscleGroup.quads),
    Exercise(id: 'front_squat', name: 'Front Squat', primary: MuscleGroup.quads),
    Exercise(id: 'leg_press', name: 'Leg Press', primary: MuscleGroup.quads),
    Exercise(id: 'leg_ext', name: 'Leg Extension', primary: MuscleGroup.quads),
    Exercise(id: 'lunge', name: 'Walking Lunge', primary: MuscleGroup.quads),
    Exercise(id: 'bulgarian_split', name: 'Bulgarian Split Squat', primary: MuscleGroup.quads),
    // ---- Hamstrings / Glutes ----
    Exercise(id: 'rdl', name: 'Romanian Deadlift', primary: MuscleGroup.hamstrings),
    Exercise(id: 'leg_curl', name: 'Leg Curl', primary: MuscleGroup.hamstrings),
    Exercise(id: 'hip_thrust', name: 'Hip Thrust', primary: MuscleGroup.glutes),
    Exercise(id: 'glute_bridge', name: 'Glute Bridge', primary: MuscleGroup.glutes, bodyweight: true),
    // ---- Calves ----
    Exercise(id: 'calf_raise', name: 'Standing Calf Raise', primary: MuscleGroup.calves),
    Exercise(id: 'seated_calf', name: 'Seated Calf Raise', primary: MuscleGroup.calves),
    // ---- Core ----
    Exercise(id: 'plank', name: 'Plank', primary: MuscleGroup.core, bodyweight: true, timed: true),
    Exercise(id: 'hanging_raise', name: 'Hanging Leg Raise', primary: MuscleGroup.core, bodyweight: true),
    Exercise(id: 'cable_crunch', name: 'Cable Crunch', primary: MuscleGroup.core),
    Exercise(id: 'russian_twist', name: 'Russian Twist', primary: MuscleGroup.core, bodyweight: true),
    // ---- Cardio ----
    Exercise(id: 'run', name: 'Running', primary: MuscleGroup.cardio, timed: true, bodyweight: true),
    Exercise(id: 'row_erg', name: 'Rowing Machine', primary: MuscleGroup.cardio, timed: true),
    Exercise(id: 'incline_walk', name: 'Incline Treadmill Walk', primary: MuscleGroup.cardio, timed: true, bodyweight: true),
  ];

  static Exercise? byId(String id) {
    for (final e in all) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Case-insensitive, order-preserving search over the built-in catalogue.
  static List<Exercise> search(String q) {
    final query = q.trim().toLowerCase();
    if (query.isEmpty) return all;
    final starts = <Exercise>[];
    final contains = <Exercise>[];
    for (final e in all) {
      final n = e.name.toLowerCase();
      if (n.startsWith(query)) {
        starts.add(e);
      } else if (n.contains(query)) {
        contains.add(e);
      }
    }
    return [...starts, ...contains];
  }

  // ---- Built-in splits ----
  static const List<WorkoutTemplate> templates = <WorkoutTemplate>[
    WorkoutTemplate(
      id: 'tpl_push',
      name: 'Push Day',
      emoji: '🔥',
      subtitle: 'Chest · Shoulders · Triceps',
      builtIn: true,
      exercises: [
        TemplateExercise('bench_press', 4),
        TemplateExercise('incline_db_press', 3),
        TemplateExercise('ohp', 3),
        TemplateExercise('lateral_raise', 3),
        TemplateExercise('tricep_pushdown', 3),
        TemplateExercise('overhead_ext', 3),
      ],
    ),
    WorkoutTemplate(
      id: 'tpl_pull',
      name: 'Pull Day',
      emoji: '🎯',
      subtitle: 'Back · Biceps · Rear Delts',
      builtIn: true,
      exercises: [
        TemplateExercise('deadlift', 3),
        TemplateExercise('pullup', 3),
        TemplateExercise('barbell_row', 3),
        TemplateExercise('seated_row', 3),
        TemplateExercise('face_pull', 3),
        TemplateExercise('barbell_curl', 3),
      ],
    ),
    WorkoutTemplate(
      id: 'tpl_legs',
      name: 'Leg Day',
      emoji: '🦵',
      subtitle: 'Quads · Hams · Glutes · Calves',
      builtIn: true,
      exercises: [
        TemplateExercise('back_squat', 4),
        TemplateExercise('rdl', 3),
        TemplateExercise('leg_press', 3),
        TemplateExercise('leg_curl', 3),
        TemplateExercise('calf_raise', 4),
      ],
    ),
    WorkoutTemplate(
      id: 'tpl_upper',
      name: 'Upper Body',
      emoji: '💪',
      subtitle: 'Chest · Back · Arms · Shoulders',
      builtIn: true,
      exercises: [
        TemplateExercise('bench_press', 4),
        TemplateExercise('barbell_row', 4),
        TemplateExercise('ohp', 3),
        TemplateExercise('lat_pulldown', 3),
        TemplateExercise('db_curl', 3),
        TemplateExercise('tricep_pushdown', 3),
      ],
    ),
    WorkoutTemplate(
      id: 'tpl_lower',
      name: 'Lower Body',
      emoji: '⚡',
      subtitle: 'Quads · Hams · Glutes',
      builtIn: true,
      exercises: [
        TemplateExercise('back_squat', 4),
        TemplateExercise('rdl', 4),
        TemplateExercise('bulgarian_split', 3),
        TemplateExercise('leg_ext', 3),
        TemplateExercise('calf_raise', 4),
      ],
    ),
    WorkoutTemplate(
      id: 'tpl_full',
      name: 'Full Body',
      emoji: '🏋️',
      subtitle: 'Hit everything',
      builtIn: true,
      exercises: [
        TemplateExercise('back_squat', 3),
        TemplateExercise('bench_press', 3),
        TemplateExercise('barbell_row', 3),
        TemplateExercise('ohp', 3),
        TemplateExercise('barbell_curl', 2),
      ],
    ),
  ];

  static WorkoutTemplate? templateById(String id) {
    for (final t in templates) {
      if (t.id == id) return t;
    }
    return null;
  }

  // ---- Auto-rotating day routines (2 variants each) ----
  // Starting a day gives you the variant you did NOT do last time, so "Push
  // Day" alternates Push A ⇄ Push B — different movements, same muscles.
  static const List<WorkoutDayRoutine> days = <WorkoutDayRoutine>[
    WorkoutDayRoutine(
      id: 'push',
      name: 'Push Day',
      emoji: '🔥',
      subtitle: 'Chest · Shoulders · Triceps',
      variants: [
        WorkoutTemplate(
          id: 'push_a',
          name: 'Push Day',
          emoji: '🔥',
          subtitle: 'Barbell focus',
          builtIn: true,
          exercises: [
            TemplateExercise('bench_press', 4),
            TemplateExercise('incline_db_press', 3),
            TemplateExercise('ohp', 3),
            TemplateExercise('lateral_raise', 3),
            TemplateExercise('tricep_pushdown', 3),
            TemplateExercise('overhead_ext', 3),
          ],
        ),
        WorkoutTemplate(
          id: 'push_b',
          name: 'Push Day',
          emoji: '🔥',
          subtitle: 'Incline & dumbbell focus',
          builtIn: true,
          exercises: [
            TemplateExercise('incline_bench', 4),
            TemplateExercise('db_bench', 3),
            TemplateExercise('db_shoulder_press', 3),
            TemplateExercise('chest_fly', 3),
            TemplateExercise('lateral_raise', 3),
            TemplateExercise('close_grip_bench', 3),
            TemplateExercise('dips', 2),
          ],
        ),
      ],
    ),
    WorkoutDayRoutine(
      id: 'pull',
      name: 'Pull Day',
      emoji: '🎯',
      subtitle: 'Back · Biceps · Rear Delts',
      variants: [
        WorkoutTemplate(
          id: 'pull_a',
          name: 'Pull Day',
          emoji: '🎯',
          subtitle: 'Deadlift & row focus',
          builtIn: true,
          exercises: [
            TemplateExercise('deadlift', 3),
            TemplateExercise('pullup', 3),
            TemplateExercise('barbell_row', 3),
            TemplateExercise('seated_row', 3),
            TemplateExercise('face_pull', 3),
            TemplateExercise('barbell_curl', 3),
          ],
        ),
        WorkoutTemplate(
          id: 'pull_b',
          name: 'Pull Day',
          emoji: '🎯',
          subtitle: 'Pulldown & cable focus',
          builtIn: true,
          exercises: [
            TemplateExercise('lat_pulldown', 4),
            TemplateExercise('chinup', 3),
            TemplateExercise('db_row', 3),
            TemplateExercise('rear_delt_fly', 3),
            TemplateExercise('hammer_curl', 3),
            TemplateExercise('preacher_curl', 3),
          ],
        ),
      ],
    ),
    WorkoutDayRoutine(
      id: 'legs',
      name: 'Leg Day',
      emoji: '🦵',
      subtitle: 'Quads · Hams · Glutes · Calves',
      variants: [
        WorkoutTemplate(
          id: 'legs_a',
          name: 'Leg Day',
          emoji: '🦵',
          subtitle: 'Squat focus',
          builtIn: true,
          exercises: [
            TemplateExercise('back_squat', 4),
            TemplateExercise('rdl', 3),
            TemplateExercise('leg_press', 3),
            TemplateExercise('leg_curl', 3),
            TemplateExercise('calf_raise', 4),
          ],
        ),
        WorkoutTemplate(
          id: 'legs_b',
          name: 'Leg Day',
          emoji: '🦵',
          subtitle: 'Front squat & unilateral',
          builtIn: true,
          exercises: [
            TemplateExercise('front_squat', 4),
            TemplateExercise('bulgarian_split', 3),
            TemplateExercise('leg_ext', 3),
            TemplateExercise('hip_thrust', 3),
            TemplateExercise('lunge', 3),
            TemplateExercise('seated_calf', 4),
          ],
        ),
      ],
    ),
    WorkoutDayRoutine(
      id: 'upper',
      name: 'Upper Body',
      emoji: '💪',
      subtitle: 'Chest · Back · Arms · Shoulders',
      variants: [
        WorkoutTemplate(
          id: 'upper_a',
          name: 'Upper Body',
          emoji: '💪',
          subtitle: 'Barbell focus',
          builtIn: true,
          exercises: [
            TemplateExercise('bench_press', 4),
            TemplateExercise('barbell_row', 4),
            TemplateExercise('ohp', 3),
            TemplateExercise('lat_pulldown', 3),
            TemplateExercise('db_curl', 3),
            TemplateExercise('tricep_pushdown', 3),
          ],
        ),
        WorkoutTemplate(
          id: 'upper_b',
          name: 'Upper Body',
          emoji: '💪',
          subtitle: 'Dumbbell focus',
          builtIn: true,
          exercises: [
            TemplateExercise('incline_db_press', 4),
            TemplateExercise('seated_row', 4),
            TemplateExercise('db_shoulder_press', 3),
            TemplateExercise('pullup', 3),
            TemplateExercise('hammer_curl', 3),
            TemplateExercise('overhead_ext', 3),
          ],
        ),
      ],
    ),
    WorkoutDayRoutine(
      id: 'lower',
      name: 'Lower Body',
      emoji: '⚡',
      subtitle: 'Quads · Hams · Glutes',
      variants: [
        WorkoutTemplate(
          id: 'lower_a',
          name: 'Lower Body',
          emoji: '⚡',
          subtitle: 'Squat focus',
          builtIn: true,
          exercises: [
            TemplateExercise('back_squat', 4),
            TemplateExercise('rdl', 4),
            TemplateExercise('bulgarian_split', 3),
            TemplateExercise('leg_ext', 3),
            TemplateExercise('calf_raise', 4),
          ],
        ),
        WorkoutTemplate(
          id: 'lower_b',
          name: 'Lower Body',
          emoji: '⚡',
          subtitle: 'Hinge & glute focus',
          builtIn: true,
          exercises: [
            TemplateExercise('front_squat', 4),
            TemplateExercise('leg_curl', 4),
            TemplateExercise('hip_thrust', 3),
            TemplateExercise('leg_press', 3),
            TemplateExercise('seated_calf', 4),
          ],
        ),
      ],
    ),
    WorkoutDayRoutine(
      id: 'full',
      name: 'Full Body',
      emoji: '🏋️',
      subtitle: 'Hit everything',
      variants: [
        WorkoutTemplate(
          id: 'full_a',
          name: 'Full Body',
          emoji: '🏋️',
          subtitle: 'Squat & bench',
          builtIn: true,
          exercises: [
            TemplateExercise('back_squat', 3),
            TemplateExercise('bench_press', 3),
            TemplateExercise('barbell_row', 3),
            TemplateExercise('ohp', 3),
            TemplateExercise('barbell_curl', 2),
          ],
        ),
        WorkoutTemplate(
          id: 'full_b',
          name: 'Full Body',
          emoji: '🏋️',
          subtitle: 'Deadlift & press',
          builtIn: true,
          exercises: [
            TemplateExercise('deadlift', 3),
            TemplateExercise('incline_db_press', 3),
            TemplateExercise('lat_pulldown', 3),
            TemplateExercise('db_shoulder_press', 3),
            TemplateExercise('hammer_curl', 2),
          ],
        ),
      ],
    ),
  ];
}
