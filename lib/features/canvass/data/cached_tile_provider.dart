import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_map/flutter_map.dart';

/// A big, long-lived on-disk cache dedicated to Sales Ranch map tiles. Imagery a
/// rep has already looked at keeps rendering with zero signal, and re-panning
/// over it is instant (no network round-trip, no gray reload flash).
///
/// 3,000 tiles ≈ a good chunk of a territory at street zoom; 30-day freshness
/// means yesterday's cached ground still shows today when you're offline.
final CacheManager salesRanchTileCache = CacheManager(
  Config(
    'salesRanchTiles',
    stalePeriod: const Duration(days: 30),
    maxNrOfCacheObjects: 3000,
  ),
);

/// flutter_map tile provider that fetches every tile through
/// [salesRanchTileCache], giving the map disk caching + offline replay. Built on
/// cached_network_image (already a dependency) — no new native code.
class CachedTileProvider extends TileProvider {
  CachedTileProvider({super.headers});

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return CachedNetworkImageProvider(
      getTileUrl(coordinates, options),
      cacheManager: salesRanchTileCache,
      headers: headers,
    );
  }
}
