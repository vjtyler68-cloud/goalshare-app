import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_icons.dart';
import 'package:spanx/core/global_widgets/app_input.dart';
import 'package:spanx/core/global_widgets/app_loading.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';
import 'package:spanx/core/global_widgets/subpage_appbar_widget.dart';
import 'package:spanx/features/mybudget/controller/my_budget_controller.dart';
import '../../../core/const/app_colors.dart';
import '../../../core/const/app_fonts.dart';
import '../../../core/const/app_images.dart';
import '../../../core/const/app_size.dart';
import '../model/my_budget_model.dart';

class MyBudgetScreen extends StatelessWidget {
  MyBudgetScreen({super.key});

  final MyBudgetController controller = Get.put(MyBudgetController());

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
        child: Obx(() {
          if (controller.myBudgetLoading.value) {
            return Center(child: loading());
          } else {
            final data = controller.myBudgetModel.value;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
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
                  // IntrinsicWidth(
                  //   child: Container(
                  //     padding: EdgeInsets.symmetric(
                  //       vertical: AppSizes.h(10),
                  //       horizontal: AppSizes.w(10),
                  //     ),
                  //     // width: AppSizes.w(110),
                  //     decoration: BoxDecoration(
                  //       color: AppColors.primaryColor,
                  //       borderRadius: BorderRadius.circular(AppSizes.w(10)),
                  //     ),
                  //     child: Row(
                  //       mainAxisAlignment: MainAxisAlignment.center,
                  //       children: [
                  //         Text(
                  //           'This Month',
                  //           style: AppFonts.spaceGrotesk.copyWith(
                  //             fontWeight: FontWeight.w700,
                  //             fontSize: AppSizes.sp(15),
                  //             color: AppColors.whiteColor,
                  //           ),
                  //         ),
                  //         Icon(
                  //           Icons.keyboard_arrow_down_rounded,
                  //           size: AppSizes.h(25),
                  //           color: AppColors.whiteColor,
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  // SizedBox(height: AppSizes.h(20)),

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
                            padding: EdgeInsets.symmetric(
                              vertical: AppSizes.h(10),
                            ),
                            child: _addNewTask('Add Income', () {
                              Get.dialog(
                                barrierDismissible: false,
                                AlertDialog(
                                  scrollable: true,
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
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

                                      SizedBox(height: 20),
                                      AppInput(
                                        hint: "Enter Income Name",
                                        controller: controller.incomeNameTEC,
                                      ),
                                      SizedBox(height: 15),
                                      AppInput(
                                        hint: "\$ 0.0",
                                        controller: controller.incomeTEC,
                                        textType: TextInputType.number,
                                      ),
                                      SizedBox(height: 20),
                                      Obx(() {
                                        return controller.addIncomeLoading.value
                                            ? loading()
                                            : CustomButtonWidget(
                                                onTap: () async {
                                                  await controller.addIncome(
                                                    data.id.toString(),
                                                  );
                                                },
                                                buttonText: "Add",
                                              );
                                      }),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      SizedBox(width: AppSizes.w(20)),
                      Expanded(
                        child: _progressBackground(
                          Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSizes.h(10),
                            ),
                            child: _addNewTask('Add Expense', () {
                              Get.dialog(
                                barrierDismissible: false,
                                AlertDialog(
                                  scrollable: true,
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
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

                                      SizedBox(height: 20),
                                      AppInput(
                                        hint: "Enter Expense Name",
                                        controller: controller.expenseNameTEC,
                                      ),
                                      SizedBox(height: 15),
                                      AppInput(
                                        hint: "\$ 0.0",
                                        controller: controller.expenseTEC,
                                        textType: TextInputType.number,
                                      ),
                                      SizedBox(height: 20),
                                      Obx(() {
                                        return controller
                                                .addExpenseLoading
                                                .value
                                            ? loading()
                                            : CustomButtonWidget(
                                                onTap: () async {
                                                  await controller.addExpense(
                                                    data.id.toString(),
                                                  );
                                                },
                                                buttonText: "Add",
                                              );
                                      }),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSizes.h(10)),
                  Obx(() {
                    final tabIndex = controller.tabIndex.value;
                    return Column(
                      children: [
                        // TabBar
                        Row(
                          children: List.generate(controller.tabTitles.length, (
                            index,
                          ) {
                            bool isSelected = tabIndex == index;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => controller.changeTab(index),
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
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
                        ),
                      ],
                    );
                  }),

                  Obx(() {
                    if (controller.tabIndex.value == 0) {
                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: data.incomeSources?.length ?? 0,
                        itemBuilder: (context, index) {
                          final income = data.incomeSources![index];
                          return
                            Padding(
                            padding: EdgeInsets.symmetric(vertical: 5.h),
                            child: Container(
                              padding: EdgeInsets.all(5.h),
                              decoration: BoxDecoration(
                                color: AppColors.whiteColor,
                                borderRadius: BorderRadius.circular(10.r)
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Insurance name and fee
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
                                        '\$${income.amount??0}',
                                        style: AppFonts.spaceGrotesk.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16.sp,
                                          color: AppColors.blackColor.withAlpha(
                                            90,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Row(
                                  //   children: [
                                  //     Container(
                                  //       decoration: BoxDecoration(
                                  //         border: Border(
                                  //           bottom: BorderSide(
                                  //             color: AppColors.blackColor,
                                  //           ),
                                  //         ),
                                  //       ),
                                  //       child: Row(
                                  //         mainAxisAlignment:
                                  //             MainAxisAlignment.spaceBetween,
                                  //         crossAxisAlignment:
                                  //             CrossAxisAlignment.center,
                                  //         children: [
                                  //           IconButton(
                                  //             onPressed: () {},
                                  //             icon: Icon(Icons.remove),
                                  //             padding: EdgeInsets.zero,
                                  //             constraints: BoxConstraints(),
                                  //           ),
                                  //           Text(
                                  //             '\$25',
                                  //             style: AppFonts.spaceGrotesk
                                  //                 .copyWith(
                                  //                   fontWeight: FontWeight.w500,
                                  //                   fontSize: AppSizes.sp(16),
                                  //                   color: AppColors.greyColor70,
                                  //                 ),
                                  //           ),
                                  //           IconButton(
                                  //             onPressed: () {},
                                  //             icon: Icon(Icons.add),
                                  //             padding: EdgeInsets.zero,
                                  //             constraints: BoxConstraints(),
                                  //           ),
                                  //         ],
                                  //       ),
                                  //     ),
                                  //     Obx(() {
                                  //       return Transform.scale(
                                  //         scale: 0.8,
                                  //         child: Switch(
                                  //           value: controller.isSwitched.value,
                                  //           onChanged: controller.toggleSwitch,
                                  //           activeColor: AppColors.primaryColor,
                                  //           inactiveThumbColor:
                                  //               AppColors.greyColor70,
                                  //         ),
                                  //       );
                                  //     }),
                                  //   ],
                                  // ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: data.expenseItems?.length ?? 0,
                        itemBuilder: (context, index) {
                          final expense = data.expenseItems![index];
                          return Padding(
                            padding:  EdgeInsets.symmetric(vertical: 5.h),
                            child: Container(
                              padding: EdgeInsets.all(5.h),
                              decoration: BoxDecoration(
                                  color: AppColors.whiteColor,
                                  borderRadius: BorderRadius.circular(10.r)
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Insurance name and fee
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        expense.name  ?? "",
                                        style: AppFonts.spaceGrotesk.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16.sp,
                                          color: AppColors.greyColor70,
                                        ),
                                      ),
                                      SizedBox(height: AppSizes.h(5)),
                                      Text(
                                        '\$${expense.totalAmount  ?? 0}',
                                        style: AppFonts.spaceGrotesk.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16.sp,
                                          color: AppColors.blackColor.withAlpha(
                                            90,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Row(
                                  //   children: [
                                  //     Container(
                                  //       decoration: BoxDecoration(
                                  //         border: Border(
                                  //           bottom: BorderSide(
                                  //             color: AppColors.blackColor,
                                  //           ),
                                  //         ),
                                  //       ),
                                  //       child: Row(
                                  //         mainAxisAlignment:
                                  //             MainAxisAlignment.spaceBetween,
                                  //         crossAxisAlignment:
                                  //             CrossAxisAlignment.center,
                                  //         children: [
                                  //           IconButton(
                                  //             onPressed: () {},
                                  //             icon: Icon(Icons.remove),
                                  //             padding: EdgeInsets.zero,
                                  //             constraints: BoxConstraints(),
                                  //           ),
                                  //           Text(
                                  //             '\$25',
                                  //             style: AppFonts.spaceGrotesk
                                  //                 .copyWith(
                                  //                   fontWeight: FontWeight.w500,
                                  //                   fontSize: AppSizes.sp(16),
                                  //                   color: AppColors.greyColor70,
                                  //                 ),
                                  //           ),
                                  //           IconButton(
                                  //             onPressed: () {},
                                  //             icon: Icon(Icons.add),
                                  //             padding: EdgeInsets.zero,
                                  //             constraints: BoxConstraints(),
                                  //           ),
                                  //         ],
                                  //       ),
                                  //     ),
                                  //     Obx(() {
                                  //       return Transform.scale(
                                  //         scale: 0.8,
                                  //         child: Switch(
                                  //           value: controller.isSwitched.value,
                                  //           onChanged: controller.toggleSwitch,
                                  //           activeColor: AppColors.primaryColor,
                                  //           inactiveThumbColor:
                                  //               AppColors.greyColor70,
                                  //         ),
                                  //       );
                                  //     }),
                                  //   ],
                                  // ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }
                  }),
                ],
              ),
            );
          }
        }),
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
Widget _budgetCardWidget(MyBudgetController controller) {
  final data = controller.myBudgetModel.value;
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
              onTap: () {
                Get.dialog(
                  barrierDismissible: false,
                  AlertDialog(
                    scrollable: true,
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: 10),
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

                        SizedBox(height: 20),
                        AppInput(
                          hint: "\$ 0.0",
                          controller: controller.createBudgetTEC,
                          textType: TextInputType.number,
                        ),
                        SizedBox(height: 20),
                        Obx(() {
                          return controller.addBudgetLoading.value
                              ? loading()
                              : CustomButtonWidget(
                                  onTap: () async {
                                    await controller.addBudget();
                                  },
                                  buttonText: "Add",
                                );
                        }),
                      ],
                    ),
                  ),
                );
              },
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
              '\$${data.targetAmount ?? 0} ',
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
Widget _incomeExpenseCardWidget(MyBudgetModel data) {
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
                  '\$${data.totalIncome ?? 0} ',
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

        // linear bar
        Column(
          children: [
           Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                 '${(((data.totalExpenseTarget ?? 0) / (data.totalIncome ?? 0))*100).round()}%',
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
              value: (((data.totalExpenseTarget ?? 0) / (data.totalIncome ?? 0))*100).round() / 100,
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
