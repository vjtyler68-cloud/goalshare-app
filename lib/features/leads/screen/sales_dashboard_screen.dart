import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';

import '../controller/leads_controller.dart';
import '../model/lead.dart';
import 'lead_form_screen.dart';

const _kBg = Color(0xffF6F4F2);
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);
const _kGreen = Color(0xff22C55E);

/// The Sales CRM production dashboard: monthly pace vs goal, pipeline value and
/// forecast, close rate, commission earned, follow-ups due, and pipeline by
/// stage. Built on top of the existing Leads data — every number is live.
class SalesDashboardScreen extends StatelessWidget {
  const SalesDashboardScreen({super.key});

  LeadsController get c => Get.isRegistered<LeadsController>()
      ? Get.find<LeadsController>()
      : Get.put(LeadsController());

  Color get _accent => AppColors.primaryColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
            onPressed: Get.back, icon: const Icon(Icons.arrow_back, color: _kText)),
        title: Text('Sales CRM',
            style: AppFonts.spaceGrotesk
                .copyWith(color: _kText, fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _editTargets,
            icon: Icon(Icons.tune_rounded, color: _kMuted, size: 22.r),
          ),
        ],
      ),
      body: Obx(() {
        c.leads.length; // reactive
        c.monthlyGoal.value;
        c.commissionRate.value;
        return ListView(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 40.h),
          children: [
            _monthHero(),
            SizedBox(height: 16.h),
            _kpiGrid(),
            SizedBox(height: 20.h),
            _followUps(),
            SizedBox(height: 20.h),
            _pipeline(),
            SizedBox(height: 20.h),
            _viewAll(),
          ],
        );
      }),
    );
  }

  // ── Monthly hero ────────────────────────────────────────────────────────────
  Widget _monthHero() {
    final rev = c.revenueThisMonth;
    final goal = c.monthlyGoal.value;
    final pct = c.goalProgress;
    final projected = c.projectedRevenue;
    final earnings = c.earningsThisMonth;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent, AppColors.primaryDarkColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THIS MONTH',
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.white.withOpacity(0.85))),
          SizedBox(height: 4.h),
          Text(_money(rev),
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 40.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          Text('${c.dealsWonThisMonth} ${c.dealsWonThisMonth == 1 ? 'deal' : 'deals'} won'
              '${c.avgDealThisMonth > 0 ? '  ·  avg ${_money(c.avgDealThisMonth)}' : ''}',
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 12.5.sp, color: Colors.white.withOpacity(0.9))),
          if (goal > 0) ...[
            SizedBox(height: 16.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 10,
                backgroundColor: Colors.white.withOpacity(0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Text('${(pct * 100).round()}% of ${_money(goal)} goal',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const Spacer(),
                Text('On pace for ${_money(projected)}',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 12.sp, color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ] else ...[
            SizedBox(height: 12.h),
            GestureDetector(
              onTap: _editTargets,
              child: Row(
                children: [
                  Icon(Icons.flag_rounded, color: Colors.white, size: 16.r),
                  SizedBox(width: 6.w),
                  Text('Set a monthly goal',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ],
              ),
            ),
          ],
          if (c.commissionRate.value > 0) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10.r)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.payments_rounded, color: Colors.white, size: 16.r),
                  SizedBox(width: 8.w),
                  Text('${_money(earnings)} commission earned '
                      '(${c.commissionRate.value.round()}%)',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── KPI grid ────────────────────────────────────────────────────────────────
  Widget _kpiGrid() {
    return Row(
      children: [
        _kpi('Pipeline', _money(c.pipelineValue), Icons.filter_alt_rounded,
            '${c.openLeads.length} open'),
        SizedBox(width: 12.w),
        _kpi('Forecast', _money(c.weightedPipeline), Icons.insights_rounded,
            'weighted'),
      ],
    );
  }

  Widget _kpi(String label, String value, IconData icon, String sub) {
    return Expanded(
      child: Container(
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
            Icon(icon, color: _accent, size: 20.r),
            SizedBox(height: 10.h),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    color: _kText)),
            Text('$label · $sub',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 10.5.sp, color: _kMuted)),
          ],
        ),
      ),
    );
  }

  Widget _statRow() {
    Widget bit(String v, String l, Color color) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(v,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w900,
                      color: color)),
              Text(l,
                  style: AppFonts.spaceGrotesk
                      .copyWith(fontSize: 10.5.sp, color: _kMuted)),
            ],
          ),
        );
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
          ]),
      child: Row(
        children: [
          bit('${c.closeRate.round()}%', 'Close rate', _kText),
          bit(_money(c.revenueThisWeek), 'This week', _kGreen),
          bit('${c.wonCount}', 'Total won', _accent),
        ],
      ),
    );
  }

  // ── Follow-ups ───────────────────────────────────────────────────────────────
  Widget _followUps() {
    final due = c.followUpsDue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Follow-ups due',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
            if (due.isNotEmpty) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                    color: _accent, borderRadius: BorderRadius.circular(20.r)),
                child: Text('${due.length}',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ],
          ],
        ),
        SizedBox(height: 10.h),
        if (due.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r)),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: _kGreen, size: 20.r),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text('All caught up — no follow-ups due.',
                      style: AppFonts.spaceGrotesk
                          .copyWith(fontSize: 13.sp, color: _kMuted)),
                ),
              ],
            ),
          )
        else
          ...due.take(5).map(_followRow),
      ],
    );
  }

  Widget _followRow(Lead l) {
    final overdue = l.reminderAt!.isBefore(
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day));
    return GestureDetector(
      onTap: () => Get.to(() => LeadFormScreen(lead: l)),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)
            ]),
        child: Row(
          children: [
            Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: _accent.withOpacity(0.12)),
              child: Center(
                child: Text(l.initials,
                    style: AppFonts.spaceGrotesk.copyWith(
                        color: _accent,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800)),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.name.isEmpty ? 'Lead' : l.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: _kText)),
                  Text(
                      '${overdue ? 'Overdue' : 'Due'} · ${l.status}'
                      '${l.dealValue > 0 ? ' · ${_money(l.dealValue)}' : ''}',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 11.sp,
                          color: overdue ? _accent : _kMuted,
                          fontWeight:
                              overdue ? FontWeight.w700 : FontWeight.w400)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: _kMuted, size: 20.r),
          ],
        ),
      ),
    );
  }

  // ── Pipeline by stage ────────────────────────────────────────────────────────
  Widget _pipeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pipeline',
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 15.sp, fontWeight: FontWeight.w800, color: _kText)),
        SizedBox(height: 6.h),
        _statRow(),
        SizedBox(height: 12.h),
        for (final stage in const ['New', 'Contacted', 'Appointment', 'Won'])
          _stageRow(stage),
      ],
    );
  }

  Widget _stageRow(String stage) {
    final count = c.countForStatus(stage);
    final value = c.valueForStatus(stage);
    final maxCount = ['New', 'Contacted', 'Appointment', 'Won']
        .map(c.countForStatus)
        .fold<int>(1, (a, b) => b > a ? b : a);
    return GestureDetector(
      onTap: () {
        c.statusFilter.value = stage;
        Get.back(); // back to the leads list, filtered to this stage
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)
            ]),
        child: Column(
          children: [
            Row(
              children: [
                Text(stage,
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w800,
                        color: _kText)),
                SizedBox(width: 8.w),
                Text('$count',
                    style: AppFonts.spaceGrotesk
                        .copyWith(fontSize: 12.sp, color: _kMuted)),
                const Spacer(),
                Text(_money(value),
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w800,
                        color: stage == 'Won' ? _kGreen : _accent)),
              ],
            ),
            SizedBox(height: 8.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: LinearProgressIndicator(
                value: (count / maxCount).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: _kMuted.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(
                    stage == 'Won' ? _kGreen : _accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _viewAll() {
    return GestureDetector(
      onTap: () {
        c.statusFilter.value = 'All';
        Get.back();
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 15.h),
        decoration: BoxDecoration(
            color: _accent, borderRadius: BorderRadius.circular(30.r)),
        child: Center(
          child: Text('View all leads',
              style: AppFonts.spaceGrotesk.copyWith(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  // ── Targets sheet ─────────────────────────────────────────────────────────────
  void _editTargets() {
    final goalCtrl = TextEditingController(
        text: c.monthlyGoal.value > 0
            ? c.monthlyGoal.value.toStringAsFixed(0)
            : '');
    final commCtrl = TextEditingController(
        text: c.commissionRate.value > 0
            ? c.commissionRate.value.toStringAsFixed(0)
            : '');
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your targets',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
            SizedBox(height: 14.h),
            _label('Monthly revenue goal (\$)'),
            SizedBox(height: 6.h),
            _numField(goalCtrl, 'e.g. 50000'),
            SizedBox(height: 14.h),
            _label('Commission rate (%)'),
            SizedBox(height: 6.h),
            _numField(commCtrl, 'e.g. 10'),
            SizedBox(height: 18.h),
            GestureDetector(
              onTap: () {
                c.setMonthlyGoal(double.tryParse(
                        goalCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                    0);
                c.setCommissionRate(double.tryParse(
                        commCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                    0);
                Get.back();
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                decoration: BoxDecoration(
                    color: _accent, borderRadius: BorderRadius.circular(30.r)),
                child: Center(
                  child: Text('Save',
                      style: AppFonts.spaceGrotesk.copyWith(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _label(String t) => Text(t,
      style: AppFonts.spaceGrotesk.copyWith(
          fontSize: 12.sp, fontWeight: FontWeight.w700, color: _kMuted));

  Widget _numField(TextEditingController ctrl, String hint) => TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        style: AppFonts.spaceGrotesk.copyWith(fontSize: 15.sp, color: _kText),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xffF6F4F2),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none),
        ),
      );

  // ── Money formatting ──────────────────────────────────────────────────────────
  static String _money(double v) {
    final n = v.round();
    final neg = n < 0;
    final s = n.abs().toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return '${neg ? '-' : ''}\$$b';
  }
}
