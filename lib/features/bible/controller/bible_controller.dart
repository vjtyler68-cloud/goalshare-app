import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import '../model/bible_mark.dart';

class BibleController extends GetxController {
  // ── Hive box for caching ───────────────────────────────────────────────────
  late Box<String> _cache;

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  // Completes once the Hive boxes are open, so consumers can await readiness
  // instead of racing the async onInit.
  final Completer<void> _readyCompleter = Completer<void>();
  Future<void> get _whenReady => _readyCompleter.future;
  bool _boxesReady = false;

  // Current chapter verses
  final RxList<Map<String, dynamic>> verses = <Map<String, dynamic>>[].obs;
  final RxString currentRef = ''.obs;
  final RxBool isCached = false.obs;

  // Search
  final RxString searchQuery = ''.obs;

  // ── Marks: highlights + notes ──────────────────────────────────────────────
  // Persisted map of "book_chapter_verse" -> BibleMark (JSON). A mark holds a
  // highlighter colour, a personal note, or both, plus a snapshot of the verse
  // text so the library screen renders without the offline cache.
  late Box<String> _marks;
  final RxMap<String, BibleMark> markMap = <String, BibleMark>{}.obs;

  String _markKey(String book, int chapter, int verse) =>
      '${book.toLowerCase()}_${chapter}_$verse';

  int _nowMs() => DateTime.now().millisecondsSinceEpoch;

  BibleMark? markOf(String book, int chapter, int verse) =>
      markMap[_markKey(book, chapter, verse)];

  int? highlightOf(String book, int chapter, int verse) =>
      markMap[_markKey(book, chapter, verse)]?.color;

  String noteOf(String book, int chapter, int verse) =>
      markMap[_markKey(book, chapter, verse)]?.note ?? '';

  /// Every verse the user has highlighted and/or noted, newest edit first.
  List<BibleMark> get savedMarks {
    final list = markMap.values.where((m) => !m.isEmpty).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  int get savedCount => savedMarks.length;

  Future<void> setHighlight(
      String book, int chapter, int verse, String text, int? colorIndex) async {
    await _whenReady;
    if (!_boxesReady) return; // storage unavailable — ignore silently
    final existing = markOf(book, chapter, verse);
    await _persistMark(BibleMark(
      book: book,
      chapter: chapter,
      verse: verse,
      text: text.isNotEmpty ? text : (existing?.text ?? ''),
      color: colorIndex,
      note: existing?.note ?? '',
      updatedAt: _nowMs(),
    ));
  }

  Future<void> setNote(
      String book, int chapter, int verse, String text, String note) async {
    await _whenReady;
    if (!_boxesReady) return;
    final existing = markOf(book, chapter, verse);
    await _persistMark(BibleMark(
      book: book,
      chapter: chapter,
      verse: verse,
      text: text.isNotEmpty ? text : (existing?.text ?? ''),
      color: existing?.color,
      note: note.trim(),
      updatedAt: _nowMs(),
    ));
  }

  /// Remove a verse's highlight and note entirely (used by the library screen).
  Future<void> removeMark(String book, int chapter, int verse) async {
    await _whenReady;
    if (!_boxesReady) return;
    final key = _markKey(book, chapter, verse);
    await _marks.delete(key);
    markMap.remove(key);
  }

  Future<void> _persistMark(BibleMark mark) async {
    final key = _markKey(mark.book, mark.chapter, mark.verse);
    if (mark.isEmpty) {
      await _marks.delete(key);
      markMap.remove(key);
    } else {
      await _marks.put(key, jsonEncode(mark.toJson()));
      markMap[key] = mark;
    }
  }

  /// Fill in verse text for any marks in the just-loaded chapter that were
  /// stored without it (e.g. migrated legacy highlights), so the library shows
  /// the actual scripture instead of a blank line.
  void _backfillMarkTexts(String book, int chapter) {
    for (final v in verses) {
      final verse = (v['verse'] as num).toInt();
      final key = _markKey(book, chapter, verse);
      final m = markMap[key];
      if (m != null && m.text.isEmpty) {
        final filled = BibleMark(
          book: book,
          chapter: chapter,
          verse: verse,
          text: v['text'] as String,
          color: m.color,
          note: m.note,
          updatedAt: m.updatedAt,
        );
        markMap[key] = filled;
        _marks.put(key, jsonEncode(filled.toJson())); // fire-and-forget
      }
    }
  }

  /// One-time import of the old `bible_highlights` box (colour-only) into the
  /// richer `bible_marks` store, so existing users keep their highlights.
  Future<void> _migrateLegacyHighlights() async {
    try {
      if (!await Hive.boxExists('bible_highlights')) return;
      final legacy = await Hive.openBox<int>('bible_highlights');
      if (legacy.isNotEmpty) {
        final byLower = {
          for (final b in BibleData.books)
            (b['name'] as String).toLowerCase(): b['name'] as String
        };
        for (final entry in legacy.toMap().entries) {
          final key = entry.key.toString();
          if (markMap.containsKey(key)) continue; // already migrated
          final parts = key.split('_');
          if (parts.length < 3) continue;
          final verse = int.tryParse(parts.removeLast());
          final chapter = int.tryParse(parts.removeLast());
          final book = byLower[parts.join('_')];
          if (verse == null || chapter == null || book == null) continue;
          final mark = BibleMark(
            book: book,
            chapter: chapter,
            verse: verse,
            text: '',
            color: entry.value,
            updatedAt: 0, // unknown original time — sorts to the bottom
          );
          markMap[key] = mark;
          await _marks.put(key, jsonEncode(mark.toJson()));
        }
      }
      await legacy.close(); // leave the legacy box on disk, just in case
    } catch (e) {
      log('Bible highlight migration failed: $e');
    }
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    try {
      _cache = await Hive.openBox<String>('bible_cache');
      _marks = await Hive.openBox<String>('bible_marks');
      for (final entry in _marks.toMap().entries) {
        try {
          markMap[entry.key.toString()] =
              BibleMark.fromJson(jsonDecode(entry.value) as Map<String, dynamic>);
        } catch (_) {
          // Skip any corrupt record rather than failing the whole load.
        }
      }
      await _migrateLegacyHighlights();
      _boxesReady = true;
    } catch (e) {
      log('Bible storage init failed: $e');
      error.value = 'Could not open offline storage.';
    } finally {
      // Always complete so awaiters never hang, even if opening failed.
      if (!_readyCompleter.isCompleted) _readyCompleter.complete();
    }
  }

  @override
  void onClose() {
    if (_boxesReady) {
      _cache.close();
      _marks.close();
    }
    super.onClose();
  }

  // ── Load a chapter ─────────────────────────────────────────────────────────
  Future<void> loadChapter(String book, int chapter) async {
    await _whenReady; // ensure the cache box is open before touching it
    final key = '${book.toLowerCase()}_$chapter';
    currentRef.value = '$book $chapter';
    isLoading.value = true;
    error.value = '';
    verses.clear();

    // Try cache first
    if (_boxesReady && _cache.containsKey(key)) {
      final raw = _cache.get(key)!;
      _parseAndSet(raw);
      _backfillMarkTexts(book, chapter);
      isCached.value = true;
      isLoading.value = false;
      return;
    }

    // Online fetch — try direct first, then CORS proxy fallback for web
    try {
      final query = Uri.encodeComponent('$book $chapter');
      final directUrl = 'https://bible-api.com/$query?translation=kjv';
      http.Response? response;

      try {
        response = await http.get(Uri.parse(directUrl), headers: {'Accept': 'application/json'})
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        // CORS or network failure — try proxy
        final proxyUrl = 'https://corsproxy.io/?${Uri.encodeComponent(directUrl)}';
        response = await http.get(Uri.parse(proxyUrl))
            .timeout(const Duration(seconds: 12));
      }

      if (response != null && response.statusCode == 200) {
        if (_boxesReady) await _cache.put(key, response.body);
        _parseAndSet(response.body);
        _backfillMarkTexts(book, chapter);
        isCached.value = true;
      } else {
        error.value = 'Could not load chapter. Check your connection.';
      }
    } catch (e) {
      log('Bible fetch error: $e');
      error.value = 'No internet connection. This chapter has not been cached yet.';
    } finally {
      isLoading.value = false;
    }
  }

  void _parseAndSet(String raw) {
    try {
      final data = json.decode(raw) as Map<String, dynamic>;
      final verseList = data['verses'] as List<dynamic>? ?? [];
      verses.assignAll(verseList.map((v) => {
        'verse': v['verse'],
        'text': (v['text'] as String).trim(),
      }));
    } catch (e) {
      error.value = 'Failed to parse Bible data.';
    }
  }

  // ── Cache status ───────────────────────────────────────────────────────────
  bool isChapterCached(String book, int chapter) {
    if (!_boxesReady) return false;
    final key = '${book.toLowerCase()}_$chapter';
    return _cache.containsKey(key);
  }

  int get cachedChapterCount => _boxesReady ? _cache.length : 0;

  void clearCache() {
    if (!_boxesReady) return;
    _cache.clear();
    isCached.value = false;
  }
}

// ── Bible structure (all 66 books + chapter counts) ────────────────────────
class BibleData {
  static const List<Map<String, dynamic>> books = [
    // Old Testament
    {'name': 'Genesis',       'abbr': 'gen',  'chapters': 50,  'testament': 'OT'},
    {'name': 'Exodus',        'abbr': 'exo',  'chapters': 40,  'testament': 'OT'},
    {'name': 'Leviticus',     'abbr': 'lev',  'chapters': 27,  'testament': 'OT'},
    {'name': 'Numbers',       'abbr': 'num',  'chapters': 36,  'testament': 'OT'},
    {'name': 'Deuteronomy',   'abbr': 'deu',  'chapters': 34,  'testament': 'OT'},
    {'name': 'Joshua',        'abbr': 'jos',  'chapters': 24,  'testament': 'OT'},
    {'name': 'Judges',        'abbr': 'jdg',  'chapters': 21,  'testament': 'OT'},
    {'name': 'Ruth',          'abbr': 'rut',  'chapters': 4,   'testament': 'OT'},
    {'name': '1 Samuel',      'abbr': '1sa',  'chapters': 31,  'testament': 'OT'},
    {'name': '2 Samuel',      'abbr': '2sa',  'chapters': 24,  'testament': 'OT'},
    {'name': '1 Kings',       'abbr': '1ki',  'chapters': 22,  'testament': 'OT'},
    {'name': '2 Kings',       'abbr': '2ki',  'chapters': 25,  'testament': 'OT'},
    {'name': '1 Chronicles',  'abbr': '1ch',  'chapters': 29,  'testament': 'OT'},
    {'name': '2 Chronicles',  'abbr': '2ch',  'chapters': 36,  'testament': 'OT'},
    {'name': 'Ezra',          'abbr': 'ezr',  'chapters': 10,  'testament': 'OT'},
    {'name': 'Nehemiah',      'abbr': 'neh',  'chapters': 13,  'testament': 'OT'},
    {'name': 'Esther',        'abbr': 'est',  'chapters': 10,  'testament': 'OT'},
    {'name': 'Job',           'abbr': 'job',  'chapters': 42,  'testament': 'OT'},
    {'name': 'Psalms',        'abbr': 'psa',  'chapters': 150, 'testament': 'OT'},
    {'name': 'Proverbs',      'abbr': 'pro',  'chapters': 31,  'testament': 'OT'},
    {'name': 'Ecclesiastes',  'abbr': 'ecc',  'chapters': 12,  'testament': 'OT'},
    {'name': 'Song of Solomon','abbr': 'sng', 'chapters': 8,   'testament': 'OT'},
    {'name': 'Isaiah',        'abbr': 'isa',  'chapters': 66,  'testament': 'OT'},
    {'name': 'Jeremiah',      'abbr': 'jer',  'chapters': 52,  'testament': 'OT'},
    {'name': 'Lamentations',  'abbr': 'lam',  'chapters': 5,   'testament': 'OT'},
    {'name': 'Ezekiel',       'abbr': 'ezk',  'chapters': 48,  'testament': 'OT'},
    {'name': 'Daniel',        'abbr': 'dan',  'chapters': 12,  'testament': 'OT'},
    {'name': 'Hosea',         'abbr': 'hos',  'chapters': 14,  'testament': 'OT'},
    {'name': 'Joel',          'abbr': 'jol',  'chapters': 3,   'testament': 'OT'},
    {'name': 'Amos',          'abbr': 'amo',  'chapters': 9,   'testament': 'OT'},
    {'name': 'Obadiah',       'abbr': 'oba',  'chapters': 1,   'testament': 'OT'},
    {'name': 'Jonah',         'abbr': 'jon',  'chapters': 4,   'testament': 'OT'},
    {'name': 'Micah',         'abbr': 'mic',  'chapters': 7,   'testament': 'OT'},
    {'name': 'Nahum',         'abbr': 'nam',  'chapters': 3,   'testament': 'OT'},
    {'name': 'Habakkuk',      'abbr': 'hab',  'chapters': 3,   'testament': 'OT'},
    {'name': 'Zephaniah',     'abbr': 'zep',  'chapters': 3,   'testament': 'OT'},
    {'name': 'Haggai',        'abbr': 'hag',  'chapters': 2,   'testament': 'OT'},
    {'name': 'Zechariah',     'abbr': 'zec',  'chapters': 14,  'testament': 'OT'},
    {'name': 'Malachi',       'abbr': 'mal',  'chapters': 4,   'testament': 'OT'},
    // New Testament
    {'name': 'Matthew',       'abbr': 'mat',  'chapters': 28,  'testament': 'NT'},
    {'name': 'Mark',          'abbr': 'mrk',  'chapters': 16,  'testament': 'NT'},
    {'name': 'Luke',          'abbr': 'luk',  'chapters': 24,  'testament': 'NT'},
    {'name': 'John',          'abbr': 'jhn',  'chapters': 21,  'testament': 'NT'},
    {'name': 'Acts',          'abbr': 'act',  'chapters': 28,  'testament': 'NT'},
    {'name': 'Romans',        'abbr': 'rom',  'chapters': 16,  'testament': 'NT'},
    {'name': '1 Corinthians', 'abbr': '1co',  'chapters': 16,  'testament': 'NT'},
    {'name': '2 Corinthians', 'abbr': '2co',  'chapters': 13,  'testament': 'NT'},
    {'name': 'Galatians',     'abbr': 'gal',  'chapters': 6,   'testament': 'NT'},
    {'name': 'Ephesians',     'abbr': 'eph',  'chapters': 6,   'testament': 'NT'},
    {'name': 'Philippians',   'abbr': 'php',  'chapters': 4,   'testament': 'NT'},
    {'name': 'Colossians',    'abbr': 'col',  'chapters': 4,   'testament': 'NT'},
    {'name': '1 Thessalonians','abbr': '1th', 'chapters': 5,   'testament': 'NT'},
    {'name': '2 Thessalonians','abbr': '2th', 'chapters': 3,   'testament': 'NT'},
    {'name': '1 Timothy',     'abbr': '1ti',  'chapters': 6,   'testament': 'NT'},
    {'name': '2 Timothy',     'abbr': '2ti',  'chapters': 4,   'testament': 'NT'},
    {'name': 'Titus',         'abbr': 'tit',  'chapters': 3,   'testament': 'NT'},
    {'name': 'Philemon',      'abbr': 'phm',  'chapters': 1,   'testament': 'NT'},
    {'name': 'Hebrews',       'abbr': 'heb',  'chapters': 13,  'testament': 'NT'},
    {'name': 'James',         'abbr': 'jas',  'chapters': 5,   'testament': 'NT'},
    {'name': '1 Peter',       'abbr': '1pe',  'chapters': 5,   'testament': 'NT'},
    {'name': '2 Peter',       'abbr': '2pe',  'chapters': 3,   'testament': 'NT'},
    {'name': '1 John',        'abbr': '1jn',  'chapters': 5,   'testament': 'NT'},
    {'name': '2 John',        'abbr': '2jn',  'chapters': 1,   'testament': 'NT'},
    {'name': '3 John',        'abbr': '3jn',  'chapters': 1,   'testament': 'NT'},
    {'name': 'Jude',          'abbr': 'jud',  'chapters': 1,   'testament': 'NT'},
    {'name': 'Revelation',    'abbr': 'rev',  'chapters': 22,  'testament': 'NT'},
  ];
}
