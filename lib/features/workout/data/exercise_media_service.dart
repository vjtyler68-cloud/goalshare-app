import 'dart:convert';
import 'dart:developer';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import 'exercise_images.dart';

/// Fetches a demo image for an exercise by name from the FREE wger open API
/// (no key), and caches the resolved URL in Hive so repeat views never re-fetch.
/// Best-effort: any miss/failure returns null and the UI falls back to the
/// bundled form cue. A cached empty string means "known to have no image" so we
/// don't hammer the API for exercises wger doesn't cover.
class ExerciseMediaService {
  ExerciseMediaService._();
  static final ExerciseMediaService instance = ExerciseMediaService._();

  static const String _boxName = 'exercise_media_v1';
  Box<String>? _box;

  Future<void> _open() async {
    if (_box != null && _box!.isOpen) return;
    try {
      _box = await Hive.openBox<String>(_boxName);
    } catch (_) {}
  }

  /// Resolved image URL for [name], or null if none/unavailable. Cached forever.
  Future<String?> imageFor(String name) async {
    final key = name.toLowerCase().trim();
    if (key.isEmpty) return null;
    // Prefer the bundled free-exercise-db map: a real photo, resolved instantly
    // with no network call. Only fall back to the wger search for names we
    // don't recognise.
    final known = ExerciseImages.startUrl(name: name);
    if (known != null) return known;
    await _open();
    final cached = _box?.get(key);
    if (cached != null) return cached.isEmpty ? null : cached;

    String? found;
    try {
      final uri = Uri.https('wger.de', '/api/v2/exercise/search/', {
        'term': name,
        'language': '2', // English
        'format': 'json',
      });
      final res = await http
          .get(uri, headers: {'Accept': 'application/json'}).timeout(
              const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final suggestions = data['suggestions'] as List?;
        if (suggestions != null) {
          for (final s in suggestions) {
            final d = (s is Map) ? s['data'] as Map? : null;
            final img = (d?['image'] ?? d?['image_thumbnail'])?.toString();
            if (img != null && img.isNotEmpty) {
              found = img.startsWith('http') ? img : 'https://wger.de$img';
              break;
            }
          }
        }
      }
    } catch (e) {
      log('ExerciseMediaService.imageFor: $e');
    }
    // Cache the result (empty string = "no image", so we stop refetching).
    await _box?.put(key, found ?? '');
    return found;
  }
}
