import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:spanx/core/const/app_icons.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_images.dart';
import 'package:spanx/core/const/app_size.dart';

import 'package:spanx/core/global_widgets/app_input.dart';
import 'package:spanx/core/global_widgets/app_loading.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';
import 'package:spanx/core/global_widgets/subpage_appbar_widget.dart';

import 'package:spanx/features/mybudget/controller/my_budget_controller.dart';
import '../model/my_budget_model.dart';

class MyBudgetScreen extends StatelessWidget {
  MyBudgetScreen({super.key});

  final MyBudgetController controller = Get.put(MyBudgetController());

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
        child: Obx(() {
          // ✅ Loading
          if (controller.myBudgetLoading.value) {
            return Center(child: loading());
          }

          final MyBudgetModel? data = controller.myBudgetModel.value;

          // ✅ No budget / API returned null
          if (data == null || data.id == null) {
            return _noBudgetUI(controller);
          }

          // ✅ Budget exists
          return _budgetUI(controller, data);
        }),
      ),
    );
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// NO BUDGET UI
Widget _noBudgetUI(MyBudgetController controller) {
  return SingleChildScrollView(
    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SubPageAppbarWidget(
          appbarTitle: "My Budget",
          onPressed: () => Get.back(),
        ),
        SizedBox(height: AppSizes.h(20)),
        _progressBackground(
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.w(12),
              vertical: AppSizes.h(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "No budget found",
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: AppSizes.sp(18),
                    fontWeight: FontWeight.w700,
                    color: AppColors.greyColor70,
                  ),
                ),
                SizedBox(height: AppSizes.h(8)),
                Text(
                  "Create your first budget to track income and expenses.",
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: AppSizes.sp(13),
                    fontWeight: FontWeight.w500,
                    color: AppColors.greyColor70,
                  ),
                ),
                SizedBox(height: AppSizes.h(16)),
                Obx(() {
                  return controller.addBudgetLoading.value
                      ? loading()
                      : CustomButtonWidget(
                    onTap: () => _openCreateBudgetDialog(controller),
                    buttonText: "Create Budget",
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// ─────────────────────────────────────────────────────────────────────────────
/// MAIN BUDGET UI (budget exists)
Widget _budgetUI(MyBudgetController controller, MyBudgetModel data) {
  return SingleChildScrollView(
    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // app bar
        SubPageAppbarWidget(
          appbarTitle: "My Budget",
          onPressed: () => Get.back(),
        ),
        SizedBox(height: AppSizes.h(20)),

        // budget card
        _progressBackground(_budgetCardWidget(controller)),
        SizedBox(height: AppSizes.h(20)),

        // income and expenses
        _progressBackground(_incomeExpenseCardWidget(data)),
        SizedBox(height: AppSizes.h(20)),

        // add income and add expenses
        Row(
          children: [
            Expanded(
              child: _progressBackground(
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSizes.h(10)),
                  child: _addNewTask('Add Income', () {
                    _openAddIncomeDialog(controller, data.id.toString());
                  }),
                ),
              ),
            ),
            SizedBox(width: AppSizes.w(20)),
            Expanded(
              child: _progressBackground(
                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSizes.h(10)),
                  child: _addNewTask('Add Expense', () {
                    _openAddExpenseDialog(controller, data.id.toString());
                  }),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: AppSizes.h(10)),

        // Tab row
        Obx(() {
          final tabIndex = controller.tabIndex.value;
          return Row(
            children: List.generate(controller.tabTitles.length, (index) {
              final isSelected = tabIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => controller.changeTab(index),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryColor
                          : AppColors.lightPinkColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      controller.tabTitles[index],
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.whiteColor
                            : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }),

        // Tab body
        Obx(() {
          final tab = controller.tabIndex.value;

          if (tab == 0) {
            final incomes = data.incomeSources ?? [];
            return ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: incomes.length,
              itemBuilder: (context, index) {
                final income = incomes[index];
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 5.h),
                  child: Container(
                    padding: EdgeInsets.all(5.h),
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              income.name ?? "",
                              style: AppFonts.spaceGrotesk.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                                color: AppColors.greyColor70,
                              ),
                            ),
                            SizedBox(height: AppSizes.h(5)),
                            Text(
                              '\$${income.amount ?? 0}',
                              style: AppFonts.spaceGrotesk.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                                color: AppColors.blackColor.withAlpha(90),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          // Expenses tab
          final expenses = data.expenseItems ?? [];
          return ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 5.h),
                child: Container(
                  padding: EdgeInsets.all(5.h),
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.name ?? "",
                            style: AppFonts.spaceGrotesk.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                              color: AppColors.greyColor70,
                            ),
                          ),
                          SizedBox(height: AppSizes.h(5)),
                          Text(
                            '\$${expense.totalAmount ?? 0}',
                            style: AppFonts.spaceGrotesk.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16.sp,
                              color: AppColors.blackColor.withAlpha(90),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ],
    ),
  );
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Dialogs

void _openCreateBudgetDialog(MyBudgetController controller) {
  Get.dialog(
    barrierDismissible: false,
    AlertDialog(
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Add Your Budget",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blackColor,
                ),
              ),
              GestureDetector(
                onTap: () => Get.back(),
                child: Icon(
                  Icons.clear,
                  size: 30,
                  color: AppColors.greyColor70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppInput(
            hint: "\$ 0.0",
            controller: controller.createBudgetTEC,
            textType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          Obx(() {
            return controller.addBudgetLoading.value
                ? loading()
                : CustomButtonWidget(
              onTap: () async {
                await controller.addBudget();
                // Optionally close after success:
                // Get.back();
              },
              buttonText: "Add",
            );
          }),
        ],
      ),
    ),
  );
}

void _openAddIncomeDialog(MyBudgetController controller, String budgetId) {
  Get.dialog(
    barrierDismissible: false,
    AlertDialog(
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Add Your Income",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blackColor,
                ),
              ),
              GestureDetector(
                onTap: () => Get.back(),
                child: Icon(
                  Icons.clear,
                  size: 30,
                  color: AppColors.greyColor70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppInput(
            hint: "Enter Income Name",
            controller: controller.incomeNameTEC,
          ),
          const SizedBox(height: 15),
          AppInput(
            hint: "\$ 0.0",
            controller: controller.incomeTEC,
            textType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          Obx(() {
            return controller.addIncomeLoading.value
                ? loading()
                : CustomButtonWidget(
              onTap: () async {
                await controller.addIncome(budgetId);
                // Optionally close after success:
                // Get.back();
              },
              buttonText: "Add",
            );
          }),
        ],
      ),
    ),
  );
}

void _openAddExpenseDialog(MyBudgetController controller, String budgetId) {
  Get.dialog(
    barrierDismissible: false,
    AlertDialog(
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Add Your Expense",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blackColor,
                ),
              ),
              GestureDetector(
                onTap: () => Get.back(),
                child: Icon(
                  Icons.clear,
                  size: 30,
                  color: AppColors.greyColor70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AppInput(
            hint: "Enter Expense Name",
            controller: controller.expenseNameTEC,
          ),
          const SizedBox(height: 15),
          AppInput(
            hint: "\$ 0.0",
            controller: controller.expenseTEC,
            textType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          Obx(() {
            return controller.addExpenseLoading.value
                ? loading()
                : CustomButtonWidget(
              onTap: () async {
                await controller.addExpense(budgetId);
                // Optionally close after success:
                // Get.back();
              },
              buttonText: "Add",
            );
          }),
        ],
      ),
    ),
  );
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Shared widgets

Widget _progressBackground(Widget widget) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: AppSizes.w(6),
      vertical: AppSizes.w(15),
    ),
    decoration: BoxDecoration(
      image: DecorationImage(
        image: AssetImage(AppImages.bg_profiles),
        fit: BoxFit.fitWidth,
      ),
      border: Border.all(color: AppColors.whiteColor),
      borderRadius: BorderRadius.circular(AppSizes.w(15)),
    ),
    child: widget,
  );
}

Widget _budgetCardWidget(MyBudgetController controller) {
  final data = controller.myBudgetModel.value; // can be null if you made it Rxn
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: AppSizes.w(10)),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Budget',
              style: AppFonts.spaceGrotesk.copyWith(
                color: AppColors.greyColor70,
                fontSize: AppSizes.sp(16),
                fontWeight: FontWeight.w500,
              ),
            ),
            InkWell(
              onTap: () => _openCreateBudgetDialog(controller),
              child: Image.asset(AppIcons.edit, height: AppSizes.h(25)),
            ),
          ],
        ),
        SizedBox(height: AppSizes.h(20)),
        Row(
          children: [
            Image.asset(AppIcons.budget, height: AppSizes.h(35)),
            SizedBox(width: AppSizes.w(10)),
            Text(
              '\$${data?.targetAmount ?? 0}',
              style: AppFonts.spaceGrotesk.copyWith(
                color: AppColors.greyColor70,
                fontSize: AppSizes.sp(19),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _incomeExpenseCardWidget(MyBudgetModel data) {
  // ✅ Safe math (no NaN/Infinity)
  final income = (data.totalIncome ?? 0).toDouble();
  final expense = (data.totalExpenseTarget ?? 0).toDouble();

  final percent = (income <= 0) ? 0.0 : (expense / income) * 100.0;
  final percentText = percent.isFinite ? percent.round() : 0;

  final progress = (income <= 0) ? 0.0 : (expense / income);
  final progressValue = progress.isFinite ? progress.clamp(0.0, 1.0) : 0.0;

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: AppSizes.w(10)),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Income',
                  style: AppFonts.spaceGrotesk.copyWith(
                    color: AppColors.greyColor70,
                    fontSize: AppSizes.sp(16),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '\$${data.totalIncome ?? 0}',
                  style: AppFonts.spaceGrotesk.copyWith(
                    color: AppColors.greyColor70,
                    fontSize: AppSizes.sp(19),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expenses',
                  style: AppFonts.spaceGrotesk.copyWith(
                    color: AppColors.greyColor70,
                    fontSize: AppSizes.sp(16),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '\$${data.totalExpenseTarget ?? 0}',
                  style: AppFonts.spaceGrotesk.copyWith(
                    color: AppColors.greyColor70,
                    fontSize: AppSizes.sp(19),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: AppSizes.h(20)),
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Expense Percentage according to Income',
                  style: AppFonts.spaceGrotesk.copyWith(
                    color: AppColors.greyColor70,
                    fontSize: AppSizes.sp(10),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$percentText%',
                  style: AppFonts.spaceGrotesk.copyWith(
                    color: AppColors.greyColor70,
                    fontSize: AppSizes.sp(10),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.h(5)),
            LinearProgressIndicator(
              backgroundColor: AppColors.whiteColor,
              value: progressValue,
              color: AppColors.maroonColor,
              borderRadius: BorderRadius.circular(AppSizes.w(15)),
              minHeight: AppSizes.h(8),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _addNewTask(String title, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: AppSizes.h(30),
          child: Image.asset(AppImages.add, fit: BoxFit.cover),
        ),
        SizedBox(width: AppSizes.w(10)),
        Text(
          title,
          style: AppFonts.spaceGrotesk.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: AppSizes.sp(15),
            color: AppColors.greyColor70,
          ),
        ),
      ],
    ),
  );
}
