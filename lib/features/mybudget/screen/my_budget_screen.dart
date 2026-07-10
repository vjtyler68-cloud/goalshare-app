import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:spanx/core/const/app_fonts.dart';

import 'package:spanx/features/mybudget/controller/my_budget_controller.dart';
import '../data/budget_models.dart';
import '../widgets/budget_theme.dart';
import '../widgets/budget_widgets.dart';
import '../widgets/budget_sheets.dart';

/// Local-first envelope budget: fun, fast to log, and accurate to the cent.
class MyBudgetScreen extends StatelessWidget {
  MyBudgetScreen({super.key});

  final MyBudgetController controller = Get.put(MyBudgetController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BudgetTheme.bg,
      floatingActionButton: Obx(() {
        if (!controller.hasBudget) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          onPressed: BudgetSheets.quickLog,
          backgroundColor: BudgetTheme.red,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text('Log spend',
              style: AppFonts.spaceGrotesk.copyWith(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800)),
        );
      }),
      body: Column(
        children: [
          _header(),
          Expanded(
            child: Obx(() {
              if (!controller.isReady.value) {
                return const Center(
                    child: CircularProgressIndicator(color: BudgetTheme.red));
              }
              if (!controller.hasBudget) return _emptyState();
              return _dashboard();
            }),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _header() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [BudgetTheme.red, BudgetTheme.redDk],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 18.h),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: Get.back,
                    child: Container(
                      width: 38.r,
                      height: 38.r,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2)),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Financial Overview',
                            style: AppFonts.spaceGrotesk.copyWith(
                                color: Colors.white70, fontSize: 12.sp)),
                        Text('My Budget',
                            style: AppFonts.spaceGrotesk.copyWith(
                                color: Colors.white,
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  Obx(() => controller.hasBudget
                      ? GestureDetector(
                          onTap: BudgetSheets.addMenu,
                          child: Container(
                            width: 38.r,
                            height: 38.r,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.2)),
                            child: const Icon(Icons.add_rounded,
                                color: Colors.white, size: 20),
                          ),
                        )
                      : const SizedBox.shrink()),
                ],
              ),
              SizedBox(height: 14.h),
              _monthSwitcher(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _monthSwitcher() {
    return Obx(() {
      final c = controller.cursor.value;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _navArrow(Icons.chevron_left_rounded, controller.goToPrevMonth),
          SizedBox(width: 18.w),
          Text('${monthName(c.month)} ${c.year}',
              style: AppFonts.spaceGrotesk.copyWith(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700)),
          SizedBox(width: 18.w),
          _navArrow(Icons.chevron_right_rounded, controller.goToNextMonth),
        ],
      );
    });
  }

  Widget _navArrow(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30.r,
          height: 30.r,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: Colors.white.withOpacity(0.15)),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );

  // ── Empty state ───────────────────────────────────────────────────────────────
  Widget _emptyState() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24.w, 40.h, 24.w, 40.h),
      child: Column(
        children: [
          Container(
            width: 88.r,
            height: 88.r,
            decoration: BoxDecoration(
                color: BudgetTheme.red.withOpacity(0.10),
                shape: BoxShape.circle),
            child: Icon(Icons.account_balance_wallet_rounded,
                color: BudgetTheme.red, size: 42),
          ),
          SizedBox(height: 20.h),
          Text('Build your budget',
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: BudgetTheme.text)),
          SizedBox(height: 8.h),
          Text(
              'Set up income, savings goals, debt payoff, bills and weekly spending envelopes — then log every dollar to the cent.',
              textAlign: TextAlign.center,
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 13.sp, color: BudgetTheme.muted, height: 1.5)),
          SizedBox(height: 28.h),
          _bigButton('Use the starter template', Icons.auto_awesome_rounded,
              controller.createPreset, filled: true),
          SizedBox(height: 12.h),
          if (controller.canCarryForward) ...[
            _bigButton('Copy last month', Icons.content_copy_rounded,
                controller.startFromPrevious, filled: false),
            SizedBox(height: 12.h),
          ],
          _bigButton('Start from scratch', Icons.edit_rounded,
              controller.createBlank, filled: false),
        ],
      ),
    );
  }

  Widget _bigButton(String label, IconData icon, VoidCallback onTap,
      {required bool filled}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon,
            size: 18, color: filled ? Colors.white : BudgetTheme.red),
        label: Text(label,
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 15.sp,
                fontWeight: FontWeight.w800,
                color: filled ? Colors.white : BudgetTheme.red)),
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? BudgetTheme.red : BudgetTheme.card,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 15.h),
          side: filled
              ? null
              : BorderSide(color: BudgetTheme.red.withOpacity(0.4)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
        ),
      ),
    );
  }

  // ── Dashboard ──────────────────────────────────────────────────────────────────
  Widget _dashboard() {
    return Obx(() {
      final m = controller.month.value;
      if (m == null) return _emptyState();

      final weekly = m.spending.where((c) => c.isWeekly).toList();
      final otherSpending = m.spending.where((c) => !c.isWeekly).toList();
      final bills = m.bills;

      return ListView(
        padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 110.h),
        children: [
          _hero(m),
          SizedBox(height: 22.h),

          // Goals
          if (m.goals.isNotEmpty) ...[
            BudgetSectionHeader(
                title: 'Savings goals',
                actionLabel: 'Add',
                onAction: () => BudgetSheets.editGoal()),
            SizedBox(
              height: 132.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: m.goals
                    .map((g) => GoalCard(
                        goal: g, onTap: () => BudgetSheets.contribute(g)))
                    .toList(),
              ),
            ),
            SizedBox(height: 22.h),
          ],

          // Debt
          if (m.debts.isNotEmpty) ...[
            BudgetSectionHeader(
                title: 'Debt payoff',
                actionLabel: 'Add',
                onAction: () => BudgetSheets.editDebt()),
            ...m.debts.map((d) =>
                DebtCard(debt: d, onTap: () => BudgetSheets.payDebt(d))),
            SizedBox(height: 22.h),
          ],

          // Weekly spending
          if (weekly.isNotEmpty) ...[
            BudgetSectionHeader(
                title: 'Weekly spending',
                actionLabel: 'Add',
                onAction: () => BudgetSheets.editCategory(section: 'spending')),
            ...weekly.map((c) => WeeklyEnvelopeCard(
                  category: c,
                  onTapWeek: (w) => BudgetSheets.logSpend(c, week: w),
                  onTapHeader: () => BudgetSheets.categoryDetail(c.id),
                )),
            SizedBox(height: 22.h),
          ],

          // Other envelopes
          if (otherSpending.isNotEmpty) ...[
            BudgetSectionHeader(
                title: 'Spending envelopes',
                actionLabel: 'Add',
                onAction: () => BudgetSheets.editCategory(section: 'spending')),
            ...otherSpending.map((c) => EnvelopeTile(
                category: c,
                onTap: () => BudgetSheets.categoryDetail(c.id))),
            SizedBox(height: 22.h),
          ],

          // Bills
          BudgetSectionHeader(
              title: 'Monthly bills',
              actionLabel: 'Add',
              onAction: () => BudgetSheets.editCategory(section: 'bill')),
          if (bills.isEmpty)
            _hint('No bills yet — tap Add to track fixed expenses.')
          else
            ...bills.map((c) => EnvelopeTile(
                category: c, onTap: () => BudgetSheets.categoryDetail(c.id))),

          SizedBox(height: 24.h),
          Center(
            child: Text('Every dollar tracked to the cent 🎯',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 11.sp, color: BudgetTheme.muted)),
          ),
        ],
      );
    });
  }

  Widget _hint(String text) => Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: BudgetTheme.card,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Text(text,
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 12.sp, color: BudgetTheme.muted)),
      );

  // ── Hero summary card ────────────────────────────────────────────────────────
  Widget _hero(BudgetMonth m) {
    final leftover = m.leftoverCents;
    final overspent = leftover < 0;
    final streak = controller.logStreak;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [BudgetTheme.ink2, BudgetTheme.ink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(overspent ? 'Overspent' : 'Left to spend',
                  style: AppFonts.spaceGrotesk.copyWith(
                      color: Colors.white70, fontSize: 13.sp)),
              const Spacer(),
              _statusChip(),
            ],
          ),
          SizedBox(height: 6.h),
          Text(fmtCents(leftover.abs(), alwaysCents: true),
              style: AppFonts.spaceGrotesk.copyWith(
                  color: overspent ? const Color(0xffFCA5A5) : Colors.white,
                  fontSize: 34.sp,
                  fontWeight: FontWeight.w800)),
          SizedBox(height: 16.h),
          BudgetBar(
            ratio: m.spentProgress,
            color: m.spentProgress > 1.0
                ? const Color(0xffFCA5A5)
                : BudgetTheme.green,
            height: 9,
          ),
          SizedBox(height: 6.h),
          Text(
              '${fmtCents(m.totalSpentCents)} spent of ${fmtCents(m.totalBudgetedCents)} budgeted',
              style: AppFonts.spaceGrotesk.copyWith(
                  color: Colors.white60, fontSize: 11.sp)),
          SizedBox(height: 18.h),
          Row(
            children: [
              _heroStat('Income', m.totalIncomeCents, Colors.white,
                  onTap: BudgetSheets.manageIncome),
              _heroDivider(),
              _heroStat('Saved + Debt', m.totalAllocatedCents,
                  const Color(0xff86EFAC)),
              _heroDivider(),
              _heroStat('Spent', m.totalSpentCents, const Color(0xffFDBA74)),
            ],
          ),
          if (streak > 1) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text('🔥 $streak-day logging streak',
                  style: AppFonts.spaceGrotesk.copyWith(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusChip() {
    final label = controller.statusLabel;
    Color c;
    if (label == 'Over budget') {
      c = const Color(0xffFCA5A5);
    } else if (label == 'Cutting it close') {
      c = const Color(0xffFDE68A);
    } else {
      c = const Color(0xff86EFAC);
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: c.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(label,
          style: AppFonts.spaceGrotesk.copyWith(
              color: c, fontSize: 11.sp, fontWeight: FontWeight.w700)),
    );
  }

  Widget _heroStat(String label, int cents, Color color, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.spaceGrotesk.copyWith(
                          color: Colors.white54, fontSize: 10.sp)),
                ),
                if (onTap != null) ...[
                  SizedBox(width: 3.w),
                  Icon(Icons.edit_rounded, size: 11, color: Colors.white38),
                ],
              ],
            ),
            SizedBox(height: 3.h),
            Text(fmtCentsCompact(cents),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.spaceGrotesk.copyWith(
                    color: color,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _heroDivider() => Container(
        width: 1,
        height: 30.h,
        margin: EdgeInsets.symmetric(horizontal: 10.w),
        color: Colors.white.withOpacity(0.12),
      );
}
