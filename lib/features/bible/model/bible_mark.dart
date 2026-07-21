/// A single saved marker on a Bible verse — a highlight colour, a personal
/// note, or both. One [BibleMark] per verse; it disappears once it has neither
/// a colour nor a note. Stored as JSON in the `bible_marks` Hive box and also
/// powers the "Highlights & Notes" library screen.
class BibleMark {
  final String book;
  final int chapter;
  final int verse;

  /// Snapshot of the verse text, captured when the mark is created so the
  /// library screen can render it even if the offline cache is cleared.
  final String text;

  /// Highlighter colour index (0,1,2) or null when only a note is attached.
  final int? color;

  /// Free-form personal note. Empty string means "no note".
  final String note;

  /// Last-edited time (ms since epoch) — the library lists newest first.
  final int updatedAt;

  const BibleMark({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.updatedAt,
    this.color,
    this.note = '',
  });

  bool get hasHighlight => color != null;
  bool get hasNote => note.trim().isNotEmpty;

  /// A mark with no colour and no note carries no information and is deleted.
  bool get isEmpty => !hasHighlight && !hasNote;

  /// Human reference like `John 3:16`.
  String get reference => '$book $chapter:$verse';

  Map<String, dynamic> toJson() => {
        'book': book,
        'chapter': chapter,
        'verse': verse,
        'text': text,
        'color': color,
        'note': note,
        'updatedAt': updatedAt,
      };

  factory BibleMark.fromJson(Map<String, dynamic> j) => BibleMark(
        book: j['book'] as String? ?? '',
        chapter: (j['chapter'] as num?)?.toInt() ?? 0,
        verse: (j['verse'] as num?)?.toInt() ?? 0,
        text: j['text'] as String? ?? '',
        color: (j['color'] as num?)?.toInt(),
        note: j['note'] as String? ?? '',
        updatedAt: (j['updatedAt'] as num?)?.toInt() ?? 0,
      );
}
