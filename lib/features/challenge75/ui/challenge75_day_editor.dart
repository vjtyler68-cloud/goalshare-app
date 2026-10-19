import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:spanx/core/const/app_fonts.dart';

import '../data/challenge75_models.dart';
import 'challenge75_theme.dart';

/// The interactive day log — the five 75-Challenge tasks as cards. Mutates the
/// passed [day] in place and reports changes via [onChanged] (debounced for
/// typing, immediate for taps) so the controller can persist. Used for both
/// today's dashboard and reviewing/editing any other day.
class Challenge75DayEditor extends StatefulWidget {
  final Challenge75Day day;
  final Challenge75Config config;
  final VoidCallback onChanged;
  final bool enabled;

  const Challenge75DayEditor({
    super.key,
    required this.day,
    required this.config,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<Challenge75DayEditor> createState() => _Challenge75DayEditorState();
}

class _Challenge75DayEditorState extends State<Challenge75DayEditor> {
  final _picker = ImagePicker();
  Timer? _debounce;
  // Only persist on dispose if the user actually changed something — otherwise
  // merely opening a past day to review it would save a blank entry and flag
  // the day as "edited".
  bool _dirty = false;

  late final TextEditingController _bookCtrl;
  late final TextEditingController _pagesCtrl;
  late final TextEditingController _dietNotesCtrl;
  final List<TextEditingController> _typeCtrls = [];
  final List<TextEditingController> _noteCtrls = [];

  Challenge75Day get day => widget.day;
  Challenge75Config get c => widget.config;
  Color get _accent => c.color;

  @override
  void initState() {
    super.initState();
    _bookCtrl = TextEditingController(text: day.bookTitle);
    _pagesCtrl =
        TextEditingController(text: day.pagesRead > 0 ? '${day.pagesRead}' : '');
    _dietNotesCtrl = TextEditingController(text: day.dietNotes);
    _ensureWorkoutSlots();
  }

  void _ensureWorkoutSlots() {
    // Make sure there are enough workout entries for the configured count.
    while (day.workouts.length < c.workoutsPerDay) {
      day.workouts.add(WorkoutEntry(minutes: c.workoutMinutes));
    }
    _typeCtrls.clear();
    _noteCtrls.clear();
    for (final w in day.workouts) {
      _typeCtrls.add(TextEditingController(text: w.type));
      _noteCtrls.add(TextEditingController(text: w.notes));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    // Flush any pending text edit so nothing is lost on navigation away — but
    // only if the user actually touched the day.
    if (_dirty) widget.onChanged();
    _bookCtrl.dispose();
    _pagesCtrl.dispose();
    _dietNotesCtrl.dispose();
    for (final ctrl in _typeCtrls) {
      ctrl.dispose();
    }
    for (final ctrl in _noteCtrls) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _changed({bool immediate = false}) {
    _dirty = true;
    setState(() {});
    _debounce?.cancel();
    if (immediate) {
      widget.onChanged();
    } else {
      _debounce = Timer(const Duration(milliseconds: 450), widget.onChanged);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutSlots = day.workouts.take(c.workoutsPerDay).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.enabled)
          Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: C75.field,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_clock_rounded, color: C75.muted, size: 18.r),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text("This day hasn't arrived yet.",
                      style: AppFonts.spaceGrotesk
                          .copyWith(color: C75.muted, fontSize: 12.5.sp)),
                ),
              ],
            ),
          ),
        // ── Workouts ──────────────────────────────────────────────────────────
        _taskCard(
          title: c.workoutsPerDay == 2 ? 'Workouts' : 'Workout',
          subtitle: '${c.workoutMinutes} min each'
              '${c.requireOneOutdoor ? ' · one outdoors' : ''}',
          done: day.workoutsDone(c),
          child: Column(
            children: [
              for (var i = 0; i < workoutSlots.length; i++) _workoutSlot(i),
            ],
          ),
        ),
        // ── Reading ───────────────────────────────────────────────────────────
        _taskCard(
          title: 'Reading',
          subtitle: '${c.readingPages} pages',
          done: day.readingDone(c),
          child: _readingBody(),
        ),
        // ── Water ─────────────────────────────────────────────────────────────
        _taskCard(
          title: 'Water',
          subtitle: WaterUnit.label(c.waterGoalMl, c.waterUnit),
          done: day.waterDone(c),
          child: _waterBody(),
        ),
        // ── Diet & alcohol ──────────────────────────────────────────────────────
        _taskCard(
          title: 'Diet & alcohol',
          subtitle: c.dietName.isEmpty ? null : c.dietName,
          done: c.dietRequired ? day.dietDone(c) : null,
          child: _dietBody(),
        ),
        // ── Progress picture ────────────────────────────────────────────────────
        _taskCard(
          title: 'Progress picture',
          subtitle: c.requireProgressPhoto ? 'Required' : 'Optional',
          done: c.requireProgressPhoto ? day.photoDone(c) : null,
          child: _photoBody(),
        ),
      ],
    );
  }

  // ── Workout slot ──────────────────────────────────────────────────────────────
  Widget _workoutSlot(int i) {
    final w = day.workouts[i];
    return Container(
      margin: EdgeInsets.only(top: i == 0 ? 0 : 10.h),
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: C75.field,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: widget.enabled
                    ? () {
                        w.done = !w.done;
                        _changed(immediate: true);
                      }
                    : null,
                child: Icon(
                  w.done
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  color: w.done ? C75.good : const Color(0xffC3C8D4),
                  size: 26.r,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  c.workoutsPerDay == 2 ? 'Workout ${i + 1}' : 'Done',
                  style: AppFonts.spaceGrotesk.copyWith(
                      color: C75.text,
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w800),
                ),
              ),
              _miniToggle('Indoor', !w.outdoor, () {
                w.outdoor = false;
                _changed(immediate: true);
              }),
              SizedBox(width: 6.w),
              _miniToggle('Outdoor', w.outdoor, () {
                w.outdoor = true;
                _changed(immediate: true);
              }),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _inlineField(
                  _typeCtrls[i],
                  hint: 'Type (Lift, Run…)',
                  onChanged: (v) {
                    w.type = v;
                    _changed();
                  },
                ),
              ),
              SizedBox(width: 8.w),
              _minutesStepper(w),
            ],
          ),
          SizedBox(height: 8.h),
          _inlineField(
            _noteCtrls[i],
            hint: 'Notes (optional)',
            onChanged: (v) {
              w.notes = v;
              _changed();
            },
          ),
        ],
      ),
    );
  }

  Widget _minutesStepper(WorkoutEntry w) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: C75.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepBtn(Icons.remove_rounded, () {
            w.minutes = (w.minutes - 5).clamp(0, 600);
            _changed(immediate: true);
          }),
          SizedBox(
            width: 44.w,
            child: Text('${w.minutes}m',
                textAlign: TextAlign.center,
                style: AppFonts.spaceGrotesk.copyWith(
                    color: C75.text,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800)),
          ),
          _stepBtn(Icons.add_rounded, () {
            w.minutes = (w.minutes + 5).clamp(0, 600);
            _changed(immediate: true);
          }),
        ],
      ),
    );
  }

  // ── Reading ─────────────────────────────────────────────────────────────────
  Widget _readingBody() {
    final pct = (day.pagesRead / c.readingPages).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inlineField(
          _bookCtrl,
          hint: 'Book title',
          onChanged: (v) {
            day.bookTitle = v;
            _changed();
          },
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Text('Pages read',
                style: AppFonts.spaceGrotesk
                    .copyWith(color: C75.muted, fontSize: 12.sp)),
            const Spacer(),
            SizedBox(
              width: 74.w,
              child: _inlineField(
                _pagesCtrl,
                hint: '0',
                keyboard: TextInputType.number,
                center: true,
                onChanged: (v) {
                  day.pagesRead = int.tryParse(v.trim()) ?? 0;
                  _changed();
                },
              ),
            ),
            SizedBox(width: 8.w),
            Text('/ ${c.readingPages}',
                style: AppFonts.spaceGrotesk.copyWith(
                    color: C75.text,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800)),
          ],
        ),
        SizedBox(height: 10.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(6.r),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7.h,
            backgroundColor: C75.field,
            valueColor: AlwaysStoppedAnimation(
                day.readingDone(c) ? C75.good : _accent),
          ),
        ),
      ],
    );
  }

  // ── Water ───────────────────────────────────────────────────────────────────
  Widget _waterBody() {
    final goal = c.waterGoalMl;
    final have = day.waterMl;
    final pct = (have / goal).clamp(0.0, 1.0);
    final remaining = (goal - have).clamp(0.0, goal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(WaterUnit.label(have, c.waterUnit),
                style: AppFonts.spaceGrotesk.copyWith(
                    color: day.waterDone(c) ? C75.good : _accent,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900)),
            SizedBox(width: 6.w),
            Text('of ${WaterUnit.label(goal, c.waterUnit)}',
                style: AppFonts.spaceGrotesk
                    .copyWith(color: C75.muted, fontSize: 12.sp)),
            const Spacer(),
            Text(
                remaining <= 0
                    ? 'Goal hit 🎉'
                    : '${WaterUnit.label(remaining, c.waterUnit)} to go',
                style: AppFonts.spaceGrotesk.copyWith(
                    color: remaining <= 0 ? C75.good : C75.muted,
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        SizedBox(height: 8.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(6.r),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 9.h,
            backgroundColor: C75.field,
            valueColor: AlwaysStoppedAnimation(
                day.waterDone(c) ? C75.good : _accent),
          ),
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            for (final q in WaterUnit.quickAdds(c.waterUnit)) ...[
              Expanded(
                child: GestureDetector(
                  onTap: widget.enabled
                      ? () {
                          day.waterMl =
                              (day.waterMl + q.ml).clamp(0.0, goal * 2);
                          _changed(immediate: true);
                        }
                      : null,
                  child: Container(
                    height: 38.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(q.label,
                        style: AppFonts.spaceGrotesk.copyWith(
                            color: _accent,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
            ],
            GestureDetector(
              onTap: widget.enabled
                  ? () {
                      day.waterMl = 0;
                      _changed(immediate: true);
                    }
                  : null,
              child: Container(
                height: 38.h,
                width: 38.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: C75.field,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.refresh_rounded, color: C75.muted, size: 18.r),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Diet ────────────────────────────────────────────────────────────────────
  Widget _dietBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dietCheck('Followed my diet', day.followedDiet, c.requireFollowedDiet,
            (v) {
          day.followedDiet = v;
          _changed(immediate: true);
        }),
        _dietCheck('No cheat meals', day.noCheatMeals, c.requireNoCheatMeals,
            (v) {
          day.noCheatMeals = v;
          _changed(immediate: true);
        }),
        _dietCheck('No alcohol', day.noAlcohol, c.requireNoAlcohol, (v) {
          day.noAlcohol = v;
          _changed(immediate: true);
        }),
        SizedBox(height: 8.h),
        _inlineField(
          _dietNotesCtrl,
          hint: 'Meal / diet notes (optional)',
          onChanged: (v) {
            day.dietNotes = v;
            _changed();
          },
        ),
      ],
    );
  }

  Widget _dietCheck(
      String label, bool value, bool required, ValueChanged<bool> onCh) {
    return GestureDetector(
      onTap: widget.enabled ? () => onCh(!value) : null,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 5.h),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_box_rounded : Icons.check_box_outline_blank,
              color: value ? C75.good : const Color(0xffC3C8D4),
              size: 24.r,
            ),
            SizedBox(width: 10.w),
            Text(label,
                style: AppFonts.spaceGrotesk.copyWith(
                    color: C75.text,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700)),
            if (required) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text('required',
                    style: AppFonts.spaceGrotesk.copyWith(
                        color: _accent,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Progress picture ──────────────────────────────────────────────────────────
  Widget _photoBody() {
    final path = day.photoPath;
    final hasPhoto = path != null && path.isNotEmpty && File(path).existsSync();
    return Row(
      children: [
        GestureDetector(
          onTap: hasPhoto ? () => _viewPhoto(path) : null,
          child: Container(
            width: 72.r,
            height: 72.r,
            decoration: BoxDecoration(
              color: C75.field,
              borderRadius: BorderRadius.circular(14.r),
              image: hasPhoto
                  ? DecorationImage(
                      image: FileImage(File(path)), fit: BoxFit.cover)
                  : null,
            ),
            child: hasPhoto
                ? null
                : Icon(Icons.add_a_photo_rounded,
                    color: C75.muted, size: 26.r),
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasPhoto ? 'Photo added for this day' : 'Add today\'s photo',
                style: AppFonts.spaceGrotesk.copyWith(
                    color: C75.text,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 6.h),
              GestureDetector(
                onTap: widget.enabled ? _photoSheet : null,
                child: Text(hasPhoto ? 'Retake / replace' : 'Take or upload',
                    style: AppFonts.spaceGrotesk.copyWith(
                        color: _accent,
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _photoSheet() {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(4.r)),
              ),
              SizedBox(height: 6.h),
              ListTile(
                leading: Icon(Icons.camera_alt_rounded, color: _accent),
                title: Text('Take a photo',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: C75.text)),
                onTap: () {
                  Get.back();
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library_rounded, color: _accent),
                title: Text('Choose from library',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: C75.text)),
                onTap: () {
                  Get.back();
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final img = await _picker.pickImage(
          source: source, imageQuality: 70, maxWidth: 1600);
      if (img == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory(p.join(dir.path, 'challenge75_photos'));
      if (!folder.existsSync()) folder.createSync(recursive: true);
      final dest = p.join(folder.path,
          'day_${day.day}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await File(img.path).copy(dest);
      day.photoPath = dest;
      _changed(immediate: true);
    } catch (_) {
      Get.snackbar('Photo', 'Could not add that photo — try again.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _viewPhoto(String path) {
    Get.dialog(
      GestureDetector(
        onTap: Get.back,
        child: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: InteractiveViewer(
            child: Image.file(File(path), fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(Icons.broken_image,
                    color: Colors.white38, size: 60.r)),
          ),
        ),
      ),
    );
  }

  // ── Shared building blocks ──────────────────────────────────────────────────
  Widget _taskCard({
    required String title,
    String? subtitle,
    required bool? done, // null = not a required task (no tick shown)
    required Widget child,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: C75.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: done == true ? C75.good.withValues(alpha: 0.5) : C75.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (done != null)
                Icon(
                  done ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: done ? C75.good : const Color(0xffC3C8D4),
                  size: 20.r,
                ),
              if (done != null) SizedBox(width: 8.w),
              Text(title,
                  style: AppFonts.spaceGrotesk.copyWith(
                      color: C75.text,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800)),
              if (subtitle != null) ...[
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(subtitle,
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.spaceGrotesk
                          .copyWith(color: C75.muted, fontSize: 11.sp)),
                ),
              ] else
                const Spacer(),
            ],
          ),
          SizedBox(height: 12.h),
          child,
        ],
      ),
    );
  }

  Widget _inlineField(
    TextEditingController ctrl, {
    required String hint,
    required ValueChanged<String> onChanged,
    TextInputType? keyboard,
    bool center = false,
  }) {
    return TextField(
      controller: ctrl,
      enabled: widget.enabled,
      keyboardType: keyboard,
      textAlign: center ? TextAlign.center : TextAlign.start,
      inputFormatters: keyboard == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      style: AppFonts.spaceGrotesk
          .copyWith(color: C75.text, fontSize: 13.sp, fontWeight: FontWeight.w600),
      onChanged: onChanged,
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle:
            AppFonts.spaceGrotesk.copyWith(color: C75.muted, fontSize: 12.sp),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: C75.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: _accent),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: const BorderSide(color: C75.line),
        ),
      ),
    );
  }

  Widget _miniToggle(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: widget.enabled ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: selected ? _accent : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: selected ? _accent : C75.line),
        ),
        child: Text(label,
            style: AppFonts.spaceGrotesk.copyWith(
                color: selected ? Colors.white : C75.muted,
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: widget.enabled ? onTap : null,
      child: Padding(
        padding: EdgeInsets.all(2.r),
        child: Icon(icon, color: C75.text, size: 18.r),
      ),
    );
  }
}
