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
import 'package:spanx/core/const/app_colors.dart';

Color get _kRed => AppColors.primaryColor;
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
      showDetailed: c.detailedEntry.value,
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
      showDetailed: c.detailedEntry.value,
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
    bool showDetailed = false,
  }) async {
    double qty = initialQty <= 0 ? 1 : initialQty;
    String meal = kMeals.contains(initialMeal) ? initialMeal : kMeals.first;

    // Exercise items are counted in "sessions", food in "servings".
    final bool isExercise = initialMeal == kExerciseMeal;
    final String unit = isExercise ? 'session' : 'serving';

    // Typable quantity — users can enter an exact amount, decimals included,
    // instead of only nudging with +/-.
    final qtyC = TextEditingController(text: _fmtQty(qty));

    final result = await Get.bottomSheet<_QtyResult>(
      StatefulBuilder(
        builder: (context, setState) {
          // Buttons nudge and keep the text field in sync.
          void bump(double d) {
            final next = double.parse((qty + d).clamp(0.1, 9999).toStringAsFixed(2));
            setState(() => qty = next);
            qtyC.text = _fmtQty(next);
            qtyC.selection =
                TextSelection.collapsed(offset: qtyC.text.length);
          }

          // Typing updates qty without fighting the cursor (no reformat here).
          void onTyped(String t) {
            final v = double.tryParse(t);
            if (v != null && v >= 0) setState(() => qty = v);
          }

          final cals = (food.calories * qty).round();
          return _sheetShell(
            // Scrollable: the qty field raises the keyboard, and on small
            // phones the full content (stepper + meal chips + button) would
            // otherwise overflow the shortened viewport.
            child: SingleChildScrollView(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 6.h),
                      child: _stepBtn(Icons.remove_rounded, () => bump(-0.5)),
                    ),
                    SizedBox(width: 16.w),
                    Column(
                      children: [
                        // Tap to type an exact amount (e.g. 1.75).
                        SizedBox(
                          width: 96.w,
                          child: TextField(
                            controller: qtyC,
                            textAlign: TextAlign.center,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]')),
                            ],
                            onChanged: onTyped,
                            style: AppFonts.spaceGrotesk.copyWith(
                                fontSize: 30.sp,
                                fontWeight: FontWeight.w800,
                                color: _kText),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 6.h),
                              filled: true,
                              fillColor: _kBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(qty == 1 ? unit : '${unit}s',
                            style: AppFonts.spaceGrotesk.copyWith(
                                fontSize: 11.sp, color: _kMuted)),
                      ],
                    ),
                    SizedBox(width: 16.w),
                    Padding(
                      padding: EdgeInsets.only(top: 6.h),
                      child: _stepBtn(Icons.add_rounded, () => bump(0.5)),
                    ),
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
                // Full nutrition for the chosen quantity — the detail view for
                // a log row. Only in Detailed mode (or when the food actually
                // carries detailed data) so Basic mode looks exactly as before.
                // Exercise entries carry no macros, so skip them.
                if (!isExercise &&
                    (showDetailed || food.hasDetailedNutrition)) ...[
                  SizedBox(height: 10.h),
                  _nutritionBreakdown(food, qty,
                      showDetailed: showDetailed || food.hasDetailedNutrition),
                ],
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
                _primaryButton(confirmLabel, () {
                  // Guard an empty/zero entry — fall back to a sensible amount.
                  final finalQty = qty <= 0
                      ? 1.0
                      : double.parse(qty.toStringAsFixed(2));
                  Get.back(result: _QtyResult(finalQty, meal));
                }),
                SizedBox(height: 8.h),
              ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
    qtyC.dispose();
    return result;
  }

  /// Per-serving nutrition scaled by [qty]. Fiber/sugar/sodium only appear
  /// when the user is in Detailed mode or the food actually carries them, so
  /// Basic-mode users see exactly what they saw before.
  static Widget _nutritionBreakdown(FoodItem food, double qty,
      {required bool showDetailed}) {
    final rows = <Widget>[
      _breakdownChip('Protein', food.protein * qty, 'g'),
      _breakdownChip('Carbs', food.carbs * qty, 'g'),
      _breakdownChip('Fat', food.fat * qty, 'g'),
      if (showDetailed) ...[
        _breakdownChip('Fiber', food.fiber * qty, 'g'),
        _breakdownChip('Sugar', food.sugar * qty, 'g'),
        _breakdownChip('Sodium', food.sodiumMg * qty, 'mg'),
      ],
    ];
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 14.w,
        runSpacing: 8.h,
        children: rows,
      ),
    );
  }

  static Widget _breakdownChip(String label, double value, String unit) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${value.round()}$unit',
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 13.sp, fontWeight: FontWeight.w800, color: _kText)),
        Text(label,
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 10.sp, color: _kMuted)),
      ],
    );
  }

  /// Format a quantity for display/input: whole numbers show as integers,
  /// fractional values keep up to 2 decimals with trailing zeros trimmed.
  static String _fmtQty(double v) {
    if (v == v.roundToDouble()) return v.round().toString();
    return v
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  // ── Save a combo (bundle several of your foods into one one-tap item) ────────
  static Future<void> saveCombo(NutritionController c) async {
    final foods = c.myFoods;
    if (foods.isEmpty) {
      AppSnackBar.error('Log a few foods first, then bundle them into a combo.');
      return;
    }
    final nameC = TextEditingController();
    final selected = <FoodItem>[];

    await Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          return _sheetShell(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _grabber(),
                Text('Save a Combo',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: _kText)),
                SizedBox(height: 4.h),
                Text('Bundle foods you always eat together (e.g. "my usual '
                    'smoothie") to log them all in one tap.',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 11.sp, color: _kMuted, height: 1.4)),
                SizedBox(height: 16.h),
                _field(nameC, 'Combo name'),
                SizedBox(height: 14.h),
                Text('Pick items (${selected.length} selected)',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: _kText)),
                SizedBox(height: 8.h),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 260.h),
                  child: SingleChildScrollView(
                    child: Column(
                      children: foods.map((f) {
                        final sel = selected.contains(f);
                        return GestureDetector(
                          onTap: () => setState(() {
                            if (sel) {
                              selected.remove(f);
                            } else {
                              selected.add(f);
                            }
                          }),
                          child: Container(
                            margin: EdgeInsets.only(bottom: 6.h),
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 10.h),
                            decoration: BoxDecoration(
                              color: sel ? _kRed.withOpacity(0.08) : _kBg,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                  color: sel
                                      ? _kRed.withOpacity(0.5)
                                      : Colors.transparent),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                    sel
                                        ? Icons.check_circle_rounded
                                        : Icons.circle_outlined,
                                    color: sel ? _kRed : _kMuted,
                                    size: 20.r),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Text(f.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppFonts.spaceGrotesk.copyWith(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                          color: _kText)),
                                ),
                                Text('${f.calories.round()} cal',
                                    style: AppFonts.spaceGrotesk.copyWith(
                                        fontSize: 11.sp, color: _kMuted)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                _primaryButton('Save Combo', () async {
                  if (selected.length < 2) {
                    AppSnackBar.error('Pick at least two foods for a combo.');
                    return;
                  }
                  final ok = await c.saveCombo(nameC.text, List.of(selected));
                  Get.back();
                  if (ok) {
                    AppSnackBar.success('Combo saved');
                  } else {
                    AppSnackBar.error('Could not save the combo.');
                  }
                }),
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

  // ── Repeat yesterday — reviewable before it commits ─────────────────────────
  /// [mealLabel] null = whole day. Returns count copied (0 if cancelled).
  static Future<int> confirmRepeat(
    NutritionController c, {
    String? mealLabel,
  }) async {
    final items = c.yesterdayEntries(meal: mealLabel);
    if (items.isEmpty) {
      AppSnackBar.error(mealLabel == null
          ? 'Nothing was logged yesterday to copy.'
          : 'No ${_cap(mealLabel)} logged yesterday.');
      return 0;
    }
    final title = mealLabel == null
        ? 'Repeat Yesterday'
        : 'Repeat ${_cap(mealLabel)}';

    final confirmed = await Get.bottomSheet<bool>(
      _sheetShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _grabber(),
            Text(title,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
            SizedBox(height: 4.h),
            Text('These ${items.length} item(s) will be copied to today. You '
                'can still edit or remove anything afterwards.',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 11.sp, color: _kMuted, height: 1.4)),
            SizedBox(height: 14.h),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 260.h),
              child: SingleChildScrollView(
                child: Column(
                  children: items
                      .map((e) => Container(
                            margin: EdgeInsets.only(bottom: 6.h),
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 10.h),
                            decoration: BoxDecoration(
                              color: _kBg,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                      '${e.foodItem.name}  ·  ${_cap(e.meal)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppFonts.spaceGrotesk.copyWith(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                          color: _kText)),
                                ),
                                Text('${e.calories.round()} cal',
                                    style: AppFonts.spaceGrotesk.copyWith(
                                        fontSize: 11.sp, color: _kMuted)),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            SizedBox(height: 18.h),
            _primaryButton('Copy to Today',
                () => Get.back(result: true)),
            SizedBox(height: 8.h),
            Center(
              child: TextButton(
                onPressed: () => Get.back(result: false),
                child: Text('Cancel',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 13.sp, color: _kMuted)),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );

    if (confirmed != true) return 0;
    final n = mealLabel == null
        ? await c.repeatDay()
        : await c.repeatMeal(mealLabel);
    if (n > 0) AppSnackBar.success('Copied $n item(s) to today');
    return n;
  }

  // ── Log weight ──────────────────────────────────────────────────────────────
  static Future<void> logWeight(NutritionController c) async {
    final latest = c.latestWeight?.weightLbs;
    final weightC =
        TextEditingController(text: latest != null ? latest.toString() : '');
    await Get.bottomSheet(
      _sheetShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _grabber(),
            Text('Log Weight',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 18.sp, fontWeight: FontWeight.w800, color: _kText)),
            SizedBox(height: 4.h),
            Text('One tap — today\'s date is used automatically.',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 11.sp, color: _kMuted)),
            SizedBox(height: 16.h),
            _field(weightC, 'Weight (lbs)', number: true),
            SizedBox(height: 22.h),
            _primaryButton('Save', () async {
              final w = double.tryParse(weightC.text.trim()) ?? 0;
              if (w <= 0 || w > 1500) {
                AppSnackBar.error('Enter a valid weight.');
                return;
              }
              final ok = await c.addWeight(w);
              Get.back();
              if (ok) {
                AppSnackBar.success('Weight logged');
              } else {
                AppSnackBar.error('Could not save — storage unavailable.');
              }
            }),
            SizedBox(height: 8.h),
          ],
        ),
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
    final proteinGoalC = TextEditingController(
        text: g.proteinGoalGrams?.round().toString() ?? '');

    await Get.bottomSheet(
      _sheetShell(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _grabber(),
              Text('Daily Goal',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: _kText)),
              SizedBox(height: 4.h),
              Text('Leave macros blank to auto-split (30/40/30).',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 11.sp, color: _kMuted)),
              SizedBox(height: 16.h),
              // Quick access to the same switch that lives in Goal Setup —
              // persists the moment it's tapped.
              trackingModeSelector(c),
              SizedBox(height: 16.h),
              Obx(() {
                if (!c.isProteinMode) return const SizedBox.shrink();
                final auto = c.defaultProteinGoal;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field(
                        proteinGoalC,
                        auto == null
                            ? 'Protein goal (g)'
                            : 'Protein goal (g) — default $auto',
                        number: true),
                    SizedBox(height: 6.h),
                    Text(
                        auto == null
                            ? 'Log a weigh-in and we\'ll suggest one for you.'
                            : 'Blank uses your bodyweight × 0.8 g.',
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 10.sp, color: _kMuted)),
                    SizedBox(height: 16.h),
                  ],
                );
              }),
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
                // Blank clears the override on purpose; garbage input must
                // NOT be mistaken for blank and silently wipe it.
                final pgRaw = proteinGoalC.text.trim();
                final pg = pgRaw.isEmpty ? null : double.tryParse(pgRaw);
                if (pgRaw.isNotEmpty &&
                    (pg == null || pg <= 0 || pg > 500)) {
                  AppSnackBar.error('Enter a protein goal between 1 and 500 g.');
                  return;
                }
                // Preserve personalization fields (goal/current weight, target
                // date/rate, profile, tracking mode) — only budget + macros +
                // the protein goal are edited here.
                await c.saveGoal(
                  (c.goal.value ?? const NutritionGoal()).copyWith(
                    dailyCalorieBudget: budget,
                    proteinTargetG: _optD(proteinC.text),
                    carbsTargetG: _optD(carbsC.text),
                    fatTargetG: _optD(fatC.text),
                    proteinGoalGrams: pg,
                    clearProteinGoalGrams: pg == null,
                  ),
                );
                Get.back();
                AppSnackBar.success('Goal updated');
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

  // ── Calories vs Protein tracking switch ─────────────────────────────────────
  /// Shared by the Goal Setup screen and the Daily Goal sheet. Writes straight
  /// through to storage on tap so the choice survives even if the surrounding
  /// form is abandoned.
  static Widget trackingModeSelector(NutritionController c) {
    return Obx(() {
      final protein = c.isProteinMode;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What do you want to track?',
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 14.sp, fontWeight: FontWeight.w800, color: _kText)),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _trackPill('Calories', !protein,
                    () => c.setTrackingMode(kTrackCalories)),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _trackPill('Protein', protein,
                    () => c.setTrackingMode(kTrackProtein)),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
              'Some people count calories. Some just count protein. Pick what '
              'works for you — you can always switch back.',
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 11.sp, color: _kMuted, height: 1.4)),
        ],
      );
    });
  }

  static Widget _trackPill(String label, bool sel, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 11.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: sel ? _kRed : _kBg,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(label,
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: sel ? Colors.white : _kMuted)),
      ),
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
    final fiberC = TextEditingController();
    final sugarC = TextEditingController();
    final sodiumC = TextEditingController();

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
              // Mirrors the Quick Add screen's Basic/Detailed choice.
              Obx(() {
                if (!c.detailedEntry.value) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Expanded(
                            child: _field(fiberC, 'Fiber g', number: true)),
                        SizedBox(width: 8.w),
                        Expanded(
                            child: _field(sugarC, 'Sugar g', number: true)),
                        SizedBox(width: 8.w),
                        Expanded(
                            child: _field(sodiumC, 'Sodium mg', number: true)),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text('Sodium is in milligrams (mg).',
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 10.sp, color: _kMuted)),
                  ],
                );
              }),
              SizedBox(height: 22.h),
              _primaryButton('Continue', () {
                final name = nameC.text.trim();
                final cal = double.tryParse(calC.text.trim()) ?? -1;
                if (name.isEmpty || cal < 0) {
                  AppSnackBar.error('Add a name and calories.');
                  return;
                }
                final detailed = c.detailedEntry.value;
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
                  fiberG: detailed ? _optD(fiberC.text) : null,
                  sugarG: detailed ? _optD(sugarC.text) : null,
                  sodiumMgValue: detailed ? _optD(sodiumC.text) : null,
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
          // Get.bottomSheet's route already pads by viewInsets.bottom (it
          // lifts the whole sheet above the keyboard) — adding the inset here
          // again would shrink the visible content to a sliver.
          20.w, 10.h, 20.w, 20.h),
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
