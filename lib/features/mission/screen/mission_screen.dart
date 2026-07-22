import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_fonts.dart';
import '../../../core/alertdialogs/create_new_mission.dart';
import '../controller/mission_controller.dart';
import '../data/metric_icons.dart';
import '../data/stats_history.dart';
import '../data/work_sessions.dart';
import '../ui/custom_stat_sheet.dart';
import 'package:spanx/core/const/app_colors.dart';

Color get _kRed => AppColors.primaryColor;
Color get _kRedDk => AppColors.primaryDarkColor;
const _kBg    = Color(0xffF6F4F2);
const _kCard  = Color(0xffFFFFFF);
const _kText  = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

class MissionScreen extends StatelessWidget {
  MissionScreen({super.key});

  final MissionController c = Get.put(MissionController(), permanent: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_kRed, _kRedDk],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Track & Crush It', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white70, fontSize: 12.sp)),
                            Text('Mission', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 26.sp, fontWeight: FontWeight.w800)),
                          ],
                        ),
                        GestureDetector(
                          onTap: CreateNewMission.show,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.add, color: Colors.white, size: 18),
                                SizedBox(width: 4.w),
                                Text('New', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    // Daily Goal Progress
                    Obx(() {
                      final knocked = c.goalCurrentValue;
                      final goal = c.dailyGoal.value;
                      final progress = goal > 0 ? (knocked / goal).clamp(0.0, 1.0) : 0.0;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Daily Goal Progress', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white70, fontSize: 12.sp)),
                              GestureDetector(
                                onTap: () => _showGoalDialog(context),
                                child: Text('Goal: $goal  ✏', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white70, fontSize: 12.sp)),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              height: 8,
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.white.withOpacity(0.25),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text('$knocked of $goal ${c.goalMetricLabel.toLowerCase()}', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w600)),
                        ],
                      );
                    }),
                    SizedBox(height: 12.h),
                    _workDayPill(),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metric counters — tap a number to type the exact value,
                  // hold a card to rename it / change its icon.
                  _sectionLabel('Today\'s Metrics'),
                  SizedBox(height: 2.h),
                  Text('Tap a number to set it · hold a card to rename it',
                      style: AppFonts.spaceGrotesk.copyWith(fontSize: 10.sp, color: _kMuted)),
                  SizedBox(height: 10.h),
                  // Tap a number to set it exactly · hold a card to rename it
                  // and change its icon (built-ins are fully customizable too).
                  Obx(() => Row(
                    children: [
                      Expanded(child: _MetricCounter(label: c.homesLabel.value, icon: metricIconFor(c.homesIcon.value), value: c.homesKnocked.value, color: const Color(0xff6366F1), onInc: () => c.increment(c.homesKnocked), onDec: () => c.decrement(c.homesKnocked), onEdit: () => _editMetricDialog(c.homesLabel.value, c.homesKnocked), onLongPress: () => CustomStatSheet.show(builtinKey: 'homes'))),
                      SizedBox(width: 10.w),
                      Expanded(child: _MetricCounter(label: c.peopleLabel.value, icon: metricIconFor(c.peopleIcon.value), value: c.peopleTalkedTo.value, color: const Color(0xff10B981), onInc: () => c.increment(c.peopleTalkedTo), onDec: () => c.decrement(c.peopleTalkedTo), onEdit: () => _editMetricDialog(c.peopleLabel.value, c.peopleTalkedTo), onLongPress: () => CustomStatSheet.show(builtinKey: 'people'))),
                      SizedBox(width: 10.w),
                      Expanded(child: _MetricCounter(label: c.salesLabel.value, icon: metricIconFor(c.salesIcon.value), value: c.salesMade.value, color: _kRed, onInc: () => c.increment(c.salesMade), onDec: () => c.decrement(c.salesMade), onEdit: () => _editMetricDialog(c.salesLabel.value, c.salesMade), onLongPress: () => CustomStatSheet.show(builtinKey: 'sales'))),
                    ],
                  )),
                  SizedBox(height: 10.h),

                  // Custom metric columns (user-added) + "add column" chip.
                  Obx(() {
                    final metrics = c.customMetrics;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (metrics.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(bottom: 10.h),
                            child: Row(
                              children: [
                                for (var i = 0; i < metrics.length; i++) ...[
                                  if (i > 0) SizedBox(width: 10.w),
                                  Expanded(
                                    child: Obx(() => _MetricCounter(
                                          label: metrics[i].name,
                                          icon: metrics[i].icon,
                                          value: metrics[i].value.value,
                                          color: const Color(0xff8B5CF6),
                                          onInc: () => c.increment(metrics[i].value),
                                          onDec: () => c.decrement(metrics[i].value),
                                          onEdit: () => _editMetricDialog(metrics[i].name, metrics[i].value),
                                          // Long-press to rename / re-icon / remove.
                                          onLongPress: () => CustomStatSheet.show(existing: metrics[i]),
                                        )),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        GestureDetector(
                          onTap: _openAddStatSheet,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: _kRed.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(color: _kRed.withOpacity(0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, color: _kRed, size: 15.r),
                                SizedBox(width: 4.w),
                                Text('Add your own stat',
                                    style: AppFonts.spaceGrotesk.copyWith(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                        color: _kRed)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                  SizedBox(height: 20.h),

                  // Week-by-week breakdown so users can see where they're at.
                  _sectionLabel('Weekly Breakdown'),
                  SizedBox(height: 10.h),
                  _weeklyBreakdownCard(),
                  SizedBox(height: 20.h),

                  // Conversion rate
                  Obx(() {
                    final rate = c.peopleTalkedTo.value > 0
                        ? ((c.salesMade.value / c.peopleTalkedTo.value) * 100).toStringAsFixed(1)
                        : '0.0';
                    return Container(
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [_kRed, _kRedDk]),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.trending_up, color: Colors.white, size: 28),
                          SizedBox(width: 12.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Conversion Rate', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white70, fontSize: 12.sp)),
                              Text('$rate%', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.w800)),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Knock Ratio', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white70, fontSize: 12.sp)),
                              Obx(() {
                                final kRatio = c.homesKnocked.value > 0
                                    ? ((c.peopleTalkedTo.value / c.homesKnocked.value) * 100).toStringAsFixed(1)
                                    : '0.0';
                                return Text('$kRatio%', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.w800));
                              }),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  SizedBox(height: 20.h),

                  // Client Timers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionLabel('Client Timers'),
                      GestureDetector(
                        onTap: () => _showAddTimerDialog(context),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(color: _kRed.withOpacity(0.1), borderRadius: BorderRadius.circular(10.r)),
                          child: Row(
                            children: [
                              Icon(Icons.timer_outlined, color: _kRed, size: 16),
                              SizedBox(width: 4.w),
                              Text('Add Timer', style: AppFonts.spaceGrotesk.copyWith(color: _kRed, fontSize: 12.sp, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Obx(() {
                    if (c.clientTimers.isEmpty) {
                      return Container(
                        padding: EdgeInsets.all(20.r),
                        decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14.r), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                        child: Center(child: Text('Tap "Add Timer" to track time with each client', style: AppFonts.spaceGrotesk.copyWith(color: _kMuted, fontSize: 13.sp), textAlign: TextAlign.center)),
                      );
                    }
                    return Column(
                      children: c.clientTimers.map((timer) => _ClientTimerTile(timer: timer, controller: c)).toList(),
                    );
                  }),
                  SizedBox(height: 20.h),

                  // End of Day button
                  _buildEndOfDayButton(context),
                  SizedBox(height: 20.h),

                  SizedBox(height: 80.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Start Day / End Day work-session pill. Elapsed time comes from the stored
  /// start timestamp, so it survives the app being closed and reopened.
  Widget _workDayPill() {
    return Obx(() {
      c.workTick.value; // repaint pulse for the live counter
      final running = c.isWorkDayRunning;
      return Row(
        children: [
          GestureDetector(
            onTap: c.toggleWorkDay,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(running ? 0.28 : 0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(running ? Icons.stop_circle_outlined : Icons.play_circle_outline,
                      color: Colors.white, size: 16.r),
                  SizedBox(width: 5.w),
                  Text(running ? 'End Day' : 'Start Day',
                      style: AppFonts.spaceGrotesk.copyWith(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          // Today's TOTAL across all sessions (includes the live one), so
          // ending a session doesn't make the morning's hours vanish.
          if (running || c.getTodaysWorkDuration() > Duration.zero) ...[
            SizedBox(width: 10.w),
            Text(WorkSessionsService.formatHm(c.getTodaysWorkDuration()),
                style: AppFonts.spaceGrotesk.copyWith(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800)),
            SizedBox(width: 4.w),
            Text(running ? 'on the clock' : 'today',
                style: AppFonts.spaceGrotesk.copyWith(
                    color: Colors.white70, fontSize: 11.sp)),
          ],
        ],
      );
    });
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: AppFonts.spaceGrotesk.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w800, color: _kText));
  }

  /// Manual backup override — the day now auto-saves on the next open, so once
  /// today is banked this button goes quiet instead of double-counting.
  Widget _buildEndOfDayButton(BuildContext context) {
    return Obx(() {
      final saved = c.isTodaySaved;
      final tint = saved ? const Color(0xff22C55E) : _kRed;
      return GestureDetector(
        onTap: saved ? null : () => _showEndOfDayDialog(context),
        child: Opacity(
          opacity: saved ? 0.7 : 1,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: tint.withOpacity(0.3)),
              boxShadow: [BoxShadow(color: tint.withOpacity(0.08), blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32.r, height: 32.r,
                  decoration: BoxDecoration(color: tint.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(saved ? Icons.check_rounded : Icons.nightlight_round, color: tint, size: 16),
                ),
                SizedBox(width: 10.w),
                Text(
                  saved ? 'Day Saved to Career Stats' : 'End of Day — Save to Career Stats',
                  style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, fontWeight: FontWeight.w700, color: tint),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  /// Tap-to-edit: type the exact number instead of tapping +/- forty times.
  void _editMetricDialog(String label, RxInt field) {
    final ctrl = TextEditingController(text: field.value.toString());
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text('Edit $label', style: AppFonts.spaceGrotesk.copyWith(fontWeight: FontWeight.w800, fontSize: 16.sp)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: TextInputType.number,
        style: AppFonts.spaceGrotesk.copyWith(fontSize: 18.sp, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: 'Enter count',
          filled: true,
          fillColor: _kBg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
        ),
      ),
      actions: [
        TextButton(onPressed: Get.back, child: Text('Cancel', style: AppFonts.spaceGrotesk.copyWith(color: _kMuted))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _kRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))),
          onPressed: () {
            final v = int.tryParse(ctrl.text.trim());
            if (v != null) c.setMetricValue(field, v);
            Get.back();
          },
          child: Text('Save', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ],
    ));
  }

  /// Add a custom stats column (e.g. "Sales Calls", "Chapters Read") — name +
  /// icon picker live in the bottom sheet now.
  void _openAddStatSheet() {
    if (c.customMetrics.length >= 4) {
      Get.snackbar('Limit reached', 'You can add up to 4 custom stats.',
          snackPosition: SnackPosition.TOP);
      return;
    }
    CustomStatSheet.show();
  }

  /// Last 4 weeks at a glance — where am I trending?
  Widget _weeklyBreakdownCard() {
    return Obx(() {
      final weeks = StatsHistoryService.to.lastWeeks(count: 4);
      // Touch the list so Obx re-runs when a day is saved.
      StatsHistoryService.to.days.length;
      final labels = ['This week', 'Last week', '2 wks ago', '3 wks ago'];
      final hasAny = weeks.any((w) => w.daysLogged > 0);
      return Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(flex: 3, child: Text('Week', style: AppFonts.spaceGrotesk.copyWith(fontSize: 11.sp, fontWeight: FontWeight.w700, color: _kMuted))),
                Expanded(flex: 2, child: Text(c.homesLabel.value, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppFonts.spaceGrotesk.copyWith(fontSize: 11.sp, fontWeight: FontWeight.w700, color: const Color(0xff6366F1)))),
                Expanded(flex: 2, child: Text(c.peopleLabel.value, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppFonts.spaceGrotesk.copyWith(fontSize: 11.sp, fontWeight: FontWeight.w700, color: const Color(0xff10B981)))),
                Expanded(flex: 2, child: Text(c.salesLabel.value, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppFonts.spaceGrotesk.copyWith(fontSize: 11.sp, fontWeight: FontWeight.w700, color: _kRed))),
              ],
            ),
            SizedBox(height: 8.h),
            ...List.generate(weeks.length, (i) {
              final w = weeks[i];
              final bold = i == 0;
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 5.h),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(labels[i], style: AppFonts.spaceGrotesk.copyWith(fontSize: 12.sp, fontWeight: bold ? FontWeight.w800 : FontWeight.w500, color: bold ? _kText : _kMuted))),
                    Expanded(flex: 2, child: Text('${w.homes}', textAlign: TextAlign.center, style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w700, color: _kText))),
                    Expanded(flex: 2, child: Text('${w.people}', textAlign: TextAlign.center, style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w700, color: _kText))),
                    Expanded(flex: 2, child: Text('${w.sales}', textAlign: TextAlign.center, style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w700, color: _kText))),
                  ],
                ),
              );
            }),
            if (!hasAny) ...[
              SizedBox(height: 4.h),
              Text('Save your day (End of Day button) to start building your weekly history.',
                  style: AppFonts.spaceGrotesk.copyWith(fontSize: 11.sp, color: _kMuted)),
            ],
          ],
        ),
      );
    });
  }

  void _showEndOfDayDialog(BuildContext context) {
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text('End of Day Summary', style: AppFonts.spaceGrotesk.copyWith(fontWeight: FontWeight.w800, fontSize: 18.sp)),
      content: Obx(() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Save today\'s metrics to your all-time career stats?', style: AppFonts.spaceGrotesk.copyWith(color: _kMuted, fontSize: 14.sp, height: 1.5)),
          SizedBox(height: 16.h),
          _eodRow(c.homesLabel.value, c.homesKnocked.value, c.homesIconData, const Color(0xff6366F1)),
          _eodRow(c.peopleLabel.value, c.peopleTalkedTo.value, c.peopleIconData, const Color(0xff10B981)),
          _eodRow(c.salesLabel.value, c.salesMade.value, c.salesIconData, _kRed),
        ],
      )),
      actions: [
        TextButton(onPressed: Get.back, child: Text('Cancel', style: AppFonts.spaceGrotesk.copyWith(color: _kMuted))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kRed,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          ),
          onPressed: () async {
            // Same shared commit the automatic rollover uses — it owns the
            // achievements + history writes and the one-save-per-day guard.
            final saved = await c.saveDayToCareerStats();
            final already = c.isTodaySaved;
            Get.back();
            Get.snackbar(
              saved
                  ? '🎉 Day Saved!'
                  : (already ? 'Already Saved' : 'Nothing to Save Yet'),
              saved
                  ? 'Your stats have been added to your career totals.'
                  : (already
                      ? 'Today is already banked in your career stats.'
                      : 'Log some activity first, then save your day.'),
              backgroundColor:
                  saved || already ? const Color(0xff22C55E) : _kMuted,
              colorText: Colors.white,
              snackPosition: SnackPosition.TOP,
              borderRadius: 14,
              margin: EdgeInsets.all(16.r),
            );
          },
          child: Text('Save Day', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ],
    ));
  }

  Widget _eodRow(String label, int value, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Container(
            width: 32.r, height: 32.r,
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          SizedBox(width: 10.w),
          Expanded(child: Text(label, style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, color: _kText))),
          Text('$value', style: AppFonts.spaceGrotesk.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  void _showGoalDialog(BuildContext context) {
    final tec = TextEditingController(text: c.dailyGoal.value.toString());
    final selected = c.goalMetric.value.obs;
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text('Set Daily Goal', style: AppFonts.spaceGrotesk.copyWith(fontWeight: FontWeight.w800)),
      content: Obx(() => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What should this goal track?',
                  style: AppFonts.spaceGrotesk.copyWith(fontSize: 12.sp, color: _kMuted)),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  for (final opt in c.goalMetricOptions)
                    GestureDetector(
                      onTap: () => selected.value = opt.key,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: selected.value == opt.key ? _kRed : _kBg,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: selected.value == opt.key
                                ? _kRed
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          opt.label,
                          style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: selected.value == opt.key
                                ? Colors.white
                                : _kText,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: tec,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Daily target',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: _kRed, width: 2)),
                ),
              ),
            ],
          )),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _kRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))),
          onPressed: () {
            c.setGoalMetric(selected.value);
            final v = int.tryParse(tec.text);
            if (v != null && v > 0) c.setDailyGoal(v);
            Get.back();
          },
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  void _showAddTimerDialog(BuildContext context) {
    final tec = TextEditingController();
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text('Add Client Timer', style: AppFonts.spaceGrotesk.copyWith(fontWeight: FontWeight.w800)),
      content: TextField(
        controller: tec,
        decoration: InputDecoration(
          labelText: 'Client name',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: _kRed, width: 2)),
        ),
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _kRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))),
          onPressed: () { c.addClientTimer(tec.text); Get.back(); },
          child: const Text('Add', style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }
}

class _MetricCounter extends StatelessWidget {
  final String label;
  final IconData icon;
  final int value;
  final Color color;
  final VoidCallback onInc;
  final VoidCallback onDec;

  /// Tap the number to type an exact value (editable stats).
  final VoidCallback? onEdit;

  /// Long-press to edit (rename / change icon / remove) — only for user-added
  /// custom metrics.
  final VoidCallback? onLongPress;

  const _MetricCounter({required this.label, required this.icon, required this.value, required this.color, required this.onInc, required this.onDec, this.onEdit, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          children: [
            Container(
              width: 36.r, height: 36.r,
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            SizedBox(height: 6.h),
            Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppFonts.spaceGrotesk.copyWith(fontSize: 10.sp, color: _kMuted, height: 1.3), textAlign: TextAlign.center),
            SizedBox(height: 4.h),
            GestureDetector(
              onTap: onEdit,
              child: Text('$value', style: AppFonts.spaceGrotesk.copyWith(fontSize: 22.sp, fontWeight: FontWeight.w800, color: _kText)),
            ),
            SizedBox(height: 6.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CircleBtn(icon: Icons.remove, color: color, onTap: onDec),
                SizedBox(width: 8.w),
                _CircleBtn(icon: Icons.add, color: color, onTap: onInc),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26.r, height: 26.r,
        decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }
}

class _ClientTimerTile extends StatelessWidget {
  final ClientTimerEntry timer;
  final MissionController controller;

  const _ClientTimerTile({required this.timer, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Accessing clientTimers to trigger rebuild
      controller.clientTimers.length;
      return Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 42.r, height: 42.r,
              decoration: BoxDecoration(
                color: timer.isRunning ? _kRed.withOpacity(0.1) : _kMuted.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(timer.isRunning ? Icons.timer : Icons.timer_outlined, color: timer.isRunning ? _kRed : _kMuted, size: 22),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(timer.name, style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, fontWeight: FontWeight.w700, color: _kText)),
                  Text(timer.formatted, style: AppFonts.spaceGrotesk.copyWith(fontSize: 20.sp, fontWeight: FontWeight.w800, color: timer.isRunning ? _kRed : _kText, fontFeatures: [FontFeature.tabularFigures()])),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => controller.toggleTimer(timer.id),
              child: Container(
                width: 36.r, height: 36.r,
                decoration: BoxDecoration(
                  color: timer.isRunning ? _kRed : Color(0xff22C55E),
                  shape: BoxShape.circle,
                ),
                child: Icon(timer.isRunning ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 20),
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: () => controller.resetTimer(timer.id),
              child: Container(
                width: 36.r, height: 36.r,
                decoration: BoxDecoration(color: _kMuted.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(Icons.refresh, color: _kMuted, size: 18),
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: () => controller.removeClientTimer(timer.id),
              child: Container(
                width: 36.r, height: 36.r,
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.red, size: 18),
              ),
            ),
          ],
        ),
      );
    });
  }
}
