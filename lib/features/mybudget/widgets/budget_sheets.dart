import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';

import '../controller/my_budget_controller.dart';
import '../data/budget_models.dart';
import 'budget_theme.dart';

/// All bottom-sheet flows for the budget. Each grabs the controller via
/// Get.find and performs the mutation directly, so the screen stays lean.
class BudgetSheets {
  BudgetSheets._();

  static MyBudgetController get _c => Get.find<MyBudgetController>();

  static void _open(Widget child) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 14.h,
          bottom: MediaQuery.of(Get.context!).viewInsets.bottom + 24.h,
        ),
        decoration: BoxDecoration(
          color: BudgetTheme.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: child,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  static Widget _grabber() => Center(
        child: Container(
          width: 44.w,
          height: 5.h,
          margin: EdgeInsets.only(bottom: 16.h),
          decoration: BoxDecoration(
              color: BudgetTheme.muted.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4.r)),
        ),
      );

  static Widget _title(String t, {String? sub}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t,
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: BudgetTheme.text)),
          if (sub != null) ...[
            SizedBox(height: 3.h),
            Text(sub,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 12.sp, color: BudgetTheme.muted)),
          ],
        ],
      );

  static Widget _field({
    required TextEditingController controller,
    required String hint,
    String? prefix,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? formatters,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: BudgetTheme.card,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        inputFormatters: formatters,
        style: AppFonts.spaceGrotesk.copyWith(
            fontSize: 15.sp, fontWeight: FontWeight.w600, color: BudgetTheme.text),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixText: prefix,
          prefixStyle: AppFonts.spaceGrotesk.copyWith(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: BudgetTheme.text),
          hintText: hint,
          hintStyle: AppFonts.spaceGrotesk.copyWith(
              fontSize: 14.sp, color: BudgetTheme.muted),
        ),
      ),
    );
  }

  static Widget _label(String t) => Padding(
        padding: EdgeInsets.only(bottom: 8.h, top: 16.h),
        child: Text(t,
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: BudgetTheme.muted)),
      );

  static Widget _primaryButton(String label, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: BudgetTheme.red,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.symmetric(vertical: 15.h),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r)),
          ),
          child: Text(label,
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 15.sp, fontWeight: FontWeight.w800)),
        ),
      );

  static List<TextInputFormatter> get _moneyInput => [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ];

  // ── Log a spend ────────────────────────────────────────────────────────────
  static void logSpend(BudgetCategory category, {int week = -1}) {
    final amount = TextEditingController();
    final note = TextEditingController();
    final resolvedWeek = category.isWeekly
        ? (week >= 0 ? week : weekIndexForDate(DateTime.now()))
        : -1;
    final where = category.isWeekly ? '${category.name} · W${resolvedWeek + 1}' : category.name;

    _open(SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _grabber(),
          _title('Log a spend', sub: where),
          _label('Amount'),
          _field(
              controller: amount,
              hint: '0.00',
              prefix: '\$ ',
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              formatters: _moneyInput),
          _label('Note (optional)'),
          _field(controller: note, hint: 'e.g. groceries at Aldi'),
          SizedBox(height: 22.h),
          _primaryButton('Log spend', () async {
            final cents = parseDollarsToCents(amount.text);
            if (cents == null || cents <= 0) {
              AppSnackBar.show(message: 'Enter a valid amount', isSuccessful: false);
              return;
            }
            Get.back();
            final within = await _c.logSpend(
              categoryId: category.id,
              cents: cents,
              note: note.text.trim(),
              week: resolvedWeek,
            );
            AppSnackBar.show(
              message: within
                  ? 'Nice — ${fmtCents(cents)} logged, still on budget! 🎯'
                  : '${fmtCents(cents)} logged — watch this envelope 👀',
              isSuccessful: within,
            );
          }),
        ],
      ),
    ));
  }

  // ── Contribute to a goal ─────────────────────────────────────────────────────
  static void contribute(BudgetGoal goal) {
    final amount = TextEditingController();
    _open(SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _grabber(),
          _title('Add to ${goal.name}',
              sub: '${fmtCents(goal.savedCents)} of ${fmtCents(goal.targetCents)} saved'),
          _label('Amount'),
          _field(
              controller: amount,
              hint: '0.00',
              prefix: '\$ ',
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              formatters: _moneyInput),
          SizedBox(height: 22.h),
          _primaryButton('Add contribution', () async {
            final cents = parseDollarsToCents(amount.text);
            if (cents == null || cents <= 0) {
              AppSnackBar.show(message: 'Enter a valid amount', isSuccessful: false);
              return;
            }
            Get.back();
            await _c.contributeToGoal(goal.id, cents);
            final after = _c.month.value?.goals
                .firstWhere((g) => g.id == goal.id, orElse: () => goal);
            final hit = after != null && after.targetCents > 0 &&
                after.savedCents >= after.targetCents;
            AppSnackBar.show(
              message: hit
                  ? '${goal.name} goal reached! 🏆'
                  : 'Added ${fmtCents(cents)} to ${goal.name} 💪',
              isSuccessful: true,
            );
          }),
        ],
      ),
    ));
  }

  // ── Pay a debt ───────────────────────────────────────────────────────────────
  static void payDebt(BudgetDebt debt) {
    final amount = TextEditingController();
    _open(SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _grabber(),
          _title('Pay down ${debt.name}',
              sub: '${fmtCents(debt.remainingCents)} remaining'),
          _label('Payment amount'),
          _field(
              controller: amount,
              hint: '0.00',
              prefix: '\$ ',
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              formatters: _moneyInput),
          SizedBox(height: 22.h),
          _primaryButton('Log payment', () async {
            final cents = parseDollarsToCents(amount.text);
            if (cents == null || cents <= 0) {
              AppSnackBar.show(message: 'Enter a valid amount', isSuccessful: false);
              return;
            }
            Get.back();
            final paidOff = await _c.payDebt(debt.id, cents);
            AppSnackBar.show(
              message: paidOff
                  ? '${debt.name} is paid off! 🎉🎉'
                  : 'Paid ${fmtCents(cents)} toward ${debt.name} 🔥',
              isSuccessful: true,
            );
          }),
        ],
      ),
    ));
  }

  // ── Manage income ────────────────────────────────────────────────────────────
  static void manageIncome() {
    _open(Obx(() {
      final m = _c.month.value;
      final incomes = m?.incomes ?? const [];
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _grabber(),
            _title('Income',
                sub: 'Total ${fmtCents(m?.totalIncomeCents ?? 0)} this month'),
            SizedBox(height: 12.h),
            ...incomes.map((i) => Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: BudgetTheme.card,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Text(i.name,
                          style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: BudgetTheme.text)),
                    ),
                    Text(fmtCents(i.amountCents),
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: BudgetTheme.greenDk)),
                    SizedBox(width: 6.w),
                    GestureDetector(
                      onTap: () {
                        Get.back();
                        _editIncome(existing: i);
                      },
                      child: Icon(Icons.edit_rounded, size: 18, color: BudgetTheme.muted),
                    ),
                    SizedBox(width: 10.w),
                    GestureDetector(
                      onTap: () async {
                        final ok = await _confirmDelete(
                          title: 'Delete ${i.name}?',
                          message:
                              'This removes ${fmtCents(i.amountCents)} of income '
                              'from this month permanently.',
                        );
                        if (!ok) return;
                        await _c.deleteIncome(i.id);
                        AppSnackBar.show(
                            message: '${i.name} deleted', isSuccessful: true);
                      },
                      child: Icon(Icons.delete_outline_rounded,
                          size: 18, color: BudgetTheme.red),
                    ),
                  ]),
                )),
            SizedBox(height: 12.h),
            _primaryButton('Add income source', () {
              Get.back();
              _editIncome();
            }),
          ],
        ),
      );
    }));
  }

  static void _editIncome({BudgetIncome? existing}) {
    final name = TextEditingController(text: existing?.name ?? '');
    final amount = TextEditingController(
        text: existing == null ? '' : (existing.amountCents / 100).toStringAsFixed(2));
    _open(SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _grabber(),
          _title(existing == null ? 'Add income' : 'Edit income'),
          _label('Name'),
          _field(controller: name, hint: 'e.g. Paycheck'),
          _label('Amount'),
          _field(
              controller: amount,
              hint: '0.00',
              prefix: '\$ ',
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              formatters: _moneyInput),
          SizedBox(height: 22.h),
          _primaryButton('Save', () async {
            final cents = parseDollarsToCents(amount.text) ?? 0;
            final nm = name.text.trim().isEmpty ? 'Income' : name.text.trim();
            Get.back();
            if (existing == null) {
              await _c.addIncome(nm, cents);
            } else {
              await _c.updateIncome(existing.id, nm, cents);
            }
          }),
        ],
      ),
    ));
  }

  // ── Category detail (transactions + edit/delete) ─────────────────────────────
  static void categoryDetail(String categoryId) {
    _open(Obx(() {
      final cat = _c.categoryById(categoryId);
      if (cat == null) {
        return Column(mainAxisSize: MainAxisSize.min, children: [_grabber()]);
      }
      final txns = [...cat.transactions]..sort((a, b) => b.date.compareTo(a.date));
      final color = Color(cat.colorValue);
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _grabber(),
            Row(
              children: [
                Container(
                  width: 42.r,
                  height: 42.r,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12.r)),
                  child: Icon(budgetIcon(cat.iconKey), color: color, size: 21),
                ),
                SizedBox(width: 12.w),
                Expanded(child: _title(cat.name, sub: '${fmtCents(cat.spentCents)} of ${fmtCents(cat.totalBudgetCents)} spent')),
                GestureDetector(
                  onTap: () {
                    Get.back();
                    editCategory(existing: cat);
                  },
                  child: Icon(Icons.edit_rounded, size: 20, color: BudgetTheme.muted),
                ),
              ],
            ),
            SizedBox(height: 18.h),
            if (txns.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Center(
                  child: Text('No spends logged yet',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 13.sp, color: BudgetTheme.muted)),
                ),
              )
            else
              ...txns.map((t) => Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
                    decoration: BoxDecoration(
                      color: BudgetTheme.card,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.note.isEmpty ? 'Spend' : t.note,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.spaceGrotesk.copyWith(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: BudgetTheme.text)),
                            Text(
                                '${_fmtDate(t.date)}${cat.isWeekly && t.weekIndex >= 0 ? ' · W${t.weekIndex + 1}' : ''}',
                                style: AppFonts.spaceGrotesk.copyWith(
                                    fontSize: 10.sp, color: BudgetTheme.muted)),
                          ],
                        ),
                      ),
                      Text(fmtCents(t.amountCents),
                          style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: BudgetTheme.text)),
                      SizedBox(width: 10.w),
                      GestureDetector(
                        onTap: () async {
                          final ok = await _confirmDelete(
                            title: 'Delete this spend?',
                            message:
                                'This removes ${fmtCents(t.amountCents)}'
                                '${t.note.trim().isEmpty ? '' : ' · ${t.note.trim()}'} '
                                'from ${cat.name} permanently.',
                          );
                          if (!ok) return;
                          await _c.deleteTxn(cat.id, t.id);
                          AppSnackBar.show(
                              message: 'Spend deleted', isSuccessful: true);
                        },
                        child: Icon(Icons.delete_outline_rounded,
                            size: 18, color: BudgetTheme.red),
                      ),
                    ]),
                  )),
            SizedBox(height: 14.h),
            _primaryButton('Log a spend', () {
              Get.back();
              logSpend(cat);
            }),
          ],
        ),
      );
    }));
  }

  // ── Create / edit a category ─────────────────────────────────────────────────
  static void editCategory({BudgetCategory? existing, String section = 'spending'}) {
    final isEdit = existing != null;
    final name = TextEditingController(text: existing?.name ?? '');
    final flatBudget = TextEditingController(
        text: existing == null || existing.isWeekly
            ? ''
            : (existing.budgetCents / 100).toStringAsFixed(2));
    final weekCtrls = List.generate(
      4,
      (i) => TextEditingController(
          text: existing != null && existing.isWeekly
              ? (existing.weeklyBudgetsCents[i] / 100).toStringAsFixed(2)
              : ''),
    );
    final rxIcon = (existing?.iconKey ?? 'category').obs;
    final rxColor = (existing?.colorValue ?? kBudgetPalette.first).obs;
    final rxWeekly = (existing?.isWeekly ?? false).obs;
    final sec = existing?.section ?? section;

    _open(SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _grabber(),
          _title(isEdit ? 'Edit envelope' : 'New envelope'),
          _label('Name'),
          _field(controller: name, hint: 'e.g. Groceries'),
          _label('Icon'),
          Obx(() => Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: kBudgetIconKeys.map((k) {
                  final selected = rxIcon.value == k;
                  return GestureDetector(
                    onTap: () => rxIcon.value = k,
                    child: Container(
                      width: 42.r,
                      height: 42.r,
                      decoration: BoxDecoration(
                        color: selected
                            ? Color(rxColor.value).withOpacity(0.15)
                            : BudgetTheme.card,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                            color: selected
                                ? Color(rxColor.value)
                                : Colors.black.withOpacity(0.06),
                            width: selected ? 2 : 1),
                      ),
                      child: Icon(budgetIcon(k),
                          size: 20,
                          color: selected ? Color(rxColor.value) : BudgetTheme.muted),
                    ),
                  );
                }).toList(),
              )),
          _label('Color'),
          Obx(() => Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: kBudgetPalette.map((c) {
                  final selected = rxColor.value == c;
                  return GestureDetector(
                    onTap: () => rxColor.value = c,
                    child: Container(
                      width: 32.r,
                      height: 32.r,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white,
                            width: selected ? 3 : 0),
                        boxShadow: selected
                            ? [BoxShadow(color: Color(c).withOpacity(0.5), blurRadius: 6)]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              )),
          _label('Budget style'),
          Obx(() => Row(children: [
                _toggleChip('Monthly', !rxWeekly.value, () => rxWeekly.value = false),
                SizedBox(width: 10.w),
                _toggleChip('Weekly (×4)', rxWeekly.value, () => rxWeekly.value = true),
              ])),
          Obx(() => rxWeekly.value
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Weekly limits'),
                    Row(
                      children: List.generate(4, (i) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 3.w),
                            child: Column(
                              children: [
                                Text('W${i + 1}',
                                    style: AppFonts.spaceGrotesk.copyWith(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w700,
                                        color: BudgetTheme.muted)),
                                SizedBox(height: 4.h),
                                _field(
                                    controller: weekCtrls[i],
                                    hint: '0',
                                    keyboard: const TextInputType.numberWithOptions(
                                        decimal: true),
                                    formatters: _moneyInput),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Monthly budget'),
                    _field(
                        controller: flatBudget,
                        hint: '0.00',
                        prefix: '\$ ',
                        keyboard: const TextInputType.numberWithOptions(decimal: true),
                        formatters: _moneyInput),
                  ],
                )),
          SizedBox(height: 22.h),
          _primaryButton('Save envelope', () async {
            final nm = name.text.trim().isEmpty ? 'Envelope' : name.text.trim();
            final weekly = rxWeekly.value;
            final weeklyCents =
                weekCtrls.map((c) => parseDollarsToCents(c.text) ?? 0).toList();
            final flatCents = parseDollarsToCents(flatBudget.text) ?? 0;
            Get.back();
            if (isEdit) {
              await _c.updateCategoryMeta(
                existing.id,
                name: nm,
                iconKey: rxIcon.value,
                colorValue: rxColor.value,
                isWeekly: weekly,
                budgetCents: weekly ? null : flatCents,
                weeklyBudgetsCents: weekly ? weeklyCents : null,
              );
            } else {
              await _c.addCategory(BudgetCategory.create(
                name: nm,
                iconKey: rxIcon.value,
                colorValue: rxColor.value,
                section: sec,
                isWeekly: weekly,
                budgetCents: flatCents,
                weeklyBudgetsCents: weekly ? weeklyCents : null,
              ));
            }
          }),
          if (isEdit) ...[
            SizedBox(height: 10.h),
            _dangerButton('Delete envelope', () async {
              if (existing.transactions.isNotEmpty) {
                final ok = await _confirmDelete(
                  title: 'Delete ${existing.name}?',
                  message:
                      'This envelope has ${existing.transactions.length} logged '
                      'spend${existing.transactions.length == 1 ? '' : 's'} '
                      'totalling ${fmtCents(existing.spentCents)}. '
                      'Deleting it removes them permanently.',
                );
                if (!ok) return;
              }
              Get.back();
              await _c.deleteCategory(existing.id);
              AppSnackBar.show(
                  message: '${existing.name} deleted', isSuccessful: true);
            }),
          ],
        ],
      ),
    ));
  }

  // ── Create / edit a goal ─────────────────────────────────────────────────────
  static void editGoal({BudgetGoal? existing}) {
    final isEdit = existing != null;
    final name = TextEditingController(text: existing?.name ?? '');
    final target = TextEditingController(
        text: existing == null ? '' : (existing.targetCents / 100).toStringAsFixed(2));
    final rxIcon = (existing?.iconKey ?? 'savings').obs;
    final rxColor = (existing?.colorValue ?? 0xff3B82F6).obs;

    _open(SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _grabber(),
          _title(isEdit ? 'Edit goal' : 'New savings goal'),
          _label('Name'),
          _field(controller: name, hint: 'e.g. Emergency Fund'),
          _label('Target amount'),
          _field(
              controller: target,
              hint: '0.00',
              prefix: '\$ ',
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              formatters: _moneyInput),
          _label('Icon'),
          Obx(() => Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: const ['savings', 'invest', 'crypto', 'travel', 'home', 'money']
                    .map((k) {
                  final selected = rxIcon.value == k;
                  return GestureDetector(
                    onTap: () => rxIcon.value = k,
                    child: Container(
                      width: 42.r,
                      height: 42.r,
                      decoration: BoxDecoration(
                        color: selected
                            ? Color(rxColor.value).withOpacity(0.15)
                            : BudgetTheme.card,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                            color: selected
                                ? Color(rxColor.value)
                                : Colors.black.withOpacity(0.06),
                            width: selected ? 2 : 1),
                      ),
                      child: Icon(budgetIcon(k),
                          size: 20,
                          color: selected ? Color(rxColor.value) : BudgetTheme.muted),
                    ),
                  );
                }).toList(),
              )),
          _label('Color'),
          Obx(() => Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: kBudgetPalette.map((c) {
                  final selected = rxColor.value == c;
                  return GestureDetector(
                    onTap: () => rxColor.value = c,
                    child: Container(
                      width: 32.r,
                      height: 32.r,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white, width: selected ? 3 : 0),
                        boxShadow: selected
                            ? [BoxShadow(color: Color(c).withOpacity(0.5), blurRadius: 6)]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              )),
          SizedBox(height: 22.h),
          _primaryButton('Save goal', () async {
            final nm = name.text.trim().isEmpty ? 'Goal' : name.text.trim();
            final cents = parseDollarsToCents(target.text) ?? 0;
            Get.back();
            if (isEdit) {
              await _c.updateGoalMeta(existing.id,
                  name: nm,
                  targetCents: cents,
                  colorValue: rxColor.value,
                  iconKey: rxIcon.value);
            } else {
              await _c.addGoal(BudgetGoal.create(
                name: nm,
                targetCents: cents,
                colorValue: rxColor.value,
                iconKey: rxIcon.value,
              ));
            }
          }),
          if (isEdit) ...[
            SizedBox(height: 10.h),
            _dangerButton('Delete goal', () async {
              if (existing.contributions.isNotEmpty) {
                final ok = await _confirmDelete(
                  title: 'Delete ${existing.name}?',
                  message:
                      'This goal has ${fmtCents(existing.savedCents)} saved across '
                      '${existing.contributions.length} '
                      'contribution${existing.contributions.length == 1 ? '' : 's'}. '
                      'Deleting it removes them permanently.',
                );
                if (!ok) return;
              }
              Get.back();
              await _c.deleteGoal(existing.id);
              AppSnackBar.show(
                  message: '${existing.name} deleted', isSuccessful: true);
            }),
          ],
        ],
      ),
    ));
  }

  // ── Create / edit a debt ─────────────────────────────────────────────────────
  static void editDebt({BudgetDebt? existing}) {
    final isEdit = existing != null;
    final name = TextEditingController(text: existing?.name ?? '');
    final balance = TextEditingController(
        text: existing == null
            ? ''
            : (existing.startingBalanceCents / 100).toStringAsFixed(2));
    final rxColor = (existing?.colorValue ?? 0xffF97316).obs;

    _open(SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _grabber(),
          _title(isEdit ? 'Edit debt' : 'New debt'),
          if (isEdit)
            Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Text('Editing the starting balance keeps your logged payments.',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 11.sp, color: BudgetTheme.muted)),
            ),
          _label('Name'),
          _field(controller: name, hint: 'e.g. Student Loan'),
          _label('Starting balance'),
          _field(
              controller: balance,
              hint: '0.00',
              prefix: '\$ ',
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              formatters: _moneyInput),
          _label('Color'),
          Obx(() => Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: kBudgetPalette.map((c) {
                  final selected = rxColor.value == c;
                  return GestureDetector(
                    onTap: () => rxColor.value = c,
                    child: Container(
                      width: 32.r,
                      height: 32.r,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white, width: selected ? 3 : 0),
                        boxShadow: selected
                            ? [BoxShadow(color: Color(c).withOpacity(0.5), blurRadius: 6)]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              )),
          SizedBox(height: 22.h),
          _primaryButton('Save debt', () async {
            final nm = name.text.trim().isEmpty ? 'Debt' : name.text.trim();
            final cents = parseDollarsToCents(balance.text) ?? 0;
            Get.back();
            if (isEdit) {
              await _c.updateDebtMeta(existing.id,
                  name: nm, startingBalanceCents: cents, colorValue: rxColor.value);
            } else {
              await _c.addDebt(BudgetDebt.create(
                name: nm,
                startingBalanceCents: cents,
                colorValue: rxColor.value,
              ));
            }
          }),
          if (isEdit) ...[
            SizedBox(height: 10.h),
            _dangerButton('Delete debt', () async {
              if (existing.payments.isNotEmpty) {
                final ok = await _confirmDelete(
                  title: 'Delete ${existing.name}?',
                  message:
                      'This debt has ${fmtCents(existing.paidCents)} logged across '
                      '${existing.payments.length} '
                      'payment${existing.payments.length == 1 ? '' : 's'}. '
                      'Deleting it removes them permanently.',
                );
                if (!ok) return;
              }
              Get.back();
              await _c.deleteDebt(existing.id);
              AppSnackBar.show(
                  message: '${existing.name} deleted', isSuccessful: true);
            }),
          ],
        ],
      ),
    ));
  }

  // ── Quick "log a spend" picker ───────────────────────────────────────────────
  static void quickLog() {
    _open(Obx(() {
      final m = _c.month.value;
      final cats = m?.categories ?? const <BudgetCategory>[];
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _grabber(),
            _title('Log a spend', sub: 'Pick an envelope'),
            SizedBox(height: 14.h),
            if (cats.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Center(
                  child: Text('Add an envelope first',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 13.sp, color: BudgetTheme.muted)),
                ),
              )
            else
              ...cats.map((c) => _menuRow(budgetIcon(c.iconKey), c.name, () {
                    Get.back();
                    logSpend(c);
                  })),
          ],
        ),
      );
    }));
  }

  // ── Manage month (danger actions) ────────────────────────────────────────────
  static void moreMenu() {
    _open(Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _grabber(),
        _title('Manage this month',
            sub: 'Careful — these actions clear budget data'),
        SizedBox(height: 18.h),
        _dangerButton('Reset this month', () {
          Get.back();
          resetMonth();
        }),
      ],
    ));
  }

  /// Wipe the whole viewed month after an explicit confirmation, then offer a
  /// one-tap undo so an accidental reset is never silent or irreversible.
  static void resetMonth() async {
    if (_c.month.value == null) return;
    final ok = await _confirmDelete(
      title: 'Reset this month?',
      message:
          'This deletes every envelope, goal, debt, income source and logged '
          'spend for this month. You can undo right after.',
      confirmLabel: 'Reset month',
    );
    if (!ok) return;
    final done = await _c.deleteMonth();
    if (done) {
      _showUndoSnack('Month reset', _c.undoDeleteMonth);
    } else {
      AppSnackBar.show(
          message: "Couldn't reset the month", isSuccessful: false);
    }
  }

  // ── "Add" menu ───────────────────────────────────────────────────────────────
  static void addMenu() {
    _open(Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _grabber(),
        _title('Add to your budget'),
        SizedBox(height: 14.h),
        _menuRow(Icons.account_balance_wallet_rounded, 'Income source', () {
          Get.back();
          _editIncome();
        }),
        _menuRow(Icons.receipt_long_rounded, 'Bill / fixed expense', () {
          Get.back();
          editCategory(section: 'bill');
        }),
        _menuRow(Icons.category_rounded, 'Spending envelope', () {
          Get.back();
          editCategory(section: 'spending');
        }),
        _menuRow(Icons.savings_rounded, 'Savings goal', () {
          Get.back();
          editGoal();
        }),
        _menuRow(Icons.credit_card_rounded, 'Debt', () {
          Get.back();
          editDebt();
        }),
      ],
    ));
  }

  // ── small helpers ────────────────────────────────────────────────────────────
  static Widget _menuRow(IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: BudgetTheme.card,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Row(children: [
            Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                  color: BudgetTheme.red.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(11.r)),
              child: Icon(icon, color: BudgetTheme.red, size: 19),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(label,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: BudgetTheme.text)),
            ),
            Icon(Icons.chevron_right_rounded, color: BudgetTheme.muted),
          ]),
        ),
      );

  static Widget _toggleChip(String label, bool active, VoidCallback onTap) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              color: active ? BudgetTheme.red : BudgetTheme.card,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: Center(
              child: Text(label,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : BudgetTheme.text)),
            ),
          ),
        ),
      );

  static Widget _dangerButton(String label, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: BudgetTheme.red,
            side: BorderSide(color: BudgetTheme.red.withOpacity(0.4)),
            padding: EdgeInsets.symmetric(vertical: 13.h),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r)),
          ),
          child: Text(label,
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 14.sp, fontWeight: FontWeight.w700)),
        ),
      );

  /// A themed confirm/cancel dialog for destructive actions. Resolves to true
  /// only when the user taps the confirm button.
  static Future<bool> _confirmDelete({
    required String title,
    required String message,
    String confirmLabel = 'Delete',
  }) async {
    final res = await Get.dialog<bool>(
      Dialog(
        backgroundColor: BudgetTheme.bg,
        insetPadding: EdgeInsets.symmetric(horizontal: 32.w),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40.r,
                    height: 40.r,
                    decoration: BoxDecoration(
                        color: BudgetTheme.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12.r)),
                    child: Icon(Icons.warning_amber_rounded,
                        color: BudgetTheme.red, size: 22),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(title,
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            color: BudgetTheme.text)),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Text(message,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 13.sp,
                      height: 1.4,
                      color: BudgetTheme.muted)),
              SizedBox(height: 22.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BudgetTheme.text,
                        side: BorderSide(color: Colors.black.withOpacity(0.12)),
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r)),
                      ),
                      child: Text('Cancel',
                          style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 14.sp, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BudgetTheme.red,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r)),
                      ),
                      child: Text(confirmLabel,
                          style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 14.sp, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
    return res ?? false;
  }

  /// A snackbar with an Undo action, used after a reset so the wipe can be
  /// reverted with a single tap.
  static void _showUndoSnack(String message, Future<bool> Function() onUndo) {
    Get.rawSnackbar(
      messageText: Text(message,
          style: AppFonts.spaceGrotesk.copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white)),
      backgroundColor: BudgetTheme.text,
      borderRadius: 14.r,
      margin: EdgeInsets.all(14.w),
      duration: const Duration(seconds: 5),
      mainButton: TextButton(
        onPressed: () async {
          if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
          final restored = await onUndo();
          AppSnackBar.show(
            message: restored ? 'Month restored' : "Couldn't undo",
            isSuccessful: restored,
          );
        },
        child: Text('Undo',
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    const mm = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final m = (d.month >= 1 && d.month <= 12) ? mm[d.month - 1] : '';
    return '$m ${d.day}';
  }
}
