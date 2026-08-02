import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/features/home/data/quick_access_module.dart';

import '../controller/buddies_controller.dart';
import '../data/accountability_profile.dart';
import '../data/buddy_options.dart';

const _kBg = Color(0xffF6F4F2);
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// The one-time (editable) onboarding: 18 questions across 3 grouped screens,
/// progress dots, Back/Next/Submit. Writes an [AccountabilityProfile] on submit.
class BuddyQuestionnaireScreen extends StatefulWidget {
  const BuddyQuestionnaireScreen({super.key});

  @override
  State<BuddyQuestionnaireScreen> createState() =>
      _BuddyQuestionnaireScreenState();
}

class _BuddyQuestionnaireScreenState extends State<BuddyQuestionnaireScreen> {
  final _page = PageController();
  int _step = 0;
  static const _steps = 3;

  // ── Answers ────────────────────────────────────────────────────────────────
  // Goals & Focus
  String _focusArea = '';
  final _monthlyGoal = TextEditingController();
  final List<String> _topModules = [];
  int _consistency = 3;
  final _obstacle = TextEditingController();
  bool _singleGoalFocus = true;
  // Accountability Style
  String _checkInFrequency = 'Daily';
  String _checkInFormat = 'Text';
  String _motivationStyle = 'Encouragement';
  String _activeTimeOfDay = 'Morning';
  bool _doneBefore = false;
  String _missedPref = 'GentleNudge';
  // Logistics + Icebreaker
  String _gender = 'Unspecified';
  String _timezone = '';
  String _genderPreference = 'NoPreference';
  bool _openToOtherGoals = true;
  String _extendPreference = 'LetsSee';
  String _earlyBirdOrNightOwl = 'EarlyBird';
  final _funFact = TextEditingController();

  late final List<String> _timezones;

  @override
  void initState() {
    super.initState();
    _timezones = _buildTimezoneList();
    _timezone = _detectTimezone();
    _hydrateFromExisting();
  }

  /// Editing an existing profile pre-fills every answer.
  void _hydrateFromExisting() {
    final p = BuddiesController.to.profile.value;
    if (p == null) return;
    _focusArea = p.focusArea;
    _monthlyGoal.text = p.monthlyGoal;
    _topModules
      ..clear()
      ..addAll(p.topModules);
    _consistency = p.consistencyRating.clamp(1, 5);
    _obstacle.text = p.biggestObstacle;
    _singleGoalFocus = p.prefersSingleGoalFocus;
    _checkInFrequency = p.checkInFrequency;
    _checkInFormat = p.checkInFormat;
    _motivationStyle = p.motivationStyle;
    _activeTimeOfDay = p.activeTimeOfDay;
    _doneBefore = p.hasDoneAccountabilityBefore;
    _missedPref = p.missedCheckInPreference;
    _gender = p.gender;
    if (p.timezone.isNotEmpty) _timezone = p.timezone;
    _genderPreference = p.genderPreference;
    _openToOtherGoals = p.openToOtherGoalAreas;
    _extendPreference = p.extendPreference;
    _earlyBirdOrNightOwl = p.earlyBirdOrNightOwl;
    _funFact.text = p.funFact;
  }

  @override
  void dispose() {
    _page.dispose();
    _monthlyGoal.dispose();
    _obstacle.dispose();
    _funFact.dispose();
    super.dispose();
  }

  Color get _accent => AppColors.primaryColor;
  bool get _isEditing => BuddiesController.to.profile.value?.isComplete ?? false;

  void _next() {
    FocusScope.of(context).unfocus();
    if (_step == 0 && _focusArea.isEmpty) {
      AppSnackBar.error('Pick the area you\'re most focused on.');
      return;
    }
    if (_step < _steps - 1) {
      _page.nextPage(
          duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
    } else {
      _submit();
    }
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_step > 0) {
      _page.previousPage(
          duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
    } else {
      Get.back();
    }
  }

  Future<void> _submit() async {
    if (_focusArea.isEmpty) {
      AppSnackBar.error('Pick the area you\'re most focused on.');
      return;
    }
    if (_monthlyGoal.text.trim().isEmpty) {
      AppSnackBar.error('Add the goal you\'re working toward this month.');
      _page.animateToPage(0,
          duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
      return;
    }
    final answers = AccountabilityProfile(
      userId: '', // stamped by the controller
      gender: _gender,
      focusArea: _focusArea,
      monthlyGoal: _monthlyGoal.text.trim(),
      topModules: List<String>.from(_topModules),
      consistencyRating: _consistency,
      biggestObstacle: _obstacle.text.trim(),
      prefersSingleGoalFocus: _singleGoalFocus,
      checkInFrequency: _checkInFrequency,
      checkInFormat: _checkInFormat,
      motivationStyle: _motivationStyle,
      activeTimeOfDay: _activeTimeOfDay,
      hasDoneAccountabilityBefore: _doneBefore,
      missedCheckInPreference: _missedPref,
      timezone: _timezone,
      genderPreference: _genderPreference,
      openToOtherGoalAreas: _openToOtherGoals,
      extendPreference: _extendPreference,
      earlyBirdOrNightOwl: _earlyBirdOrNightOwl,
      funFact: _funFact.text.trim(),
    );
    await BuddiesController.to.saveProfile(answers);
    AppSnackBar.success(
        _isEditing ? 'Buddy profile updated!' : 'You\'re all set! 🤝');
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
            onPressed: _back,
            icon: const Icon(Icons.arrow_back, color: _kText)),
        title: Text(_isEditing ? 'Edit Buddy Profile' : 'Buddy Profile',
            style: AppFonts.spaceGrotesk
                .copyWith(color: _kText, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _progressDots(),
          Expanded(
            child: PageView(
              controller: _page,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _step = i),
              children: [
                _screen1(),
                _screen2(),
                _screen3(),
              ],
            ),
          ),
          _navBar(),
        ],
      ),
    );
  }

  // ── Progress ────────────────────────────────────────────────────────────────
  Widget _progressDots() {
    const titles = ['Goals & Focus', 'Your Style', 'Logistics'];
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 12.h),
      child: Column(
        children: [
          Row(
            children: List.generate(_steps, (i) {
              final active = i <= _step;
              return Expanded(
                child: Container(
                  height: 5.h,
                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                  decoration: BoxDecoration(
                    color: active ? _accent : _accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 8.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('${_step + 1} / $_steps  ·  ${titles[_step]}',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: _kMuted)),
          ),
        ],
      ),
    );
  }

  // ── Screen 1 — Goals & Focus ────────────────────────────────────────────────
  Widget _screen1() {
    final modules = QuickAccessRegistry.modules.map((m) => m.title).toList();
    return _pageBody([
      _q('Which area are you most focused on right now?'),
      _singleChips(BuddyOptions.focusAreas, _focusArea,
          (v) => setState(() => _focusArea = v)),
      _q('What\'s one specific goal you\'re working toward this month?'),
      _textField(_monthlyGoal, 'e.g. Hit the gym 4× a week'),
      _q('Which GoalShare modules do you use most?'),
      _multiChips(modules, _topModules),
      _q('How consistent have you been lately?'),
      _rating1to5(_consistency, (v) => setState(() => _consistency = v)),
      _q('What\'s your biggest obstacle right now?'),
      _textField(_obstacle, 'e.g. Staying consistent on weekends'),
      _q('Do you prefer one goal at a time, or juggling multiple?'),
      _toggle('One at a time', 'Juggle multiple', _singleGoalFocus,
          (v) => setState(() => _singleGoalFocus = v)),
    ]);
  }

  // ── Screen 2 — Accountability Style ─────────────────────────────────────────
  Widget _screen2() {
    return _pageBody([
      _q('How often do you want to check in?'),
      _singleChoice(BuddyOptions.checkInFrequency, _checkInFrequency,
          (v) => setState(() => _checkInFrequency = v)),
      _q('Preferred check-in format?'),
      _singleChoice(BuddyOptions.checkInFormat, _checkInFormat,
          (v) => setState(() => _checkInFormat = v)),
      _q('What motivates you more?'),
      _singleChoice(BuddyOptions.motivationStyle, _motivationStyle,
          (v) => setState(() => _motivationStyle = v)),
      _q('What time of day are you most active?'),
      _singleChoice(BuddyOptions.activeTimeOfDay, _activeTimeOfDay,
          (v) => setState(() => _activeTimeOfDay = v)),
      _q('Have you done an accountability partnership before?'),
      _toggle('Yes', 'No', _doneBefore,
          (v) => setState(() => _doneBefore = v)),
      _q('If your buddy misses a check-in, how should they handle yours?'),
      _singleChoice(BuddyOptions.missedCheckInPreference, _missedPref,
          (v) => setState(() => _missedPref = v)),
    ]);
  }

  // ── Screen 3 — Logistics + Icebreaker ───────────────────────────────────────
  Widget _screen3() {
    return _pageBody([
      _q('Your timezone'),
      _timezoneDropdown(),
      _q('You are'),
      _singleChoice(BuddyOptions.genders, _gender,
          (v) => setState(() => _gender = v)),
      _q('Preferred buddy gender?'),
      _singleChoice(BuddyOptions.genderPreference, _genderPreference,
          (v) => setState(() => _genderPreference = v)),
      _q('Open to being paired outside your main goal area?'),
      _toggle('Yes', 'No', _openToOtherGoals,
          (v) => setState(() => _openToOtherGoals = v)),
      _q('Want to stay paired beyond the week if it\'s a good match?'),
      _singleChoice(BuddyOptions.extendPreference, _extendPreference,
          (v) => setState(() => _extendPreference = v)),
      _q('Early bird or night owl?'),
      _singleChoice(BuddyOptions.earlyBirdOrNightOwl, _earlyBirdOrNightOwl,
          (v) => setState(() => _earlyBirdOrNightOwl = v)),
      _q('One fun fact or hobby'),
      _textField(_funFact, 'e.g. I make a mean sourdough 🍞'),
    ]);
  }

  // ── Building blocks ─────────────────────────────────────────────────────────
  Widget _pageBody(List<Widget> children) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _q(String text) => Padding(
        padding: EdgeInsets.only(top: 20.h, bottom: 10.h),
        child: Text(text,
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 15.sp, fontWeight: FontWeight.w800, color: _kText)),
      );

  Widget _pill(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: selected ? _accent : Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
              color: selected ? _accent : const Color(0xffE6E0DE), width: 1.5),
        ),
        child: Text(label,
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : _kText)),
      ),
    );
  }

  Widget _singleChips(
      List<String> values, String selected, ValueChanged<String> onPick) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        for (final v in values) _pill(v, v == selected, () => onPick(v)),
      ],
    );
  }

  Widget _singleChoice(List<BuddyChoice> choices, String selected,
      ValueChanged<String> onPick) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        for (final c in choices)
          _pill(c.label, c.value == selected, () => onPick(c.value)),
      ],
    );
  }

  Widget _multiChips(List<String> values, List<String> selected) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        for (final v in values)
          _pill(v, selected.contains(v), () {
            setState(() {
              if (selected.contains(v)) {
                selected.remove(v);
              } else {
                selected.add(v);
              }
            });
          }),
      ],
    );
  }

  Widget _textField(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      style: AppFonts.spaceGrotesk
          .copyWith(fontSize: 14.sp, color: _kText, fontWeight: FontWeight.w600),
      maxLines: null,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppFonts.spaceGrotesk
            .copyWith(fontSize: 13.sp, color: _kMuted),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Color(0xffE6E0DE), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: _accent, width: 1.5),
        ),
      ),
    );
  }

  Widget _rating1to5(int value, ValueChanged<int> onPick) {
    return Row(
      children: [
        for (var i = 1; i <= 5; i++) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onPick(i),
              child: Container(
                height: 44.h,
                margin: EdgeInsets.only(right: i == 5 ? 0 : 8.w),
                decoration: BoxDecoration(
                  color: i <= value ? _accent : Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                      color: i <= value ? _accent : const Color(0xffE6E0DE),
                      width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text('$i',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: i <= value ? Colors.white : _kMuted)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _toggle(String onLabel, String offLabel, bool value,
      ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
            child: _segment(onLabel, value, () => onChanged(true))),
        SizedBox(width: 8.w),
        Expanded(
            child: _segment(offLabel, !value, () => onChanged(false))),
      ],
    );
  }

  Widget _segment(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44.h,
        decoration: BoxDecoration(
          color: selected ? _accent : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
              color: selected ? _accent : const Color(0xffE6E0DE), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : _kText)),
      ),
    );
  }

  Widget _timezoneDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: const Border.fromBorderSide(
            BorderSide(color: Color(0xffE6E0DE), width: 1.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _timezones.contains(_timezone) ? _timezone : _timezones.first,
          isExpanded: true,
          icon: Icon(Icons.expand_more, color: _kMuted),
          style: AppFonts.spaceGrotesk.copyWith(
              fontSize: 14.sp, color: _kText, fontWeight: FontWeight.w600),
          items: [
            for (final tz in _timezones)
              DropdownMenuItem(value: tz, child: Text(tz)),
          ],
          onChanged: (v) => setState(() => _timezone = v ?? _timezone),
        ),
      ),
    );
  }

  // ── Nav bar ─────────────────────────────────────────────────────────────────
  Widget _navBar() {
    final last = _step == _steps - 1;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 10.h),
        child: Row(
          children: [
            if (_step > 0)
              Expanded(
                child: GestureDetector(
                  onTap: _back,
                  child: Container(
                    height: 52.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: const Color(0xffE6E0DE)),
                    ),
                    alignment: Alignment.center,
                    child: Text('Back',
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            color: _kText)),
                  ),
                ),
              ),
            if (_step > 0) SizedBox(width: 12.w),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: _next,
                child: Container(
                  height: 52.h,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  alignment: Alignment.center,
                  child: Text(last ? 'Submit' : 'Next',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Timezone helpers ────────────────────────────────────────────────────────
  /// The device's current UTC offset as a stable label the matcher can bucket on
  /// (e.g. "UTC-05:00"). Dependency-free — no timezone package needed.
  String _detectTimezone() {
    final off = DateTime.now().timeZoneOffset;
    final sign = off.isNegative ? '-' : '+';
    final h = off.inHours.abs().toString().padLeft(2, '0');
    final m = (off.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final label = 'UTC$sign$h:$m';
    return _buildTimezoneList().contains(label) ? label : label;
  }

  List<String> _buildTimezoneList() {
    const offsets = [
      'UTC-11:00',
      'UTC-10:00',
      'UTC-09:00',
      'UTC-08:00',
      'UTC-07:00',
      'UTC-06:00',
      'UTC-05:00',
      'UTC-04:00',
      'UTC-03:00',
      'UTC+00:00',
      'UTC+01:00',
      'UTC+02:00',
      'UTC+03:00',
      'UTC+05:30',
      'UTC+08:00',
      'UTC+09:00',
      'UTC+10:00',
    ];
    final off = DateTime.now().timeZoneOffset;
    final sign = off.isNegative ? '-' : '+';
    final h = off.inHours.abs().toString().padLeft(2, '0');
    final m = (off.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final detected = 'UTC$sign$h:$m';
    final list = List<String>.from(offsets);
    if (!list.contains(detected)) {
      list.add(detected);
      list.sort();
    }
    return list;
  }
}
