import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/routes/app_routes.dart';
import '../controller/journal_controller.dart';
import '../data/journal_entry.dart';
import '../widgets/mood_selector.dart';
import '../widgets/star_rating.dart';
import 'package:spanx/core/const/app_colors.dart';

Color get _kRed => AppColors.primaryColor;
Color get _kRedDark => AppColors.primaryDarkColor;
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);
const _kBg = Color(0xffF6F4F2);

/// Create or edit today's (or a chosen day's) journal entry.
/// Optional `Get.arguments` may be a [DateTime] to open a specific day.
class JournalEntryScreen extends StatefulWidget {
  const JournalEntryScreen({super.key});

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final JournalController c = JournalController.to;

  late DateTime _date;
  final List<TextEditingController> _grat =
      List.generate(kMaxGratitude, (_) => TextEditingController());
  final TextEditingController _dayText = TextEditingController();
  int _rating = 0;
  String? _mood;

  int _hintTick = 0;
  Timer? _hintTimer;
  Worker? _readyWorker;

  static const List<String> _hints = [
    'my family',
    'my health',
    'a warm bed',
    'a good friend',
    'the morning sun',
    'a hot coffee',
    'my home',
    'clean water',
    'a kind stranger',
    'music I love',
    'a good meal',
    'time to rest',
    'a lesson learned',
    'laughter today',
    'a fresh start',
  ];

  @override
  void initState() {
    super.initState();
    final arg = Get.arguments;
    _date = arg is DateTime ? arg : DateTime.now();
    // Only read existing data once the Hive box is actually open, otherwise
    // an existing entry would silently fail to prefill.
    if (c.isReady.value) {
      _loadForDate(_date);
    } else {
      _readyWorker = ever<bool>(c.isReady, (ready) {
        if (ready && mounted) _loadForDate(_date);
      });
    }
    _hintTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (mounted) setState(() => _hintTick++);
    });
  }

  @override
  void dispose() {
    _readyWorker?.dispose();
    _hintTimer?.cancel();
    for (final t in _grat) {
      t.dispose();
    }
    _dayText.dispose();
    super.dispose();
  }

  void _loadForDate(DateTime d) {
    final existing = c.entryFor(d);
    for (var i = 0; i < kMaxGratitude; i++) {
      _grat[i].text =
          (existing != null && i < existing.gratitudeItems.length)
              ? existing.gratitudeItems[i]
              : '';
    }
    _dayText.text = existing?.dayText ?? '';
    _rating = existing?.starRating ?? 0;
    _mood = existing?.mood;
    setState(() {});
  }

  int get _filled => _grat.where((t) => t.text.trim().isNotEmpty).length;
  bool get _canSave => _filled >= kMinGratitude;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: _kRed),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _date = picked;
      _loadForDate(picked);
    }
  }

  Future<void> _save() async {
    if (!_canSave) {
      AppSnackBar.show(
        message: 'Add at least $kMinGratitude things to save.',
        isSuccessful: false,
      );
      return;
    }
    if (!c.isReady.value) {
      AppSnackBar.show(
        message: 'Still loading — try again in a moment.',
        isSuccessful: false,
      );
      return;
    }
    final items = _grat
        .map((t) => t.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final existing = c.entryFor(_date);
    final now = DateTime.now();
    final entry = JournalEntry(
      id: JournalController.keyFor(_date),
      date: DateTime(_date.year, _date.month, _date.day),
      gratitudeItems: items,
      dayText: _dayText.text.trim(),
      starRating: _rating,
      mood: _mood,
      createdAt: existing?.createdAt ?? now,
      updatedAt: existing != null ? now : null,
      edited: existing != null,
    );
    final ok = await c.save(entry);
    if (!ok) {
      AppSnackBar.show(
        message: "Couldn't save — storage isn't ready yet.",
        isSuccessful: false,
      );
      return;
    }
    AppSnackBar.show(message: 'Entry saved 🙏', isSuccessful: true);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: Get.back,
        ),
        title: Text(
          'Gratitude Journal',
          style: AppFonts.spaceGrotesk.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            onPressed: () => Get.toNamed(AppRoutes.journalHistoryScreen),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 40.h),
        children: [
          _dateHeader(),
          SizedBox(height: 20.h),
          _sectionTitle('I AM Happy and Grateful For…', trailing: _counterPill()),
          SizedBox(height: 4.h),
          Text(
            'Write at least $kMinGratitude. Fields $kMinGratitude–$kMaxGratitude are optional.',
            style: AppFonts.spaceGrotesk.copyWith(fontSize: 11.sp, color: _kMuted),
          ),
          SizedBox(height: 12.h),
          ...List.generate(kMaxGratitude, _gratField),
          SizedBox(height: 24.h),
          _sectionTitle('How was your day?'),
          SizedBox(height: 10.h),
          _dayTextField(),
          SizedBox(height: 24.h),
          _sectionTitle('Rate your day'),
          SizedBox(height: 10.h),
          Center(
            child: StarRating(
              value: _rating,
              onChanged: (v) => setState(() => _rating = v),
            ),
          ),
          SizedBox(height: 24.h),
          _sectionTitle('Mood', trailing: _optionalTag()),
          SizedBox(height: 10.h),
          MoodSelector(value: _mood, onChanged: (m) => setState(() => _mood = m)),
          SizedBox(height: 30.h),
          _saveButton(),
        ],
      ),
    );
  }

  // ── pieces ───────────────────────────────────────────────────────────────��─
  Widget _dateHeader() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                color: _kRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Icon(Icons.calendar_today_rounded, color: _kRed, size: 18.r),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE').format(_date),
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 10.sp,
                      color: _kMuted,
                    ),
                  ),
                  Text(
                    DateFormat('MMMM d, y').format(_date),
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: _kText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_calendar_outlined, color: _kMuted, size: 18.r),
          ],
        ),
      ),
    );
  }

  Widget _gratField(int i) {
    final hint = _hints[(i + _hintTick) % _hints.length];
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 26.r,
            height: 26.r,
            margin: EdgeInsets.all(10.r),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _grat[i].text.trim().isNotEmpty
                  ? _kRed
                  : _kRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${i + 1}',
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: _grat[i].text.trim().isNotEmpty ? Colors.white : _kRed,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _grat[i],
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, color: _kText),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'e.g. $hint',
                hintStyle:
                    AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, color: _kMuted),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 4.w),
              ),
            ),
          ),
          if (i >= kMinGratitude)
            Padding(
              padding: EdgeInsets.only(right: 10.w),
              child: Text(
                'optional',
                style:
                    AppFonts.spaceGrotesk.copyWith(fontSize: 8.sp, color: _kMuted),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dayTextField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
      child: TextField(
        controller: _dayText,
        minLines: 3,
        maxLines: null,
        textCapitalization: TextCapitalization.sentences,
        style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, color: _kText, height: 1.4),
        decoration: InputDecoration(
          hintText: 'Write anything about your day…',
          hintStyle: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, color: _kMuted),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _saveButton() {
    return GestureDetector(
      onTap: _canSave ? _save : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          gradient: _canSave
              ? LinearGradient(colors: [_kRed, _kRedDark])
              : null,
          color: _canSave ? null : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Center(
          child: Text(
            _canSave ? 'Save Entry' : 'Add $kMinGratitude to save ($_filled/$kMinGratitude)',
            style: AppFonts.spaceGrotesk.copyWith(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: _canSave ? Colors.white : _kMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _counterPill() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _kRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        '$_filled of $kMaxGratitude',
        style: AppFonts.spaceGrotesk.copyWith(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: _kRed,
        ),
      ),
    );
  }

  Widget _optionalTag() => Text(
        'optional',
        style: AppFonts.spaceGrotesk.copyWith(fontSize: 10.sp, color: _kMuted),
      );

  Widget _sectionTitle(String text, {Widget? trailing}) {
    return Row(
      children: [
        Text(
          text,
          style: AppFonts.spaceGrotesk.copyWith(
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
            color: _kText,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing,
      ],
    );
  }
}
