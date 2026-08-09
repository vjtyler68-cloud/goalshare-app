import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/const/app_fonts.dart';
import '../controller/goflow_controller.dart';
import '../data/goflow_models.dart';

const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// One-screen quick log: flow, mood, energy, cramps and optional symptom tags —
/// chips and taps, not a form. Idempotent per day (re-opening the same day
/// pre-fills what's there and overwrites on save).
class GoFlowLogSheet extends StatefulWidget {
  final DateTime day;
  const GoFlowLogSheet({super.key, required this.day});

  static Future<void> show(DateTime day) => Get.bottomSheet(
        GoFlowLogSheet(day: day),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );

  @override
  State<GoFlowLogSheet> createState() => _GoFlowLogSheetState();
}

class _GoFlowLogSheetState extends State<GoFlowLogSheet> {
  late GoFlowIntensity _flow;
  late int _mood;
  late int _energy;
  late int _cramps;
  late List<String> _symptoms;
  late bool _intercourse;
  late final TextEditingController _notes;

  static const List<String> _symptomTags = [
    'Bloating',
    'Headache',
    'Backache',
    'Nausea',
    'Tender',
    'Acne',
    'Insomnia',
    'Anxious',
  ];

  Color get _accent => GoFlowController.to.accentColor;

  @override
  void initState() {
    super.initState();
    final e = GoFlowController.to.entryFor(widget.day);
    _flow = e?.flow ?? GoFlowIntensity.none;
    _mood = e?.mood ?? 0;
    _energy = e?.energy ?? 0;
    _cramps = e?.cramps ?? 0;
    _symptoms = List<String>.from(e?.symptoms ?? const []);
    _intercourse = e?.intercourse ?? false;
    _notes = TextEditingController(text: e?.notes ?? '');
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    GoFlowController.to.saveEntry(GoFlowEntry(
      date: DateTime(widget.day.year, widget.day.month, widget.day.day),
      flow: _flow,
      mood: _mood,
      energy: _energy,
      cramps: _cramps,
      symptoms: _symptoms,
      intercourse: _intercourse,
      notes: _notes.text.trim(),
    ));
    Get.back();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final isToday = _sameDay(widget.day, DateTime.now());
    final title = isToday
        ? 'How are you today?'
        : 'Log ${widget.day.month}/${widget.day.day}';
    return Container(
      constraints: BoxConstraints(maxHeight: 0.9.sh),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
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
          Text(title,
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 19.sp, fontWeight: FontWeight.w800, color: _kText)),
          SizedBox(height: 16.h),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Flow'),
                  SizedBox(height: 8.h),
                  _flowRow(),
                  SizedBox(height: 18.h),
                  _scale('Mood', _mood, (v) => setState(() => _mood = v),
                      ['😞', '😕', '😐', '🙂', '😄']),
                  SizedBox(height: 16.h),
                  _scale('Energy', _energy, (v) => setState(() => _energy = v),
                      ['🪫', '🔅', '⚡', '⚡', '🔋']),
                  SizedBox(height: 16.h),
                  _scale('Cramps', _cramps, (v) => setState(() => _cramps = v),
                      ['—', '·', '••', '•••', '‼️']),
                  SizedBox(height: 18.h),
                  _label('Symptoms  ·  up to 5'),
                  SizedBox(height: 8.h),
                  _symptomWrap(),
                  SizedBox(height: 18.h),
                  _intimacyToggle(),
                  SizedBox(height: 18.h),
                  _label('Notes'),
                  SizedBox(height: 8.h),
                  TextField(
                    controller: _notes,
                    maxLines: 3,
                    maxLength: 300,
                    style: AppFonts.spaceGrotesk
                        .copyWith(fontSize: 14.sp, color: _kText),
                    decoration: InputDecoration(
                      hintText: 'Anything you want to remember…',
                      hintStyle: AppFonts.spaceGrotesk
                          .copyWith(fontSize: 13.sp, color: _kMuted),
                      filled: true,
                      fillColor: const Color(0xffF6F4F2),
                      counterText: '',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: _save,
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
    );
  }

  Widget _label(String t) => Text(t,
      style: AppFonts.spaceGrotesk.copyWith(
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: _kMuted));

  Widget _flowRow() {
    final items = <MapEntry<GoFlowIntensity, String>>[
      const MapEntry(GoFlowIntensity.none, 'None'),
      const MapEntry(GoFlowIntensity.light, 'Light'),
      const MapEntry(GoFlowIntensity.medium, 'Medium'),
      const MapEntry(GoFlowIntensity.heavy, 'Heavy'),
    ];
    return Row(
      children: [
        for (final it in items) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _flow = it.key),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: _flow == it.key ? _accent : const Color(0xffF6F4F2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    Icon(
                      it.key == GoFlowIntensity.none
                          ? Icons.block
                          : Icons.water_drop,
                      size: 16.r,
                      color: _flow == it.key
                          ? Colors.white
                          : (it.key == GoFlowIntensity.none
                              ? _kMuted
                              : _accent),
                    ),
                    SizedBox(height: 4.h),
                    Text(it.value,
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color:
                                _flow == it.key ? Colors.white : _kText)),
                  ],
                ),
              ),
            ),
          ),
          if (it.key != GoFlowIntensity.heavy) SizedBox(width: 8.w),
        ],
      ],
    );
  }

  Widget _scale(
      String label, int value, ValueChanged<int> onChange, List<String> emojis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        SizedBox(height: 8.h),
        Row(
          children: [
            for (int i = 1; i <= 5; i++) ...[
              Expanded(
                child: GestureDetector(
                  // Tapping the active level again clears it (back to unset).
                  onTap: () => onChange(value == i ? 0 : i),
                  child: Container(
                    height: 46.h,
                    decoration: BoxDecoration(
                      color:
                          value == i ? _accent.withOpacity(0.15) : const Color(0xffF6F4F2),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                          color: value == i ? _accent : Colors.transparent,
                          width: 1.5),
                    ),
                    child: Center(
                      child: Text(emojis[i - 1],
                          style: TextStyle(fontSize: 18.sp)),
                    ),
                  ),
                ),
              ),
              if (i != 5) SizedBox(width: 8.w),
            ],
          ],
        ),
      ],
    );
  }

  Widget _intimacyToggle() {
    return GestureDetector(
      onTap: () => setState(() => _intercourse = !_intercourse),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: _intercourse ? _accent.withOpacity(0.12) : const Color(0xffF6F4F2),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
              color: _intercourse ? _accent : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(Icons.favorite_rounded,
                size: 18.r, color: _intercourse ? _accent : _kMuted),
            SizedBox(width: 10.w),
            Expanded(
              child: Text('Intimacy',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: _kText)),
            ),
            Icon(
                _intercourse
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                size: 20.r,
                color: _intercourse ? _accent : _kMuted),
          ],
        ),
      ),
    );
  }

  Widget _symptomWrap() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        for (final tag in _symptomTags)
          GestureDetector(
            onTap: () {
              setState(() {
                if (_symptoms.contains(tag)) {
                  _symptoms.remove(tag);
                } else if (_symptoms.length < 5) {
                  _symptoms.add(tag);
                }
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
              decoration: BoxDecoration(
                color: _symptoms.contains(tag)
                    ? _accent
                    : const Color(0xffF6F4F2),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(tag,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                      color: _symptoms.contains(tag) ? Colors.white : _kText)),
            ),
          ),
      ],
    );
  }
}
