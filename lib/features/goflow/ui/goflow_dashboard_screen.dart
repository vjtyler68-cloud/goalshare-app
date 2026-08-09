import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/const/app_fonts.dart';
import '../../sharing/controller/sharing_controller.dart';
import '../../sharing/data/shared_summary.dart';
import '../controller/goflow_controller.dart';
import '../data/goflow_content.dart';
import '../data/goflow_models.dart';
import '../data/goflow_pregnancy.dart';
import '../service/goflow_insights.dart';
import '../service/goflow_service.dart';
import 'goflow_calendar.dart';
import 'goflow_log_sheet.dart';
import 'goflow_onboarding.dart';
import 'goflow_settings_sheet.dart';

const _kBg = Color(0xffF6F4F2);
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// GoFlow's home. Routes by state: the intro questionnaire on first run, then
/// either the full self-tracker or the simple partner view.
class GoFlowDashboardScreen extends StatelessWidget {
  const GoFlowDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Obx(() {
          final c = GoFlowController.to;
          if (!c.ready.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final accent = c.accentColor;
          return Column(
            children: [
              _header(accent, showSettings: c.onboarded),
              Expanded(
                child: !c.onboarded
                    ? const GoFlowOnboarding()
                    : c.isPartner
                        ? const _PartnerView()
                        : c.isPregnant
                            ? const _PregnancyView()
                            : const _SelfView(),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _header(Color accent, {required bool showSettings}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(8.w, 4.h, 12.w, 4.h),
      child: Row(
        children: [
          IconButton(
              onPressed: Get.back,
              icon: const Icon(Icons.arrow_back, color: _kText)),
          Icon(Icons.spa_rounded, color: accent, size: 20.r),
          SizedBox(width: 6.w),
          Text('GoFlow',
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: _kText)),
          const Spacer(),
          if (showSettings)
            IconButton(
                onPressed: GoFlowSettingsSheet.show,
                icon: Icon(Icons.settings_outlined, color: _kMuted, size: 22.r)),
        ],
      ),
    );
  }
}

// ── Self tracker ──────────────────────────────────────────────────────────────
class _SelfView extends StatelessWidget {
  const _SelfView();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = GoFlowController.to;
      c.entries.length; // reactive
      c.settings.value;
      final accent = c.accentColor;
      final status = c.status;
      final today = DateTime.now();
      final loggedToday = c.entryFor(today) != null;

      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 30.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ringCard(accent, status),
            SizedBox(height: 16.h),
            _predictionCard(accent, status),
            if (status.phase != null) ...[
              SizedBox(height: 16.h),
              _sparkCard(accent, status.phase!),
              SizedBox(height: 12.h),
              _dailyActionCard(accent, status.phase!),
            ],
            if (status.ovulationDate != null) ...[
              SizedBox(height: 16.h),
              _fertilityCard(accent, status),
            ],
            SizedBox(height: 16.h),
            _logButton(accent, loggedToday),
            if (c.perimenopauseMode) ...[
              SizedBox(height: 22.h),
              _perimenopauseCard(accent, c),
            ],
            SizedBox(height: 22.h),
            _insightsSection(accent, c),
            SizedBox(height: 6.h),
            Text('Calendar',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18.r),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04), blurRadius: 10)
                  ]),
              child: const GoFlowCalendar(),
            ),
          ],
        ),
      );
    });
  }

  Widget _ringCard(Color accent, GoFlowStatus status) {
    final day = status.cycleDay;
    final phase = status.phase;
    final progress = (day == null)
        ? 0.0
        : (day / status.cycleLength).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 26.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 170.r,
            height: 170.r,
            child: CustomPaint(
              painter: _RingPainter(progress: progress, color: accent),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(day == null ? '—' : 'Day $day',
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.w900,
                            color: _kText)),
                    if (phase != null)
                      Text('of your cycle',
                          style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 11.sp, color: _kMuted)),
                  ],
                ),
              ),
            ),
          ),
          if (phase != null) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20.r)),
              child: Text('${phase.label} phase',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w800,
                      color: accent)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _predictionCard(Color accent, GoFlowStatus status) {
    String title;
    String body;
    IconData icon;
    switch (status.confidence) {
      case GoFlowConfidence.ready:
        icon = Icons.calendar_month_rounded;
        final a = status.nextWindowStart!;
        final b = status.nextWindowEnd!;
        title = 'Next period';
        final days = status.daysUntilNext ?? 0;
        body = '${_md(a)} – ${_md(b)}'
            '${days > 0 ? '  ·  in ~$days days' : (days == 0 ? '  ·  around today' : '')}';
        break;
      case GoFlowConfidence.low:
        icon = Icons.timelapse_rounded;
        title = 'Learning your rhythm';
        body =
            'Log a few cycles and GoFlow will predict your next period window.';
        break;
      case GoFlowConfidence.none:
        icon = Icons.event_available_rounded;
        title = 'Set your last period';
        body = 'Add when your last period started in settings to begin.';
        break;
    }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
          ]),
      child: Row(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
                color: accent.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: accent, size: 20.r),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: _kText)),
                SizedBox(height: 3.h),
                Text(body,
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 12.5.sp, color: _kMuted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sparkCard(Color accent, GoFlowPhase phase) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.14), accent.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded, color: accent, size: 20.r),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(GoFlowContent.sparkFor(phase),
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 13.5.sp,
                    color: _kText,
                    height: 1.5,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _dailyActionCard(Color accent, GoFlowPhase phase) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
          ]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
                color: accent.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(Icons.checklist_rounded, color: accent, size: 20.r),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's insight",
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: _kText)),
                SizedBox(height: 3.h),
                Text(GoFlowContent.dailyActionFor(phase),
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 12.5.sp, color: _kMuted, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fertilityCard(Color accent, GoFlowStatus status) {
    final today = DateTime.now();
    final fertileToday = status.isFertileOn(today);
    final fs = status.fertileWindowStart!;
    final fe = status.fertileWindowEnd!;
    final ov = status.ovulationDate!;
    final estimate = status.confidence != GoFlowConfidence.ready;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_florist_rounded, color: accent, size: 20.r),
              SizedBox(width: 10.w),
              Text('Fertility window',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: _kText)),
              const Spacer(),
              if (fertileToday)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                      color: accent, borderRadius: BorderRadius.circular(20.r)),
                  child: Text('Fertile today',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _fertBit('Fertile', '${_md(fs)} – ${_md(fe)}', accent),
              _fertBit('Est. ovulation', _md(ov), accent),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
              estimate
                  ? 'Estimates — they sharpen after you log a few cycles.'
                  : 'Estimates based on your typical cycle. Not birth control.',
              style: AppFonts.spaceGrotesk
                  .copyWith(fontSize: 10.5.sp, color: _kMuted)),
        ],
      ),
    );
  }

  Widget _fertBit(String label, String value, Color accent) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: _kMuted)),
            SizedBox(height: 2.h),
            Text(value,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
          ],
        ),
      );

  Widget _insightsSection(Color accent, GoFlowController c) {
    final insights = GoFlowInsights.build(c.entries.toList(), c.settings.value);
    if (insights.isEmpty) return const SizedBox.shrink();
    IconData iconFor(String k) {
      switch (k) {
        case 'cramp':
          return Icons.bolt_rounded;
        case 'energy':
          return Icons.battery_charging_full_rounded;
        case 'mood':
          return Icons.sentiment_satisfied_rounded;
        case 'heart':
          return Icons.favorite_rounded;
        case 'note':
          return Icons.label_important_rounded;
        default:
          return Icons.insights_rounded;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your patterns',
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 15.sp, fontWeight: FontWeight.w800, color: _kText)),
        SizedBox(height: 12.h),
        for (final ins in insights)
          Container(
            margin: EdgeInsets.only(bottom: 10.h),
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03), blurRadius: 6)
                ]),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(iconFor(ins.icon), size: 18.r, color: accent),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(ins.text,
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 13.sp, color: _kText, height: 1.4)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _perimenopauseCard(Color accent, GoFlowController c) {
    final now = DateTime.now();
    final since = now.subtract(const Duration(days: 14));
    var flashes = 0;
    final sleeps = <int>[];
    for (final e in c.entries) {
      if (e.date.isBefore(since)) continue;
      flashes += e.hotFlashes;
      if (e.sleepQuality > 0) sleeps.add(e.sleepQuality);
    }
    final avgSleep = sleeps.isEmpty
        ? null
        : (sleeps.reduce((a, b) => a + b) / sleeps.length);
    String sleepLabel(double v) {
      if (v >= 4) return 'good';
      if (v >= 3) return 'fair';
      return 'poor';
    }

    Widget bit(String label, String value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: _kMuted)),
              SizedBox(height: 2.h),
              Text(value,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: _kText)),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Perimenopause',
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 15.sp, fontWeight: FontWeight.w800, color: _kText)),
        SizedBox(height: 12.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18.r),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
              ]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.thermostat_auto_rounded,
                      color: accent, size: 20.r),
                  SizedBox(width: 10.w),
                  Text('Last 14 days',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: _kText)),
                ],
              ),
              SizedBox(height: 14.h),
              Row(
                children: [
                  bit('Hot flashes', '$flashes'),
                  bit('Avg sleep',
                      avgSleep == null ? '—' : sleepLabel(avgSleep)),
                  bit('Cycle', '${c.status.cycleLength}d'),
                ],
              ),
              SizedBox(height: 8.h),
              Text('Tracking only — bring these trends to your doctor.',
                  style: AppFonts.spaceGrotesk
                      .copyWith(fontSize: 10.5.sp, color: _kMuted)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _logButton(Color accent, bool loggedToday) {
    return GestureDetector(
      onTap: () => GoFlowLogSheet.show(DateTime.now()),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration:
            BoxDecoration(color: accent, borderRadius: BorderRadius.circular(30.r)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(loggedToday ? Icons.check_circle_rounded : Icons.add_rounded,
                color: Colors.white, size: 20.r),
            SizedBox(width: 8.w),
            Text(loggedToday ? 'Update today' : 'Log today',
                style: AppFonts.spaceGrotesk.copyWith(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  static String _md(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${m[d.month - 1]} ${d.day}';
  }
}

/// A thick progress ring for the cycle-day indicator.
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 9;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = color.withOpacity(0.12);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ── Partner view ──────────────────────────────────────────────────────────────
class _PartnerView extends StatefulWidget {
  const _PartnerView();

  @override
  State<_PartnerView> createState() => _PartnerViewState();
}

class _PartnerViewState extends State<_PartnerView> {
  SharedStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = GoFlowController.to.settings.value.partnerId;
    if (id == null || id.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final s = await SharingController.to.statsFor(id);
    if (mounted) {
      setState(() {
        _stats = s;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = GoFlowController.to;
    final accent = c.accentColor;
    final partnerName = c.settings.value.partnerName ?? 'Your partner';
    final partnerId = c.settings.value.partnerId;

    if (partnerId == null || partnerId.isEmpty) {
      return _empty(
        accent,
        Icons.favorite_border_rounded,
        'Choose your partner',
        'Open settings to pick who you\'re supporting.',
        action: 'Open settings',
        onAction: GoFlowSettingsSheet.show,
      );
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final g = _stats?.goflow;
    if (g == null || !g.hasAny) {
      return _empty(
        accent,
        Icons.lock_outline_rounded,
        '$partnerName hasn\'t shared yet',
        'Once they turn on GoFlow sharing for you, their current status and '
            'ways to support them will show up here.',
        action: 'Refresh',
        onAction: () {
          setState(() => _loading = true);
          _load();
        },
      );
    }

    final isPreg = g.pregnancyWeek != null;
    final phase = g.phase != null ? GoFlowPhaseX.fromId(g.phase) : null;

    final String heroTitle;
    final String heroSub;
    final List<String> tips;
    if (isPreg) {
      heroTitle = 'Expecting · Week ${g.pregnancyWeek}';
      heroSub = 'You\'re going to be a parent. Here\'s how to show up for '
          'her right now.';
      tips = GoFlowContent.partnerPregnancyTips;
    } else if (phase != null) {
      heroTitle = '${phase.label} phase';
      heroSub = GoFlowContent.partnerHeadline[phase] ?? '';
      tips = GoFlowContent.partnerTips[phase] ?? const [];
    } else {
      heroTitle = 'Shared with you';
      heroSub = '';
      tips = const [];
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 30.h),
        children: [
          Text('Supporting $partnerName',
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 14.sp, color: _kMuted)),
          SizedBox(height: 12.h),
          // Headline card.
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent, HSLColor.fromColor(accent)
                    .withLightness(
                        (HSLColor.fromColor(accent).lightness * 0.7)
                            .clamp(0.0, 1.0))
                    .toColor()],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(heroTitle,
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
                if (heroSub.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Text(heroSub,
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 13.5.sp,
                          color: Colors.white.withOpacity(0.92),
                          height: 1.5)),
                ],
                if ((g.customStatus?.trim().isNotEmpty ?? false)) ...[
                  SizedBox(height: 14.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10.r)),
                    child: Text('"${g.customStatus!.trim()}"',
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 12.5.sp,
                            color: Colors.white,
                            fontStyle: FontStyle.italic)),
                  ),
                ],
              ],
            ),
          ),
          // Cycle heads-up chips (only in cycle mode).
          if (!isPreg &&
              (g.fertileNow || (g.daysUntilPeriod != null))) ...[
            SizedBox(height: 12.h),
            Wrap(
              spacing: 10.w,
              runSpacing: 8.h,
              children: [
                if (g.daysUntilPeriod != null)
                  _pill(
                      accent,
                      Icons.calendar_month_rounded,
                      g.daysUntilPeriod! > 0
                          ? 'Period in ~${g.daysUntilPeriod} days'
                          : g.daysUntilPeriod == 0
                              ? 'Period expected today'
                              : 'Period may be late'),
                if (g.fertileNow)
                  _pill(accent, Icons.local_florist_rounded, 'Fertile window'),
              ],
            ),
          ],
          SizedBox(height: 20.h),
          if (tips.isNotEmpty) ...[
            Text('How to show up',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
            SizedBox(height: 12.h),
            for (final tip in tips)
              Container(
                margin: EdgeInsets.only(bottom: 10.h),
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03), blurRadius: 6)
                    ]),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.favorite_rounded, size: 16.r, color: accent),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(tip,
                          style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 13.5.sp, color: _kText, height: 1.4)),
                    ),
                  ],
                ),
              ),
          ],
          SizedBox(height: 8.h),
          Center(
            child: Text('GoFlow only shows a summary — never their logs.',
                textAlign: TextAlign.center,
                style: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 11.5.sp, color: _kMuted)),
          ),
        ],
      ),
    );
  }

  Widget _pill(Color accent, IconData icon, String label) => Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20.r)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14.r, color: accent),
            SizedBox(width: 6.w),
            Text(label,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: accent)),
          ],
        ),
      );

  Widget _empty(Color accent, IconData icon, String title, String body,
      {String? action, VoidCallback? onAction}) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(30.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44.r, color: accent.withOpacity(0.7)),
            SizedBox(height: 14.h),
            Text(title,
                textAlign: TextAlign.center,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
            SizedBox(height: 8.h),
            Text(body,
                textAlign: TextAlign.center,
                style: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 13.sp, color: _kMuted, height: 1.5)),
            if (action != null) ...[
              SizedBox(height: 18.h),
              GestureDetector(
                onTap: onAction,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 26.w, vertical: 12.h),
                  decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(30.r)),
                  child: Text(action,
                      style: AppFonts.spaceGrotesk.copyWith(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Pregnancy mode ────────────────────────────────────────────────────────────
class _PregnancyView extends StatelessWidget {
  const _PregnancyView();

  static String _md(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = GoFlowController.to;
      final accent = c.accentColor;
      final lmp = c.settings.value.pregnancyLmp;
      if (lmp == null) return const SizedBox.shrink();
      final st = GoFlowPregnancy.statusFrom(lmp);
      final wk = GoFlowPregnancy.forWeek(st.week);

      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 30.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero: week + trimester + progress + due countdown.
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(22.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent,
                    HSLColor.fromColor(accent)
                        .withLightness(
                            (HSLColor.fromColor(accent).lightness * 0.7)
                                .clamp(0.0, 1.0))
                        .toColor()
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(st.trimesterLabel.toUpperCase(),
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: Colors.white.withOpacity(0.85))),
                  SizedBox(height: 4.h),
                  Text('Week ${st.week}',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 30.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                  SizedBox(height: 4.h),
                  Text('Day ${st.daysIntoWeek} of week ${st.week}',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 12.sp,
                          color: Colors.white.withOpacity(0.9))),
                  SizedBox(height: 14.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: LinearProgressIndicator(
                      value: st.progress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                      st.daysUntilDue >= 0
                          ? 'Due ${_md(st.dueDate)}  ·  ${st.daysUntilDue} days to go'
                          : 'Due date was ${_md(st.dueDate)}',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            _infoCard(accent, Icons.child_care_rounded, 'Baby this week',
                'About the size of ${wk.size}.', wk.development),
            SizedBox(height: 12.h),
            _infoCard(accent, Icons.self_improvement_rounded, 'For you',
                wk.forYou, null),
            SizedBox(height: 20.h),
            Center(
              child: TextButton(
                onPressed: () => _confirmEnd(c),
                child: Text('End pregnancy tracking',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w700,
                        color: _kMuted)),
              ),
            ),
            Center(
              child: Text('General guidance, not medical advice.',
                  style: AppFonts.spaceGrotesk
                      .copyWith(fontSize: 11.sp, color: _kMuted)),
            ),
          ],
        ),
      );
    });
  }

  Widget _infoCard(
      Color accent, IconData icon, String title, String line, String? sub) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
          ]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
                color: accent.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: accent, size: 20.r),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: _kText)),
                SizedBox(height: 3.h),
                Text(line,
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 13.sp, color: _kText, height: 1.4)),
                if (sub != null) ...[
                  SizedBox(height: 4.h),
                  Text(sub,
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 12.sp, color: _kMuted, height: 1.4)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmEnd(GoFlowController c) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 24.h),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('End pregnancy tracking?',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
            SizedBox(height: 8.h),
            Text('GoFlow will switch back to cycle tracking. Your logs stay.',
                style: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 13.sp, color: _kMuted, height: 1.4)),
            SizedBox(height: 16.h),
            GestureDetector(
              onTap: () {
                c.endPregnancy();
                Get.back();
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                    color: c.accentColor,
                    borderRadius: BorderRadius.circular(30.r)),
                child: Center(
                  child: Text('End tracking',
                      style: AppFonts.spaceGrotesk.copyWith(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
