/// Lightweight, dependency-free fuzzy matching for on-device search.
///
/// Designed for small, local lists (leads, tasks, food, etc.) where users type
/// fast and imperfectly. It tolerates typos, transpositions, missing letters,
/// accents and word-order differences, and ranks results by relevance — all in
/// plain Dart with no packages, so it works offline and adds no build weight.
///
/// Typical use:
/// ```dart
/// final results = fuzzySearch<Lead>(
///   leads,
///   query,
///   fields: (l) => [l.name, l.company, l.phone, l.email],
/// );
/// ```
library;

/// Strip a string down to a comparable form: lowercase, trimmed, whitespace
/// collapsed, and common accents folded (café -> cafe). Keeps the search
/// forgiving of casing/spacing/diacritics the user won't think about.
String normalizeForSearch(String input) {
  var s = input.toLowerCase().trim();
  if (s.isEmpty) return s;
  s = _foldDiacritics(s);
  // Collapse any run of whitespace to a single space.
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  return s;
}

const Map<String, String> _diacritics = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a', 'ā': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', 'ø': 'o', 'ō': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u',
  'ñ': 'n', 'ç': 'c', 'ß': 'ss',
};

String _foldDiacritics(String s) {
  if (!s.contains(RegExp(r'[^\x00-\x7F]'))) return s; // ASCII fast path
  final buf = StringBuffer();
  for (final ch in s.split('')) {
    buf.write(_diacritics[ch] ?? ch);
  }
  return buf.toString();
}

/// Levenshtein edit distance (insert/delete/substitute) between two strings.
/// Uses two rolling rows so memory is O(min(a,b)).
int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  // Iterate over the shorter string for the inner loop.
  if (a.length > b.length) {
    final tmp = a;
    a = b;
    b = tmp;
  }

  var prev = List<int>.generate(a.length + 1, (i) => i);
  var curr = List<int>.filled(a.length + 1, 0);

  for (var j = 1; j <= b.length; j++) {
    curr[0] = j;
    final bj = b.codeUnitAt(j - 1);
    for (var i = 1; i <= a.length; i++) {
      final cost = a.codeUnitAt(i - 1) == bj ? 0 : 1;
      final del = prev[i] + 1;
      final ins = curr[i - 1] + 1;
      final sub = prev[i - 1] + cost;
      curr[i] = del < ins ? (del < sub ? del : sub) : (ins < sub ? ins : sub);
    }
    final swap = prev;
    prev = curr;
    curr = swap;
  }
  return prev[a.length];
}

/// True if every character of [needle] appears in [haystack] in order (not
/// necessarily contiguous). Great for abbreviations: "jdoe" ⊂ "john doe".
bool isSubsequence(String needle, String haystack) {
  if (needle.isEmpty) return true;
  var i = 0;
  for (var j = 0; j < haystack.length && i < needle.length; j++) {
    if (needle.codeUnitAt(i) == haystack.codeUnitAt(j)) i++;
  }
  return i == needle.length;
}

/// Similarity of two single words, 0..1, blending prefix/substring hits with
/// edit-distance tolerance. Returns 0 below a sensible similarity floor so junk
/// matches are dropped.
double _tokenScore(String a, String b) {
  if (a.isEmpty || b.isEmpty) return 0;
  if (a == b) return 1;
  if (b.startsWith(a)) return 0.92;
  if (b.contains(a)) return 0.85;
  final dist = levenshtein(a, b);
  final maxLen = a.length > b.length ? a.length : b.length;
  final ratio = 1 - dist / maxLen;
  return ratio >= 0.6 ? ratio : 0;
}

/// Score how well [rawQuery] matches [rawTarget], from 0 (no match) to 1
/// (exact). Empty query matches everything (returns 1) so a cleared search box
/// shows the full list.
double fuzzyScore(String rawQuery, String rawTarget) {
  final query = normalizeForSearch(rawQuery);
  final target = normalizeForSearch(rawTarget);
  if (query.isEmpty) return 1;
  if (target.isEmpty) return 0;

  // Tier 1 — exact / prefix / substring (high confidence, cheap).
  if (target == query) return 1;
  if (target.startsWith(query)) return 0.95;
  final idx = target.indexOf(query);
  if (idx >= 0) {
    // Earlier position ranks slightly higher.
    return 0.85 - (idx / target.length) * 0.1;
  }

  // Tier 2 — per-token match with typo tolerance (handles word order +
  // multi-field values like "Acme Corp  555-1234").
  final qTokens = query.split(' ').where((t) => t.isNotEmpty).toList();
  final tTokens = target.split(' ').where((t) => t.isNotEmpty).toList();
  if (qTokens.length > 1 || tTokens.length > 1) {
    var sum = 0.0;
    for (final qt in qTokens) {
      var best = 0.0;
      for (final tt in tTokens) {
        final s = _tokenScore(qt, tt);
        if (s > best) best = s;
      }
      sum += best;
    }
    final tokenScore = sum / qTokens.length;
    if (tokenScore > 0) return tokenScore * 0.8; // capped below substring tier
  }

  // Tier 3 — whole-string typo tolerance, then subsequence fallback.
  final whole = _tokenScore(query, target);
  final subseq = isSubsequence(query, target) ? 0.55 : 0.0;
  final best = whole > subseq ? whole : subseq;
  return best * 0.8;
}

/// Convenience boolean check against a relevance [threshold] (0..1).
bool fuzzyMatches(String query, String target, {double threshold = 0.5}) =>
    fuzzyScore(query, target) >= threshold;

/// Filter + rank [items] by the best fuzzy score across each item's searchable
/// [fields]. Results above [threshold] are returned most-relevant first.
///
/// - [fields]: returns the strings to search for a given item.
/// - [threshold]: minimum score to include (0..1). Lower = more forgiving.
/// - [limit]: optional cap on the number of results.
///
/// An empty/whitespace query returns the list unchanged (original order).
List<T> fuzzySearch<T>(
  List<T> items,
  String query, {
  required Iterable<String> Function(T item) fields,
  double threshold = 0.5,
  int? limit,
}) {
  if (normalizeForSearch(query).isEmpty) return List<T>.from(items);

  final scored = <_Scored<T>>[];
  for (final item in items) {
    var best = 0.0;
    for (final field in fields(item)) {
      final s = fuzzyScore(query, field);
      if (s > best) best = s;
      if (best >= 1) break; // can't do better than exact
    }
    if (best >= threshold) scored.add(_Scored(item, best));
  }

  scored.sort((a, b) => b.score.compareTo(a.score));
  final result = scored.map((e) => e.item).toList();
  if (limit != null && result.length > limit) {
    return result.sublist(0, limit);
  }
  return result;
}

class _Scored<T> {
  final T item;
  final double score;
  const _Scored(this.item, this.score);
}
