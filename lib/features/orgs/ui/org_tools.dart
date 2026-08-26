import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';

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

  // Cowboys (Aveyo Springfield) Google reviews. Opened in the system browser,
  // NOT an in-app WebView — Google review pages throw consent / sign-in walls
  // inside a WebView, but render perfectly in Safari/Chrome where the user is
  // already signed in. Keyed to the business by its Google search query.
  static const String reviewsUrl =
      'https://www.google.com/search?q=aveyo+springfield+reviews';

  /// Open the Cowboys Google reviews in the system browser.
  static Future<void> openReviews() async {
    try {
      await launchUrl(Uri.parse(reviewsUrl),
          mode: LaunchMode.externalApplication);
    } catch (_) {
      // Best effort — nothing else to do if no browser can handle it.
    }
  }

  // Cowboys-only appointment booking widgets (LeadConnector), by team. Hardcoded
  // and surfaced ONLY in the Cowboys org (see OrgSpaceScreen._cowboysSchedulerCard),
  // so no other organization can see or open them.
  static const List<({String name, String url})> cowboysBookingTeams = [
    (
      name: 'Team Jordan',
      url: 'https://api.leadconnectorhq.com/widget/booking/BJqvy6nOcDmXhPCNAcnS',
    ),
    (
      name: 'Team Reed',
      url: 'https://api.leadconnectorhq.com/widget/booking/v5Suzpv6qekh6bH9Alex',
    ),
  ];

  /// Open any booking widget IN-APP in a WebView with the given title.
  static void openBookingUrl(String url, String title) {
    Get.to(() => OrgWebScreen(url: url.trim(), title: title));
  }

  /// Show the Cowboys two-team booking picker (Team Jordan / Team Reed), then
  /// open the chosen team's widget in-app. Reusable from Team HQ and the
  /// profile org card so it's the same experience everywhere.
  static void openCowboysBooking() {
    Get.bottomSheet(
      const _CowboysBookingSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
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

/// The Cowboys "Schedule an Appointment" picker — pick Team Jordan or Team Reed,
/// then their booking widget opens in-app. Shown by [OrgTools.openCowboysBooking].
class _CowboysBookingSheet extends StatelessWidget {
  const _CowboysBookingSheet();

  static const Color _kBg = Color(0xffF6F4F2);
  static const Color _kText = Color(0xff1A1010);
  static const Color _kMuted = Color(0xff9E9090);
  Color get _accent => AppColors.primaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 14.h),
                decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(4.r)),
              ),
            ),
            Text('Schedule an Appointment',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
            SizedBox(height: 4.h),
            Text('Choose the team you\'re booking with.',
                style: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 12.sp, color: _kMuted)),
            SizedBox(height: 16.h),
            for (final t in OrgTools.cowboysBookingTeams)
              Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: GestureDetector(
                  onTap: () {
                    Get.back();
                    OrgTools.openBookingUrl(t.url, t.name);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: _accent.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38.r,
                          height: 38.r,
                          decoration: BoxDecoration(
                              color: _accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10.r)),
                          child: Icon(Icons.event_available_rounded,
                              color: _accent, size: 20.r),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(t.name,
                              style: AppFonts.spaceGrotesk.copyWith(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w800,
                                  color: _kText)),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: _kMuted, size: 20.r),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
