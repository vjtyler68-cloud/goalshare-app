import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/features/nutrition/controller/nutrition_controller.dart';
import 'package:spanx/features/nutrition/data/logged_entry.dart';
import 'package:spanx/features/nutrition/data/nutrition_goal.dart';
import 'package:spanx/features/nutrition/screen/food_entry_screen.dart';
import 'package:spanx/features/nutrition/widgets/nutrition_sheets.dart';

const _kRed = Color(0xffE84040);
const _kRedDk = Color(0xff9B1414);
const _kBg = Color(0xffF6F4F2);
const _kCard = Color(0xffFFFFFF);
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);
const _kGreen = Color(0xff22C55E);

const _kProtein = Color(0xff6366F1);
const _kCarbs = Color(0xffF59E0B);
const _kFat = Color(0xffEC4899);

class NutritionDashboardScreen extends StatelessWidget {
  NutritionDashboardScreen({super.key});

  final NutritionController c = NutritionController.to;

  static const _mealMeta = {
    'breakfast': (Icons.wb_twilight_rounded, Color(0xffF59E0B)),
    'lunch': (Icons.lunch_dining_rounded, Color(0xff10B981)),
    'dinner': (Icons.dinner_dining_rounded, Color(0xff6366F1)),
    'snacks': (Icons.cookie_rounded, Color(0xffEC4899)),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _header(),
          Expanded(
            child: Obx(() {
              if (!c.isReady.value) {
                return const Center(
                    child: CircularProgressIndicator(color: _kRed));
              }
              // Touch reactive fields so Obx tracks date + entries + goal.
              c.selectedDate.value;
              c.allEntries.length;
              c.goal.value;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(18.r, 18.r, 18.r, 40.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _calorieCard(),
                    SizedBox(height: 16.h),
                    _macroCard(),
                    SizedBox(height: 20.h),
                    ...kMeals.map(_mealSection),
                    _exerciseSection(),
                    SizedBox(height: 20.h),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── HEADER + DATE NAV ────────────────────────────────────────────────────────
  Widget _header() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kRed, _kRedDk],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
          child: Column(
            children: [
              Row(
                children: [
                  _circleBtn(Icons.arrow_back_ios_new, Get.back),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fuel Your Day',
                            style: AppFonts.spaceGrotesk.copyWith(
                                color: Colors.white70, fontSize: 12.sp)),
                        Text('My Nutrition',
                            style: AppFonts.spaceGrotesk.copyWith(
                                color: Colors.white,
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  _circleBtn(Icons.tune_rounded,
                      () => NutritionSheets.editGoal(c)),
                ],
              ),
              SizedBox(height: 14.h),
              _dateNav(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateNav() {
    return Obx(() {
      final d = c.selectedDate.value;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          children: [
            _circleBtn(Icons.chevron_left_rounded, c.goToPreviousDay, small: true),
            Expanded(
              child: Center(
                child: Text(
                  c.isViewingToday ? 'Today · ${_pretty(d)}' : _pretty(d),
                  style: AppFonts.spaceGrotesk.copyWith(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
            Opacity(
              opacity: c.isViewingToday ? 0.35 : 1,
              child: _circleBtn(
                  Icons.chevron_right_rounded, c.goToNextDay, small: true),
            ),
          ],
        ),
      );
    });
  }

  // ── CALORIE BUDGET CARD ──────────────────────────────────────────────────────
  Widget _calorieCard() {
    final budget = c.budget;
    final food = c.foodCalories;
    final exercise = c.exerciseCalories;
    final remaining = c.remaining;
    final pct = budget <= 0 ? 0.0 : (food / budget).clamp(0.0, 1.0);
    final over = remaining < 0;

    return Container(
      width: double.infinity,
      decoration: _cardDecor(),
      padding: EdgeInsets.all(18.r),
      child: Column(
        children: [
          SizedBox(
            height: 150.r,
            width: 150.r,
            child: CustomPaint(
              painter: _CalorieRingPainter(
                  progress: pct, color: over ? _kRed : _kGreen),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      remaining.abs().round().toString(),
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 30.sp,
                          fontWeight: FontWeight.w800,
                          color: over ? _kRed : _kText),
                    ),
                    Text(over ? 'over budget' : 'remaining',
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 11.sp, color: _kMuted)),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              _calStat('Budget', budget.toDouble(), Icons.flag_rounded, _kMuted),
              _divider(),
              _calStat('Food', food, Icons.restaurant_rounded, _kRed),
              _divider(),
              _calStat('Exercise', exercise, Icons.local_fire_department_rounded,
                  const Color(0xffFF6B35)),
            ],
          ),
          SizedBox(height: 10.h),
          Text('Budget − Food + Exercise = Remaining',
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 10.sp, color: _kMuted)),
        ],
      ),
    );
  }

  Widget _calStat(String label, double value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18.r),
          SizedBox(height: 4.h),
          Text(value.round().toString(),
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 15.sp, fontWeight: FontWeight.w800, color: _kText)),
          Text(label,
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 10.sp, color: _kMuted)),
        ],
      ),
    );
  }

  // ── MACRO CARD ───────────────────────────────────────────────────────────────
  Widget _macroCard() {
    final g = c.goal.value ?? const NutritionGoal();
    return Container(
      width: double.infinity,
      decoration: _cardDecor(),
      padding: EdgeInsets.all(18.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Macros',
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 15.sp, fontWeight: FontWeight.w800, color: _kText)),
          SizedBox(height: 14.h),
          _macroBar('Protein', c.proteinToday, g.effectiveProtein, _kProtein),
          SizedBox(height: 12.h),
          _macroBar('Carbs', c.carbsToday, g.effectiveCarbs, _kCarbs),
          SizedBox(height: 12.h),
          _macroBar('Fat', c.fatToday, g.effectiveFat, _kFat),
        ],
      ),
    );
  }

  Widget _macroBar(String label, double value, double target, Color color) {
    final pct = target <= 0 ? 0.0 : (value / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 12.sp, fontWeight: FontWeight.w700, color: _kText)),
            Text('${value.round()} / ${target.round()} g',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 11.sp, color: _kMuted)),
          ],
        ),
        SizedBox(height: 6.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 8.h,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  // ── MEAL SECTIONS ────────────────────────────────────────────────────────────
  Widget _mealSection(String meal) {
    final meta = _mealMeta[meal]!;
    final entries = c.entriesForMeal(meal);
    final total = c.caloriesForMeal(meal);

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: _cardDecor(),
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34.r,
                height: 34.r,
                decoration: BoxDecoration(
                    color: meta.$2.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10.r)),
                child: Icon(meta.$1, color: meta.$2, size: 18.r),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_cap(meal),
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: _kText)),
                    Text('target ~${c.suggestedMealTarget} cal',
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 10.sp, color: _kMuted)),
                  ],
                ),
              ),
              Text('${total.round()} cal',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: meta.$2)),
            ],
          ),
          if (entries.isNotEmpty) ...[
            SizedBox(height: 10.h),
            ...entries.map((e) => _foodRow(e, meta.$2)),
          ],
          SizedBox(height: 10.h),
          _addButton(meal, meta.$2),
        ],
      ),
    );
  }

  Widget _foodRow(LoggedEntry e, Color accent) {
    return GestureDetector(
      onTap: () => NutritionSheets.adjustExisting(c, e),
      child: Container(
        margin: EdgeInsets.only(bottom: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.foodItem.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: _kText)),
                  Text('${_qty(e.quantity)} × ${e.foodItem.servingSize}',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 10.sp, color: _kMuted)),
                ],
              ),
            ),
            Text('${e.calories.round()}',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: _kText)),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: () => _confirmDelete(e.id),
              child: Icon(Icons.close_rounded, size: 16.r, color: _kMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addButton(String meal, Color accent) {
    return GestureDetector(
      onTap: () => Get.to(() => FoodEntryScreen(meal: meal)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: accent.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: accent, size: 18.r),
            SizedBox(width: 6.w),
            Text('Add ${_cap(meal)}',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: accent)),
          ],
        ),
      ),
    );
  }

  // ── EXERCISE SECTION ─────────────────────────────────────────────────────────
  Widget _exerciseSection() {
    const accent = Color(0xffFF6B35);
    final entries = c.exerciseEntries;
    return Container(
      decoration: _cardDecor(),
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34.r,
                height: 34.r,
                decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10.r)),
                child: Icon(Icons.local_fire_department_rounded,
                    color: accent, size: 18.r),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text('Exercise',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: _kText)),
              ),
              Text('+${c.exerciseCalories.round()} cal',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: accent)),
            ],
          ),
          if (entries.isNotEmpty) ...[
            SizedBox(height: 10.h),
            ...entries.map((e) => _foodRow(e, accent)),
          ],
          SizedBox(height: 10.h),
          GestureDetector(
            onTap: () => NutritionSheets.addExercise(c),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 10.h),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: accent.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: accent, size: 18.r),
                  SizedBox(width: 6.w),
                  Text('Log Exercise',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: accent)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── helpers ──────────────────────────────────────────────────────────────────
  void _confirmDelete(String id) {
    Get.defaultDialog(
      backgroundColor: Colors.white,
      title: 'Remove item?',
      middleText: 'This will remove it from your log.',
      confirm: TextButton(
        onPressed: () {
          Get.back();
          c.deleteEntry(id);
        },
        child: const Text('Remove', style: TextStyle(color: Colors.red)),
      ),
      cancel: TextButton(onPressed: Get.back, child: const Text('Cancel')),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {bool small = false}) {
    final s = small ? 32.r : 38.r;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
            shape: BoxShape.circle, color: Colors.white.withOpacity(0.2)),
        child: Icon(icon, color: Colors.white, size: small ? 20.r : 16.r),
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 34.h, color: Colors.black.withOpacity(0.06));

  BoxDecoration _cardDecor() => BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.055),
              blurRadius: 14,
              offset: const Offset(0, 4)),
        ],
      );

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
  String _qty(double q) =>
      q == q.roundToDouble() ? q.round().toString() : q.toStringAsFixed(1);
  String _pretty(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    const wd = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${wd[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }
}

class _CalorieRingPainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;
  _CalorieRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 8;
    final stroke = 12.0;

    final bg = Paint()
      ..color = color.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);

    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _CalorieRingPainter old) =>
      old.progress != progress || old.color != color;
}
