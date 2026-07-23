import 'dart:convert';

import 'package:http/http.dart' as http;

/// A single GIF result from GIPHY, reduced to the two URLs the app needs:
/// a lightweight animated [previewUrl] for the picker grid, and a [fullUrl]
/// (GIPHY's "downsized" rendition, kept under ~2 MB) for the sent message.
class GiphyGif {
  final String id;
  final String previewUrl;
  final String fullUrl;
  const GiphyGif({
    required this.id,
    required this.previewUrl,
    required this.fullUrl,
  });
}

/// Thin GIPHY REST client. A GIF message stores only the chosen GIF's URL —
/// GIFs are animated and usually too big for the base64-in-Firestore path that
/// photos use, so, like every messaging app, we point at GIPHY's CDN instead.
///
/// GIPHY API keys are meant to be embedded in the client (they identify and
/// rate-limit the app; they are not a secret), so the key lives here as a
/// const. Content is filtered to `pg-13` for App Store safety. Uses the `http`
/// package already in pubspec — no new dependency.
class GiphyService {
  GiphyService._();

  static const String _apiKey = 'MpJ8zsnsRvjAlVWvc1NijIfKOO9Maohz';
  static const String _base = 'https://api.giphy.com/v1/gifs';
  static const String _rating = 'pg-13';

  /// Trending GIFs — shown when the search box is empty.
  static Future<List<GiphyGif>> trending({int limit = 24}) {
    final uri = Uri.parse(
        '$_base/trending?api_key=$_apiKey&limit=$limit&rating=$_rating');
    return _fetch(uri);
  }

  /// Search GIFs by [query]. Empty query falls back to trending.
  static Future<List<GiphyGif>> search(String query, {int limit = 24}) {
    final q = query.trim();
    if (q.isEmpty) return trending(limit: limit);
    final uri = Uri.parse('$_base/search?api_key=$_apiKey'
        '&q=${Uri.encodeQueryComponent(q)}'
        '&limit=$limit&rating=$_rating&lang=en');
    return _fetch(uri);
  }

  static Future<List<GiphyGif>> _fetch(Uri uri) async {
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return const [];
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final data = (body['data'] as List?) ?? const [];
      final out = <GiphyGif>[];
      for (final item in data) {
        final m = (item as Map).cast<String, dynamic>();
        final images =
            (m['images'] as Map?)?.cast<String, dynamic>() ?? const {};
        final preview = _url(images, 'fixed_width') ??
            _url(images, 'fixed_width_downsampled') ??
            _url(images, 'downsized');
        final full = _url(images, 'downsized') ??
            _url(images, 'fixed_width') ??
            _url(images, 'original');
        if (preview == null || full == null) continue;
        out.add(GiphyGif(
          id: (m['id'] ?? '').toString(),
          previewUrl: preview,
          fullUrl: full,
        ));
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  static String? _url(Map<String, dynamic> images, String key) {
    final r = (images[key] as Map?)?.cast<String, dynamic>();
    final u = r?['url'];
    return (u is String && u.isNotEmpty) ? u : null;
  }
}
