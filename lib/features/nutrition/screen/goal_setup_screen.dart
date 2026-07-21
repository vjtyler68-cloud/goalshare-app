import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/features/nutrition/controller/nutrition_controller.dart';
import 'package:spanx/features/nutrition/data/nutrition_goal.dart';
import 'package:spanx/features/nutrition/widgets/nutrition_sheets.dart';
import 'package:spanx/core/const/app_colors.dart';

Color get _kRed => AppColors.primaryColor;
Color get _kRedDk => AppColors.primaryDarkColor;
const _kBg = Color(0xffF6F4F2);
const _kCard = Color(0xffFFFFFF);
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);
const _kGreen = Color(0xff22C55E);

/// Personalized goal setup — turns body stats + a target into a daily calorie
/// budget via Mifflin-St Jeor (pure arithmetic, no AI).
class GoalSetupScreen extends StatefulWidget {
  const GoalSetupScreen({super.key});

  @override
  State<GoalSetupScreen> createState() => _GoalSetupScreenState();
}

class _GoalSetupScreenState extends State<GoalSetupScreen> {
  final NutritionController c = NutritionController.to;

  final _currentC = TextEditingController();
  final _goalC = TextEditingController();
  final _ageC = TextEditingController();
  final _ftC = TextEditingController();
  final _inC = TextEditingController();
  final _proteinGoalC = TextEditingController();

  bool _male = true;
  double _activity = 1.375; // lightly active
  bool _byRate = true; // rate vs. target date
  double _rateMag = 1.0; // lbs/week magnitude
  DateTime? _targetDate;

  // NOT const: doubles lack primitive equality, so a const map with double
  // keys is a compile error ("The key '1.2' does not have a primitive
  // equality"). A static final runtime map behaves identically here.
  static final Map<double, String> _activities = {
    1.2: 'Sedentary',
    1.375: 'Light',
    1.55: 'Moderate',
    1.725: 'Very active',
    1.9: 'Athlete',
  };
  static const _rates = [0.5, 1.0, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    final g = c.goal.value;
    if (g != null) {
      if (g.currentWeightLbs != null) {
        _currentC.text = _num(g.currentWeightLbs!);
      }
      if (g.goalWeightLbs != null) _goalC.text = _num(g.goalWeightLbs!);
      if (g.ageYears != null) _ageC.text = g.ageYears.toString();
      if (g.sexMale != null) _male = g.sexMale!;
      if (g.activityLevel != null) _activity = g.activityLevel!;
      if (g.heightCm != null) {
        final totalIn = (g.heightCm! / 2.54).round();
        _ftC.text = (totalIn ~/ 12).toString();
        _inC.text = (totalIn % 12).toString();
      }
      if (g.targetWeeklyRateLbs != null && g.targetWeeklyRateLbs != 0) {
        _rateMag = g.targetWeeklyRateLbs!.abs().clamp(0.5, 2.0);
      }
      if (g.targetDate != null) {
        _byRate = false;
        _targetDate = g.targetDate;
      }
      if (g.proteinGoalGrams != null) {
        _proteinGoalC.text = g.proteinGoalGrams!.round().toString();
      }
    }
  }

  @override
  void dispose() {
    _currentC.dispose();
    _goalC.dispose();
    _ageC.dispose();
    _ftC.dispose();
    _inC.dispose();
    _proteinGoalC.dispose();
    super.dispose();
  }

  // ── computed preview ─────────────────────────────────────────────────────────
  double? get _currentLbs => double.tryParse(_currentC.text.trim());
  double? get _goalLbs => double.tryParse(_goalC.text.trim());
  int? get _age => int.tryParse(_ageC.text.trim());
  double? get _heightCm {
    final ft = int.tryParse(_ftC.text.trim());
    final inch = int.tryParse(_inC.text.trim()) ?? 0;
    if (ft == null) return null;
    return (ft * 12 + inch) * 2.54;
  }

  /// Signed weekly rate: negative = lose, positive = gain.
  double? get _weeklyRate {
    final cur = _currentLbs, gl = _goalLbs;
    if (cur == null || gl == null) return null;
    final losing = gl < cur;
    if (_byRate) {
      if ((gl - cur).abs() < 0.5) return 0; // already there
      return losing ? -_rateMag : _rateMag;
    }
    // by date
    if (_targetDate == null) return null;
    final days = _targetDate!.difference(DateTime.now()).inDays;
    if (days <= 0) return null;
    final weeks = days / 7.0;
    return (gl - cur) / weeks;
  }

  int? get _previewBudget {
    final cur = _currentLbs, age = _age, h = _heightCm, rate = _weeklyRate;
    if (cur == null || age == null || h == null || rate == null) return null;
    return NutritionGoal.computeBudget(
      currentLbs: cur,
      male: _male,
      age: age,
      heightCm: h,
      activity: _activity,
      weeklyRateLbs: rate,
    );
  }

  Future<void> _save() async {
    final cur = _currentLbs, gl = _goalLbs, age = _age, h = _heightCm;
    if (cur == null || cur < 50 || cur > 1000) {
      AppSnackBar.error('Enter a valid current weight.');
      return;
    }
    if (gl == null || gl < 50 || gl > 1000) {
      AppSnackBar.error('Enter a valid goal weight.');
      return;
    }
    if (age == null || age < 13 || age > 100) {
      AppSnackBar.error('Enter a valid age.');
      return;
    }
    if (h == null || h < 100 || h > 250) {
      AppSnackBar.error('Enter your height.');
      return;
    }
    final rate = _weeklyRate;
    if (rate == null) {
      AppSnackBar.error(_byRate
          ? 'Pick a weekly pace.'
          : 'Pick a target date in the future.');
      return;
    }
    // Only meaningful in protein mode; blank there means "use bodyweight × 0.8".
    // Blank and invalid are different: blank clears the override on purpose,
    // garbage input must NOT silently wipe it.
    final proteinRaw = _proteinGoalC.text.trim();
    final proteinGoal = proteinRaw.isEmpty ? null : double.tryParse(proteinRaw);
    if (c.isProteinMode &&
        proteinRaw.isNotEmpty &&
        (proteinGoal == null || proteinGoal <= 0 || proteinGoal > 500)) {
      AppSnackBar.error('Enter a protein goal between 1 and 500 g.');
      return;
    }
    final ok = await c.saveGoalSetup(
      currentLbs: cur,
      goalLbs: gl,
      male: _male,
      age: age,
      heightCm: h,
      activity: _activity,
      weeklyRateLbs: rate,
      targetDate: _byRate ? null : _targetDate,
    );
    // After saveGoalSetup, which preserves the tracking fields it doesn't own.
    if (ok && c.isProteinMode) await c.setProteinGoal(proteinGoal);
    if (ok) {
      Get.back();
      AppSnackBar.success('Goal set — daily budget updated');
    } else {
      AppSnackBar.error('Could not save your goal.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _header(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18.r, 18.r, 18.r, 40.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _card([
                    _label('Your weight'),
                    Row(
                      children: [
                        Expanded(child: _field(_currentC, 'Current (lbs)', number: true)),
                        SizedBox(width: 10.w),
                        Expanded(child: _field(_goalC, 'Goal (lbs)', number: true)),
                      ],
                    ),
                  ]),
                  SizedBox(height: 14.h),
                  _card([_trackingSection()]),
                  SizedBox(height: 14.h),
                  _card([
                    _label('About you'),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _field(_ageC, 'Age', number: true),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(child: _field(_ftC, 'ft', number: true)),
                        SizedBox(width: 8.w),
                        Expanded(child: _field(_inC, 'in', number: true)),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        _pill('Male', _male, () => setState(() => _male = true)),
                        SizedBox(width: 8.w),
                        _pill('Female', !_male, () => setState(() => _male = false)),
                      ],
                    ),
                  ]),
                  SizedBox(height: 14.h),
                  _card([
                    _label('Activity level'),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: _activities.entries
                          .map((e) => _pill(e.value, _activity == e.key,
                              () => setState(() => _activity = e.key)))
                          .toList(),
                    ),
                  ]),
                  SizedBox(height: 14.h),
                  _card([
                    _label('How fast?'),
                    Row(
                      children: [
                        _pill('By pace', _byRate,
                            () => setState(() => _byRate = true)),
                        SizedBox(width: 8.w),
                        _pill('By date', !_byRate,
                            () => setState(() => _byRate = false)),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    if (_byRate)
                      Wrap(
                        spacing: 8.w,
                        runSpacing: 8.h,
                        children: _rates
                            .map((r) => _pill('${_num(r)} lb/wk', _rateMag == r,
                                () => setState(() => _rateMag = r)))
                            .toList(),
                      )
                    else
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                              horizontal: 14.w, vertical: 14.h),
                          decoration: BoxDecoration(
                              color: _kBg,
                              borderRadius: BorderRadius.circular(12.r)),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  color: _kMuted, size: 18.r),
                              SizedBox(width: 10.w),
                              Text(
                                  _targetDate == null
                                      ? 'Pick a target date'
                                      : _pretty(_targetDate!),
                                  style: AppFonts.spaceGrotesk.copyWith(
                                      fontSize: 14.sp,
                                      color: _targetDate == null
                                          ? _kMuted
                                          : _kText)),
                            ],
                          ),
                        ),
                      ),
                  ]),
                  SizedBox(height: 18.h),
                  _preview(),
                  SizedBox(height: 18.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRed,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r)),
                      ),
                      child: Text('Save Goal',
                          style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Calories vs Protein ─────────────────────────────────────────────────────
  /// The selector persists on tap (see `NutritionSheets.trackingModeSelector`).
  /// The protein target below it only matters in protein mode, so it's revealed
  /// rather than always shown.
  Widget _trackingSection() {
    return Obx(() {
      final protein = c.isProteinMode;
      final auto = c.defaultProteinGoal;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NutritionSheets.trackingModeSelector(c),
          if (protein) ...[
            SizedBox(height: 16.h),
            // Prompt only when NO goal exists at all — a manual override set
            // elsewhere still deserves an editable field even without a
            // weigh-in (the dashboard renders that override happily).
            if (c.proteinGoal == null)
              // No weigh-in yet, so there's nothing to derive 0.8 g/lb from.
              // Hand the user straight to the existing Log Weight flow.
              _logWeightPrompt()
            else ...[
              _field(
                  _proteinGoalC,
                  auto == null
                      ? 'Protein goal (g)'
                      : 'Protein goal (g) — default $auto',
                  number: true),
              SizedBox(height: 8.h),
              Text(
                  auto == null
                      ? 'Set manually — log a weigh-in to get a suggested '
                          'goal (bodyweight × 0.8 g).'
                      : 'Suggested from your latest weigh-in (bodyweight × 0.8 g). '
                          'Leave blank to keep using it.',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 11.sp, color: _kMuted, height: 1.4)),
            ],
          ],
        ],
      );
    });
  }

  Widget _logWeightPrompt() {
    return GestureDetector(
      onTap: () => NutritionSheets.logWeight(c),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: _kRed.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: _kRed.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.monitor_weight_rounded, color: _kRed, size: 20.r),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Log a weigh-in first',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: _kText)),
                  SizedBox(height: 2.h),
                  Text('We set your protein goal at 0.8 g per lb of bodyweight.',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 11.sp, color: _kMuted, height: 1.35)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: _kRed, size: 22.r),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? now.add(const Duration(days: 90)),
      firstDate: now.add(const Duration(days: 7)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Widget _preview() {
    final budget = _previewBudget;
    final rate = _weeklyRate;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [_kRed.withOpacity(0.1), _kRed.withOpacity(0.03)]),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: _kRed.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text('Your daily calorie budget',
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 12.sp, color: _kMuted)),
          SizedBox(height: 6.h),
          Text(budget != null ? '$budget' : '—',
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 40.sp,
                  fontWeight: FontWeight.w800,
                  color: budget != null ? _kText : _kMuted)),
          Text('calories / day',
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 12.sp, color: _kMuted)),
          if (budget != null && rate != null && rate != 0) ...[
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                  color: _kGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20.r)),
              child: Text(
                  '${rate < 0 ? 'Losing' : 'Gaining'} ~${_num(rate.abs())} lb/week',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xff15803D))),
            ),
          ],
          SizedBox(height: 8.h),
          Text('Calculated from Mifflin-St Jeor — updates as you type.',
              textAlign: TextAlign.center,
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 10.sp, color: _kMuted)),
        ],
      ),
    );
  }

  // ── header + widgets ──────────────────────────────────────────────────────
  Widget _header() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kRed, _kRedDk],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
          child: Row(
            children: [
              GestureDetector(
                onTap: Get.back,
                child: Container(
                  width: 38.r,
                  height: 38.r,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2)),
                  child: Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 16.r),
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Personalize',
                      style: AppFonts.spaceGrotesk.copyWith(
                          color: Colors.white70, fontSize: 12.sp)),
                  Text('Goal Setup',
                      style: AppFonts.spaceGrotesk.copyWith(
                          color: Colors.white,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _label(String t) => Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: Text(t,
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 14.sp, fontWeight: FontWeight.w800, color: _kText)),
      );

  Widget _pill(String text, bool sel, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: sel ? _kRed : _kBg,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(text,
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: sel ? Colors.white : _kMuted)),
      ),
    );
  }

  Widget _field(TextEditingController controller, String hint,
      {bool number = false}) {
    return TextField(
      controller: controller,
      onChanged: (_) => setState(() {}), // live budget preview
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: number
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,
      style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, color: _kText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, color: _kMuted),
        filled: true,
        fillColor: _kBg,
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none),
      ),
    );
  }

  String _num(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
  String _pretty(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
