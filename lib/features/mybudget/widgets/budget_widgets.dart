import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:spanx/core/const/app_fonts.dart';

import '../data/budget_models.dart';
import 'budget_theme.dart';

// ── Progress bar ─────────────────────────────────────────────────────────────

class BudgetBar extends StatelessWidget {
  final double ratio;
  final Color color;
  final double height;
  const BudgetBar({super.key, required this.ratio, required this.color, this.height = 8});

  @override
  Widget build(BuildContext context) {
    final double r = ratio.isNaN ? 0.0 : ratio.clamp(0.0, 1.0).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(height: height, color: color.withOpacity(0.14)),
          FractionallySizedBox(
            widthFactor: r,
            child: Container(height: height, color: color),
          ),
        ],
      ),
    );
  }
}

// ── Section header ───────────────────────────────────────────────────────────

class BudgetSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;
  const BudgetSectionHeader(
      {super.key, required this.title, this.actionLabel, this.onAction, this.actionIcon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h, top: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: BudgetTheme.text)),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Row(children: [
                Icon(actionIcon ?? Icons.add_rounded, size: 16, color: BudgetTheme.red),
                SizedBox(width: 3.w),
                Text(actionLabel!,
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: BudgetTheme.red)),
              ]),
            ),
        ],
      ),
    );
  }
}

// ── Flat envelope tile ───────────────────────────────────────────────────────

class EnvelopeTile extends StatelessWidget {
  final BudgetCategory category;
  final VoidCallback onTap;
  const EnvelopeTile({super.key, required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);
    final ratio = category.progress;
    final fill = BudgetTheme.fillColor(ratio);
    final remaining = category.remainingCents;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: BudgetTheme.card,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12.r)),
                  child: Icon(budgetIcon(category.iconKey), color: color, size: 20),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: BudgetTheme.text)),
                      SizedBox(height: 2.h),
                      Text('${fmtCents(category.spentCents)} of ${fmtCents(category.totalBudgetCents)}',
                          style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 11.sp, color: BudgetTheme.muted)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(remaining < 0 ? 'Over' : 'Left',
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 10.sp, color: BudgetTheme.muted)),
                    Text(fmtCents(remaining.abs()),
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: remaining < 0 ? BudgetTheme.red : BudgetTheme.greenDk)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10.h),
            BudgetBar(ratio: ratio, color: fill),
          ],
        ),
      ),
    );
  }
}

// ── Weekly envelope card ─────────────────────────────────────────────────────

class WeeklyEnvelopeCard extends StatelessWidget {
  final BudgetCategory category;
  final void Function(int week) onTapWeek;
  final VoidCallback onTapHeader;
  const WeeklyEnvelopeCard(
      {super.key,
      required this.category,
      required this.onTapWeek,
      required this.onTapHeader});

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);
    final remaining = category.remainingCents;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: BudgetTheme.card,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTapHeader,
            child: Row(
              children: [
                Container(
                  width: 38.r,
                  height: 38.r,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(11.r)),
                  child: Icon(budgetIcon(category.iconKey), color: color, size: 19),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: BudgetTheme.text)),
                      Text('Weekly envelopes',
                          style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 10.sp, color: BudgetTheme.muted)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(remaining < 0 ? 'Over' : 'Left',
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 10.sp, color: BudgetTheme.muted)),
                    Text(fmtCents(remaining.abs()),
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: remaining < 0 ? BudgetTheme.red : BudgetTheme.greenDk)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: List.generate(4, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: _WeekColumn(
                    week: i,
                    spent: category.spentForWeek(i),
                    limit: category.budgetForWeek(i),
                    onTap: () => onTapWeek(i),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _WeekColumn extends StatelessWidget {
  final int week;
  final int spent;
  final int limit;
  final VoidCallback onTap;
  const _WeekColumn(
      {required this.week, required this.spent, required this.limit, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final double ratio = limit <= 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0).toDouble();
    final remaining = limit - spent;
    final fill = BudgetTheme.fillColor(limit <= 0 ? 0.0 : spent / limit);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(fmtCentsCompact(remaining),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                  color: remaining < 0 ? BudgetTheme.red : BudgetTheme.muted)),
          SizedBox(height: 5.h),
          Container(
            height: 60.h,
            decoration: BoxDecoration(
              color: fill.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: ratio == 0 ? 0.02 : ratio,
                child: Container(
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 5.h),
          Text('W${week + 1}',
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  color: BudgetTheme.text)),
        ],
      ),
    );
  }
}

// ── Goal card ────────────────────────────────────────────────────────────────

class GoalCard extends StatelessWidget {
  final BudgetGoal goal;
  final VoidCallback onTap;
  const GoalCard({super.key, required this.goal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(goal.colorValue);
    final double ratio = goal.progress.clamp(0.0, 1.0).toDouble();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150.w,
        margin: EdgeInsets.only(right: 12.w),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: BudgetTheme.card,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34.r,
                  height: 34.r,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10.r)),
                  child: Icon(budgetIcon(goal.iconKey), color: color, size: 17),
                ),
                const Spacer(),
                SizedBox(
                  width: 34.r,
                  height: 34.r,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 34.r,
                        height: 34.r,
                        child: CircularProgressIndicator(
                          value: ratio,
                          strokeWidth: 4,
                          backgroundColor: color.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      Text('${(ratio * 100).round()}',
                          style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w800,
                              color: BudgetTheme.text)),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(goal.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: BudgetTheme.text)),
            SizedBox(height: 2.h),
            Text(fmtCents(goal.savedCents),
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 16.sp, fontWeight: FontWeight.w800, color: color)),
            Text('of ${fmtCents(goal.targetCents)}',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 10.sp, color: BudgetTheme.muted)),
          ],
        ),
      ),
    );
  }
}

// ── Debt card ────────────────────────────────────────────────────────────────

class DebtCard extends StatelessWidget {
  final BudgetDebt debt;
  final VoidCallback onTap;
  const DebtCard({super.key, required this.debt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(debt.colorValue);
    final double ratio = debt.progress.clamp(0.0, 1.0).toDouble();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: BudgetTheme.card,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12.r)),
                  child: Icon(budgetIcon(debt.iconKey), color: color, size: 20),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(debt.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: BudgetTheme.text)),
                      Text(debt.isPaidOff
                          ? 'Paid off! 🎉'
                          : '${fmtCents(debt.remainingCents)} left',
                          style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: debt.isPaidOff ? BudgetTheme.greenDk : BudgetTheme.muted)),
                    ],
                  ),
                ),
                Text('${(ratio * 100).round()}%',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                        color: color)),
              ],
            ),
            SizedBox(height: 10.h),
            BudgetBar(ratio: ratio, color: debt.isPaidOff ? BudgetTheme.green : color),
            SizedBox(height: 6.h),
            Text('${fmtCents(debt.paidCents)} paid of ${fmtCents(debt.startingBalanceCents)}',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 10.sp, color: BudgetTheme.muted)),
          ],
        ),
      ),
    );
  }
}
