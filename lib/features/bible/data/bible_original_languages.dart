/// Optional Greek & Hebrew word study for the Bible reader.
///
/// A curated, offline map of key biblical concepts to their original-language
/// words (with transliteration + plain meaning). This is a concept-level study
/// aid — not a full interlinear — so a reader who turns it on can see, e.g.,
/// that "love" in the New Testament is often ἀγάπη (agapē). Bundled in the
/// binary; no network, no cost. Shown only when the user opts in.

class OriginalWord {
  final String lang; // 'Greek' | 'Hebrew'
  final String word; // native script
  final String translit;
  final String meaning;
  const OriginalWord(this.lang, this.word, this.translit, this.meaning);
}

class BibleOriginalLanguages {
  BibleOriginalLanguages._();

  static const Map<String, List<OriginalWord>> byConcept = {
    'love': [
      OriginalWord('Greek', 'ἀγάπη', 'agapē',
          'selfless, unconditional love — the love God has for us'),
      OriginalWord(
          'Greek', 'φιλία', 'philia', 'warm friendship / brotherly affection'),
      OriginalWord('Hebrew', 'אַהֲבָה', 'ahavah', 'love, affection'),
    ],
    'grace': [
      OriginalWord('Greek', 'χάρις', 'charis',
          'grace — undeserved favor and kindness'),
      OriginalWord('Hebrew', 'חֵן', 'chen', 'favor, grace'),
    ],
    'faith': [
      OriginalWord('Greek', 'πίστις', 'pistis', 'faith, trust, confidence'),
      OriginalWord('Hebrew', 'אֱמוּנָה', 'emunah', 'faithfulness, steady trust'),
    ],
    'peace': [
      OriginalWord('Hebrew', 'שָׁלוֹם', 'shalom',
          'peace — wholeness, completeness, well-being'),
      OriginalWord('Greek', 'εἰρήνη', 'eirēnē', 'peace'),
    ],
    'spirit': [
      OriginalWord('Hebrew', 'רוּחַ', 'ruach', 'spirit, breath, wind'),
      OriginalWord('Greek', 'πνεῦμα', 'pneuma', 'spirit, breath'),
    ],
    'word': [
      OriginalWord('Greek', 'λόγος', 'logos',
          'word, reason — the divine Word (John 1)'),
      OriginalWord('Hebrew', 'דָּבָר', 'davar', 'word, matter, thing'),
    ],
    'holy': [
      OriginalWord('Hebrew', 'קָדוֹשׁ', 'qadosh', 'holy, set apart'),
      OriginalWord('Greek', 'ἅγιος', 'hagios', 'holy, set apart'),
    ],
    'glory': [
      OriginalWord('Hebrew', 'כָּבוֹד', 'kavod', 'glory, weight, honor'),
      OriginalWord('Greek', 'δόξα', 'doxa', 'glory, splendor'),
    ],
    'lord': [
      OriginalWord(
          'Hebrew', 'יְהוָה', 'YHWH', "the LORD — God's covenant name"),
      OriginalWord('Hebrew', 'אֲדֹנָי', 'Adonai', 'Lord, Master'),
      OriginalWord('Greek', 'κύριος', 'kyrios', 'Lord, master'),
    ],
    'god': [
      OriginalWord('Hebrew', 'אֱלֹהִים', 'Elohim', 'God, the Creator'),
      OriginalWord('Hebrew', 'אֵל', 'El', 'God, Mighty One'),
      OriginalWord('Greek', 'θεός', 'theos', 'God'),
    ],
    'mercy': [
      OriginalWord('Hebrew', 'חֶסֶד', 'chesed',
          'steadfast love, loyal covenant mercy'),
      OriginalWord('Greek', 'ἔλεος', 'eleos', 'mercy, compassion'),
    ],
    'righteousness': [
      OriginalWord('Hebrew', 'צֶדֶק', 'tsedeq', 'righteousness, justice'),
      OriginalWord('Greek', 'δικαιοσύνη', 'dikaiosynē', 'righteousness'),
    ],
    'sin': [
      OriginalWord(
          'Hebrew', 'חַטָּאת', "chatta'ath", 'sin — to miss the mark'),
      OriginalWord(
          'Greek', 'ἁμαρτία', 'hamartia', 'sin — missing the mark'),
    ],
    'soul': [
      OriginalWord('Hebrew', 'נֶפֶשׁ', 'nephesh', 'soul, life, living being'),
      OriginalWord('Greek', 'ψυχή', 'psychē', 'soul, life'),
    ],
    'heart': [
      OriginalWord(
          'Hebrew', 'לֵב', 'lev', 'heart — mind, will, inner self'),
      OriginalWord('Greek', 'καρδία', 'kardia', 'heart'),
    ],
    'life': [
      OriginalWord('Hebrew', 'חַיִּים', 'chayyim', 'life'),
      OriginalWord(
          'Greek', 'ζωή', 'zōē', 'life — especially eternal life'),
    ],
    'light': [
      OriginalWord('Hebrew', 'אוֹר', 'or', 'light'),
      OriginalWord('Greek', 'φῶς', 'phōs', 'light'),
    ],
    'truth': [
      OriginalWord('Hebrew', 'אֱמֶת', 'emet', 'truth, faithfulness'),
      OriginalWord('Greek', 'ἀλήθεια', 'alētheia', 'truth'),
    ],
    'salvation': [
      OriginalWord(
          'Hebrew', 'יְשׁוּעָה', 'yeshuah', 'salvation, deliverance'),
      OriginalWord('Greek', 'σωτηρία', 'sōtēria', 'salvation'),
    ],
    'covenant': [
      OriginalWord(
          'Hebrew', 'בְּרִית', 'berith', 'covenant, binding agreement'),
      OriginalWord(
          'Greek', 'διαθήκη', 'diathēkē', 'covenant, testament'),
    ],
    'blessed': [
      OriginalWord('Hebrew', 'בָּרַךְ', 'barak', 'to bless, to kneel'),
      OriginalWord('Greek', 'μακάριος', 'makarios', 'blessed, happy'),
    ],
    'praise': [
      OriginalWord('Hebrew', 'הָלַל', 'halal',
          'to praise — the root of "hallelujah"'),
      OriginalWord('Hebrew', 'יָדָה', 'yadah', 'to give thanks, praise'),
    ],
    'worship': [
      OriginalWord('Hebrew', 'שָׁחָה', 'shachah', 'to bow down, worship'),
      OriginalWord('Greek', 'προσκυνέω', 'proskyneō', 'to worship, bow'),
    ],
    'fear': [
      OriginalWord('Hebrew', 'יִרְאָה', 'yirah', 'fear, reverence, awe'),
      OriginalWord('Greek', 'φόβος', 'phobos', 'fear, reverence'),
    ],
    'name': [
      OriginalWord('Hebrew', 'שֵׁם', 'shem', 'name, reputation, character'),
    ],
    'king': [
      OriginalWord('Hebrew', 'מֶלֶךְ', 'melek', 'king'),
      OriginalWord('Greek', 'βασιλεύς', 'basileus', 'king'),
    ],
    'gospel': [
      OriginalWord(
          'Greek', 'εὐαγγέλιον', 'euangelion', 'good news, the gospel'),
    ],
    'church': [
      OriginalWord('Greek', 'ἐκκλησία', 'ekklēsia',
          'assembly — the "called-out" people'),
    ],
    'wisdom': [
      OriginalWord('Hebrew', 'חָכְמָה', 'chokmah', 'wisdom, skill'),
      OriginalWord('Greek', 'σοφία', 'sophia', 'wisdom'),
    ],
    'joy': [
      OriginalWord('Hebrew', 'שִׂמְחָה', 'simchah', 'joy, gladness'),
      OriginalWord('Greek', 'χαρά', 'chara', 'joy'),
    ],
    'hope': [
      OriginalWord(
          'Greek', 'ἐλπίς', 'elpis', 'hope — confident expectation'),
    ],
    'power': [
      OriginalWord('Greek', 'δύναμις', 'dynamis',
          'power, might — the root of "dynamite"'),
      OriginalWord('Hebrew', 'גְּבוּרָה', 'gevurah', 'strength, might'),
    ],
    'servant': [
      OriginalWord('Hebrew', 'עֶבֶד', 'eved', 'servant, slave'),
      OriginalWord('Greek', 'δοῦλος', 'doulos', 'servant, bondservant'),
    ],
    'shepherd': [
      OriginalWord('Hebrew', 'רָעָה', "ra'ah", 'to shepherd, to tend'),
      OriginalWord('Greek', 'ποιμήν', 'poimēn', 'shepherd'),
    ],
    'law': [
      OriginalWord('Hebrew', 'תּוֹרָה', 'torah',
          'law, instruction, teaching'),
      OriginalWord('Greek', 'νόμος', 'nomos', 'law'),
    ],
    'redeemer': [
      OriginalWord('Hebrew', 'גָּאַל', "ga'al",
          'to redeem, to act as kinsman-redeemer'),
    ],
    'atonement': [
      OriginalWord('Hebrew', 'כָּפַר', 'kaphar',
          'to cover, to make atonement'),
    ],
  };

  /// Concept keys present in a verse (whole words, case-insensitive, tolerant
  /// of a trailing "s" and simple verb endings like -ed/-eth).
  static List<MapEntry<String, List<OriginalWord>>> forVerse(String verseText) {
    final seen = <String>{};
    final out = <MapEntry<String, List<OriginalWord>>>[];
    for (final raw in verseText.split(RegExp(r'[^A-Za-z]+'))) {
      if (raw.isEmpty) continue;
      final w = raw.toLowerCase();
      if (seen.contains(w)) continue;
      seen.add(w);
      final entry = byConcept[w] ??
          (w.endsWith('s') ? byConcept[w.substring(0, w.length - 1)] : null) ??
          (w.endsWith('ed') ? byConcept[w.substring(0, w.length - 2)] : null) ??
          (w.endsWith('eth') ? byConcept[w.substring(0, w.length - 3)] : null);
      if (entry != null) out.add(MapEntry(_title(raw), entry));
    }
    return out;
  }

  static String _title(String w) =>
      w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
}
