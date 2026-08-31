import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vector_tile/vector_tile.dart';

/// One decoded Ameren distribution line: a polyline as `[lat, lng]` points,
/// coloured by hosting-capacity class.
class AmerenLine {
  final List<List<double>> latlng; // each element = [lat, lng]
  final Color color;
  const AmerenLine(this.latlng, this.color);
}

/// Fetches + decodes Ameren Illinois' PUBLIC hosting-capacity VECTOR tiles (the
/// real distribution lines, coloured by how much new solar the grid can take)
/// into native polylines.
///
/// This is what lets the Apple map show the grid across the WHOLE STATE at any
/// zoom: MapKit can't render vector tiles, and the raw FeatureServer is capped at
/// 2000 features (a dense city alone has ~16k), so neither works zoomed out. The
/// vector-tile server pre-generalises geometry per zoom, so a statewide view is
/// just a handful of tiles. We decode them ourselves (the app already bundles the
/// `vector_tile` package) and hand Apple native, perfectly-aligned polylines.
/// Free, no key. Tile LODs 4–14; capacity is the `_symbol` attribute (2 = red /
/// no capacity → 7+ = green / lots).
class AmerenGridTiles {
  AmerenGridTiles._();
  static final AmerenGridTiles instance = AmerenGridTiles._();

  static const _base =
      'https://tiles.arcgis.com/tiles/3jEEGnl6c1x9Sze7/arcgis/rest/services/HcVectorTiles/VectorTileServer/tile';

  // Decoded lines cached per tile (z/x/y). An empty list means "fetched, nothing
  // there" so we never re-request a blank tile.
  final Map<String, List<AmerenLine>> _cache = {};
  final Set<String> _inFlight = {};

  /// Server has tiles for zoom 4–14; clamp the map zoom into that.
  int _tileZoom(double appZoom) {
    final z = appZoom.round();
    return z < 4 ? 4 : (z > 14 ? 14 : z);
  }

  int _lon2x(double lon, int z) => ((lon + 180.0) / 360.0 * (1 << z)).floor();

  int _lat2y(double lat, int z) {
    final r = lat * math.pi / 180.0;
    return ((1 - math.log(math.tan(r) + 1 / math.cos(r)) / math.pi) /
            2 *
            (1 << z))
        .floor();
  }

  /// Every currently-cached line for the viewport; also kicks off fetches for any
  /// missing tiles and calls [onLoaded] as each arrives so the caller can redraw.
  /// Bounded so it can never explode the tile or line count.
  List<AmerenLine> linesForView({
    required double west,
    required double south,
    required double east,
    required double north,
    required double appZoom,
    required VoidCallback onLoaded,
  }) {
    final z = _tileZoom(appZoom);
    final n = 1 << z;
    int clampT(int v) => v < 0 ? 0 : (v >= n ? n - 1 : v);
    final xa = clampT(_lon2x(west, z));
    final xb = clampT(_lon2x(east, z));
    final ya = clampT(_lat2y(north, z)); // north edge = smaller tile-y
    final yb = clampT(_lat2y(south, z));
    final out = <AmerenLine>[];
    var tiles = 0;
    for (var x = math.min(xa, xb); x <= math.max(xa, xb); x++) {
      for (var y = math.min(ya, yb); y <= math.max(ya, yb); y++) {
        if (tiles++ > 40) return out; // never fetch a runaway number of tiles
        final key = '$z/$x/$y';
        final cached = _cache[key];
        if (cached != null) {
          out.addAll(cached);
          if (out.length > 6000) return out; // cap what we hand the map to draw
        } else {
          _fetch(z, x, y, onLoaded);
        }
      }
    }
    return out;
  }

  void _fetch(int z, int x, int y, VoidCallback onLoaded) {
    final key = '$z/$x/$y';
    if (_inFlight.contains(key) || _cache.containsKey(key)) return;
    _inFlight.add(key);
    // Tile path is {z}/{y}/{x}.
    http
        .get(Uri.parse('$_base/$z/$y/$x.pbf'))
        .timeout(const Duration(seconds: 12))
        .then((res) {
      _inFlight.remove(key);
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        try {
          _cache[key] = _decode(res.bodyBytes, z, x, y);
        } catch (_) {
          _cache[key] = const [];
        }
      } else {
        _cache[key] = const []; // 404 / empty = no grid here; don't refetch
      }
      onLoaded();
    }).catchError((_) {
      _inFlight.remove(key); // network blip — leave uncached so a pan can retry
    });
  }

  List<AmerenLine> _decode(Uint8List bytes, int z, int x, int y) {
    final tile = VectorTile.fromBytes(bytes: bytes);
    final lines = <AmerenLine>[];
    for (final layer in tile.layers) {
      final name = layer.name;
      // The colored capacity conductors live in the ":1" source-layer; ":2" is a
      // decorative black casing we skip.
      if (!name.contains('CONDUCTOR') || name.endsWith(':2')) continue;
      final ext = layer.extent;
      final size = ext * (1 << z);
      final x0 = ext * x;
      final y0 = ext * y;
      for (final f in layer.features) {
        var sym = 0;
        try {
          final props = f.decodeProperties();
          sym = int.tryParse(props['_symbol']?.value.toString() ?? '') ?? 0;
        } catch (_) {}
        final color = _colorFor(sym);
        GeoJson? geo;
        try {
          geo = f.toGeoJsonWithExtentCalculated(x0: x0, y0: y0, size: size);
        } catch (_) {
          continue;
        }
        if (geo is GeoJsonLineString) {
          final c = geo.geometry?.coordinates;
          if (c != null && c.length >= 2) lines.add(AmerenLine(_latLng(c), color));
        } else if (geo is GeoJsonMultiLineString) {
          final ml = geo.geometry?.coordinates;
          if (ml != null) {
            for (final c in ml) {
              if (c.length >= 2) lines.add(AmerenLine(_latLng(c), color));
            }
          }
        }
        if (lines.length > 6000) return lines; // per-tile safety cap
      }
    }
    return lines;
  }

  // GeoJson coordinates are [lng, lat]; polylines want [lat, lng].
  List<List<double>> _latLng(List<List<double>> lngLat) =>
      [for (final p in lngLat) [p[1], p[0]]];

  /// Hosting-capacity ramp: red (no room for new solar) → green (lots).
  Color _colorFor(int symbol) {
    switch (symbol) {
      case 2:
        return const Color(0xffEF4444); // red — constrained
      case 3:
        return const Color(0xffF97316);
      case 4:
        return const Color(0xffF59E0B);
      case 5:
        return const Color(0xffEAB308);
      case 6:
        return const Color(0xff84CC16);
      case 7:
        return const Color(0xff22C55E); // green — open
      default:
        // 8+ = highest capacity (deep green); anything unexpected = neutral blue.
        return symbol >= 8 ? const Color(0xff16A34A) : const Color(0xff38BDF8);
    }
  }
}
