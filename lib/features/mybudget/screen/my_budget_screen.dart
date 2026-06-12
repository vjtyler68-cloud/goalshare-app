import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_input.dart';
import 'package:spanx/core/global_widgets/app_loading.dart';

import 'package:spanx/features/mybudget/controller/my_budget_controller.dart';
import '../model/my_budget_model.dart';

const _kRed   = Color(0xffE84040);
const _kRedDk = Color(0xff9B1414);
const _kBg    = Color(0xffF6F4F2);
const _kCard  = Color(0xffFFFFFF);
const _kText  = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);
const _kGreen = Color(0xff22C55E);
const _kGreenDk = Color(0xff16A34A);

class MyBudgetScreen extends StatelessWidget {
  MyBudgetScreen({super.key});

  final MyBudgetController controller = Get.put(MyBudgetController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kRed, _kRedDk],
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
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: Get.back,
                      child: Container(
                        width: 38.r, height: 38.r,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.2)),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Financial Overview', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white70, fontSize: 12.sp)),
                        Text('My Budget', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (controller.myBudgetLoading.value) {
                return Center(child: loading());
              }
              final data = controller.myBudgetModel.value;
              if (data == null || data.id == null) {
                return _NoBudgetBody(controller: controller);
              }
              return _BudgetBody(controller: controller, data: data);
            }),
          ),
        ],
      ),
    );
  }
}

// ── No Budget ─────────────────────────────────────────────────────────────────

class _NoBudgetBody extends StatelessWidget {
  final MyBudgetController controller;
  const _NoBudgetBody({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(28.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80.r, height: 80.r,
              decoration: BoxDecoration(color: _kRed.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.account_balance_wallet_outlined, color: _kRed, size: 40),
            ),
            SizedBox(height: 20.h),
            Text('No Budget Yet', style: AppFonts.spaceGrotesk.copyWith(fontSize: 22.sp, fontWeight: FontWeight.w800, color: _kText)),
            SizedBox(height: 8.h),
            Text('Create your first budget to start tracking your income and expenses like a pro.', style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, color: _kMuted, height: 1.6), textAlign: TextAlign.center),
            SizedBox(height: 28.h),
            Obx(() => controller.addBudgetLoading.value
                ? loading()
                : GestureDetector(
                    onTap: () => _openCreateBudgetDialog(controller),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 40.w),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_kRed, _kRedDk]),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [BoxShadow(color: _kRed.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 5))],
                      ),
                      child: Text('Create Budget', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w700)),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

// ── Budget Body ───────────────────────────────────────────────────────────────

class _BudgetBody extends StatelessWidget {
  final MyBudgetController controller;
  final MyBudgetModel data;
  const _BudgetBody({required this.controller, required this.data});

  @override
  Widget build(BuildContext context) {
    final income = (data.totalIncome ?? 0).toDouble();
    final expense = (data.totalExpenseTarget ?? 0).toDouble();
    final budget = (data.targetAmount ?? 0).toDouble();
    final remaining = budget - expense;
    final savings = income - expense;
    final expensePercent = income > 0 ? (expense / income).clamp(0.0, 1.0) : 0.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4.h),

          // ── Summary card ────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xff1E293B), Color(0xff0F172A)]),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 16, offset: const Offset(0, 4))],
            ),
            padding: EdgeInsets.all(20.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Budget', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white54, fontSize: 12.sp)),
                    GestureDetector(
                      onTap: () => _openCreateBudgetDialog(controller),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(8.r)),
                        child: Row(children: [
                          const Icon(Icons.edit, color: Colors.white54, size: 12),
                          SizedBox(width: 4.w),
                          Text('Edit', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white54, fontSize: 11.sp)),
                        ]),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text('\$${_fmt(budget)}', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 32.sp, fontWeight: FontWeight.w800)),
                SizedBox(height: 16.h),
                // Progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Spent', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white54, fontSize: 11.sp)),
                      Text('${(expensePercent * 100).toStringAsFixed(0)}% used', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white54, fontSize: 11.sp)),
                    ]),
                    SizedBox(height: 6.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 8,
                        child: LinearProgressIndicator(
                          value: expensePercent,
                          backgroundColor: Colors.white.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(expensePercent > 0.85 ? Colors.orange : _kGreen),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(child: _SummaryChip(label: 'Remaining', amount: remaining, positive: remaining >= 0)),
                    SizedBox(width: 10.w),
                    Expanded(child: _SummaryChip(label: 'Net Savings', amount: savings, positive: savings >= 0)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // ── Income / Expense split ───────────────────────────────────────
          Row(
            children: [
              Expanded(child: _StatCard(label: 'Total Income', amount: income, color: _kGreen, icon: Icons.arrow_downward_rounded)),
              SizedBox(width: 10.w),
              Expanded(child: _StatCard(label: 'Total Expenses', amount: expense, color: _kRed, icon: Icons.arrow_upward_rounded)),
            ],
          ),
          SizedBox(height: 20.h),

          // ── Action buttons ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(child: _ActionBtn(label: 'Add Income', icon: Icons.add_circle_outline, color: _kGreen, onTap: () => _openAddIncomeDialog(controller, data.id.toString()))),
              SizedBox(width: 10.w),
              Expanded(child: _ActionBtn(label: 'Add Expense', icon: Icons.remove_circle_outline, color: _kRed, onTap: () => _openAddExpenseDialog(controller, data.id.toString()))),
            ],
          ),
          SizedBox(height: 20.h),

          // ── Tab switcher ─────────────────────────────────────────────────
          Obx(() {
            final tab = controller.tabIndex.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: List.generate(controller.tabTitles.length, (i) {
                      final sel = tab == i;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => controller.changeTab(i),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            decoration: BoxDecoration(
                              gradient: sel ? const LinearGradient(colors: [_kRed, _kRedDk]) : null,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            alignment: Alignment.center,
                            child: Text(controller.tabTitles[i], style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 13.sp, fontWeight: FontWeight.w700,
                              color: sel ? Colors.white : _kMuted,
                            )),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                SizedBox(height: 12.h),
                if (tab == 0) _buildIncomeList(data.incomeSources ?? []),
                if (tab == 1) _buildExpenseList(data.expenseItems ?? []),
              ],
            );
          }),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildIncomeList(List<dynamic> items) {
    if (items.isEmpty) {
      return _EmptyState(label: 'No income sources yet.\nTap "Add Income" to get started.');
    }
    return Column(children: items.map((income) => _TransactionTile(
      name: income.name ?? '',
      amount: (income.amount ?? 0).toDouble(),
      isIncome: true,
    )).toList());
  }

  Widget _buildExpenseList(List<dynamic> items) {
    if (items.isEmpty) {
      return _EmptyState(label: 'No expenses yet.\nTap "Add Expense" to track spending.');
    }
    return Column(children: items.map((expense) => _TransactionTile(
      name: expense.name ?? '',
      amount: (expense.totalAmount ?? 0).toDouble(),
      isIncome: false,
    )).toList());
  }
}

String _fmt(double v) {
  if (v == v.truncateToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(2);
}

// ── Small widgets ─────────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  final double amount;
  final bool positive;
  const _SummaryChip({required this.label, required this.amount, required this.positive});

  @override
  Widget build(BuildContext context) {
    final color = positive ? _kGreen : Colors.orange;
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12.r)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AppFonts.spaceGrotesk.copyWith(color: Colors.white54, fontSize: 10.sp)),
        SizedBox(height: 2.h),
        Text('\$${_fmt(amount)}', style: AppFonts.spaceGrotesk.copyWith(color: color, fontSize: 15.sp, fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  const _StatCard({required this.label, required this.amount, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 38.r, height: 38.r,
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 18),
        ),
        SizedBox(width: 10.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppFonts.spaceGrotesk.copyWith(fontSize: 10.sp, color: _kMuted)),
          Text('\$${_fmt(amount)}', style: AppFonts.spaceGrotesk.copyWith(fontSize: 15.sp, fontWeight: FontWeight.w800, color: _kText)),
        ])),
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 18),
          SizedBox(width: 6.w),
          Text(label, style: AppFonts.spaceGrotesk.copyWith(color: color, fontSize: 13.sp, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final String name;
  final double amount;
  final bool isIncome;
  const _TransactionTile({required this.name, required this.amount, required this.isIncome});

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? _kGreen : _kRed;
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 40.r, height: 40.r,
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: color, size: 18),
        ),
        SizedBox(width: 12.w),
        Expanded(child: Text(name, style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, fontWeight: FontWeight.w700, color: _kText))),
        Text('${isIncome ? '+' : '-'}\$${_fmt(amount)}', style: AppFonts.spaceGrotesk.copyWith(fontSize: 15.sp, fontWeight: FontWeight.w800, color: color)),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(color: _kCard, borderRadius: BorderRadius.circular(14.r)),
      child: Center(child: Text(label, style: AppFonts.spaceGrotesk.copyWith(color: _kMuted, fontSize: 13.sp, height: 1.6), textAlign: TextAlign.center)),
    );
  }
}

// ── Dialogs ───────────────────────────────────────────────────────────────────

void _openCreateBudgetDialog(MyBudgetController controller) {
  Get.dialog(barrierDismissible: false, _BudgetDialog(
    title: 'Set Budget Amount',
    fields: [_DialogField(hint: '\$ 0.0', controller: controller.createBudgetTEC, keyboardType: TextInputType.number, label: 'Monthly Budget Target')],
    loadingObs: controller.addBudgetLoading,
    onSave: () async { await controller.addBudget(); },
  ));
}

void _openAddIncomeDialog(MyBudgetController controller, String budgetId) {
  Get.dialog(barrierDismissible: false, _BudgetDialog(
    title: 'Add Income Source',
    fields: [
      _DialogField(hint: 'e.g. Salary, Freelance...', controller: controller.incomeNameTEC, label: 'Source Name'),
      _DialogField(hint: '\$ 0.0', controller: controller.incomeTEC, keyboardType: TextInputType.number, label: 'Amount'),
    ],
    loadingObs: controller.addIncomeLoading,
    onSave: () async { await controller.addIncome(budgetId); },
  ));
}

void _openAddExpenseDialog(MyBudgetController controller, String budgetId) {
  Get.dialog(barrierDismissible: false, _BudgetDialog(
    title: 'Add Expense',
    fields: [
      _DialogField(hint: 'e.g. Rent, Groceries...', controller: controller.expenseNameTEC, label: 'Expense Name'),
      _DialogField(hint: '\$ 0.0', controller: controller.expenseTEC, keyboardType: TextInputType.number, label: 'Amount'),
    ],
    loadingObs: controller.addExpenseLoading,
    onSave: () async { await controller.addExpense(budgetId); },
  ));
}

class _DialogField {
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String label;
  const _DialogField({required this.hint, required this.controller, this.keyboardType = TextInputType.text, required this.label});
}

class _BudgetDialog extends StatelessWidget {
  final String title;
  final List<_DialogField> fields;
  final RxBool loadingObs;
  final Future<void> Function() onSave;
  const _BudgetDialog({required this.title, required this.fields, required this.loadingObs, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      contentPadding: EdgeInsets.all(20.r),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(title, style: AppFonts.spaceGrotesk.copyWith(fontSize: 17.sp, fontWeight: FontWeight.w800, color: _kText)),
            GestureDetector(onTap: Get.back, child: const Icon(Icons.close, size: 22, color: _kMuted)),
          ]),
          ...fields.map((f) => Padding(
            padding: EdgeInsets.only(top: 14.h),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f.label, style: AppFonts.spaceGrotesk.copyWith(fontSize: 12.sp, fontWeight: FontWeight.w700, color: _kText)),
              SizedBox(height: 6.h),
              AppInput(hint: f.hint, controller: f.controller, textType: f.keyboardType),
            ]),
          )),
          SizedBox(height: 20.h),
          Obx(() => loadingObs.value
              ? Center(child: loading())
              : GestureDetector(
                  onTap: onSave,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_kRed, _kRedDk]),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    alignment: Alignment.center,
                    child: Text('Save', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w700)),
                  ),
                )),
        ],
      ),
    );
  }
}
