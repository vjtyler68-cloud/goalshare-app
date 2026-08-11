import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controller/goalendar_controller.dart';
import '../data/goalendar_models.dart';
import 'goalendar_theme.dart';

/// Create / edit an event. Opens as a scrollable bottom sheet.
Future<void> showGoalendarEditor(BuildContext context,
    {GoalendarEvent? event, DateTime? initialDay}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditorSheet(event: event, initialDay: initialDay),
  );
}

class _EditorSheet extends StatefulWidget {
  final GoalendarEvent? event;
  final DateTime? initialDay;
  const _EditorSheet({this.event, this.initialDay});

  @override
  State<_EditorSheet> createState() => _EditorSheetState();
}

class _EditorSheetState extends State<_EditorSheet> {
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _notes = TextEditingController();

  late DateTime _start;
  late DateTime _end;
  bool _allDay = false;
  GoalCategory _category = GoalCategory.personal;
  GoalRecur _recur = GoalRecur.none;
  final Set<int> _weekDays = {};
  final Set<int> _reminders = {};

  bool get _isEdit => widget.event != null;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    if (e != null) {
      _title.text = e.title;
      _location.text = e.location ?? '';
      _notes.text = e.notes ?? '';
      _start = e.start;
      _end = e.end;
      _allDay = e.allDay;
      _category = e.category;
      _recur = e.recurrence;
      _weekDays.addAll(e.recurDaysOfWeek);
      _reminders.addAll(e.reminderMinutes);
    } else {
      final base = widget.initialDay ?? DateTime.now();
      final now = DateTime.now();
      _start = DateTime(base.year, base.month, base.day, now.hour + 1, 0);
      _end = _start.add(const Duration(hours: 1));
      _reminders.add(15);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initial = isStart ? _start : _end;
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (d == null) return;
    TimeOfDay? t;
    if (!_allDay) {
      t = await showTimePicker(
          context: context, initialTime: TimeOfDay.fromDateTime(initial));
      if (t == null) return;
    }
    final picked =
        DateTime(d.year, d.month, d.day, t?.hour ?? 0, t?.minute ?? 0);
    setState(() {
      if (isStart) {
        final delta = _end.difference(_start);
        _start = picked;
        if (_end.isBefore(_start)) _end = _start.add(delta.abs());
      } else {
        _end = picked.isBefore(_start) ? _start.add(const Duration(hours: 1)) : picked;
      }
    });
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      Get.rawSnackbar(
          message: 'Give your event a title',
          duration: const Duration(seconds: 2));
      return;
    }
    final c = GoalendarController.to;
    final now = DateTime.now();
    final e = widget.event?.copy() ??
        GoalendarEvent(
          id: c.newId(),
          title: title,
          start: _start,
          end: _end,
          createdAt: now,
          updatedAt: now,
        );
    e.title = title;
    e.start = _start;
    e.end = _allDay ? DateTime(_end.year, _end.month, _end.day, 23, 59) : _end;
    e.allDay = _allDay;
    e.location = _location.text.trim().isEmpty ? null : _location.text.trim();
    e.notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    e.category = _category;
    e.recurrence = _recur;
    e.recurDaysOfWeek = _recur == GoalRecur.weekly ? _weekDays.toList() : [];
    e.reminderMinutes = _reminders.toList()..sort();
    c.upsert(e);
    Navigator.pop(context);
  }

  void _confirmDelete() {
    Get.defaultDialog(
      title: 'Delete event?',
      middleText: 'This can\'t be undone.',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: GCal.danger,
      onConfirm: () {
        GoalendarController.to.delete(widget.event!.id);
        Get.back();
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: 0.92.sh),
        decoration: BoxDecoration(
          color: GCal.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10.h),
            Container(
              width: 42.w,
              height: 4.h,
              decoration: BoxDecoration(
                  color: GCal.line, borderRadius: BorderRadius.circular(4.r)),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 10.h),
              child: Row(
                children: [
                  Text(_isEdit ? 'Edit event' : 'New event',
                      style: GCal.h1),
                  const Spacer(),
                  if (_isEdit)
                    IconButton(
                      onPressed: _confirmDelete,
                      icon: Icon(Icons.delete_outline_rounded,
                          color: GCal.danger, size: 22.r),
                    ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _title,
                      textCapitalization: TextCapitalization.sentences,
                      style: GCal.body.copyWith(
                          fontSize: 18.sp, fontWeight: FontWeight.w800),
                      decoration: _dec('Event title'),
                    ),
                    SizedBox(height: 14.h),
                    _card(Column(
                      children: [
                        _rowToggle('All-day', _allDay,
                            (v) => setState(() => _allDay = v)),
                        Divider(color: GCal.line, height: 18.h),
                        _timeRow('Starts', _start, () => _pickDateTime(isStart: true)),
                        SizedBox(height: 10.h),
                        _timeRow('Ends', _end, () => _pickDateTime(isStart: false)),
                      ],
                    )),
                    SizedBox(height: 14.h),
                    Text('CATEGORY', style: GCal.label),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: GoalCategory.values.map(_swatch).toList(),
                    ),
                    SizedBox(height: 16.h),
                    _card(Column(
                      children: [
                        _iconField(Icons.place_outlined, _location, 'Add location'),
                        Divider(color: GCal.line, height: 18.h),
                        _iconField(Icons.notes_rounded, _notes, 'Add notes',
                            maxLines: 3),
                      ],
                    )),
                    SizedBox(height: 16.h),
                    Text('REMIND ME', style: GCal.label),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        for (final m in const [
                          [15, '15 min'],
                          [30, '30 min'],
                          [60, '1 hour'],
                          [1440, '1 day'],
                        ])
                          _chip('${m[1]}', _reminders.contains(m[0] as int),
                              () => setState(() {
                                    final v = m[0] as int;
                                    _reminders.contains(v)
                                        ? _reminders.remove(v)
                                        : _reminders.add(v);
                                  })),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Text('REPEATS', style: GCal.label),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: GoalRecur.values
                          .map((r) => _chip(
                              r == GoalRecur.none ? 'None' : r.label,
                              _recur == r,
                              () => setState(() => _recur = r)))
                          .toList(),
                    ),
                    if (_recur == GoalRecur.weekly) ...[
                      SizedBox(height: 10.h),
                      Wrap(
                        spacing: 6.w,
                        children: [
                          for (var i = 1; i <= 7; i++)
                            _dayDot(i, _weekDays.contains(i),
                                () => setState(() {
                                      _weekDays.contains(i)
                                          ? _weekDays.remove(i)
                                          : _weekDays.add(i);
                                    })),
                        ],
                      ),
                    ],
                    SizedBox(height: 22.h),
                    GestureDetector(
                      onTap: _save,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 15.h),
                        decoration: BoxDecoration(
                            gradient: GCal.brand,
                            borderRadius: BorderRadius.circular(30.r)),
                        child: Center(
                          child: Text(_isEdit ? 'Save changes' : 'Add event',
                              style: GCal.body.copyWith(
                                  color: Colors.white,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── bits ──
  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: GCal.body.copyWith(color: GCal.muted),
        filled: true,
        fillColor: GCal.card,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide.none),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      );

  Widget _card(Widget child) => Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
            color: GCal.card, borderRadius: BorderRadius.circular(16.r)),
        child: child,
      );

  Widget _rowToggle(String label, bool value, ValueChanged<bool> onCh) => Row(
        children: [
          Text(label, style: GCal.body),
          const Spacer(),
          Switch(value: value, activeColor: GCal.violet, onChanged: onCh),
        ],
      );

  Widget _timeRow(String label, DateTime dt, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            Text(label, style: GCal.body),
            const Spacer(),
            Text(
                _allDay
                    ? DateFormat('EEE, MMM d').format(dt)
                    : DateFormat('EEE, MMM d · h:mm a').format(dt),
                style: GCal.body.copyWith(
                    color: GCal.violet, fontWeight: FontWeight.w700)),
          ],
        ),
      );

  Widget _iconField(IconData icon, TextEditingController ctrl, String hint,
          {int maxLines = 1}) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 10.h),
            child: Icon(icon, color: GCal.muted, size: 20.r),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              controller: ctrl,
              maxLines: maxLines,
              textCapitalization: TextCapitalization.sentences,
              style: GCal.body,
              decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GCal.body.copyWith(color: GCal.muted),
                  border: InputBorder.none,
                  isDense: true),
            ),
          ),
        ],
      );

  Widget _swatch(GoalCategory cat) {
    final selected = _category == cat;
    return GestureDetector(
      onTap: () => setState(() => _category = cat),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: cat.color.withOpacity(selected ? 0.9 : 0.14),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
              color: cat.color.withOpacity(selected ? 1 : 0.35), width: 1.2),
        ),
        child: Text(cat.label,
            style: GCal.body.copyWith(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : cat.color)),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
          decoration: BoxDecoration(
            color: selected ? GCal.violet : GCal.card,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(label,
              style: GCal.body.copyWith(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : GCal.text)),
        ),
      );

  Widget _dayDot(int weekday, bool selected, VoidCallback onTap) {
    const labels = {1: 'M', 2: 'T', 3: 'W', 4: 'T', 5: 'F', 6: 'S', 7: 'S'};
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34.r,
        height: 34.r,
        decoration: BoxDecoration(
          color: selected ? GCal.violet : GCal.card,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(labels[weekday]!,
              style: GCal.body.copyWith(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : GCal.text)),
        ),
      ),
    );
  }
}
