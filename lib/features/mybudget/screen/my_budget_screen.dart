import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_icons.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/subpage_appbar_widget.dart';
import 'package:spanx/features/mybudget/controller/my_budget_controller.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/const/app_fonts.dart';
import '../../../core/const/app_images.dart';
import '../../../core/const/app_size.dart';

class MyBudgetScreen extends StatelessWidget {
  MyBudgetScreen({super.key});

  final MyBudgetController myBudgetController = Get.put(MyBudgetController());

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.w(20),
            vertical: AppSizes.h(30),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // app bar
              SubPageAppbarWidget(
                appbarTitle: "My Budget",
                onPressed: () {
                  Get.back();
                },
              ),
              SizedBox(height: AppSizes.h(20)),
              // drop down
              IntrinsicWidth(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    vertical: AppSizes.h(10),
                    horizontal: AppSizes.w(10),
                  ),
                  // width: AppSizes.w(110),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(AppSizes.w(10)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'This Month',
                        style: AppFonts.spaceGrotesk.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: AppSizes.sp(15),
                          color: AppColors.whiteColor,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: AppSizes.h(25),
                        color: AppColors.whiteColor,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSizes.h(20)),

              // budget card
              _progressBackground(_budgetCardWidget()),
              SizedBox(height: AppSizes.h(20)),

              // income and expenses
              _progressBackground(_incomeExpenseCardWidget()),
              SizedBox(height: AppSizes.h(20)),

              // add income and add expenses
              Row(
                children: [
                  Expanded(
                    child: _progressBackground(
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSizes.h(10)),
                        child: _addNewTask('Add Income', () {}),
                      ),
                    ),
                  ),
                  SizedBox(width: AppSizes.w(20)),
                  Expanded(
                    child: _progressBackground(
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSizes.h(10)),
                        child: _addNewTask('Add Expense', () {}),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.h(20)),

              // expenses
              Text(
                'Expenses',
                style: AppFonts.spaceGrotesk.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: AppSizes.sp(20),
                  color: AppColors.greyColor70,
                ),
              ),
              SizedBox(height: AppSizes.h(20)),
              ...List.generate(5, (index) {
                return Padding(
                  padding:  EdgeInsets.symmetric(vertical: 5.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Insurance name and fee
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Life/Car insurance',
                            style: AppFonts.spaceGrotesk.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: AppSizes.sp(16),
                              color: AppColors.greyColor70,
                            ),
                          ),
                          SizedBox(height: AppSizes.h(5)),
                          Text(
                            '\$100',
                            style: AppFonts.spaceGrotesk.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: AppSizes.sp(16),
                              color: AppColors.blackColor.withAlpha(90),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: AppColors.blackColor),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: () {},
                                  icon: Icon(Icons.remove),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                ),
                                Text(
                                  '\$25',
                                  style: AppFonts.spaceGrotesk.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: AppSizes.sp(16),
                                    color: AppColors.greyColor70,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {},
                                  icon: Icon(Icons.add),
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                          Obx(() {
                            return Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: myBudgetController.isSwitched.value,
                                onChanged: myBudgetController.toggleSwitch,
                                activeThumbColor: AppColors.primaryColor,
                                inactiveThumbColor: AppColors.greyColor70,
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                );
              })
            ],
          ),
        ),
      ),
    );
  }
}

// this widget will be used for keeping same background
Widget _progressBackground(Widget widget) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: AppSizes.w(6),
      vertical: AppSizes.w(15),
    ),
    // width: AppSizes.w(220),
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

// card for budget card
Widget _budgetCardWidget() {
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
              onTap: () {},
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
              '\$2000 ',
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

// card for income and expenses card
Widget _incomeExpenseCardWidget() {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: AppSizes.w(10)),
    child: Column(
      children: [
        // text and money
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
                  '\$3200 ',
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
                  '\$1500',
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

        // linear bar
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '48%',
              style: AppFonts.spaceGrotesk.copyWith(
                color: AppColors.greyColor70,
                fontSize: AppSizes.sp(10),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSizes.h(5)),
            LinearProgressIndicator(
              backgroundColor: AppColors.whiteColor,
              value: 48 / 100,
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

// this is add income and add expense card
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
        // Image.asset(AppImages.add),
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
