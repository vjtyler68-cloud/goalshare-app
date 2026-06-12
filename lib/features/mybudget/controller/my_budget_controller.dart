import 'dart:convert';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';

import '../model/my_budget_model.dart';

class MyBudgetController extends GetxController {
  final RxBool isSwitched = false.obs;
  final List<String> tabTitles = ['Income', 'Expense'];
  final RxInt tabIndex = 0.obs;
  final RxBool myBudgetLoading = false.obs;
  final RxBool addBudgetLoading = false.obs;
  final RxBool addIncomeLoading = false.obs;
  final RxBool addExpenseLoading = false.obs;

  final Rxn<MyBudgetModel> myBudgetModel = Rxn<MyBudgetModel>();

  final budgetTEC = TextEditingController();
  final createBudgetTEC = TextEditingController();
  final incomeTEC = TextEditingController();
  final incomeNameTEC = TextEditingController();
  final expenseTEC = TextEditingController();
  final expenseNameTEC = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    getMyBudget();
  }

  @override
  void onClose() {
    budgetTEC.dispose();
    createBudgetTEC.dispose();
    incomeTEC.dispose();
    incomeNameTEC.dispose();
    expenseTEC.dispose();
    expenseNameTEC.dispose();
    super.onClose();
  }

  void toggleSwitch(bool value) => isSwitched.value = value;
  void changeTab(int index) => tabIndex.value = index;

  Future<bool> getMyBudget() async {
    myBudgetLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.getMyBudget,
        {},
        is_auth: true,
      );
      if (response != null && response['success'] == true) {
        myBudgetModel.value = MyBudgetModel.fromJson(response['data']);
        return true;
      }
      return false;
    } catch (e) {
      log('getMyBudget error: $e');
      return false;
    } finally {
      myBudgetLoading.value = false;
    }
  }

  Future<bool> addBudget() async {
    final amount = int.tryParse(createBudgetTEC.text);
    if (amount == null || amount <= 0) {
      AppSnackBar.error('Please enter a valid budget amount');
      return false;
    }

    addBudgetLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.addBudget,
        jsonEncode({'targetAmount': amount}),
        is_auth: true,
      );
      if (response != null && response['success'] == true) {
        await getMyBudget();
        AppSnackBar.success('Budget added successfully');
        Navigator.pop(Get.context!);
        createBudgetTEC.clear();
        return true;
      }
      AppSnackBar.error(response?['message'] ?? 'Failed to add budget');
      return false;
    } catch (e) {
      log('addBudget error: $e');
      AppSnackBar.error('Something went wrong. Please try again.');
      return false;
    } finally {
      addBudgetLoading.value = false;
    }
  }

  Future<bool> addIncome(String budgetId) async {
    if (incomeNameTEC.text.trim().isEmpty) {
      AppSnackBar.error('Please enter an income name');
      return false;
    }
    final amount = int.tryParse(incomeTEC.text);
    if (amount == null || amount <= 0) {
      AppSnackBar.error('Please enter a valid income amount');
      return false;
    }

    addIncomeLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.addIncome(budgetId: budgetId),
        jsonEncode({'name': incomeNameTEC.text.trim(), 'amount': amount}),
        is_auth: true,
      );
      if (response != null && response['success'] == true) {
        await getMyBudget();
        AppSnackBar.success('Income added successfully');
        Navigator.pop(Get.context!);
        incomeNameTEC.clear();
        incomeTEC.clear();
        return true;
      }
      AppSnackBar.error(response?['message'] ?? 'Failed to add income');
      return false;
    } catch (e) {
      log('addIncome error: $e');
      AppSnackBar.error('Something went wrong. Please try again.');
      return false;
    } finally {
      addIncomeLoading.value = false;
    }
  }

  Future<bool> addExpense(String budgetId) async {
    if (expenseNameTEC.text.trim().isEmpty) {
      AppSnackBar.error('Please enter an expense name');
      return false;
    }
    final amount = int.tryParse(expenseTEC.text);
    if (amount == null || amount <= 0) {
      AppSnackBar.error('Please enter a valid expense amount');
      return false;
    }

    addExpenseLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.addExpense(budgetId: budgetId),
        jsonEncode({'name': expenseNameTEC.text.trim(), 'totalAmount': amount}),
        is_auth: true,
      );
      if (response != null && response['success'] == true) {
        await getMyBudget();
        AppSnackBar.success('Expense added successfully');
        Navigator.pop(Get.context!);
        expenseNameTEC.clear();
        expenseTEC.clear();
        return true;
      }
      AppSnackBar.error(response?['message'] ?? 'Failed to add expense');
      return false;
    } catch (e) {
      log('addExpense error: $e');
      AppSnackBar.error('Something went wrong. Please try again.');
      return false;
    } finally {
      addExpenseLoading.value = false;
    }
  }
}
