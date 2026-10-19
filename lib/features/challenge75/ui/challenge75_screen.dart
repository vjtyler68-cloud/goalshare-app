import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:spanx/core/const/app_fonts.dart';

import '../controller/challenge75_controller.dart';
import '../data/challenge75_crew.dart';
import '../data/challenge75_models.dart';
import 'challenge75_day_detail_screen.dart';
import 'challenge75_day_editor.dart';
import 'challenge75_setup_screen.dart';
import 'challenge75_theme.dart';

/// 75 Challenge home. Gates on setup, then shows the four tabs:
/// Today · 75 Days · Summary · Crew.
class Challenge75Screen extends StatelessWidget {
  const Challenge75Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Challenge75Controller.to;
    return Obx(() {
      if (c.loading.value) {
        return Scaffold(
          backgroundColor: C75.bg,
          body: Center(
            child: CircularProgressIndicator(
                color: Challenge75Variant.all.first.color, strokeWidth: 2),
          ),
        );
      }
      if (!c.started) return const Challenge75SetupScreen();
      return const _Challenge75Home();
    });
  }
}

class _Challenge75Home extends StatelessWidget {
  const _Challenge75Home();

  Challenge75Controller get c => Challenge75Controller.to;

  @override
  Widget build(BuildContext context) {
    final accent = c.config.value?.color ?? Challenge75Variant.all.first.color;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: C75.bg,
        appBar: AppBar(
          backgroundColor: C75.bg,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: C75.text),
            onPressed: Get.back,
          ),
          title: Obx(() {
            final v = c.config.value?.variant;
            return Text(
              v?.name ?? '75 Challenge',
              style: AppFonts.spaceGrotesk.copyWith(
                  color: C75.text, fontSize: 17.sp, fontWeight: FontWeight.w900),
            );
          }),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: C75.text),
              onSelected: (v) => _onMenu(context, v),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit goals')),
                const PopupMenuItem(
                    value: 'restart', child: Text('Restart from today')),
                const PopupMenuItem(
                    value: 'reset', child: Text('Reset & delete data')),
              ],
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(46.h),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: accent,
              indicatorWeight: 3,
              labelColor: C75.text,
              unselectedLabelColor: C75.muted,
              labelStyle: AppFonts.spaceGrotesk
                  .copyWith(fontSize: 13.sp, fontWeight: FontWeight.w800),
              unselectedLabelStyle: AppFonts.spaceGrotesk
                  .copyWith(fontSize: 13.sp, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'Today'),
                Tab(text: '75 Days'),
                Tab(text: 'Summary'),
                Tab(text: 'Crew'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            // Keyed by the day number so a midnight rollover (or restart) gives
            // a fresh Today page; the tab's own body is reactive internally.
            Obx(() => _TodayTab(key: ValueKey(c.currentDayNumber))),
            _GridTab(),
            _SummaryTab(),
            _CrewTab(),
          ],
        ),
      ),
    );
  }

  Future<void> _onMenu(BuildContext context, String v) async {
    switch (v) {
      case 'edit':
        await Get.to(() => const Challenge75SetupScreen(editing: true));
        break;
      case 'restart':
        final ok = await _confirm(
          context,
          title: 'Restart from today?',
          message:
              'Your logged days and photos will be cleared and Day 1 becomes '
              'today. Your rules stay the same.',
          confirmLabel: 'Restart',
          color: C75.bad,
        );
        if (ok) await c.restartFromToday();
        break;
      case 'reset':
        final ok = await _confirm(
          context,
          title: 'Reset & delete everything?',
          message:
              'This deletes your challenge setup, every logged day, and all '
              'progress photos. This cannot be undone.',
          confirmLabel: 'Delete',
          color: C75.bad,
        );
        if (ok) await c.reset();
        break;
    }
  }
}

// ── Shared confirm dialog ─────────────────────────────────────────────────────
Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required Color color,
}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
      title: Text(title,
          style: AppFonts.spaceGrotesk.copyWith(
              color: C75.text, fontSize: 16.sp, fontWeight: FontWeight.w900)),
      content: Text(message,
          style: AppFonts.spaceGrotesk
              .copyWith(color: C75.muted, fontSize: 13.sp, height: 1.4)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Cancel',
              style: AppFonts.spaceGrotesk
                  .copyWith(color: C75.muted, fontWeight: FontWeight.w700)),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel,
              style: AppFonts.spaceGrotesk
                  .copyWith(color: color, fontWeight: FontWeight.w900)),
        ),
      ],
    ),
  );
  return res ?? false;
}

// ── TODAY ─────────────────────────────────────────────────────────────────────
class _TodayTab extends StatefulWidget {
  const _TodayTab({super.key});

  @override
  State<_TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends State<_TodayTab> {
  late Challenge75Day _work;

  Challenge75Controller get c => Challenge75Controller.to;

  @override
  void initState() {
    super.initState();
    _work = c.today.clone();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final config = c.config.value;
      if (config == null) return const SizedBox.shrink();
      if (c.notStartedYet) return _countdown(config);
      if (c.finished) return _finished(config);
      return _active(config);
    });
  }

  Widget _active(Challenge75Config config) {
    final accent = config.color;
    final pct = _work.completion(config);
    final done = _work.requiredDone(config);
    final total = config.requiredTaskCount;
    final allDone = _work.isComplete(config);
    final missed = c.missedDay;

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 40.h),
      children: [
        // Hero: ring + stats
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: C75.card,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: C75.line),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _ring(pct, allDone ? C75.good : accent, '$done/$total',
                      'tasks'),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Day ${c.currentDayNumber} of 75',
                            style: AppFonts.spaceGrotesk.copyWith(
                                color: C75.text,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w900)),
                        Text(DateFormat('EEEE, MMM d').format(DateTime.now()),
                            style: AppFonts.spaceGrotesk.copyWith(
                                color: C75.muted, fontSize: 12.sp)),
                        SizedBox(height: 10.h),
                        Row(
                          children: [
                            _pill(Icons.local_fire_department_rounded,
                                '${c.streak} day streak', accent),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Row(
                children: [
                  _stat('DONE', '${c.daysCompleted}'),
                  _divider(),
                  _stat('LEFT', '${c.daysRemaining}'),
                  _divider(),
                  _stat('TODAY', '${(pct * 100).round()}%'),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        if (allDone)
          _banner(
            C75.good,
            Icons.emoji_events_rounded,
            'Day ${c.currentDayNumber} complete!',
            'Every required task is done. Keep the streak alive. 🔥',
          ),
        if (missed != null)
          _banner(
            C75.bad,
            Icons.warning_amber_rounded,
            'Challenge broken on Day $missed',
            'Your rules restart on a miss. Tap the menu → Restart from today to '
                'begin again.',
          ),
        SizedBox(height: 4.h),
        Challenge75DayEditor(
          key: ValueKey('today_${_work.day}'),
          day: _work,
          config: config,
          // saveDay bumps the reactive day map, which rebuilds this Obx body
          // (hero ring + stats); the editor refreshes its own ticks locally.
          onChanged: () => c.saveDay(_work),
        ),
      ],
    );
  }

  Widget _countdown(Challenge75Config config) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_top_rounded,
                size: 54.r, color: config.color),
            SizedBox(height: 16.h),
            Text('Your 75 starts in ${c.daysUntilStart} '
                '${c.daysUntilStart == 1 ? 'day' : 'days'}',
                textAlign: TextAlign.center,
                style: AppFonts.spaceGrotesk.copyWith(
                    color: C75.text,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800)),
            SizedBox(height: 8.h),
            Text('Starts ${DateFormat('EEEE, MMM d').format(config.startDate)}',
                style: AppFonts.spaceGrotesk
                    .copyWith(color: C75.muted, fontSize: 13.sp)),
          ],
        ),
      ),
    );
  }

  Widget _finished(Challenge75Config config) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_rounded, size: 60.r, color: config.color),
            SizedBox(height: 16.h),
            Text('You reached the end of your 75!',
                textAlign: TextAlign.center,
                style: AppFonts.spaceGrotesk.copyWith(
                    color: C75.text,
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w900)),
            SizedBox(height: 8.h),
            Text('${c.daysCompleted} of 75 days completed. '
                'Check the Summary tab for the full picture.',
                textAlign: TextAlign.center,
                style: AppFonts.spaceGrotesk.copyWith(
                    color: C75.muted, fontSize: 13.sp, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _ring(double pct, Color color, String center, String sub) {
    return SizedBox(
      width: 86.r,
      height: 86.r,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 86.r,
            height: 86.r,
            child: CircularProgressIndicator(
              value: pct,
              strokeWidth: 8,
              backgroundColor: C75.field,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(center,
                  style: AppFonts.spaceGrotesk.copyWith(
                      color: C75.text,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900)),
              Text(sub,
                  style: AppFonts.spaceGrotesk
                      .copyWith(color: C75.muted, fontSize: 9.5.sp)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15.r),
          SizedBox(width: 5.w),
          Text(label,
              style: AppFonts.spaceGrotesk.copyWith(
                  color: color, fontSize: 11.5.sp, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: AppFonts.spaceGrotesk.copyWith(
                    color: C75.text,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900)),
            SizedBox(height: 2.h),
            Text(label,
                style: AppFonts.spaceGrotesk.copyWith(
                    color: C75.muted,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6)),
          ],
        ),
      );

  Widget _divider() =>
      Container(width: 1, height: 28.h, color: C75.line);

  Widget _banner(Color color, IconData icon, String title, String body) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22.r),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppFonts.spaceGrotesk.copyWith(
                        color: color,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900)),
                SizedBox(height: 3.h),
                Text(body,
                    style: AppFonts.spaceGrotesk.copyWith(
                        color: C75.text, fontSize: 12.sp, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 75-DAY GRID ─────────────────────────────────────────────────────────────
class _GridTab extends StatelessWidget {
  Challenge75Controller get c => Challenge75Controller.to;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final accent =
          c.config.value?.color ?? Challenge75Variant.all.first.color;
      // Read every day's state INSIDE the Obx closure so the grid is subscribed
      // to the reactive day map (LayoutBuilder/itemBuilder run later, outside
      // this closure, so reads deferred into them wouldn't be observed).
      final states = List<Challenge75DayState>.generate(
          kChallenge75Length, (i) => c.stateFor(i + 1));
      return LayoutBuilder(builder: (ctx, cons) {
        final cols = (cons.maxWidth / 54.w).floor().clamp(7, 12);
        return ListView(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 40.h),
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: kChallenge75Length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 8.r,
                crossAxisSpacing: 8.r,
                childAspectRatio: 1,
              ),
              itemBuilder: (_, i) => _cell(i + 1, states[i], accent),
            ),
            SizedBox(height: 18.h),
            _legend(accent),
          ],
        );
      });
    });
  }

  Widget _cell(int day, Challenge75DayState state, Color accent) {
    late Color bg;
    late Color fg;
    Border? border;
    switch (state) {
      case Challenge75DayState.complete:
        bg = C75.good;
        fg = Colors.white;
        break;
      case Challenge75DayState.missed:
        bg = C75.bad.withValues(alpha: 0.85);
        fg = Colors.white;
        break;
      case Challenge75DayState.current:
        bg = Colors.white;
        fg = accent;
        border = Border.all(color: accent, width: 2);
        break;
      case Challenge75DayState.future:
        bg = C75.field;
        fg = C75.muted;
        break;
    }
    return GestureDetector(
      onTap: () =>
          Get.to(() => Challenge75DayDetailScreen(dayNumber: day)),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10.r),
          border: border,
        ),
        child: Text('$day',
            style: AppFonts.spaceGrotesk.copyWith(
                color: fg, fontSize: 12.sp, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _legend(Color accent) {
    Widget item(Color color, String label, {Border? border}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16.r,
              height: 16.r,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5.r),
                border: border,
              ),
            ),
            SizedBox(width: 6.w),
            Text(label,
                style: AppFonts.spaceGrotesk
                    .copyWith(color: C75.muted, fontSize: 11.5.sp)),
          ],
        );
    return Wrap(
      spacing: 16.w,
      runSpacing: 8.h,
      children: [
        item(C75.good, 'Complete'),
        item(C75.bad.withValues(alpha: 0.85), 'Missed'),
        item(Colors.white, 'Today',
            border: Border.all(color: accent, width: 2)),
        item(C75.field, 'Upcoming'),
      ],
    );
  }
}

// ── SUMMARY ─────────────────────────────────────────────────────────────────
class _SummaryTab extends StatelessWidget {
  Challenge75Controller get c => Challenge75Controller.to;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final config = c.config.value;
      if (config == null) return const SizedBox.shrink();

      var missed = 0;
      var totalWorkouts = 0;
      var totalPages = 0;
      double totalWaterMl = 0;
      final photos = <Challenge75Day>[];
      final cur = c.currentDayNumber;
      for (var i = 1; i <= kChallenge75Length; i++) {
        final d = c.days[i];
        if (d != null) {
          totalWorkouts += d.workouts.where((w) => w.done).length;
          totalPages += d.pagesRead;
          totalWaterMl += d.waterMl;
          if (d.photoPath != null &&
              d.photoPath!.isNotEmpty &&
              File(d.photoPath!).existsSync()) {
            photos.add(d);
          }
        }
        if (i < cur && (d == null || !d.isComplete(config))) missed++;
      }

      return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 40.h),
      children: [
        Row(
          children: [
            _metric('Days done', '${c.daysCompleted}', C75.good),
            SizedBox(width: 12.w),
            _metric('Days missed', '$missed', C75.bad),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            _metric('Workouts', '$totalWorkouts', config.color),
            SizedBox(width: 12.w),
            _metric('Pages read', '$totalPages', config.color),
          ],
        ),
        SizedBox(height: 12.h),
        _wideMetric('Water logged',
            WaterUnit.label(totalWaterMl, config.waterUnit), config.color),
        SizedBox(height: 20.h),
        Text('PROGRESS PHOTOS',
            style: AppFonts.spaceGrotesk.copyWith(
                color: C75.muted,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 1)),
        SizedBox(height: 10.h),
        if (photos.isEmpty)
          Text('No progress photos yet — add one from the Today tab.',
              style: AppFonts.spaceGrotesk
                  .copyWith(color: C75.muted, fontSize: 12.5.sp))
        else
          Wrap(
            spacing: 10.r,
            runSpacing: 10.r,
            children: photos.map(_photoThumb).toList(),
          ),
        ],
      );
    });
  }

  Widget _photoThumb(Challenge75Day d) {
    return GestureDetector(
      onTap: () => Get.to(() => Challenge75DayDetailScreen(dayNumber: d.day)),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Image.file(
              File(d.photoPath!),
              width: 76.r,
              height: 76.r,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 76.r,
                height: 76.r,
                color: C75.field,
                child: Icon(Icons.broken_image, color: C75.muted, size: 20.r),
              ),
            ),
          ),
          SizedBox(height: 3.h),
          Text('Day ${d.day}',
              style: AppFonts.spaceGrotesk
                  .copyWith(color: C75.muted, fontSize: 10.sp)),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: C75.card,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: C75.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: AppFonts.spaceGrotesk.copyWith(
                    color: color,
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w900)),
            SizedBox(height: 2.h),
            Text(label,
                style: AppFonts.spaceGrotesk
                    .copyWith(color: C75.muted, fontSize: 12.sp)),
          ],
        ),
      ),
    );
  }

  Widget _wideMetric(String label, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: C75.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: C75.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppFonts.spaceGrotesk
                  .copyWith(color: C75.muted, fontSize: 13.sp)),
          Text(value,
              style: AppFonts.spaceGrotesk.copyWith(
                  color: color, fontSize: 20.sp, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

// ── CREW (sharing / accountability) ──────────────────────────────────────────
class _CrewTab extends StatefulWidget {
  @override
  State<_CrewTab> createState() => _CrewTabState();
}

class _CrewTabState extends State<_CrewTab> {
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _busy = false;

  Challenge75Controller get c => Challenge75Controller.to;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = c.config.value?.color ?? Challenge75Variant.all.first.color;
    if (!c.sharingAvailable) {
      return _info(
        Icons.cloud_off_rounded,
        'Sharing is offline',
        'A crew keeps you and your friends accountable by syncing each '
            'other\'s progress. It needs a connection to GoalShare — your own '
            'tracking still works fully offline.',
      );
    }
    return Obx(() {
      if (!c.inCrew) return _joinOrCreate(accent);
      return _roster(accent);
    });
  }

  Widget _joinOrCreate(Color accent) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 40.h),
      children: [
        _info(
          Icons.group_rounded,
          'Do it with your friends',
          'Create a crew and share the code, or join one. Everyone sees each '
              'other\'s day, streak and today\'s progress — so nobody slacks.',
        ),
        SizedBox(height: 16.h),
        _panel(
          title: 'Create a crew',
          child: Column(
            children: [
              _field(_nameCtrl, 'Crew name (e.g. Summer Shred)'),
              SizedBox(height: 10.h),
              _action('Create & get code', accent,
                  _busy ? null : _createCrew),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        _panel(
          title: 'Join a crew',
          child: Column(
            children: [
              _field(_codeCtrl, 'Enter 6-character code',
                  caps: true, maxLen: 6),
              SizedBox(height: 10.h),
              _action('Join crew', accent, _busy ? null : _joinCrew),
            ],
          ),
        ),
      ],
    );
  }

  Widget _roster(Color accent) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 40.h),
      children: [
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CREW CODE',
                      style: AppFonts.spaceGrotesk.copyWith(
                          color: C75.muted,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1)),
                  SizedBox(height: 2.h),
                  Text(c.crewCode.value,
                      style: AppFonts.spaceGrotesk.copyWith(
                          color: C75.text,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3)),
                ],
              ),
              const Spacer(),
              _iconBtn(Icons.copy_rounded, accent, () {
                Clipboard.setData(ClipboardData(text: c.crewCode.value));
                Get.snackbar('Copied', 'Crew code copied to clipboard',
                    snackPosition: SnackPosition.BOTTOM);
              }),
              SizedBox(width: 8.w),
              _iconBtn(Icons.ios_share_rounded, accent, _shareCode),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Text('YOUR CREW',
            style: AppFonts.spaceGrotesk.copyWith(
                color: C75.muted,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 1)),
        SizedBox(height: 10.h),
        StreamBuilder<List<Challenge75CrewMember>>(
          stream: c.watchCrew(),
          builder: (ctx, snap) {
            final members = snap.data ?? const <Challenge75CrewMember>[];
            if (snap.connectionState == ConnectionState.waiting) {
              return Padding(
                padding: EdgeInsets.all(20.r),
                child: Center(
                    child: CircularProgressIndicator(
                        color: accent, strokeWidth: 2)),
              );
            }
            if (members.isEmpty) {
              return Text(
                  'No one has synced progress yet. Share your code to get '
                  'your crew started.',
                  style: AppFonts.spaceGrotesk
                      .copyWith(color: C75.muted, fontSize: 12.5.sp));
            }
            return Column(
                children: members.map((m) => _memberRow(m, accent)).toList());
          },
        ),
        SizedBox(height: 20.h),
        Center(
          child: TextButton.icon(
            onPressed: _leaveCrew,
            icon: Icon(Icons.logout_rounded, color: C75.bad, size: 18.r),
            label: Text('Leave crew',
                style: AppFonts.spaceGrotesk.copyWith(
                    color: C75.bad,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _memberRow(Challenge75CrewMember m, Color accent) {
    final variant = m.variantId.isEmpty
        ? null
        : Challenge75Variant.byId(m.variantId);
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: C75.card,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: C75.line),
      ),
      child: Row(
        children: [
          Container(
            width: 42.r,
            height: 42.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (variant?.color ?? accent).withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Text(
              m.name.trim().isEmpty ? '?' : m.name.trim()[0].toUpperCase(),
              style: AppFonts.spaceGrotesk.copyWith(
                  color: variant?.color ?? accent,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.name,
                    style: AppFonts.spaceGrotesk.copyWith(
                        color: C75.text,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 2.h),
                Text(
                    'Day ${m.day} · ${m.daysCompleted} done · '
                    '${m.streak} streak',
                    style: AppFonts.spaceGrotesk
                        .copyWith(color: C75.muted, fontSize: 11.5.sp)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: (m.todayComplete ? C75.good : accent)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
                m.todayComplete
                    ? 'Today ✓'
                    : '${(m.completionToday * 100).round()}%',
                style: AppFonts.spaceGrotesk.copyWith(
                    color: m.todayComplete ? C75.good : accent,
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Future<void> _createCrew() async {
    setState(() => _busy = true);
    final code = await c.createCrew(_nameCtrl.text);
    if (mounted) setState(() => _busy = false);
    if (code == null) {
      Get.snackbar('Couldn\'t create crew',
          'Try again in a moment — sharing needs a connection.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _joinCrew() async {
    final code = _codeCtrl.text.trim();
    if (code.length < 4) {
      Get.snackbar('Crew code', 'Enter the full code your friend shared.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    setState(() => _busy = true);
    final ok = await c.joinCrew(code);
    if (mounted) setState(() => _busy = false);
    if (!ok) {
      Get.snackbar('No crew found',
          'Double-check the code — it may be wrong or the crew is gone.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _leaveCrew() async {
    final ok = await _confirm(
      context,
      title: 'Leave this crew?',
      message:
          'You\'ll stop sharing progress with them. Your own tracking stays.',
      confirmLabel: 'Leave',
      color: C75.bad,
    );
    if (ok) await c.leaveCrew();
  }

  void _shareCode() {
    SharePlus.instance.share(ShareParams(
      text: 'Join my 75 Challenge crew on GoalShare! '
          'Open the 75 Challenge → Crew → Join, and enter code: '
          '${c.crewCode.value}',
    ));
  }

  // ── small bits ──────────────────────────────────────────────────────────────
  Widget _info(IconData icon, String title, String body) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: C75.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: C75.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: C75.muted, size: 20.r),
              SizedBox(width: 8.w),
              Text(title,
                  style: AppFonts.spaceGrotesk.copyWith(
                      color: C75.text,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          SizedBox(height: 8.h),
          Text(body,
              style: AppFonts.spaceGrotesk
                  .copyWith(color: C75.muted, fontSize: 12.5.sp, height: 1.4)),
        ],
      ),
    );
  }

  Widget _panel({required String title, required Widget child}) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: C75.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: C75.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppFonts.spaceGrotesk.copyWith(
                  color: C75.text,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800)),
          SizedBox(height: 10.h),
          child,
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint,
      {bool caps = false, int? maxLen}) {
    return TextField(
      controller: ctrl,
      textCapitalization:
          caps ? TextCapitalization.characters : TextCapitalization.words,
      maxLength: maxLen,
      style: AppFonts.spaceGrotesk
          .copyWith(color: C75.text, fontSize: 13.5.sp),
      decoration: InputDecoration(
        isDense: true,
        counterText: '',
        hintText: hint,
        hintStyle:
            AppFonts.spaceGrotesk.copyWith(color: C75.muted, fontSize: 12.5.sp),
        filled: true,
        fillColor: C75.field,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _action(String label, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 46.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap == null ? color.withValues(alpha: 0.5) : color,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(_busy ? 'Working…' : label,
            style: AppFonts.spaceGrotesk.copyWith(
                color: Colors.white,
                fontSize: 14.sp,
                fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.r,
        height: 40.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, color: color, size: 20.r),
      ),
    );
  }
}
