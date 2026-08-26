import 'package:get/get.dart';

import '../data/org_models.dart';
import 'org_web_screen.dart';
import 'territory_metrics_bar.dart';

/// Shared openers for an org's in-app web tools — the territory map and the
/// appointment scheduler — so every entry point (Team HQ, the profile org card,
/// …) opens them the exact same way, in-app.
class OrgTools {
  OrgTools._();

  /// Open the org's territory map IN-APP in a WebView.
  static void openMap(OrgSummary org) {
    if (!org.hasMap) return;
    Get.to(() => OrgWebScreen(
          url: webMapUrl(org.mapUrl!),
          title: org.mapLabel?.trim().isNotEmpty == true
              ? org.mapLabel!.trim()
              : 'Territory Map',
          // Door-knocking counters + live compass pinned under the map.
          bottomBar: const TerritoryMetricsBar(),
        ));
  }

  // The Solar Cowboys "Install Map" — a shared Google My Map of installs across
  // the territory. Unlike the per-org Territory Map, this is HARDCODED and only
  // ever surfaced for the Cowboys org (see OrgSpaceScreen._installMapCard), so
  // no other organization can see or open it. Uses the /embed form so the
  // custom map renders full-bleed and interactive inside the WebView.
  static const String installMapUrl =
      'https://www.google.com/maps/d/embed?mid=1GyOML0ZiYJ241bcN8Uh92eMH-RzxySc'
      '&ll=40.85166872820045%2C-89.68171569351496&z=15';

  /// Open the Cowboys Install Map IN-APP in a WebView.
  static void openInstallMap() {
    Get.to(() => const OrgWebScreen(
          url: installMapUrl,
          title: 'Install Map',
        ));
  }

  /// Open the org's appointment scheduler IN-APP in a WebView.
  static void openScheduler(OrgSummary org) {
    if (!org.hasBooking) return;
    Get.to(() => OrgWebScreen(
          url: org.bookingUrl!.trim(),
          title: org.bookingLabel?.trim().isNotEmpty == true
              ? org.bookingLabel!.trim()
              : 'Book an appointment',
        ));
  }

  /// Convert a stored map link into one that renders in a WebView. Only the
  /// ArcGIS Field Maps *app* deep link (`fieldmaps.arcgis.app`, center "lat,lon")
  /// needs rewriting to the public web Map Viewer; any real web page (including
  /// an arcgis.com Map Viewer link) is returned unchanged.
  static String webMapUrl(String stored) {
    final s = stored.trim();
    final uri = Uri.tryParse(s);
    if (uri == null) return s;
    final isFieldMapsApp =
        uri.host.contains('fieldmaps.arcgis') || uri.scheme == 'fieldmaps';
    if (!isFieldMapsApp) return s;
    final itemId = uri.queryParameters['itemID'] ??
        uri.queryParameters['itemId'] ??
        uri.queryParameters['webmap'];
    if (itemId == null || itemId.isEmpty) return s;
    final params = <String>['webmap=$itemId'];
    // Field Maps centers are "lat,lon"; the web Map Viewer wants "lon,lat".
    final center = uri.queryParameters['center'];
    if (center != null && center.contains(',')) {
      final p = center.split(',');
      if (p.length == 2) {
        params.add('center=${p[1].trim()},${p[0].trim()}');
      }
    }
    final scale = uri.queryParameters['scale'];
    if (scale != null && scale.isNotEmpty) params.add('scale=$scale');
    return 'https://www.arcgis.com/apps/mapviewer/index.html?${params.join('&')}';
  }
}
