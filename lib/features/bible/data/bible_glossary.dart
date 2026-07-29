/// Offline plain-English glossary for the Bible reader.
///
/// KJV language is full of archaic words (thee, hath, begat) and heavy
/// theological terms (propitiation, sanctify). This bundled dictionary lets a
/// reader tap a verse and see simple meanings — no network, no cost. Same
/// philosophy as common_foods.dart: ships in the binary, works fully offline.
class BibleGlossary {
  BibleGlossary._();

  /// word (lowercase) -> plain-English meaning.
  static const Map<String, String> terms = {
    // ── Archaic pronouns & verb forms ──
    'thee': 'you (to one person)',
    'thou': 'you (the one being spoken to)',
    'thy': 'your',
    'thine': 'yours (or "your", before a vowel)',
    'ye': 'you (more than one person)',
    'hast': 'have ("you have")',
    'hath': 'has',
    'doth': 'does',
    'dost': 'do ("you do")',
    'art': 'are ("you are")',
    'wast': 'was ("you were")',
    'wilt': 'will ("you will")',
    'shalt': 'shall / will ("you shall")',
    'canst': 'can ("you can")',
    'saith': 'says',
    'sayeth': 'says',
    'cometh': 'comes',
    'goeth': 'goes',
    'giveth': 'gives',
    'maketh': 'makes',
    'unto': 'to',
    'whither': 'to where',
    'thence': 'from there',
    'hence': 'from here / from now',
    'hither': 'to here',
    'wherefore': 'why / therefore',
    'whence': 'from where',
    'verily': 'truly / for sure',
    'behold': 'look / pay attention',
    'lo': 'look / see',
    'nigh': 'near / close',
    'yea': 'yes / indeed',
    'nay': 'no',
    'peradventure': 'perhaps / maybe',
    'suffer': 'allow / let (in older English)',
    'begat': 'became the father of',
    'brethren': 'brothers / fellow believers',
    'raiment': 'clothing',
    'countenance': 'face / expression',
    'firmament': 'the sky / the heavens',
    'tarry': 'wait / stay',
    'smite': 'to strike or hit hard',
    'rent': 'torn',
    'wroth': 'very angry',

    // ── Core theological terms ──
    'grace': 'God\'s undeserved love and kindness given freely',
    'mercy': 'kindness and forgiveness instead of the punishment deserved',
    'righteous': 'living rightly / being right with God',
    'righteousness': 'right living; being made right with God',
    'covenant': 'a binding promise or agreement between God and people',
    'atonement': 'making things right between God and people; repairing the relationship',
    'redemption': 'being bought back and set free',
    'redeem': 'to buy back and set free',
    'repent': 'to turn away from wrong and change direction',
    'repentance': 'a genuine change of heart, turning from wrong to God',
    'salvation': 'being rescued and saved by God',
    'sanctify': 'to make holy / set apart for God',
    'holy': 'set apart, pure, belonging to God',
    'gospel': 'the good news of Jesus',
    'covet': 'to crave what belongs to someone else',
    'iniquity': 'deep wrongdoing / sin',
    'transgression': 'breaking a law or command',
    'trespass': 'a wrong done against someone',
    'sin': 'falling short of God\'s standard; doing wrong',
    'propitiation': 'the sacrifice that satisfies justice and turns away wrath',
    'justification': 'being declared "not guilty" and right before God',
    'reconcile': 'to restore a broken relationship',
    'blessed': 'happy and favored by God',
    'blessing': 'God\'s favor and good gifts',
    'forsake': 'to abandon or leave behind',
    'wrath': 'strong, righteous anger',
    'glorify': 'to honor and give great praise',
    'glory': 'greatness, honor, and shining presence',
    'hallowed': 'honored as holy',
    'meek': 'gentle and humble, strength under control',
    'humble': 'not proud; modest',
    'faith': 'trust and confidence in God',
    'mediator': 'a go-between who brings two sides together',
    'disciple': 'a follower and student',
    'apostle': 'one sent out with a mission (esp. Jesus\' messengers)',
    'prophet': 'someone who speaks God\'s message',
    'gentile': 'a person who is not Jewish',
    'covenanted': 'made a binding promise',
    'testament': 'a covenant or will/agreement',
    'parable': 'a short story that teaches a spiritual lesson',
    'psalm': 'a sacred song or poem',
    'manna': 'the bread God gave Israel in the desert',
    'altar': 'a raised place for offering sacrifices to God',
    'sacrifice': 'an offering given to God, often at a cost',
    'offering': 'something given to God in worship',
    'tithe': 'giving a tenth of what you earn to God',
    'sabbath': 'the weekly day of rest set apart for God',
    'anoint': 'to pour oil on someone to set them apart for God',
    'anointed': 'set apart by God (the word "Messiah/Christ" means this)',
    'messiah': 'the promised Savior ("the Anointed One")',
    'begotten': 'born of / brought forth (uniquely God\'s own)',
    'everlasting': 'lasting forever',
    'eternal': 'without beginning or end; forever',
    'perish': 'to be destroyed or die',
    'condemn': 'to declare guilty and deserving punishment',
    'condemnation': 'the guilty verdict and its penalty',
    'intercession': 'praying or pleading on behalf of someone else',
    'abide': 'to stay, remain, and live in',
    'exalt': 'to lift high and honor',
    'rebuke': 'to sharply correct',
    'contrite': 'deeply sorry for wrong; humbled',
    'steadfast': 'firm, loyal, and unchanging',
    'yoke': 'a wooden bar joining oxen; a picture of a burden or partnership',
    'vine': 'a grape plant; a picture of staying connected to Jesus',
    'shepherd': 'one who guides and protects the sheep (a picture of God caring for people)',
    'flesh': 'human nature, often the weak or sinful side of us',
    'spirit': 'the non-physical part of a person; also the Holy Spirit',
  };

  /// Notable words in a verse that appear in the glossary, in reading order,
  /// de-duplicated. Handles capitalisation, punctuation, and simple plurals.
  static List<MapEntry<String, String>> termsIn(String verseText) {
    final seen = <String>{};
    final out = <MapEntry<String, String>>[];
    for (final raw in verseText.split(RegExp(r'[^A-Za-z]+'))) {
      if (raw.isEmpty) continue;
      final w = raw.toLowerCase();
      if (seen.contains(w)) continue;
      seen.add(w);
      final def = terms[w] ?? (w.endsWith('s') ? terms[w.substring(0, w.length - 1)] : null);
      if (def != null) out.add(MapEntry(_titleCase(raw), def));
    }
    return out;
  }

  static String _titleCase(String w) =>
      w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
}
