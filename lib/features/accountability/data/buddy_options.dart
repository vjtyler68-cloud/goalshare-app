/// A stored value paired with the label shown in the UI. The [value] is what we
/// persist / send for matching (stable, never localise it); [label] is display
/// only and can be reworded freely.
class BuddyChoice {
  final String value;
  final String label;
  const BuddyChoice(this.value, this.label);
}

/// Single source of truth for every questionnaire option set + the rotating
/// supportive check-in prompts. Kept separate from the widgets so the same lists
/// feed the form, the match screen, and (later) the backend matcher.
class BuddyOptions {
  BuddyOptions._();

  // ── Goals & Focus ─────────────────────────────────────────────────────────
  static const List<String> focusAreas = [
    'Fitness',
    'Finances',
    'Faith',
    'Career/Sales',
    'Mindset',
    'Relationships',
  ];

  static const List<BuddyChoice> genders = [
    BuddyChoice('Male', 'Male'),
    BuddyChoice('Female', 'Female'),
    BuddyChoice('Unspecified', 'Prefer not to say'),
  ];

  // ── Accountability Style ──────────────────────────────────────────────────
  static const List<BuddyChoice> checkInFrequency = [
    BuddyChoice('Daily', 'Daily'),
    BuddyChoice('EveryOtherDay', 'Every other day'),
    BuddyChoice('TwoToThreeWeek', '2–3× per week'),
  ];

  static const List<BuddyChoice> checkInFormat = [
    BuddyChoice('Text', 'Text'),
    BuddyChoice('VoiceNotes', 'Voice notes'),
    BuddyChoice('PhotoProof', 'Photo proof'),
    BuddyChoice('AppActivityOnly', 'App activity only'),
  ];

  static const List<BuddyChoice> motivationStyle = [
    BuddyChoice('Encouragement', 'Encouragement'),
    BuddyChoice('ToughLove', 'Tough love'),
    BuddyChoice('Competition', 'Friendly competition'),
  ];

  static const List<BuddyChoice> activeTimeOfDay = [
    BuddyChoice('Morning', 'Morning'),
    BuddyChoice('Afternoon', 'Afternoon'),
    BuddyChoice('Evening', 'Evening'),
    BuddyChoice('NightOwl', 'Night owl'),
  ];

  static const List<BuddyChoice> missedCheckInPreference = [
    BuddyChoice('GentleNudge', 'Gentle nudge'),
    BuddyChoice('DirectCallOut', 'Call me out directly'),
    BuddyChoice('DontMind', "Don't mind"),
    BuddyChoice('RatherNotPushed', 'Rather not be pushed'),
  ];

  // ── Logistics / Comfort ───────────────────────────────────────────────────
  static const List<BuddyChoice> genderPreference = [
    BuddyChoice('NoPreference', 'No preference'),
    BuddyChoice('SameGenderOnly', 'Same gender only'),
  ];

  static const List<BuddyChoice> extendPreference = [
    BuddyChoice('Yes', 'Yes'),
    BuddyChoice('No', 'No'),
    BuddyChoice('LetsSee', "Let's see"),
  ];

  static const List<BuddyChoice> earlyBirdOrNightOwl = [
    BuddyChoice('EarlyBird', '🌅 Early bird'),
    BuddyChoice('NightOwl', '🌙 Night owl'),
  ];

  /// Friendly label for a stored value across any of the sets above (falls back
  /// to the raw value so nothing ever renders blank).
  static String labelFor(List<BuddyChoice> set, String value) {
    for (final c in set) {
      if (c.value == value) return c.label;
    }
    return value;
  }

  /// Rotating "really good questions" — the heart of a supportive check-in.
  /// The match screen surfaces one per day so buddies always have a meaningful
  /// prompt to open with instead of a dry "did you do it?".
  static const List<String> checkInPrompts = [
    'What’s one win — big or small — you had since we last talked?',
    'What’s the ONE thing that would make today a success?',
    'Where did you get stuck this week, and what would help you get unstuck?',
    'On a scale of 1–10, how’s your energy today? What’s driving that number?',
    'What’s a promise you made to yourself that you kept?',
    'What’s one thing you’ve been avoiding? What’s the smallest first step?',
    'What did you learn about yourself this week?',
    'What’s working right now that you want to keep doing?',
    'If you could redo one moment this week, what would you change?',
    'What are you most proud of right now?',
    'What’s one obstacle in your way, and how can I help you clear it?',
    'What does your day look like tomorrow? Where might you slip?',
    'What’s something good that happened that you almost overlooked?',
    'What boundary do you need to protect your goals this week?',
    'Who are you becoming through this — and are you proud of that person?',
    'What’s one small habit you can stack onto something you already do?',
    'What would “showing up for yourself” look like today?',
    'What’s draining you, and what’s filling you back up?',
    'What’s the next right step — not the whole staircase, just the next step?',
    'What do you need from me this week: a push, a cheer, or just an ear?',
    'What did you do today that your future self will thank you for?',
    'What story are you telling yourself that might not be true?',
    'What’s a goal you can shrink so it feels doable again?',
    'End the day with a win: what’s one thing you’ll finish before bed?',
  ];

  /// A stable prompt for a given day so both buddies see the same question and
  /// it changes daily without any randomness that would break widget tests.
  static String promptForDay(DateTime day) {
    final index = (day.year * 372 + day.month * 31 + day.day) %
        checkInPrompts.length;
    return checkInPrompts[index];
  }
}
