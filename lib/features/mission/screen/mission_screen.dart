import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/features/achievements/achievements_controller.dart';
import '../../../core/alertdialogs/create_new_mission.dart';
import '../controller/mission_controller.dart';
import '../data/stats_history.dart';
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
                      final knocked = c.homesKnocked.value;
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
                          Text('$knocked of $goal homes knocked', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w600)),
                        ],
                      );
                    }),
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
                  // Metric counters — tap a number to type the exact value.
                  _sectionLabel('Today\'s Metrics'),
                  SizedBox(height: 10.h),
                  Obx(() => Row(
                    children: [
                      Expanded(child: _MetricCounter(label: 'Homes\nKnocked', icon: Icons.home_outlined, value: c.homesKnocked.value, color: const Color(0xff6366F1), onInc: () => c.increment(c.homesKnocked), onDec: () => c.decrement(c.homesKnocked), onEdit: () => _editMetricDialog('Homes Knocked', c.homesKnocked))),
                      SizedBox(width: 10.w),
                      Expanded(child: _MetricCounter(label: 'People\nTalked To', icon: Icons.people_outline, value: c.peopleTalkedTo.value, color: const Color(0xff10B981), onInc: () => c.increment(c.peopleTalkedTo), onDec: () => c.decrement(c.peopleTalkedTo), onEdit: () => _editMetricDialog('People Talked To', c.peopleTalkedTo))),
                      SizedBox(width: 10.w),
                      Expanded(child: _MetricCounter(label: 'Sales\nMade', icon: Icons.attach_money, value: c.salesMade.value, color: _kRed, onInc: () => c.increment(c.salesMade), onDec: () => c.decrement(c.salesMade), onEdit: () => _editMetricDialog('Sales Made', c.salesMade))),
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
                                          icon: Icons.tune_rounded,
                                          value: metrics[i].value.value,
                                          color: const Color(0xff8B5CF6),
                                          onInc: () => c.increment(metrics[i].value),
                                          onDec: () => c.decrement(metrics[i].value),
                                          onEdit: () => _editMetricDialog(metrics[i].name, metrics[i].value),
                                          onRemove: () => _confirmRemoveMetric(metrics[i]),
                                        )),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        GestureDetector(
                          onTap: _addMetricDialog,
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

  Widget _sectionLabel(String text) {
    return Text(text, style: AppFonts.spaceGrotesk.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w800, color: _kText));
  }

  Widget _buildEndOfDayButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showEndOfDayDialog(context),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: _kRed.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: _kRed.withOpacity(0.08), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32.r, height: 32.r,
              decoration: BoxDecoration(color: _kRed.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.nightlight_round, color: _kRed, size: 16),
            ),
            SizedBox(width: 10.w),
            Text('End of Day — Save to Career Stats', style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, fontWeight: FontWeight.w700, color: _kRed)),
          ],
        ),
      ),
    );
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

  /// Add a custom stats column (e.g. "Doors Hung", "Appointments Set").
  void _addMetricDialog() {
    if (c.customMetrics.length >= 4) {
      Get.snackbar('Limit reached', 'You can add up to 4 custom stats.',
          snackPosition: SnackPosition.TOP);
      return;
    }
    final ctrl = TextEditingController();
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text('Add your own stat', style: AppFonts.spaceGrotesk.copyWith(fontWeight: FontWeight.w800, fontSize: 16.sp)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp),
        decoration: InputDecoration(
          hintText: 'e.g. Appointments Set',
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
            if (c.addCustomMetric(ctrl.text)) Get.back();
          },
          child: Text('Add', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ],
    ));
  }

  void _confirmRemoveMetric(CustomMetric m) {
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text('Remove "${m.name}"?', style: AppFonts.spaceGrotesk.copyWith(fontWeight: FontWeight.w800, fontSize: 16.sp)),
      content: Text('This removes the stat column. Past saved days keep their numbers.',
          style: AppFonts.spaceGrotesk.copyWith(color: _kMuted, fontSize: 13.sp)),
      actions: [
        TextButton(onPressed: Get.back, child: Text('Cancel', style: AppFonts.spaceGrotesk.copyWith(color: _kMuted))),
        TextButton(
          onPressed: () {
            c.removeCustomMetric(m.id);
            Get.back();
          },
          child: Text('Remove', style: AppFonts.spaceGrotesk.copyWith(color: _kRed, fontWeight: FontWeight.w700)),
        ),
      ],
    ));
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
                Expanded(flex: 2, child: Text('Homes', textAlign: TextAlign.center, style: AppFonts.spaceGrotesk.copyWith(fontSize: 11.sp, fontWeight: FontWeight.w700, color: const Color(0xff6366F1)))),
                Expanded(flex: 2, child: Text('People', textAlign: TextAlign.center, style: AppFonts.spaceGrotesk.copyWith(fontSize: 11.sp, fontWeight: FontWeight.w700, color: const Color(0xff10B981)))),
                Expanded(flex: 2, child: Text('Sales', textAlign: TextAlign.center, style: AppFonts.spaceGrotesk.copyWith(fontSize: 11.sp, fontWeight: FontWeight.w700, color: _kRed))),
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
          _eodRow('Homes Knocked', c.homesKnocked.value, Icons.home_outlined, const Color(0xff6366F1)),
          _eodRow('People Talked To', c.peopleTalkedTo.value, Icons.people_outline, const Color(0xff10B981)),
          _eodRow('Sales Made', c.salesMade.value, Icons.attach_money, _kRed),
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
            final ac = Get.find<AchievementsController>();
            await ac.recordDailyActivity(
              homes: c.homesKnocked.value,
              people: c.peopleTalkedTo.value,
              sales: c.salesMade.value,
              dailyGoal: c.dailyGoal.value,
            );
            // Also store the day in local history so the Weekly Breakdown
            // (and future charts) have per-day data. Same-date saves replace.
            await StatsHistoryService.to.recordDay(DayStat(
              date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
              homes: c.homesKnocked.value,
              people: c.peopleTalkedTo.value,
              sales: c.salesMade.value,
              custom: {
                for (final m in c.customMetrics) m.name: m.value.value,
              },
            ));
            Get.back();
            Get.snackbar(
              '🎉 Day Saved!',
              'Your stats have been added to your career totals.',
              backgroundColor: const Color(0xff22C55E),
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
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text('Set Daily Goal', style: AppFonts.spaceGrotesk.copyWith(fontWeight: FontWeight.w800)),
      content: TextField(
        controller: tec,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: 'Homes to knock today',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: _kRed, width: 2)),
        ),
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _kRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r))),
          onPressed: () {
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

  /// Long-press to remove — only for user-added custom metrics.
  final VoidCallback? onRemove;

  const _MetricCounter({required this.label, required this.icon, required this.value, required this.color, required this.onInc, required this.onDec, this.onEdit, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onRemove,
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
