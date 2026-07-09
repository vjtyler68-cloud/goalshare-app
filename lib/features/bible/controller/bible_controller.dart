import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

class BibleController extends GetxController {
  // ── Hive box for caching ───────────────────────────────────────────────────
  late Box<String> _cache;

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  // Completes once the Hive boxes are open, so consumers can await readiness
  // instead of racing the async onInit.
  final Completer<void> _readyCompleter = Completer<void>();
  Future<void> get _whenReady => _readyCompleter.future;

  // Current chapter verses
  final RxList<Map<String, dynamic>> verses = <Map<String, dynamic>>[].obs;
  final RxString currentRef = ''.obs;
  final RxBool isCached = false.obs;

  // Search
  final RxString searchQuery = ''.obs;

  // ── Highlights (3-colour marker) ───────────────────────────────────────────
  // Persisted map of "book_chapter_verse" -> colour index (0,1,2).
  late Box<int> _highlights;
  final RxMap<String, int> highlightMap = <String, int>{}.obs;

  String _hlKey(String book, int chapter, Object verse) =>
      '${book.toLowerCase()}_${chapter}_$verse';

  int? highlightOf(String book, int chapter, Object verse) =>
      highlightMap[_hlKey(book, chapter, verse)];

  Future<void> setHighlight(
      String book, int chapter, Object verse, int? colorIndex) async {
    await _whenReady; // ensure the highlights box is open
    final key = _hlKey(book, chapter, verse);
    if (colorIndex == null) {
      await _highlights.delete(key);
      highlightMap.remove(key);
    } else {
      await _highlights.put(key, colorIndex);
      highlightMap[key] = colorIndex;
    }
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    _cache = await Hive.openBox<String>('bible_cache');
    _highlights = await Hive.openBox<int>('bible_highlights');
    highlightMap.assignAll(
      _highlights.toMap().map((k, v) => MapEntry(k.toString(), v as int)),
    );
    if (!_readyCompleter.isCompleted) _readyCompleter.complete();
  }

  @override
  void onClose() {
    _cache.close();
    _highlights.close();
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
    if (_cache.containsKey(key)) {
      final raw = _cache.get(key)!;
      _parseAndSet(raw);
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
        await _cache.put(key, response.body);
        _parseAndSet(response.body);
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
    final key = '${book.toLowerCase()}_$chapter';
    return _cache.containsKey(key);
  }

  int get cachedChapterCount => _cache.length;

  void clearCache() {
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
