import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/core/user_info/user_info_controller.dart';

import '../controller/org_controller.dart';
import '../controller/org_space_controller.dart';
import '../data/org_models.dart';

const _kBg = Color(0xffF6F4F2);
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// Team HQ — a private space for one org's members: Announcements (admin posts),
/// Team Feed (everyone posts), and shared Team Goals. Server-enforced to that
/// org's membership, so no other org or the public can see it.
class OrgSpaceScreen extends StatefulWidget {
  const OrgSpaceScreen({super.key});

  @override
  State<OrgSpaceScreen> createState() => _OrgSpaceScreenState();
}

class _OrgSpaceScreenState extends State<OrgSpaceScreen> {
  Color get _accent => AppColors.primaryColor;

  @override
  void initState() {
    super.initState();
    final org = OrgController.to.myOrg.value;
    if (org != null) OrgSpaceController.to.load(org.id);
  }

  @override
  Widget build(BuildContext context) {
    final org = OrgController.to.myOrg.value;
    final isAdmin = OrgController.to.isAdmin;
    final space = OrgSpaceController.to;
    if (org == null) {
      return const Scaffold(
          backgroundColor: _kBg, body: Center(child: Text('No organization')));
    }
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kBg,
          elevation: 0,
          leading: IconButton(
              onPressed: Get.back,
              icon: const Icon(Icons.arrow_back, color: _kText)),
          title: Column(
            children: [
              Text('${org.name} · HQ',
                  style: AppFonts.spaceGrotesk.copyWith(
                      color: _kText,
                      fontWeight: FontWeight.w800,
                      fontSize: 16.sp)),
              Text('Private to your team',
                  style: AppFonts.spaceGrotesk
                      .copyWith(color: _kMuted, fontSize: 10.sp)),
            ],
          ),
          centerTitle: true,
          bottom: TabBar(
            labelColor: _accent,
            unselectedLabelColor: _kMuted,
            indicatorColor: _accent,
            labelStyle: AppFonts.spaceGrotesk
                .copyWith(fontWeight: FontWeight.w800, fontSize: 12.5.sp),
            tabs: const [
              Tab(text: 'Announcements'),
              Tab(text: 'Feed'),
              Tab(text: 'Goals'),
            ],
          ),
        ),
        body: Obx(() {
          if (space.loading.value &&
              space.announcements.isEmpty &&
              space.feed.isEmpty &&
              space.goals.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            children: [
              _announcementsTab(space, isAdmin),
              _feedTab(space),
              _goalsTab(space, isAdmin),
            ],
          );
        }),
      ),
    );
  }

  // ── Territory Map (data map grid) ─────────────────────────────────────────────
  // A per-org map link (e.g. an ArcGIS Field Maps deep link). Only orgs that have
  // one set ever show it, so it's private to that team. Members tap to open it in
  // the map app; admins can set / edit / remove the link.
  Widget _mapCard(OrgSummary org, bool isAdmin) {
    final hasMap = org.hasMap;
    if (!hasMap && !isAdmin) return const SizedBox.shrink();
    final subtitle = hasMap
        ? (org.mapLabel?.trim().isNotEmpty == true
            ? org.mapLabel!.trim()
            : 'Open your team\'s data map grid')
        : 'Add a map link only your team can see';
    return GestureDetector(
      onTap: hasMap
          ? () => _openMap(org.mapUrl!)
          : (isAdmin ? () => _editMap(org) : null),
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_accent, _accent.withOpacity(0.72)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
                color: _accent.withOpacity(0.28),
                blurRadius: 14,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42.r,
              height: 42.r,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r)),
              child: Icon(Icons.map_rounded, color: Colors.white, size: 24.r),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Territory Map',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  SizedBox(height: 2.h),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 11.5.sp,
                          color: Colors.white.withOpacity(0.9))),
                ],
              ),
            ),
            if (isAdmin)
              GestureDetector(
                onTap: () => _editMap(org),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Icon(Icons.edit_rounded,
                      color: Colors.white.withOpacity(0.95), size: 20.r),
                ),
              ),
            SizedBox(width: 2.w),
            Icon(hasMap ? Icons.open_in_new_rounded : Icons.add_rounded,
                color: Colors.white, size: 22.r),
          ],
        ),
      ),
    );
  }

  Future<void> _openMap(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      AppSnackBar.error('That map link looks invalid.');
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        AppSnackBar.error(
            'Couldn\'t open the map. Make sure the map app is installed.');
      }
    } catch (_) {
      AppSnackBar.error('Couldn\'t open the map on this device.');
    }
  }

  // Convenience default so setting up the Cowboys map is one tap: pre-fill the
  // ArcGIS Field Maps link when this org looks like the Cowboys org and none is
  // set yet. Admins can always paste a different link.
  //
  // center/scale only set the STARTING camera — the grid map (itemID) holds all
  // its data regardless. This opens zoomed out to the whole state of Illinois
  // (center ≈ state centroid, scale ≈ 1:5.5M) instead of just the Joliet block,
  // so the full grid is visible on open; users can still pan and zoom anywhere.
  static const String _cowboysMapUrl =
      'https://fieldmaps.arcgis.app?referenceContext=center&itemID=2f5cd680134d4eeea6cb9c72dc22b596&center=39.7392,-89.2700&scale=5500000';

  void _editMap(OrgSummary org) {
    final initialUrl = org.hasMap
        ? org.mapUrl!
        : (org.name.toLowerCase().contains('cowboys') ? _cowboysMapUrl : '');
    final urlCtrl = TextEditingController(text: initialUrl);
    final labelCtrl = TextEditingController(text: org.mapLabel ?? '');
    Get.bottomSheet(
      _sheet(
        title: 'Territory map',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Paste a map link (e.g. an ArcGIS Field Maps link). Only your '
                'team\'s members can see or open it.',
                style: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 11.5.sp, color: _kMuted, height: 1.45)),
            SizedBox(height: 12.h),
            TextField(
              controller: urlCtrl,
              maxLines: 3,
              minLines: 1,
              keyboardType: TextInputType.url,
              style:
                  AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, color: _kText),
              decoration: _dec('https://…'),
            ),
            SizedBox(height: 10.h),
            TextField(
              controller: labelCtrl,
              maxLength: 60,
              textCapitalization: TextCapitalization.sentences,
              style:
                  AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, color: _kText),
              decoration: _dec('Label (optional, e.g. Joliet grid)'),
            ),
            _primaryBtn('Save map', () async {
              final err = await OrgController.to
                  .setMap(urlCtrl.text.trim(), labelCtrl.text.trim());
              Get.back();
              if (err != null) {
                AppSnackBar.error(err);
              } else {
                AppSnackBar.success('Territory map saved.');
              }
            }),
            if (org.hasMap)
              Center(
                child: TextButton(
                  onPressed: () async {
                    final err = await OrgController.to.setMap('', '');
                    Get.back();
                    if (err != null) AppSnackBar.error(err);
                  },
                  child: Text('Remove map',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w700,
                          color: _kMuted)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Announcements ───────────────────────────────────────────────────────────
  Widget _announcementsTab(OrgSpaceController space, bool isAdmin) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => space.load(OrgController.to.myOrg.value!.id),
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 90.h),
            children: [
              Obx(() {
                final o = OrgController.to.myOrg.value;
                return o == null
                    ? const SizedBox.shrink()
                    : _mapCard(o, isAdmin);
              }),
              if (space.announcements.isEmpty)
                _empty(Icons.campaign_rounded, 'No announcements yet',
                    isAdmin
                        ? 'Tap + to post an update for your team.'
                        : 'Your manager\'s updates will show up here.')
              else
                ...space.announcements.map((p) => _postCard(space, p, false)),
            ],
          ),
        ),
        if (isAdmin) _fab(() => _compose('announcement'), Icons.campaign_rounded),
      ],
    );
  }

  // ── Feed ─────────────────────────────────────────────────────────────────────
  Widget _feedTab(OrgSpaceController space) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => space.load(OrgController.to.myOrg.value!.id),
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 90.h),
            children: [
              if (space.feed.isEmpty)
                _empty(Icons.forum_rounded, 'Nothing here yet',
                    'Be the first to share something with the team.')
              else
                ...space.feed.map((p) => _postCard(space, p, true)),
            ],
          ),
        ),
        _fab(() => _compose('feed'), Icons.edit_rounded),
      ],
    );
  }

  String? get _myUserId => Get.isRegistered<UserInfoController>()
      ? Get.find<UserInfoController>().userData.value?.id
      : null;

  Widget _postCard(OrgSpaceController space, OrgPost p, bool showLike) {
    final initial =
        p.authorName.trim().isEmpty ? '?' : p.authorName.trim()[0].toUpperCase();
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: p.isAnnouncement
            ? Border.all(color: _accent.withOpacity(0.35), width: 1.2)
            : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34.r,
                height: 34.r,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: _accent.withOpacity(0.12)),
                child: ClipOval(
                  child: p.authorAvatar.isNotEmpty
                      ? Image.network(p.authorAvatar,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _initFill(initial))
                      : _initFill(initial),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(p.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: _kText)),
              ),
              if (p.isAnnouncement)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                      color: _accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20.r)),
                  child: Text('Announcement',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          color: _accent)),
                ),
              _postMenu(space, p),
            ],
          ),
          SizedBox(height: 8.h),
          Text(p.text,
              style: AppFonts.spaceGrotesk
                  .copyWith(fontSize: 14.sp, color: _kText, height: 1.45)),
          if (showLike) ...[
            SizedBox(height: 10.h),
            GestureDetector(
              onTap: () => space.like(p),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                      p.likedByMe
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 18.r,
                      color: p.likedByMe ? _accent : _kMuted),
                  SizedBox(width: 6.w),
                  Text('${p.likeCount}',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: _kMuted)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _postMenu(OrgSpaceController space, OrgPost p) {
    final canDelete = OrgController.to.isAdmin || p.authorId == _myUserId;
    if (!canDelete) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => space.removePost(p),
      child: Padding(
        padding: EdgeInsets.only(left: 4.w),
        child: Icon(Icons.close_rounded, size: 16.r, color: _kMuted),
      ),
    );
  }

  // ── Goals ────────────────────────────────────────────────────────────────────
  Widget _goalsTab(OrgSpaceController space, bool isAdmin) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => space.load(OrgController.to.myOrg.value!.id),
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 90.h),
            children: [
              if (space.goals.isEmpty)
                _empty(Icons.flag_rounded, 'No team goals yet',
                    isAdmin
                        ? 'Tap + to set a shared target for the team.'
                        : 'Your manager will set team targets here.')
              else
                ...space.goals.map((g) => _goalCard(space, g, isAdmin)),
            ],
          ),
        ),
        if (isAdmin) _fab(_createGoal, Icons.flag_rounded),
      ],
    );
  }

  Widget _goalCard(OrgSpaceController space, OrgGoal g, bool isAdmin) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(g.title,
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: _kText)),
              ),
              Text('${g.progress} / ${g.target}',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: _accent)),
              if (isAdmin)
                GestureDetector(
                  onTap: () => space.removeGoal(g),
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: Icon(Icons.close_rounded, size: 16.r, color: _kMuted),
                  ),
                ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(_metricLabel(g.metricKey),
              style: AppFonts.spaceGrotesk
                  .copyWith(fontSize: 10.5.sp, color: _kMuted)),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: g.fraction,
              minHeight: 8,
              backgroundColor: _kMuted.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(_accent),
            ),
          ),
          if (isAdmin && g.isManual) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                _bump(space, g, -1, Icons.remove),
                SizedBox(width: 10.w),
                _bump(space, g, 1, Icons.add),
                const Spacer(),
                Text('Manual — tap to update',
                    style: AppFonts.spaceGrotesk
                        .copyWith(fontSize: 10.sp, color: _kMuted)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _bump(OrgSpaceController space, OrgGoal g, int delta, IconData icon) =>
      GestureDetector(
        onTap: () => space.bumpGoal(g, delta),
        child: Container(
          width: 34.r,
          height: 34.r,
          decoration: BoxDecoration(color: _accent, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 18.r),
        ),
      );

  String _metricLabel(String key) {
    switch (key) {
      case 'leads.count':
        return 'Auto — total team leads';
      case 'rpm.goal_completed':
        return 'Auto — goals completed by the team';
      default:
        return 'Manual progress';
    }
  }

  // ── Composers ────────────────────────────────────────────────────────────────
  void _compose(String kind) {
    final ctrl = TextEditingController();
    Get.bottomSheet(
      _sheet(
        title: kind == 'announcement' ? 'New announcement' : 'Share with the team',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ctrl,
              maxLines: 4,
              maxLength: 1000,
              autofocus: true,
              style: AppFonts.spaceGrotesk
                  .copyWith(fontSize: 14.sp, color: _kText),
              decoration: InputDecoration(
                hintText: kind == 'announcement'
                    ? 'What does the team need to know?'
                    : 'Share a win, a tip, anything…',
                filled: true,
                fillColor: const Color(0xffF6F4F2),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none),
              ),
            ),
            _primaryBtn('Post', () async {
              final err = await OrgSpaceController.to.post(kind, ctrl.text.trim());
              Get.back();
              if (err != null) AppSnackBar.error(err);
            }),
          ],
        ),
      ),
    );
  }

  void _createGoal() {
    final titleCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    var metric = 'manual';
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheet) => _sheet(
          title: 'New team goal',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleCtrl,
                textCapitalization: TextCapitalization.sentences,
                style: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 14.sp, color: _kText),
                decoration: _dec('Goal (e.g. Close 50 deals this month)'),
              ),
              SizedBox(height: 10.h),
              TextField(
                controller: targetCtrl,
                keyboardType: TextInputType.number,
                style: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 14.sp, color: _kText),
                decoration: _dec('Target number'),
              ),
              SizedBox(height: 12.h),
              Text('TRACK BY',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: _kMuted)),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  for (final m in const [
                    ['manual', 'Manual'],
                    ['leads.count', 'Team leads'],
                    ['rpm.goal_completed', 'Goals done'],
                  ])
                    GestureDetector(
                      onTap: () => setSheet(() => metric = m[0]),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 9.h),
                        decoration: BoxDecoration(
                            color: metric == m[0]
                                ? _accent
                                : const Color(0xffF6F4F2),
                            borderRadius: BorderRadius.circular(20.r)),
                        child: Text(m[1],
                            style: AppFonts.spaceGrotesk.copyWith(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w700,
                                color:
                                    metric == m[0] ? Colors.white : _kText)),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 6.h),
              _primaryBtn('Create goal', () async {
                final t = int.tryParse(targetCtrl.text.trim()) ?? 0;
                final err = await OrgSpaceController.to
                    .createGoal(titleCtrl.text.trim(), t, metric);
                Get.back();
                if (err != null) AppSnackBar.error(err);
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bits ────────────────────────────────────────────────────────────────────
  Widget _fab(VoidCallback onTap, IconData icon) => Positioned(
        right: 20.w,
        bottom: 24.h,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 54.r,
            height: 54.r,
            decoration: BoxDecoration(
              color: _accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: _accent.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24.r),
          ),
        ),
      );

  Widget _sheet({required String title, required Widget child}) {
    return Padding(
      padding: EdgeInsets.only(bottom: Get.mediaQuery.viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 22.h),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
            SizedBox(height: 14.h),
            child,
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle:
            AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, color: _kMuted),
        filled: true,
        fillColor: const Color(0xffF6F4F2),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none),
      );

  Widget _primaryBtn(String label, VoidCallback onTap) => Padding(
        padding: EdgeInsets.only(top: 14.h),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 15.h),
            decoration: BoxDecoration(
                color: _accent, borderRadius: BorderRadius.circular(30.r)),
            child: Center(
              child: Text(label,
                  style: AppFonts.spaceGrotesk.copyWith(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      );

  Widget _initFill(String initial) => Center(
        child: Text(initial,
            style: AppFonts.spaceGrotesk.copyWith(
                color: _accent, fontSize: 14.sp, fontWeight: FontWeight.w800)),
      );

  Widget _empty(IconData icon, String title, String body) {
    return Padding(
      padding: EdgeInsets.only(top: 60.h),
      child: Column(
        children: [
          Icon(icon, size: 44.r, color: _accent.withOpacity(0.6)),
          SizedBox(height: 12.h),
          Text(title,
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: _kText)),
          SizedBox(height: 6.h),
          Text(body,
              textAlign: TextAlign.center,
              style: AppFonts.spaceGrotesk
                  .copyWith(fontSize: 12.5.sp, color: _kMuted, height: 1.5)),
        ],
      ),
    );
  }
}
