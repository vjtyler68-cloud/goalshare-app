/// Real exercise photos, straight from the internet — no API key, no cost.
///
/// Source: the open **free-exercise-db** (yuhonas/free-exercise-db), served over
/// the jsDelivr CDN. Every exercise has two frames — `0.jpg` (start position)
/// and `1.jpg` (end position) — so we can show the actual movement, not just a
/// static pose. Images are cached on-device after first load (CachedNetworkImage).
///
/// Lookups are by the built-in exercise **id** first (exact, reliable), then by
/// a loose **name** match so user-created exercises ("Flat Bench Press", "Squat")
/// still resolve. A miss returns null and the UI simply shows no photo.
class ExerciseImages {
  ExerciseImages._();

  static const String _base =
      'https://cdn.jsdelivr.net/gh/yuhonas/free-exercise-db@main/exercises';

  /// Built-in library id → free-exercise-db folder. Verified to exist (both
  /// 0.jpg and 1.jpg present) at build time.
  static const Map<String, String> _byId = {
    'bench_press': 'Barbell_Bench_Press_-_Medium_Grip',
    'incline_bench': 'Barbell_Incline_Bench_Press_-_Medium_Grip',
    'db_bench': 'Dumbbell_Bench_Press',
    'incline_db_press': 'Incline_Dumbbell_Press',
    'chest_fly': 'Cable_Crossover',
    'pushup': 'Pushups',
    'dips': 'Dips_-_Chest_Version',
    'deadlift': 'Barbell_Deadlift',
    'pullup': 'Pullups',
    'chinup': 'Chin-Up',
    'lat_pulldown': 'Wide-Grip_Lat_Pulldown',
    'barbell_row': 'Bent_Over_Barbell_Row',
    'db_row': 'One-Arm_Dumbbell_Row',
    'seated_row': 'Seated_Cable_Rows',
    'face_pull': 'Face_Pull',
    'ohp': 'Standing_Military_Press',
    'db_shoulder_press': 'Dumbbell_Shoulder_Press',
    'lateral_raise': 'Side_Lateral_Raise',
    'rear_delt_fly': 'Reverse_Flyes',
    'arnold_press': 'Arnold_Dumbbell_Press',
    'barbell_curl': 'Barbell_Curl',
    'db_curl': 'Dumbbell_Bicep_Curl',
    'hammer_curl': 'Hammer_Curls',
    'preacher_curl': 'Cable_Preacher_Curl',
    'tricep_pushdown': 'Triceps_Pushdown',
    'overhead_ext': 'Standing_Dumbbell_Triceps_Extension',
    'skullcrusher': 'Lying_Triceps_Press',
    'close_grip_bench': 'Close-Grip_Barbell_Bench_Press',
    'back_squat': 'Barbell_Squat',
    'front_squat': 'Front_Barbell_Squat',
    'leg_press': 'Leg_Press',
    'leg_ext': 'Leg_Extensions',
    'lunge': 'Barbell_Walking_Lunge',
    'bulgarian_split': 'Split_Squat_with_Dumbbells',
    'rdl': 'Romanian_Deadlift',
    'leg_curl': 'Lying_Leg_Curls',
    'hip_thrust': 'Barbell_Hip_Thrust',
    'glute_bridge': 'Butt_Lift_Bridge',
    'calf_raise': 'Standing_Calf_Raises',
    'seated_calf': 'Barbell_Seated_Calf_Raise',
    'plank': 'Plank',
    'hanging_raise': 'Hanging_Leg_Raise',
    'cable_crunch': 'Cable_Crunch',
    'russian_twist': 'Cable_Russian_Twists',
    'run': 'Running_Treadmill',
    'row_erg': 'Rowing_Stationary',
    'incline_walk': 'Walking_Treadmill',
  };

  /// Loose name → folder, for user-created exercises. ORDER MATTERS: more
  /// specific phrases come before generic ones, and the first `contains` match
  /// wins (so "romanian deadlift" beats "deadlift", "front squat" beats "squat").
  static const Map<String, String> _alias = {
    'romanian deadlift': 'Romanian_Deadlift',
    'stiff leg deadlift': 'Romanian_Deadlift',
    'deadlift': 'Barbell_Deadlift',
    'incline dumbbell': 'Incline_Dumbbell_Press',
    'incline bench': 'Barbell_Incline_Bench_Press_-_Medium_Grip',
    'close-grip bench': 'Close-Grip_Barbell_Bench_Press',
    'close grip bench': 'Close-Grip_Barbell_Bench_Press',
    'dumbbell bench': 'Dumbbell_Bench_Press',
    'bench press': 'Barbell_Bench_Press_-_Medium_Grip',
    'chest fly': 'Cable_Crossover',
    'chest dip': 'Dips_-_Chest_Version',
    'push-up': 'Pushups',
    'push up': 'Pushups',
    'pushup': 'Pushups',
    'front squat': 'Front_Barbell_Squat',
    'bulgarian split squat': 'Split_Squat_with_Dumbbells',
    'split squat': 'Split_Squat_with_Dumbbells',
    'squat': 'Barbell_Squat',
    'hammer curl': 'Hammer_Curls',
    'preacher curl': 'Cable_Preacher_Curl',
    'barbell curl': 'Barbell_Curl',
    'curl': 'Dumbbell_Bicep_Curl',
    'lateral raise': 'Side_Lateral_Raise',
    'rear delt': 'Reverse_Flyes',
    'arnold press': 'Arnold_Dumbbell_Press',
    'overhead press': 'Standing_Military_Press',
    'shoulder press': 'Dumbbell_Shoulder_Press',
    'skullcrusher': 'Lying_Triceps_Press',
    'overhead tricep': 'Standing_Dumbbell_Triceps_Extension',
    'tricep extension': 'Standing_Dumbbell_Triceps_Extension',
    'pushdown': 'Triceps_Pushdown',
    'pull-up': 'Pullups',
    'pull up': 'Pullups',
    'pullup': 'Pullups',
    'chin': 'Chin-Up',
    'pulldown': 'Wide-Grip_Lat_Pulldown',
    'face pull': 'Face_Pull',
    'seated cable row': 'Seated_Cable_Rows',
    'dumbbell row': 'One-Arm_Dumbbell_Row',
    'row': 'Bent_Over_Barbell_Row',
    'leg press': 'Leg_Press',
    'leg extension': 'Leg_Extensions',
    'leg ext': 'Leg_Extensions',
    'leg curl': 'Lying_Leg_Curls',
    'walking lunge': 'Barbell_Walking_Lunge',
    'lunge': 'Barbell_Walking_Lunge',
    'hip thrust': 'Barbell_Hip_Thrust',
    'glute bridge': 'Butt_Lift_Bridge',
    'calf raise': 'Standing_Calf_Raises',
    'calf': 'Standing_Calf_Raises',
    'plank': 'Plank',
    'hanging leg raise': 'Hanging_Leg_Raise',
    'leg raise': 'Hanging_Leg_Raise',
    'cable crunch': 'Cable_Crunch',
    'crunch': 'Cable_Crunch',
    'russian twist': 'Cable_Russian_Twists',
    'rowing': 'Rowing_Stationary',
    'treadmill': 'Running_Treadmill',
    'running': 'Running_Treadmill',
  };

  /// Resolve a folder for an exercise by id (preferred) then loose name.
  static String? folderFor({String? id, String? name}) {
    if (id != null) {
      final f = _byId[id];
      if (f != null) return f;
    }
    if (name != null) {
      final n = name.toLowerCase().trim();
      for (final e in _alias.entries) {
        if (n.contains(e.key)) return e.value;
      }
    }
    return null;
  }

  /// Does this exercise have real photos?
  static bool has({String? id, String? name}) =>
      folderFor(id: id, name: name) != null;

  /// URL for one frame (0 = start, 1 = end).
  static String frameUrl(String folder, int frame) => '$_base/$folder/$frame.jpg';

  /// The start-position photo URL, or null. Handy for a card thumbnail.
  static String? startUrl({String? id, String? name}) {
    final f = folderFor(id: id, name: name);
    return f == null ? null : frameUrl(f, 0);
  }

  /// Both frames [start, end] for an animated demo, or empty on a miss.
  static List<String> frames({String? id, String? name}) {
    final f = folderFor(id: id, name: name);
    if (f == null) return const [];
    return [frameUrl(f, 0), frameUrl(f, 1)];
  }
}
