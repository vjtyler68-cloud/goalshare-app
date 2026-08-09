import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/routes/app_routes.dart';

import '../controller/org_controller.dart';
import '../data/org_models.dart';
import '../data/org_visibility.dart';

const _kBg = Color(0xffF6F4F2);
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// Admin (trainer) dashboard: org identity + invite, a roster of members, and a
/// per-member detail limited to the whitelisted fields for that org type. Only
/// reachable when the current user is an org admin.
class OrgAdminScreen extends StatelessWidget {
  const OrgAdminScreen({super.key});

  Color get _accent => AppColors.primaryColor;

  @override
  Widget build(BuildContext context) {
    final c = OrgController.to;
    // Refresh roster on open.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => c.refreshRoster());
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
            onPressed: Get.back, icon: const Icon(Icons.arrow_back, color: _kText)),
        title: Text('Admin Dashboard',
            style: AppFonts.spaceGrotesk
                .copyWith(color: _kText, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: Obx(() {
        final org = c.myOrg.value;
        if (org == null || !org.isAdmin) {
          return Center(
            child: Text('You are not an org admin.',
                style: AppFonts.spaceGrotesk
                    .copyWith(color: _kMuted, fontSize: 14.sp)),
          );
        }
        return RefreshIndicator(
          onRefresh: c.refreshRoster,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 30.h),
            children: [
              _orgHeader(org),
              if (org.orgType == OrgType.salesOrg) ...[
                SizedBox(height: 12.h),
                GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.orgSpaceScreen),
                  child: Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.04), blurRadius: 8)
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44.r,
                          height: 44.r,
                          decoration: BoxDecoration(
                              color: _accent.withOpacity(0.12),
                              shape: BoxShape.circle),
                          child: Icon(Icons.workspaces_rounded,
                              color: _accent, size: 22.r),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Team HQ',
                                  style: AppFonts.spaceGrotesk.copyWith(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w800,
                                      color: _kText)),
                              Text('Announcements, feed & team goals — private',
                                  style: AppFonts.spaceGrotesk.copyWith(
                                      fontSize: 11.5.sp, color: _kMuted)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: _kMuted, size: 20.r),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: 16.h),
              _aggregateCard(org, c.roster),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Text('${org.orgType.memberLabel}s',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: _kText)),
                  SizedBox(width: 8.w),
                  if (c.rosterLoading.value)
                    SizedBox(
                        width: 14.r,
                        height: 14.r,
                        child: const CircularProgressIndicator(strokeWidth: 2)),
                  const Spacer(),
                  // Sales-only leaderboard toggle (default off).
                  if (org.orgType == OrgType.salesOrg && c.roster.isNotEmpty)
                    GestureDetector(
                      onTap: () => c.leaderboard.toggle(),
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: c.leaderboard.value
                              ? _accent
                              : _accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.leaderboard_rounded,
                                size: 14.r,
                                color: c.leaderboard.value
                                    ? Colors.white
                                    : _accent),
                            SizedBox(width: 4.w),
                            Text('Leaderboard',
                                style: AppFonts.spaceGrotesk.copyWith(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    color: c.leaderboard.value
                                        ? Colors.white
                                        : _accent)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12.h),
              if (c.roster.isEmpty && !c.rosterLoading.value)
                _emptyRoster(org)
              else
                ..._orderedRoster(org, c).asMap().entries.map(
                    (e) => _memberRow(org, e.value,
                        rank: c.leaderboard.value ? e.key + 1 : null)),
            ],
          ),
        );
      }),
    );
  }

  Widget _orgHeader(OrgSummary org) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent, AppColors.primaryDarkColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(org.orgType.label.toUpperCase(),
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: Colors.white.withOpacity(0.85))),
          SizedBox(height: 4.h),
          Text(org.name,
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          SizedBox(height: 14.h),
          Row(
            children: [
              Text('Invite code',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 11.sp, color: Colors.white.withOpacity(0.8))),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: org.inviteCode));
                  AppSnackBar.success('Code copied');
                },
                child: Icon(Icons.copy_rounded,
                    color: Colors.white, size: 18.r),
              ),
              SizedBox(width: 14.w),
              GestureDetector(
                onTap: () => SharePlus.instance.share(ShareParams(
                    text:
                        'Join our ${org.name} on Goalshare: ${org.inviteCode}')),
                child: Icon(Icons.ios_share_rounded,
                    color: Colors.white, size: 18.r),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(org.inviteCode,
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 5,
                  color: Colors.white)),
        ],
      ),
    );
  }

  // Roster ordered for display — leaderboard sorts sales reps by lead count.
  List<OrgMember> _orderedRoster(OrgSummary org, OrgController c) {
    final list = c.roster.toList();
    if (c.leaderboard.value && org.orgType == OrgType.salesOrg) {
      list.sort((a, b) => _numOf(b, 'leads.count')
          .compareTo(_numOf(a, 'leads.count')));
    }
    return list;
  }

  num _numOf(OrgMember m, String key) {
    final v = m.summary[key];
    return v is num ? v : 0;
  }

  bool _boolOf(OrgMember m, String key) => m.summary[key] == true;

  /// Roster-level aggregate stats, computed from members' shared summaries.
  Widget _aggregateCard(OrgSummary org, List<OrgMember> roster) {
    final withData = roster.where((m) => m.hasSummary).toList();
    final n = roster.length;
    int pct(bool Function(OrgMember) f) =>
        withData.isEmpty ? 0 : ((withData.where(f).length / withData.length) * 100).round();
    double avg(String key) => withData.isEmpty
        ? 0
        : withData.map((m) => _numOf(m, key)).fold<num>(0, (a, b) => a + b) /
            withData.length;

    final stats = <List<String>>[]; // [value, label]
    switch (org.orgType) {
      case OrgType.school:
        stats.add(['${pct((m) => _boolOf(m, 'rpm.goal_set'))}%', 'Active goal']);
        stats.add([
          '${pct((m) => _numOf(m, 'gratitude.streak_count') > 0 || _numOf(m, 'gratitude.entries_logged_count') > 0)}%',
          'Gratitude'
        ]);
        stats.add([
          '${pct((m) => _boolOf(m, 'daily_spark.viewed_today'))}%',
          'Spark today'
        ]);
        break;
      case OrgType.salesOrg:
        stats.add([
          '${withData.fold<num>(0, (a, m) => a + _numOf(m, 'leads.count')).round()}',
          'Team leads'
        ]);
        stats.add(['${avg('leads.conversion_rate').round()}%', 'Avg conv.']);
        stats.add(['${avg('rpm.quota_progress').round()}%', 'Avg quota']);
        break;
      case OrgType.gym:
        stats.add([
          '${pct((m) => _boolOf(m, 'nutrition.logged_today'))}%',
          'Logged today'
        ]);
        stats.add([
          '${pct((m) => _boolOf(m, 'nutrition.protein_target_met'))}%',
          'Protein met'
        ]);
        stats.add(['$n', org.orgType.memberLabel]);
        break;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, color: _accent, size: 20.r),
              SizedBox(width: 8.w),
              Text('$n ${org.orgType.memberLabel.toLowerCase()}'
                  '${n == 1 ? '' : 's'}',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: _kText)),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              for (final s in stats)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s[0],
                          style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w900,
                              color: _kText)),
                      Text(s[1],
                          style: AppFonts.spaceGrotesk
                              .copyWith(fontSize: 10.5.sp, color: _kMuted)),
                    ],
                  ),
                ),
            ],
          ),
          if (withData.length < n) ...[
            SizedBox(height: 8.h),
            Text('${n - withData.length} haven\'t reported yet.',
                style: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 10.5.sp, color: _kMuted)),
          ],
        ],
      ),
    );
  }

  Widget _memberRow(OrgSummary org, OrgMember m, {int? rank}) {
    final initial = m.name.trim().isEmpty ? '?' : m.name.trim()[0].toUpperCase();
    // A single at-a-glance metric on the row, per org type.
    String? metric;
    if (m.hasSummary) {
      if (org.orgType == OrgType.salesOrg) {
        metric = '${_numOf(m, 'leads.count').round()} leads';
      } else if (org.orgType == OrgType.gym) {
        metric = _boolOf(m, 'nutrition.logged_today') ? 'Logged ✓' : 'Not today';
      } else {
        metric = '${_numOf(m, 'gratitude.streak_count').round()}🔥';
      }
    }
    return GestureDetector(
      onTap: () => _openMember(org, m),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)
            ]),
        child: Row(
          children: [
            if (rank != null) ...[
              SizedBox(
                width: 22.r,
                child: Text('$rank',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w900,
                        color: rank <= 3 ? _accent : _kMuted)),
              ),
              SizedBox(width: 6.w),
            ],
            Container(
              width: 42.r,
              height: 42.r,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: _accent.withOpacity(0.12)),
              child: ClipOval(
                child: m.avatar.isNotEmpty
                    ? Image.network(m.avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _initFill(initial))
                    : _initFill(initial),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: _kText)),
                  Text(
                      m.isAdmin
                          ? org.orgType.adminLabel
                          : (m.joinedAt != null
                              ? 'Joined ${_md(m.joinedAt!)}'
                              : org.orgType.memberLabel),
                      style: AppFonts.spaceGrotesk
                          .copyWith(fontSize: 11.5.sp, color: _kMuted)),
                ],
              ),
            ),
            if (metric != null) ...[
              Text(metric,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: _accent)),
              SizedBox(width: 6.w),
            ],
            Icon(Icons.chevron_right, color: _kMuted, size: 20.r),
          ],
        ),
      ),
    );
  }

  Widget _initFill(String initial) => Center(
        child: Text(initial,
            style: AppFonts.spaceGrotesk.copyWith(
                color: _accent, fontSize: 16.sp, fontWeight: FontWeight.w800)),
      );

  void _openMember(OrgSummary org, OrgMember m) {
    final keys = OrgVisibility.allowedKeys(org.orgType).toList()..sort();
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: 0.8.sh),
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4.r)),
              ),
            ),
            Text(m.name,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: _kText)),
            SizedBox(height: 4.h),
            Text(
                m.joinedAt != null
                    ? '${org.orgType.memberLabel} · joined ${_md(m.joinedAt!)}'
                    : org.orgType.memberLabel,
                style: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 12.5.sp, color: _kMuted)),
            SizedBox(height: 18.h),
            Text('WHAT YOU CAN SEE',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: _kMuted)),
            SizedBox(height: 10.h),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final k in keys)
                    Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded,
                              size: 18.r, color: _accent),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(_fieldLabel(k),
                                style: AppFonts.spaceGrotesk.copyWith(
                                    fontSize: 13.5.sp, color: _kText)),
                          ),
                          Text(_fieldValue(k, m.summary),
                              style: AppFonts.spaceGrotesk.copyWith(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w800,
                                  color: m.hasSummary ? _kText : _kMuted)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                  color: _accent.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12.r)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 16.r, color: _accent),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                        org.orgType == OrgType.school
                            ? 'Journal entries and personal notes are always private to the student.'
                            : org.orgType == OrgType.gym
                                ? 'Exact foods and macros stay private — only counts/streaks are ever shared.'
                                : 'Budget and personal notes are always private to the member.',
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 11.5.sp, color: _kText, height: 1.4)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            Center(
              child: Text(
                  m.hasSummary
                      ? (m.summaryAt != null
                          ? 'Updated ${_md(m.summaryAt!)}'
                          : 'Updated recently')
                      : 'Live values appear as they use the app.',
                  style: AppFonts.spaceGrotesk
                      .copyWith(fontSize: 11.sp, color: _kMuted)),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _emptyRoster(OrgSummary org) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
      child: Column(
        children: [
          Icon(Icons.group_add_outlined, size: 34.r, color: _kMuted),
          SizedBox(height: 8.h),
          Text('No ${org.orgType.memberLabel.toLowerCase()}s yet',
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: _kText)),
          SizedBox(height: 4.h),
          Text('Share your invite code ${org.inviteCode} to add them.',
              textAlign: TextAlign.center,
              style: AppFonts.spaceGrotesk
                  .copyWith(fontSize: 12.5.sp, color: _kMuted)),
        ],
      ),
    );
  }

  String _md(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${m[d.month - 1]} ${d.day}';
  }

  /// Display value for a field key from a member's summary.
  String _fieldValue(String key, Map<String, dynamic> summary) {
    if (!summary.containsKey(key)) return 'No data';
    final v = summary[key];
    const boolKeys = {
      'rpm.goal_set',
      'daily_spark.viewed_today',
      'vision_board.created',
      'nutrition.logged_today',
      'nutrition.protein_target_met',
    };
    const pctKeys = {'leads.conversion_rate', 'rpm.quota_progress'};
    if (boolKeys.contains(key)) return v == true ? 'Yes' : 'No';
    if (pctKeys.contains(key)) return '${v is num ? v.round() : 0}%';
    return v is num ? '${v.round()}' : v.toString();
  }

  /// Human label for a `module.field` visibility key.
  String _fieldLabel(String key) {
    const labels = {
      'rpm.goal_set': 'Has an active goal',
      'rpm.goal_completed': 'Goals completed',
      'rpm.quota_progress': 'Quota progress',
      'gratitude.streak_count': 'Gratitude streak',
      'gratitude.entries_logged_count': 'Gratitude entries',
      'daily_spark.viewed_today': 'Viewed Daily Spark today',
      'vision_board.created': 'Has a vision board',
      'leads.count': 'Lead count',
      'leads.pipeline_stage': 'Pipeline stage',
      'leads.conversion_rate': 'Conversion rate',
      'nutrition.logged_today': 'Logged nutrition today',
      'nutrition.protein_target_met': 'Protein target met',
      'accountability_buddies.checkin_streak': 'Check-in streak',
    };
    return labels[key] ?? key;
  }
}
