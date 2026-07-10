import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/features/nutrition/controller/nutrition_controller.dart';
import 'package:spanx/features/nutrition/data/food_item.dart';
import 'package:spanx/features/nutrition/data/logged_entry.dart';
import 'package:spanx/features/nutrition/data/nutrition_goal.dart';

const _kRed = Color(0xffE84040);
const _kBg = Color(0xffF6F4F2);
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// All the modal flows for logging / editing nutrition. Kept in one place so
/// both the dashboard and the food-entry screen share identical UX.
abstract class NutritionSheets {
  // ── Quantity adjuster for a NEW food ────────────────────────────────────────
  /// Returns true if the user confirmed and the food was logged.
  static Future<bool> adjustNew(
      NutritionController c, FoodItem food, String meal) async {
    final res = await _quantitySheet(
      food: food,
      initialQty: 1,
      initialMeal: meal,
      title: 'Add to Log',
      confirmLabel: 'Add',
    );
    if (res == null) return false;
    final ok = await c.addFood(
        food: food, meal: res.meal, quantity: res.quantity);
    if (ok) {
      AppSnackBar.success('${food.name} added to ${_cap(res.meal)}');
    } else {
      AppSnackBar.error('Could not save — storage unavailable.');
    }
    return ok;
  }

  // ── Quantity adjuster for an EXISTING entry (edit) ──────────────────────────
  static Future<void> adjustExisting(
      NutritionController c, LoggedEntry entry) async {
    final res = await _quantitySheet(
      food: entry.foodItem,
      initialQty: entry.quantity,
      initialMeal: entry.meal,
      title: 'Edit Item',
      confirmLabel: 'Save',
      allowMealChange: entry.meal != kExerciseMeal,
    );
    if (res == null) return;
    await c.updateEntry(entry.copyWith(quantity: res.quantity, meal: res.meal));
    AppSnackBar.success('Updated');
  }

  static Future<_QtyResult?> _quantitySheet({
    required FoodItem food,
    required double initialQty,
    required String initialMeal,
    required String title,
    required String confirmLabel,
    bool allowMealChange = true,
  }) {
    double qty = initialQty <= 0 ? 1 : initialQty;
    String meal = kMeals.contains(initialMeal) ? initialMeal : kMeals.first;

    return Get.bottomSheet<_QtyResult>(
      StatefulBuilder(
        builder: (context, setState) {
          void bump(double d) {
            final next = (qty + d);
            if (next >= 0.5) setState(() => qty = double.parse(next.toStringAsFixed(2)));
          }

          final cals = (food.calories * qty).round();
          return _sheetShell(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _grabber(),
                Text(title,
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 18.sp, fontWeight: FontWeight.w800, color: _kText)),
                SizedBox(height: 4.h),
                Text(food.name,
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 14.sp, color: _kText, fontWeight: FontWeight.w600)),
                Text('per ${food.servingSize} · ${food.calories.round()} cal',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 11.sp, color: _kMuted)),
                SizedBox(height: 18.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _stepBtn(Icons.remove_rounded, () => bump(-0.5)),
                    SizedBox(width: 20.w),
                    Column(
                      children: [
                        Text(
                          qty == qty.roundToDouble()
                              ? qty.round().toString()
                              : qty.toStringAsFixed(1),
                          style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 30.sp,
                              fontWeight: FontWeight.w800,
                              color: _kText),
                        ),
                        Text('servings',
                            style: AppFonts.spaceGrotesk.copyWith(
                                fontSize: 11.sp, color: _kMuted)),
                      ],
                    ),
                    SizedBox(width: 20.w),
                    _stepBtn(Icons.add_rounded, () => bump(0.5)),
                  ],
                ),
                SizedBox(height: 16.h),
                Center(
                  child: Text('$cals cal total',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: _kRed)),
                ),
                if (allowMealChange) ...[
                  SizedBox(height: 18.h),
                  Text('Meal',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: _kText)),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    children: kMeals.map((m) {
                      final sel = m == meal;
                      return GestureDetector(
                        onTap: () => setState(() => meal = m),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: sel ? _kRed : _kBg,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(_cap(m),
                              style: AppFonts.spaceGrotesk.copyWith(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: sel ? Colors.white : _kMuted)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                SizedBox(height: 22.h),
                _primaryButton(confirmLabel,
                    () => Get.back(result: _QtyResult(qty, meal))),
                SizedBox(height: 8.h),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // ── Add exercise ────────────────────────────────────────────────────────────
  static Future<void> addExercise(NutritionController c) async {
    final nameC = TextEditingController();
    final calC = TextEditingController();
    await Get.bottomSheet(
      _sheetShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _grabber(),
            Text('Log Exercise',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 18.sp, fontWeight: FontWeight.w800, color: _kText)),
            SizedBox(height: 16.h),
            _field(nameC, 'Activity (e.g. Running)'),
            SizedBox(height: 12.h),
            _field(calC, 'Calories burned', number: true),
            SizedBox(height: 22.h),
            _primaryButton('Log It', () async {
              final cal = double.tryParse(calC.text.trim()) ?? 0;
              if (cal <= 0) {
                AppSnackBar.error('Enter the calories burned.');
                return;
              }
              await c.addExercise(name: nameC.text, calories: cal);
              Get.back();
              AppSnackBar.success('Exercise logged');
            }),
            SizedBox(height: 8.h),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // ── Edit daily goal ───────────────────────────────────────────────────────��─
  static Future<void> editGoal(NutritionController c) async {
    final g = c.goal.value ?? const NutritionGoal();
    final budgetC = TextEditingController(text: g.dailyCalorieBudget.toString());
    final proteinC = TextEditingController(
        text: g.proteinTargetG?.round().toString() ?? '');
    final carbsC =
        TextEditingController(text: g.carbsTargetG?.round().toString() ?? '');
    final fatC =
        TextEditingController(text: g.fatTargetG?.round().toString() ?? '');

    await Get.bottomSheet(
      _sheetShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _grabber(),
            Text('Daily Goal',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 18.sp, fontWeight: FontWeight.w800, color: _kText)),
            SizedBox(height: 4.h),
            Text('Leave macros blank to auto-split (30/40/30).',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 11.sp, color: _kMuted)),
            SizedBox(height: 16.h),
            _field(budgetC, 'Daily calorie budget', number: true),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(child: _field(proteinC, 'Protein g', number: true)),
                SizedBox(width: 8.w),
                Expanded(child: _field(carbsC, 'Carbs g', number: true)),
                SizedBox(width: 8.w),
                Expanded(child: _field(fatC, 'Fat g', number: true)),
              ],
            ),
            SizedBox(height: 22.h),
            _primaryButton('Save Goal', () async {
              final budget = int.tryParse(budgetC.text.trim()) ?? 0;
              if (budget < 800 || budget > 10000) {
                AppSnackBar.error('Enter a budget between 800 and 10000.');
                return;
              }
              await c.saveGoal(NutritionGoal(
                dailyCalorieBudget: budget,
                proteinTargetG: _optD(proteinC.text),
                carbsTargetG: _optD(carbsC.text),
                fatTargetG: _optD(fatC.text),
              ));
              Get.back();
              AppSnackBar.success('Goal updated');
            }),
            SizedBox(height: 8.h),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // ── Manual "Create New Food" ─────────────────────────────────────────────────
  static Future<void> createFood(NutritionController c, String meal) async {
    final nameC = TextEditingController();
    final servingC = TextEditingController(text: '1 serving');
    final calC = TextEditingController();
    final proteinC = TextEditingController();
    final carbsC = TextEditingController();
    final fatC = TextEditingController();

    await Get.bottomSheet(
      _sheetShell(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _grabber(),
              Text('Create Food',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: _kText)),
              SizedBox(height: 16.h),
              _field(nameC, 'Food name'),
              SizedBox(height: 12.h),
              _field(servingC, 'Serving size (e.g. 1 cup, 100 g)'),
              SizedBox(height: 12.h),
              _field(calC, 'Calories per serving', number: true),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(child: _field(proteinC, 'Protein g', number: true)),
                  SizedBox(width: 8.w),
                  Expanded(child: _field(carbsC, 'Carbs g', number: true)),
                  SizedBox(width: 8.w),
                  Expanded(child: _field(fatC, 'Fat g', number: true)),
                ],
              ),
              SizedBox(height: 22.h),
              _primaryButton('Continue', () {
                final name = nameC.text.trim();
                final cal = double.tryParse(calC.text.trim()) ?? -1;
                if (name.isEmpty || cal < 0) {
                  AppSnackBar.error('Add a name and calories.');
                  return;
                }
                final food = FoodItem(
                  id: 'manual_${DateTime.now().microsecondsSinceEpoch}',
                  name: name,
                  servingSize: servingC.text.trim().isEmpty
                      ? '1 serving'
                      : servingC.text.trim(),
                  calories: cal,
                  protein: _optD(proteinC.text) ?? 0,
                  carbs: _optD(carbsC.text) ?? 0,
                  fat: _optD(fatC.text) ?? 0,
                  source: 'manual',
                );
                Get.back(); // close create sheet
                adjustNew(c, food, meal);
              }),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // ── shared bits ───────────────────────────────────────────────────────────��─
  static Widget _sheetShell({required Widget child}) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20.w, 10.h, 20.w, MediaQuery.of(Get.context!).viewInsets.bottom + 20.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: child,
    );
  }

  static Widget _grabber() => Center(
        child: Container(
          width: 40.w,
          height: 4.h,
          margin: EdgeInsets.only(bottom: 16.h),
          decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4.r)),
        ),
      );

  static Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48.r,
        height: 48.r,
        decoration: BoxDecoration(
            shape: BoxShape.circle, color: _kRed.withOpacity(0.1)),
        child: Icon(icon, color: _kRed, size: 24.r),
      ),
    );
  }

  static Widget _field(TextEditingController c, String hint,
      {bool number = false}) {
    return TextField(
      controller: c,
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
        contentPadding:
            EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none),
      ),
    );
  }

  static Widget _primaryButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kRed,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 15.h),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r)),
        ),
        child: Text(label,
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
      ),
    );
  }

  static double? _optD(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  static String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _QtyResult {
  final double quantity;
  final String meal;
  _QtyResult(this.quantity, this.meal);
}
