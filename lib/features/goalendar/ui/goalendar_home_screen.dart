import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controller/goalendar_controller.dart';
import '../data/goalendar_models.dart';
import 'goalendar_event_editor.dart';
import 'goalendar_settings_screen.dart';
import 'goalendar_theme.dart';

class GoalendarHomeScreen extends StatefulWidget {
  const GoalendarHomeScreen({super.key});

  @override
  State<GoalendarHomeScreen> createState() => _GoalendarHomeScreenState();
}

class _GoalendarHomeScreenState extends State<GoalendarHomeScreen> {
  final GoalendarController c = GoalendarController.to;
  late String _view; // 'month' | 'agenda'

  @override
  void initState() {
    super.initState();
    _view = c.settings.value.defaultView == 'agenda' ? 'agenda' : 'month';
    // Pull the latest device-calendar events each time the calendar opens.
    if (c.syncEnabled) c.refreshDeviceEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GCal.bg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: GCal.violet,
        onPressed: () => showGoalendarEditor(context, initialDay: c.selectedDay.value),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          _header(),
          Expanded(
            child: Obx(() {
              // touch reactive sources so the body rebuilds on change
              c.events.length;
              c.deviceEvents.length;
              c.focusedMonth.value;
              c.selectedDay.value;
              c.settings.value;
              return _view == 'month' ? _monthView() : _agendaView();
            }),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _header() {
    return Container(
      decoration: const BoxDecoration(gradient: GCal.brand),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(10.w, 6.h, 14.w, 14.h),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                      onPressed: Get.back,
                      icon: const Icon(Icons.arrow_back, color: Colors.white)),
                  Text('Goalendar',
                      style: GCal.h1.copyWith(
                          color: Colors.white, fontSize: 20.sp)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Get.to(() => const GoalendarSettingsScreen()),
                    icon: const Icon(Icons.tune_rounded, color: Colors.white),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Row(
                children: [
                  Obx(() => Text(DateFormat('MMMM yyyy').format(c.focusedMonth.value),
                      style: GCal.h1.copyWith(
                          color: Colors.white, fontSize: 17.sp))),
                  const Spacer(),
                  _navBtn(Icons.chevron_left_rounded, () => _shiftMonth(-1)),
                  SizedBox(width: 4.w),
                  GestureDetector(
                    onTap: _goToday,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20.r)),
                      child: Text('Today',
                          style: GCal.body.copyWith(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  _navBtn(Icons.chevron_right_rounded, () => _shiftMonth(1)),
                ],
              ),
              SizedBox(height: 12.h),
              _switcher(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32.r,
          height: 32.r,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 20.r),
        ),
      );

  Widget _switcher() {
    Widget seg(String id, String label) {
      final on = _view == id;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _view = id),
          child: Container(
            margin: EdgeInsets.all(3.r),
            padding: EdgeInsets.symmetric(vertical: 8.h),
            decoration: BoxDecoration(
                color: on ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(20.r)),
            child: Center(
              child: Text(label,
                  style: GCal.body.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: on ? GCal.violet : Colors.white)),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(24.r)),
      child: Row(children: [seg('month', 'Month'), seg('agenda', 'Agenda')]),
    );
  }

  void _shiftMonth(int delta) {
    final m = c.focusedMonth.value;
    c.focusedMonth.value = DateTime(m.year, m.month + delta, 1);
  }

  void _goToday() {
    final now = DateTime.now();
    c.focusedMonth.value = DateTime(now.year, now.month, 1);
    c.selectedDay.value = DateUtils.dateOnly(now);
  }

  // ── Month view ──────────────────────────────────────────────────────────────
  Widget _monthView() {
    final weekStart = c.settings.value.weekStartDay; // 0 Sun, 1 Mon
    final labels = weekStart == 1
        ? const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
        : const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final month = c.focusedMonth.value;
    final first = DateTime(month.year, month.month, 1);
    final leadWeekday = weekStart == 1 ? DateTime.monday : DateTime.sunday;
    final leading = (first.weekday - leadWeekday) % 7;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final today = DateUtils.dateOnly(DateTime.now());

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          child: Row(
            children: labels
                .map((l) => Expanded(
                      child: Center(
                          child: Text(l,
                              style: GCal.label.copyWith(fontSize: 10.sp))),
                    ))
                .toList(),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, childAspectRatio: 0.72),
            itemCount: 42,
            itemBuilder: (_, i) {
              final dayNum = i - leading + 1;
              if (dayNum < 1 || dayNum > daysInMonth) {
                return const SizedBox();
              }
              final day = DateTime(month.year, month.month, dayNum);
              final isToday = DateUtils.isSameDay(day, today);
              final isSelected = DateUtils.isSameDay(day, c.selectedDay.value);
              final dots = c.dotColorsForDay(day);
              return GestureDetector(
                onTap: () {
                  c.selectedDay.value = day;
                  _openDaySheet(day);
                },
                child: Container(
                  margin: EdgeInsets.all(2.r),
                  decoration: BoxDecoration(
                    color: isSelected ? GCal.violet.withOpacity(0.10) : null,
                    borderRadius: BorderRadius.circular(12.r),
                    border: isToday
                        ? Border.all(color: GCal.violet, width: 1.6)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$dayNum',
                          style: GCal.body.copyWith(
                              fontSize: 13.sp,
                              fontWeight:
                                  isToday ? FontWeight.w900 : FontWeight.w600,
                              color: isToday ? GCal.violet : GCal.text)),
                      SizedBox(height: 4.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final col in dots)
                            Container(
                              width: 5.r,
                              height: 5.r,
                              margin: EdgeInsets.symmetric(horizontal: 1.r),
                              decoration: BoxDecoration(
                                  color: col, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openDaySheet(DateTime day) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GCal.bg,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22.r))),
      builder: (_) => Obx(() {
        final list = c.eventsForDay(day);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 18.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('EEEE, MMMM d').format(day), style: GCal.h1),
                SizedBox(height: 12.h),
                if (list.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                    child: Text(
                        'Nothing scheduled yet — what\'s one thing that moves '
                        'you forward today?',
                        style: GCal.body.copyWith(color: GCal.muted, height: 1.5)),
                  )
                else
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: list.map((e) => _eventCard(e)).toList(),
                      ),
                    ),
                  ),
                SizedBox(height: 12.h),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    showGoalendarEditor(context, initialDay: day);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 13.h),
                    decoration: BoxDecoration(
                        gradient: GCal.brand,
                        borderRadius: BorderRadius.circular(30.r)),
                    child: Center(
                      child: Text('Add event',
                          style: GCal.body.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── Agenda view ─────────────────────────────────────────────────────────────
  Widget _agendaView() {
    final items = c.upcoming(days: 60);
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(32.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_available_rounded,
                  size: 48.r, color: GCal.violet.withOpacity(0.6)),
              SizedBox(height: 14.h),
              Text('Your week is a blank canvas',
                  style: GCal.h1, textAlign: TextAlign.center),
              SizedBox(height: 6.h),
              Text('Tap + to schedule what moves you forward.',
                  textAlign: TextAlign.center,
                  style: GCal.body.copyWith(color: GCal.muted)),
            ],
          ),
        ),
      );
    }
    DateTime? lastDay;
    final children = <Widget>[];
    for (final it in items) {
      if (lastDay == null || !DateUtils.isSameDay(lastDay, it.day)) {
        lastDay = it.day;
        children.add(Padding(
          padding: EdgeInsets.fromLTRB(4.w, 14.h, 4.w, 6.h),
          child: Text(
              DateUtils.isSameDay(it.day, DateTime.now())
                  ? 'Today · ${DateFormat('MMM d').format(it.day)}'
                  : DateFormat('EEEE · MMM d').format(it.day),
              style: GCal.label),
        ));
      }
      children.add(_eventCard(it.event));
    }
    return ListView(
      padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 90.h),
      children: children,
    );
  }

  // Read-only detail for an event pulled from the iPhone Calendar.
  void _showReadOnly(GoalendarEvent e) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GCal.bg,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22.r))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 22.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.phone_iphone_rounded, size: 16.r, color: GCal.muted),
                  SizedBox(width: 6.w),
                  Text('From iPhone Calendar', style: GCal.label),
                ],
              ),
              SizedBox(height: 10.h),
              Text(e.title, style: GCal.h1),
              SizedBox(height: 8.h),
              Text(
                  e.allDay
                      ? 'All-day · ${DateFormat('EEE, MMM d').format(e.start)}'
                      : '${DateFormat('EEE, MMM d · h:mm a').format(e.start)} – ${DateFormat('h:mm a').format(e.end)}',
                  style: GCal.body.copyWith(color: GCal.muted)),
              if ((e.location ?? '').isNotEmpty) ...[
                SizedBox(height: 10.h),
                Row(children: [
                  Icon(Icons.place_outlined, size: 18.r, color: GCal.muted),
                  SizedBox(width: 8.w),
                  Expanded(child: Text(e.location!, style: GCal.body)),
                ]),
              ],
              if ((e.notes ?? '').isNotEmpty) ...[
                SizedBox(height: 10.h),
                Text(e.notes!, style: GCal.body.copyWith(height: 1.5)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventCard(GoalendarEvent e) {
    return GestureDetector(
      onTap: () => e.deviceReadOnly
          ? _showReadOnly(e)
          : showGoalendarEditor(context, event: e),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: GCal.card,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 5.w,
              height: 40.h,
              decoration: BoxDecoration(
                  color: e.color, borderRadius: BorderRadius.circular(4.r)),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GCal.body.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          decoration: e.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: e.isCompleted ? GCal.muted : GCal.text)),
                  SizedBox(height: 2.h),
                  Text(
                      e.allDay
                          ? 'All-day'
                          : '${DateFormat('h:mm a').format(e.start)} – ${DateFormat('h:mm a').format(e.end)}',
                      style: GCal.body.copyWith(fontSize: 11.5.sp, color: GCal.muted)),
                  if ((e.location ?? '').isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(e.location!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GCal.body
                            .copyWith(fontSize: 11.sp, color: GCal.muted)),
                  ],
                ],
              ),
            ),
            if (e.deviceReadOnly)
              Icon(Icons.phone_iphone_rounded, color: GCal.muted, size: 18.r)
            else
              GestureDetector(
                onTap: () => c.toggleComplete(e),
                behavior: HitTestBehavior.opaque,
                child: Icon(
                    e.isCompleted
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: e.isCompleted ? e.color : GCal.line,
                    size: 24.r),
              ),
          ],
        ),
      ),
    );
  }
}
