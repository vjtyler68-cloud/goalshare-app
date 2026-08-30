import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_map/flutter_map.dart';

/// Big on-disk cache for Sales Ranch satellite tiles. This is what makes the map
/// load INSTANTLY on repeat views and across app restarts (like SalesRabbit)
/// instead of re-downloading every tile every time — the #1 reason the map felt
/// slow. Tiles a rep has already seen also render offline.
///
/// ⚠️ This provider was WRONGLY blamed for the gray-map saga. Build 241 removed
/// it and the map was STILL gray — the real culprit was `retinaMode` (removed in
/// 244). So caching is safe as long as NO retinaMode touches these layers. Do
/// not add retinaMode.
final CacheManager salesRanchTileCache = CacheManager(
  Config(
    'salesRanchTilesV2',
    stalePeriod: const Duration(days: 30),
    maxNrOfCacheObjects: 4000,
  ),
);

/// flutter_map tile provider that serves every tile through [salesRanchTileCache]
/// (disk cache) via cached_network_image — both already dependencies, so no new
/// native code.
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
