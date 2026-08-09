import 'goflow_models.dart';

/// Phase-tagged encouragement — GoFlow's private take on the Daily Spark /
/// Priming idea. Because cycle phase is intimate, this content is surfaced ONLY
/// inside GoFlow (never pushed into the shared global Daily Spark feed, which
/// could inadvertently signal a user's phase). One line is picked per day,
/// deterministically, so it feels steady rather than random.
class GoFlowContent {
  GoFlowContent._();

  static const Map<GoFlowPhase, List<String>> _byPhase = {
    GoFlowPhase.menstrual: [
      'Rest is productive too. Be gentle with yourself today.',
      'Lower energy is normal now — lean into slow, restorative movement.',
      'Hydrate, keep warm, and give your body what it asks for.',
      'A quiet day is not a wasted day. Recover well.',
    ],
    GoFlowPhase.follicular: [
      'Energy is climbing — a great window to start something new.',
      'Fresh momentum ahead. Set an intention and chase it.',
      'Your body is building up. Channel that into a bold goal.',
      'Rising energy, rising focus — make a plan and move.',
    ],
    GoFlowPhase.ovulatory: [
      'Peak energy and confidence — go do the big thing.',
      'You feel most magnetic now. Take the meeting, make the ask.',
      'High-output window: tackle what needs your best self.',
      'Strong and social today — put yourself out there.',
    ],
    GoFlowPhase.luteal: [
      'Wind-down phase — protect your focus and your peace.',
      'Great time to finish and tidy up rather than start anew.',
      'Cravings and moods can rise now; nourish and pace yourself.',
      'Slow the tempo. Prioritize sleep and simple wins.',
    ],
  };

  /// A stable, once-per-day line for [phase] (rotates by day-of-year so it
  /// changes daily but is the same all day).
  static String sparkFor(GoFlowPhase phase, {DateTime? on}) {
    final list = _byPhase[phase] ?? const ['Keep listening to your body.'];
    final d = on ?? DateTime.now();
    final dayOfYear = d.difference(DateTime(d.year, 1, 1)).inDays;
    return list[dayOfYear % list.length];
  }

  /// Action-oriented daily insights (what to DO), tailored to the phase. Paired
  /// with [sparkFor] on the dashboard — spark is the mindset, this is the move.
  static const Map<GoFlowPhase, List<String>> _dailyActions = {
    GoFlowPhase.menstrual: [
      'Prioritize iron-rich foods and gentle movement like walking or yoga.',
      'Keep hydrated and give yourself permission to rest today.',
      'Warmth helps — a heating pad or warm bath can ease cramps.',
    ],
    GoFlowPhase.follicular: [
      'Energy is building — a good day to start a new workout or project.',
      'Great window for planning and brainstorming; your focus is climbing.',
      'Try strength training — recovery tends to be stronger now.',
    ],
    GoFlowPhase.ovulatory: [
      'Peak energy — schedule your hardest workout or biggest task here.',
      'You may feel most social; put yourself out there today.',
      'Hydrate well and fuel up — you\'re running hot.',
    ],
    GoFlowPhase.luteal: [
      'Wind down intensity; swap HIIT for steady, lower-impact movement.',
      'Magnesium-rich foods and steady blood sugar help with PMS.',
      'Protect your sleep tonight — aim to wind down earlier.',
    ],
  };

  /// One stable action for [phase] today (rotates by day-of-year).
  static String dailyActionFor(GoFlowPhase phase, {DateTime? on}) {
    final list = _dailyActions[phase] ?? const ['Listen to your body today.'];
    final d = on ?? DateTime.now();
    final dayOfYear = d.difference(DateTime(d.year, 1, 1)).inDays;
    return list[dayOfYear % list.length];
  }

  /// A one-line headline for the partner view — what this phase means for
  /// the person supporting.
  static const Map<GoFlowPhase, String> partnerHeadline = {
    GoFlowPhase.menstrual: 'She may have lower energy — comfort and patience go far.',
    GoFlowPhase.follicular: 'Energy is rising — a great time to plan and do things together.',
    GoFlowPhase.ovulatory: 'She likely feels her best — be present and match the energy.',
    GoFlowPhase.luteal: 'Moods and cravings can rise — extra patience and small gestures help.',
  };

  /// Concrete "how to show up" tips for the partner, per phase.
  static const Map<GoFlowPhase, List<String>> partnerTips = {
    GoFlowPhase.menstrual: [
      'Offer warmth: a heating pad, tea, or a cozy night in.',
      'Take chores off her plate without being asked.',
      'Keep plans low-key and flexible.',
    ],
    GoFlowPhase.follicular: [
      'Say yes to new ideas — she may want to start things.',
      'Plan a fun outing or date; energy is climbing.',
      'Be a sounding board for her goals this week.',
    ],
    GoFlowPhase.ovulatory: [
      'Make time for connection — she likely feels most social.',
      'Be affectionate and present.',
      'Great week for a special date or big conversation.',
    ],
    GoFlowPhase.luteal: [
      'Lead with patience; don\'t take mood shifts personally.',
      'Have her favorite snacks on hand.',
      'Small, steady reassurance beats grand gestures now.',
    ],
  };

  /// Supportive tips for a partner when the person they follow is pregnant.
  static const List<String> partnerPregnancyTips = [
    'Offer to take chores and errands off her plate as energy shifts.',
    'Go to prenatal appointments together whenever you can.',
    'Keep her favorite snacks stocked — cravings and nausea come and go.',
    'Lead with patience and reassurance; hormones and fatigue are real.',
    'Ask how she\'s feeling today, and really listen.',
  ];

  static String partnerTipOfDay(GoFlowPhase phase, {DateTime? on}) {
    final list = partnerTips[phase] ?? const ['Be present and patient.'];
    final d = on ?? DateTime.now();
    final dayOfYear = d.difference(DateTime(d.year, 1, 1)).inDays;
    return list[dayOfYear % list.length];
  }
}
