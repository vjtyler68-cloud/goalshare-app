/// Week-by-week pregnancy content + a small gestational-age calculator. All
/// educational and general — not medical advice.

class PregnancyWeek {
  final int week;
  final String size; // fruit/object comparison
  final String development; // what's developing
  final String forYou; // body change / tip for the mother
  const PregnancyWeek(this.week, this.size, this.development, this.forYou);
}

class PregnancyStatus {
  final int week; // 1-based current gestational week (clamped 1..42)
  final int daysIntoWeek; // 0..6
  final DateTime dueDate;
  final int daysUntilDue;
  final int trimester; // 1, 2, or 3
  const PregnancyStatus({
    required this.week,
    required this.daysIntoWeek,
    required this.dueDate,
    required this.daysUntilDue,
    required this.trimester,
  });

  double get progress => (week / 40).clamp(0.0, 1.0);
  String get trimesterLabel => switch (trimester) {
        1 => 'First trimester',
        2 => 'Second trimester',
        _ => 'Third trimester',
      };
}

class GoFlowPregnancy {
  GoFlowPregnancy._();

  /// Gestational status from the last-menstrual-period anchor.
  static PregnancyStatus statusFrom(DateTime lmp, {DateTime? on}) {
    final now = on ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(lmp.year, lmp.month, lmp.day);
    final days = today.difference(start).inDays;
    final safeDays = days < 0 ? 0 : days;
    final week = (safeDays ~/ 7) + 1;
    final clampedWeek = week.clamp(1, 42);
    final due = start.add(const Duration(days: 280));
    final trimester = clampedWeek <= 13
        ? 1
        : clampedWeek <= 27
            ? 2
            : 3;
    return PregnancyStatus(
      week: clampedWeek,
      daysIntoWeek: safeDays % 7,
      dueDate: due,
      daysUntilDue: due.difference(today).inDays,
      trimester: trimester,
    );
  }

  static PregnancyWeek forWeek(int week) {
    final w = week.clamp(4, 40);
    return _weeks[w] ?? _weeks[w.clamp(4, 40)] ?? _weeks[8]!;
  }

  static const Map<int, PregnancyWeek> _weeks = {
    4: PregnancyWeek(4, 'a poppy seed',
        'The embryo implants and the placenta begins to form.',
        'You may notice a missed period — a good time to confirm with a test.'),
    5: PregnancyWeek(5, 'a sesame seed',
        'The neural tube (brain & spine) starts developing.',
        'Early symptoms like fatigue and tender breasts can begin.'),
    6: PregnancyWeek(6, 'a lentil',
        'A tiny heart begins to beat and limb buds appear.',
        'Morning sickness may start; small frequent meals help.'),
    7: PregnancyWeek(7, 'a blueberry',
        'Hands and feet are forming; the brain is growing fast.',
        'Extra bathroom trips are normal — stay hydrated anyway.'),
    8: PregnancyWeek(8, 'a raspberry',
        'Fingers, toes, and facial features are taking shape.',
        'Your first prenatal visit is usually around now.'),
    9: PregnancyWeek(9, 'a cherry',
        'The embryo is now a fetus; tiny muscles are forming.',
        'Mood swings from hormones are common — be kind to yourself.'),
    10: PregnancyWeek(10, 'a strawberry',
        'Vital organs are in place and starting to function.',
        'Cravings or aversions may appear; follow what feels right.'),
    11: PregnancyWeek(11, 'a fig',
        'The baby can open and close tiny fists.',
        'Nausea often begins to ease over the next few weeks.'),
    12: PregnancyWeek(12, 'a lime',
        'Reflexes develop; the baby can move, though you can\'t feel it yet.',
        'End of the first trimester — energy often returns soon.'),
    13: PregnancyWeek(13, 'a pea pod',
        'Vocal cords and tiny fingerprints are forming.',
        'You may start to feel more like yourself again.'),
    14: PregnancyWeek(14, 'a lemon',
        'The baby can squint, frown, and make facial expressions.',
        'Second trimester begins — often the most comfortable stretch.'),
    15: PregnancyWeek(15, 'an apple',
        'Bones are hardening and the baby is sensing light.',
        'A gentle skin-care and stretching routine can ease changes.'),
    16: PregnancyWeek(16, 'an avocado',
        'Tiny bones in the ears form — the baby may hear you.',
        'Some feel the first flutters ("quickening") around now.'),
    17: PregnancyWeek(17, 'a turnip',
        'Fat stores begin to develop under the skin.',
        'Sleeping on your side becomes more comfortable.'),
    18: PregnancyWeek(18, 'a bell pepper',
        'The baby is yawning, hiccupping, and moving a lot.',
        'Your anatomy scan is often scheduled around this time.'),
    19: PregnancyWeek(19, 'a mango',
        'A protective coating (vernix) covers the skin.',
        'Round-ligament aches are common as the belly grows.'),
    20: PregnancyWeek(20, 'a banana',
        'Halfway there — the baby is swallowing and building taste.',
        'You may feel steady movement now; note the patterns.'),
    21: PregnancyWeek(21, 'a carrot',
        'The baby\'s movements grow stronger and more regular.',
        'Stay active with walks or prenatal yoga as you feel able.'),
    22: PregnancyWeek(22, 'a spaghetti squash',
        'Senses are sharpening; the baby responds to sound.',
        'Talking or singing to your belly is a lovely habit to start.'),
    23: PregnancyWeek(23, 'a large mango',
        'Lungs are developing in preparation for breathing.',
        'Watch for swelling; elevate your feet when you can.'),
    24: PregnancyWeek(24, 'an ear of corn',
        'The baby reaches viability; skin is becoming less translucent.',
        'A glucose screening for gestational diabetes is often near.'),
    25: PregnancyWeek(25, 'a rutabaga',
        'The baby is putting on baby fat and hair is growing.',
        'Practice good posture as your center of gravity shifts.'),
    26: PregnancyWeek(26, 'a head of lettuce',
        'Eyes begin to open and respond to light.',
        'Start thinking about a birth plan and childbirth classes.'),
    27: PregnancyWeek(27, 'a cauliflower',
        'Brain activity ramps up; the baby has sleep cycles.',
        'End of the second trimester — rest when your body asks.'),
    28: PregnancyWeek(28, 'an eggplant',
        'The baby can blink and dream (REM sleep).',
        'Third trimester begins; prenatal visits get more frequent.'),
    29: PregnancyWeek(29, 'a butternut squash',
        'Muscles and lungs continue to mature.',
        'Kick counts help you tune into the baby\'s normal patterns.'),
    30: PregnancyWeek(30, 'a large cabbage',
        'The brain is growing rapidly and taking on folds.',
        'Heartburn and shortness of breath are common — eat smaller meals.'),
    31: PregnancyWeek(31, 'a coconut',
        'The baby can process information and track light.',
        'Begin gathering newborn essentials if you haven\'t.'),
    32: PregnancyWeek(32, 'a squash',
        'Practice breathing movements; toenails are fully formed.',
        'Braxton Hicks (practice contractions) may increase.'),
    33: PregnancyWeek(33, 'a pineapple',
        'The immune system is developing; bones harden (skull stays soft).',
        'Pack thoughts for a hospital bag as your date nears.'),
    34: PregnancyWeek(34, 'a cantaloupe',
        'Lungs are nearly ready; the baby often settles head-down.',
        'Discuss signs of labor with your provider.'),
    35: PregnancyWeek(35, 'a honeydew melon',
        'Rapid weight gain; the baby is filling out the womb.',
        'Rest often — fatigue returns in the home stretch.'),
    36: PregnancyWeek(36, 'a head of romaine',
        'The baby is likely head-down, getting into position.',
        'Weekly checkups usually begin around now.'),
    37: PregnancyWeek(37, 'a bunch of chard',
        'Considered early-term; the baby practices breathing and sucking.',
        'Finalize your birth and support plans.'),
    38: PregnancyWeek(38, 'a leek',
        'The baby has a firm grasp and organs are ready.',
        'Watch for labor signs; keep your bag and contacts handy.'),
    39: PregnancyWeek(39, 'a mini watermelon',
        'Full term — the baby continues adding a little fat.',
        'Rest, hydrate, and note any regular contractions.'),
    40: PregnancyWeek(40, 'a small pumpkin',
        'Your due date! Babies arrive on their own schedule.',
        'Stay in close touch with your provider about next steps.'),
  };
}
