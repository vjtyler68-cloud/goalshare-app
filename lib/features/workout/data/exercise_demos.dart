/// Lightweight, offline exercise demos — a one-line form cue (and an optional
/// image/GIF URL) so users know what a lift is and how to do it right. Bundled
/// in the binary; graceful fallback (no cue → just the name). Image URLs are
/// optional and rendered with a broken-image fallback, so a demo library of
/// GIFs (wger / ExerciseDB) can be layered in later without any UI change.
class ExerciseDemo {
  final String cue;
  final String? imageUrl;
  const ExerciseDemo(this.cue, {this.imageUrl});
}

class ExerciseDemos {
  ExerciseDemos._();

  static const Map<String, ExerciseDemo> _byName = {
    'romanian deadlift': ExerciseDemo(
        'Soft knees, hinge at the hips, keep the bar close and back flat — feel the stretch in your hamstrings, then squeeze your glutes to stand.'),
    'deadlift': ExerciseDemo(
        'Bar over mid-foot, flat back, brace hard, and drive the floor away — lock out with your glutes, never round the spine.'),
    'barbell squat': ExerciseDemo(
        'Brace your core, sit down between your hips, knees tracking over your toes, and drive up through mid-foot.'),
    'squat': ExerciseDemo(
        'Brace, sit down between your hips, knees over toes, and drive up evenly.'),
    'leg press': ExerciseDemo(
        'Feet shoulder-width, lower until knees hit ~90°, and never let your lower back round off the pad.'),
    'bench press': ExerciseDemo(
        'Shoulder blades pinched, slight arch, lower to mid-chest with elbows ~45°, then press to lockout.'),
    'incline bench press': ExerciseDemo(
        'Same as flat bench but touch the upper chest; keep the elbows tucked around 45°.'),
    'overhead press': ExerciseDemo(
        'Brace, bar over mid-foot, press straight up, and move your head "through the window" at lockout.'),
    'pull up': ExerciseDemo(
        'Start from a full dead hang, pull your chest toward the bar, and control the way down.'),
    'chin up': ExerciseDemo(
        'Underhand grip, dead hang to chest-to-bar, squeeze the biceps and lats, lower slowly.'),
    'lat pulldown': ExerciseDemo(
        'Chest up, pull the bar to your collarbone, squeeze your lats, and control it back up.'),
    'barbell row': ExerciseDemo(
        'Hinge to ~45°, flat back, row to your lower ribs, and squeeze the shoulder blades together.'),
    'seated row': ExerciseDemo(
        'Tall chest, pull to your stomach, squeeze the back — don\'t yank with just your arms.'),
    'bicep curl': ExerciseDemo(
        'Elbows pinned to your sides, curl without swinging, and squeeze hard at the top.'),
    'hammer curl': ExerciseDemo(
        'Neutral (thumbs-up) grip, elbows fixed, curl up and control the descent.'),
    'tricep pushdown': ExerciseDemo(
        'Elbows tucked to your sides, push down to full lockout, and control back up.'),
    'tricep extension': ExerciseDemo(
        'Keep your elbows high and still, get a stretch behind your head, and extend to lockout.'),
    'lateral raise': ExerciseDemo(
        'Slight bend in the elbows, raise to shoulder height leading with the elbows — no swinging.'),
    'shoulder press': ExerciseDemo(
        'Brace your core, press overhead, and don\'t flare your ribs.'),
    'leg curl': ExerciseDemo(
        'Curl your heels toward your glutes, squeeze the hamstrings, and control the way back.'),
    'leg extension': ExerciseDemo(
        'Extend to straight legs, squeeze the quads at the top, and lower slowly.'),
    'calf raise': ExerciseDemo(
        'Full stretch at the bottom, rise all the way onto your toes, and pause at the top.'),
    'lunge': ExerciseDemo(
        'Step out, drop the back knee toward the floor, and drive through your front heel.'),
    'plank': ExerciseDemo(
        'Straight line from head to heels — brace your abs and glutes, and don\'t let your hips sag.'),
    'push up': ExerciseDemo(
        'Keep your body in a straight line, lower to a fist off the floor, elbows ~45°.'),
    'dumbbell press': ExerciseDemo(
        'Lower to chest level, press up and slightly together, and control the negative.'),
    'dumbbell fly': ExerciseDemo(
        'Slight elbow bend, open wide for a chest stretch, then hug back up like a bear hug.'),
    'face pull': ExerciseDemo(
        'Pull to your forehead with high elbows and rotate outward — gold for shoulder health.'),
    'hip thrust': ExerciseDemo(
        'Chin tucked, drive through your heels, and squeeze your glutes hard at the top.'),
    'dip': ExerciseDemo(
        'Lean slightly forward, lower until your upper arms are parallel, and press to lockout.'),
  };

  /// Best-effort match by exercise name (exact, then loose "contains").
  static ExerciseDemo? forName(String name) {
    final n = name.toLowerCase().trim();
    final exact = _byName[n];
    if (exact != null) return exact;
    for (final e in _byName.entries) {
      if (n.contains(e.key)) return e.value;
    }
    return null;
  }
}
