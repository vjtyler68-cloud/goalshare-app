import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:spanx/core/const/app_fonts.dart';

import '../controller/challenge75_controller.dart';
import '../data/challenge75_models.dart';
import 'challenge75_theme.dart';

/// Pick a variant, then fine-tune every rule, then start. Doubles as the
/// "Edit goals" screen ([editing] true) — in that mode it does not wipe
/// logged progress.
class Challenge75SetupScreen extends StatefulWidget {
  final bool editing;
  const Challenge75SetupScreen({super.key, this.editing = false});

  @override
  State<Challenge75SetupScreen> createState() => _Challenge75SetupScreenState();
}

class _Challenge75SetupScreenState extends State<Challenge75SetupScreen> {
  late String _variantId;
  late DateTime _startDate;
  late int _workoutsPerDay;
  late int _workoutMinutes;
  late bool _requireOneOutdoor;
  late int _readingPages;
  late double _waterGoalMl;
  late String _waterUnit;
  late bool _requireFollowedDiet;
  late bool _requireNoCheatMeals;
  late bool _requireNoAlcohol;
  late bool _requireProgressPhoto;
  late bool _restartOnMiss;
  final _dietCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final existing =
        widget.editing ? Challenge75Controller.to.config.value : null;
    if (existing != null) {
      _variantId = existing.variantId;
      _startDate = existing.startDate;
      _workoutsPerDay = existing.workoutsPerDay;
      _workoutMinutes = existing.workoutMinutes;
      _requireOneOutdoor = existing.requireOneOutdoor;
      _readingPages = existing.readingPages;
      _waterGoalMl = existing.waterGoalMl;
      _waterUnit = existing.waterUnit;
      _requireFollowedDiet = existing.requireFollowedDiet;
      _requireNoCheatMeals = existing.requireNoCheatMeals;
      _requireNoAlcohol = existing.requireNoAlcohol;
      _requireProgressPhoto = existing.requireProgressPhoto;
      _restartOnMiss = existing.restartOnMiss;
      _dietCtrl.text = existing.dietName;
    } else {
      _applyVariant(Challenge75Variant.all.first, keepDate: false);
    }
  }

  @override
  void dispose() {
    _dietCtrl.dispose();
    super.dispose();
  }

  void _applyVariant(Challenge75Variant v, {bool keepDate = true}) {
    setState(() {
      _variantId = v.id;
      if (!keepDate) _startDate = _todayDate();
      _workoutsPerDay = v.workoutsPerDay;
      _workoutMinutes = 45;
      _requireOneOutdoor = v.requireOneOutdoor;
      _readingPages = v.readingPages;
      _waterGoalMl = v.waterGoalMl;
      _waterUnit = v.waterUnit;
      _requireFollowedDiet = v.requireFollowedDiet;
      _requireNoCheatMeals = v.requireNoCheatMeals;
      _requireNoAlcohol = v.requireNoAlcohol;
      _requireProgressPhoto = v.requireProgressPhoto;
      _restartOnMiss = v.restartOnMiss;
      _dietCtrl.text = v.dietName;
    });
  }

  DateTime _todayDate() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  Color get _accent => Challenge75Variant.byId(_variantId).color;

  /// A tasteful two-stop gradient from the accent to a darker shade of it.
  LinearGradient _grad(Color c) {
    final hsl = HSLColor.fromColor(c);
    final darker =
        hsl.withLightness((hsl.lightness * 0.78).clamp(0.0, 1.0)).toColor();
    return LinearGradient(
      colors: [c, darker],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Challenge75Config _buildConfig() => Challenge75Config(
        variantId: _variantId,
        startDate: _startDate,
        workoutsPerDay: _workoutsPerDay,
        workoutMinutes: _workoutMinutes,
        requireOneOutdoor: _requireOneOutdoor,
        readingPages: _readingPages,
        waterGoalMl: _waterGoalMl,
        waterUnit: _waterUnit,
        dietName: _dietCtrl.text.trim(),
        requireFollowedDiet: _requireFollowedDiet,
        requireNoCheatMeals: _requireNoCheatMeals,
        requireNoAlcohol: _requireNoAlcohol,
        requireProgressPhoto: _requireProgressPhoto,
        restartOnMiss: _restartOnMiss,
      );

  Future<void> _submit() async {
    final c = Challenge75Controller.to;
    if (widget.editing) {
      await c.updateConfig(_buildConfig());
      Get.back();
    } else {
      await c.start(_buildConfig());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C75.bg,
      appBar: AppBar(
        backgroundColor: C75.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: C75.text),
          onPressed: Get.back,
        ),
        title: Text(
          widget.editing ? 'Edit goals' : '75 Challenge',
          style: AppFonts.spaceGrotesk.copyWith(
            color: C75.text,
            fontWeight: FontWeight.w800,
            fontSize: 17.sp,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 120.h),
        children: [
          if (!widget.editing) ...[
            Text(
              'Pick your challenge',
              style: AppFonts.spaceGrotesk.copyWith(
                  color: C75.text, fontSize: 20.sp, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 4.h),
            Text(
              'Choose a preset to start — you can fine-tune every rule below.',
              style: AppFonts.spaceGrotesk
                  .copyWith(color: C75.muted, fontSize: 12.5.sp, height: 1.35),
            ),
            SizedBox(height: 14.h),
            ...Challenge75Variant.all.map(_variantCard),
            SizedBox(height: 20.h),
          ],
          _sectionLabel('YOUR DAILY RULES'),
          SizedBox(height: 10.h),
          _startDateCard(),
          SizedBox(height: 12.h),
          _workoutsCard(),
          SizedBox(height: 12.h),
          _readingCard(),
          SizedBox(height: 12.h),
          _waterCard(),
          SizedBox(height: 12.h),
          _dietCard(),
          SizedBox(height: 12.h),
          _photoCard(),
          SizedBox(height: 12.h),
          _missCard(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
        child: GestureDetector(
          onTap: _submit,
          child: Container(
            height: 54.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: _grad(_accent),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                    color: _accent.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6)),
              ],
            ),
            child: Text(
              widget.editing ? 'Save goals' : 'Start my 75',
              style: AppFonts.spaceGrotesk.copyWith(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }

  // ── Variant cards ───────────────────────────────────────────────────────────
  Widget _variantCard(Challenge75Variant v) {
    final selected = v.id == _variantId;
    return GestureDetector(
      onTap: () => _applyVariant(v),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: selected ? null : C75.card,
          gradient: selected
              ? LinearGradient(
                  colors: [
                    v.color.withValues(alpha: 0.16),
                    v.color.withValues(alpha: 0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: selected ? v.color : const Color(0xffE6E8EF),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44.r,
              height: 44.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: v.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                v.id == Challenge75VariantId.custom
                    ? Icons.tune_rounded
                    : Icons.local_fire_department_rounded,
                color: v.color,
                size: 24.r,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.name,
                      style: AppFonts.spaceGrotesk.copyWith(
                          color: C75.text,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: 2.h),
                  Text(v.tagline,
                      style: AppFonts.spaceGrotesk.copyWith(
                          color: C75.muted, fontSize: 11.5.sp, height: 1.3)),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? v.color : const Color(0xffC3C8D4),
              size: 22.r,
            ),
          ],
        ),
      ),
    );
  }

  // ── Rule cards ────────────────────────────────────────────────────────────────
  Widget _startDateCard() {
    return _card(
      icon: Icons.event_rounded,
      title: 'Start date',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(DateFormat('EEE, MMM d, y').format(_startDate),
              style: AppFonts.spaceGrotesk.copyWith(
                  color: C75.text, fontSize: 14.sp, fontWeight: FontWeight.w700)),
          TextButton(
            onPressed: _pickStartDate,
            child: Text('Change',
                style: AppFonts.spaceGrotesk.copyWith(
                    color: _accent,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final now = _todayDate();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: now.subtract(const Duration(days: 60)),
      lastDate: now.add(const Duration(days: 60)),
      helpText: 'When does your 75 begin?',
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: _accent,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: C75.text,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() =>
          _startDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Widget _workoutsCard() {
    return _card(
      icon: Icons.fitness_center_rounded,
      title: 'Workouts',
      subtitle: '$_workoutsPerDay × $_workoutMinutes min a day',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _choice('1 a day', _workoutsPerDay == 1,
                  () => setState(() => _workoutsPerDay = 1)),
              SizedBox(width: 10.w),
              _choice('2 a day', _workoutsPerDay == 2,
                  () => setState(() => _workoutsPerDay = 2)),
            ],
          ),
          SizedBox(height: 12.h),
          _stepperRow(
            'Minutes per workout',
            '$_workoutMinutes min',
            onMinus: () => setState(
                () => _workoutMinutes = (_workoutMinutes - 5).clamp(10, 180)),
            onPlus: () => setState(
                () => _workoutMinutes = (_workoutMinutes + 5).clamp(10, 180)),
          ),
          SizedBox(height: 4.h),
          _switchRow(
            'Require one workout outdoors',
            _requireOneOutdoor,
            (v) => setState(() => _requireOneOutdoor = v),
          ),
        ],
      ),
    );
  }

  Widget _readingCard() {
    return _card(
      icon: Icons.menu_book_rounded,
      title: 'Reading',
      subtitle: '$_readingPages pages a day',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bigValue('$_readingPages', 'pages / day'),
          _accentSlider(
            value: _readingPages.toDouble().clamp(1, 50),
            min: 1,
            max: 50,
            divisions: 49,
            label: '$_readingPages',
            onChanged: (v) => setState(() => _readingPages = v.round()),
          ),
          SizedBox(height: 4.h),
          Wrap(
            spacing: 8.w,
            children: [
              for (final p in const [5, 10, 20, 30])
                _presetChip('$p', _readingPages == p,
                    () => setState(() => _readingPages = p)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _waterCard() {
    final spec = WaterUnit.sliderSpec(_waterUnit);
    final cur =
        WaterUnit.fromMl(_waterGoalMl, _waterUnit).clamp(spec.min, spec.max);
    return _card(
      icon: Icons.local_drink_rounded,
      title: 'Water',
      subtitle: '${WaterUnit.label(_waterGoalMl, _waterUnit)} a day',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _unitChip('L', WaterUnit.litre),
              SizedBox(width: 8.w),
              _unitChip('oz', WaterUnit.ounce),
              SizedBox(width: 8.w),
              _unitChip('gal', WaterUnit.gallon),
            ],
          ),
          SizedBox(height: 8.h),
          _bigValue(WaterUnit.label(_waterGoalMl, _waterUnit), 'per day'),
          _accentSlider(
            value: cur,
            min: spec.min,
            max: spec.max,
            divisions: ((spec.max - spec.min) / spec.step).round(),
            label: WaterUnit.label(_waterGoalMl, _waterUnit),
            onChanged: (v) =>
                setState(() => _waterGoalMl = WaterUnit.toMl(v, _waterUnit)),
          ),
          Text('Drag to set any amount — a glass up to 8 litres',
              style: AppFonts.spaceGrotesk
                  .copyWith(color: C75.muted, fontSize: 10.5.sp)),
        ],
      ),
    );
  }

  Widget _dietCard() {
    return _card(
      icon: Icons.restaurant_rounded,
      title: 'Diet',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _dietCtrl,
            style: AppFonts.spaceGrotesk
                .copyWith(color: C75.text, fontSize: 13.5.sp),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Name your diet (e.g. no sugar, high protein)',
              hintStyle: AppFonts.spaceGrotesk
                  .copyWith(color: C75.muted, fontSize: 12.5.sp),
              filled: true,
              fillColor: const Color(0xffF2F3F8),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          _switchRow('Require "Followed my diet"', _requireFollowedDiet,
              (v) => setState(() => _requireFollowedDiet = v)),
          _switchRow('Require "No cheat meals"', _requireNoCheatMeals,
              (v) => setState(() => _requireNoCheatMeals = v)),
          _switchRow('Require "No alcohol"', _requireNoAlcohol,
              (v) => setState(() => _requireNoAlcohol = v)),
        ],
      ),
    );
  }

  Widget _photoCard() {
    return _card(
      icon: Icons.photo_camera_rounded,
      title: 'Progress picture',
      child: _switchRow('Require a daily progress photo', _requireProgressPhoto,
          (v) => setState(() => _requireProgressPhoto = v)),
    );
  }

  Widget _missCard() {
    return _card(
      icon: Icons.flag_rounded,
      title: 'If I miss a required task',
      child: Column(
        children: [
          _radioRow('Restart the whole challenge from Day 1', _restartOnMiss,
              () => setState(() => _restartOnMiss = true)),
          _radioRow('Just mark that day incomplete', !_restartOnMiss,
              () => setState(() => _restartOnMiss = false)),
        ],
      ),
    );
  }

  // ── Small building blocks ───────────────────────────────────────────────────
  Widget _card({
    required IconData icon,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: C75.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xffEDEFF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _accent, size: 18.r),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppFonts.spaceGrotesk.copyWith(
                            color: C75.text,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800)),
                    if (subtitle != null)
                      Text(subtitle,
                          style: AppFonts.spaceGrotesk.copyWith(
                              color: C75.muted, fontSize: 11.sp)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          child,
        ],
      ),
    );
  }

  Widget _sectionLabel(String s) => Text(
        s,
        style: AppFonts.spaceGrotesk.copyWith(
            color: C75.muted,
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 1),
      );

  Widget _choice(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _accent : const Color(0xffF2F3F8),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text(label,
              style: AppFonts.spaceGrotesk.copyWith(
                  color: selected ? Colors.white : C75.text,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  Widget _unitChip(String label, String unit) {
    final selected = _waterUnit == unit;
    return GestureDetector(
      onTap: () => setState(() {
        _waterUnit = unit;
        // Keep the same amount, re-expressed in the new unit's range.
        final s = WaterUnit.sliderSpec(unit);
        final v = WaterUnit.fromMl(_waterGoalMl, unit).clamp(s.min, s.max);
        _waterGoalMl = WaterUnit.toMl(v, unit);
      }),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: selected ? _accent : const Color(0xffF2F3F8),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(label,
            style: AppFonts.spaceGrotesk.copyWith(
                color: selected ? Colors.white : C75.text,
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w800)),
      ),
    );
  }

  // Big numeric readout above a slider (e.g. "2.5 L" · "per day").
  Widget _bigValue(String value, String caption) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value,
            style: AppFonts.spaceGrotesk.copyWith(
                color: _accent, fontSize: 26.sp, fontWeight: FontWeight.w900)),
        SizedBox(width: 7.w),
        Padding(
          padding: EdgeInsets.only(bottom: 4.h),
          child: Text(caption,
              style: AppFonts.spaceGrotesk
                  .copyWith(color: C75.muted, fontSize: 12.sp)),
        ),
      ],
    );
  }

  Widget _accentSlider({
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: _accent,
        thumbColor: _accent,
        overlayColor: _accent.withValues(alpha: 0.15),
        inactiveTrackColor: const Color(0xffE6E8EF),
        trackHeight: 5.h,
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions < 1 ? 1 : divisions,
        label: label,
        onChanged: onChanged,
      ),
    );
  }

  Widget _presetChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: selected ? _accent.withValues(alpha: 0.14) : C75.field,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
              color: selected ? _accent : Colors.transparent, width: 1.5),
        ),
        child: Text(label,
            style: AppFonts.spaceGrotesk.copyWith(
                color: selected ? _accent : C75.muted,
                fontSize: 12.sp,
                fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _stepperRow(
    String label,
    String value, {
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: AppFonts.spaceGrotesk
                  .copyWith(color: C75.text, fontSize: 12.5.sp)),
        ),
        _roundStep(Icons.remove_rounded, onMinus),
        SizedBox(
          width: 58.w,
          child: Text(value,
              textAlign: TextAlign.center,
              style: AppFonts.spaceGrotesk.copyWith(
                  color: C75.text,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800)),
        ),
        _roundStep(Icons.add_rounded, onPlus),
      ],
    );
  }

  Widget _roundStep(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34.r,
        height: 34.r,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _accent, size: 18.r),
      ),
    );
  }

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: AppFonts.spaceGrotesk
                    .copyWith(color: C75.text, fontSize: 12.5.sp)),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _accent,
          ),
        ],
      ),
    );
  }

  Widget _radioRow(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? _accent : const Color(0xffC3C8D4),
              size: 20.r,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(label,
                  style: AppFonts.spaceGrotesk
                      .copyWith(color: C75.text, fontSize: 12.5.sp)),
            ),
          ],
        ),
      ),
    );
  }
}
