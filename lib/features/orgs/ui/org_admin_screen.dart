import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';

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
              SizedBox(height: 16.h),
              _aggregateCard(org, c.roster.length),
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
                ],
              ),
              SizedBox(height: 12.h),
              if (c.roster.isEmpty && !c.rosterLoading.value)
                _emptyRoster(org)
              else
                ...c.roster.map((m) => _memberRow(org, m)),
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

  Widget _aggregateCard(OrgSummary org, int memberCount) {
    // Roster-level aggregates (member-metric-driven percentages arrive with the
    // member-summary sync). For now show the roster size clearly.
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
          ]),
      child: Row(
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
                color: _accent.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(Icons.groups_rounded, color: _accent, size: 22.r),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$memberCount ${org.orgType.memberLabel.toLowerCase()}'
                    '${memberCount == 1 ? '' : 's'}',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: _kText)),
                Text('Engagement stats appear as your team uses the app.',
                    style: AppFonts.spaceGrotesk
                        .copyWith(fontSize: 11.5.sp, color: _kMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _memberRow(OrgSummary org, OrgMember m) {
    final initial = m.name.trim().isEmpty ? '?' : m.name.trim()[0].toUpperCase();
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
    final fields = OrgVisibility.allowedKeys(org.orgType)
        .map(_fieldLabel)
        .toList()
      ..sort();
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
                  for (final f in fields)
                    Padding(
                      padding: EdgeInsets.only(bottom: 10.h),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded,
                              size: 18.r, color: _accent),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(f,
                                style: AppFonts.spaceGrotesk.copyWith(
                                    fontSize: 13.5.sp, color: _kText)),
                          ),
                          Text('—',
                              style: AppFonts.spaceGrotesk.copyWith(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: _kMuted)),
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
              child: Text('Live values appear as members use the app.',
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
