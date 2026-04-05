import 'dart:convert';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import '../../../core/global_widgets/app_snackbar.dart';
import '../model/my_budget_model.dart';

class MyBudgetController extends GetxController {
  final RxBool isSwitched = false.obs;

  void toggleSwitch(bool value) {
    isSwitched.value = value;
  }

  List<String> tabTitles = ['Income', 'Expense'];
  final RxInt tabIndex = 0.obs;

  // Method to update tab
  void changeTab(int index) {
    tabIndex.value = index;
  }

  @override
  void onInit() {
    super.onInit();
    getMyBudget();
  }

  final RxBool myBudgetLoading = false.obs;
  final Rxn<MyBudgetModel> myBudgetModel = Rxn<MyBudgetModel>();
  Future<bool> getMyBudget() async {
    myBudgetLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.getMyBudget,
        {},
        is_auth: true,
      );
      log("Get my budget response $response");
      if (response != null && response["success"] == true) {
        myBudgetModel.value = MyBudgetModel.fromJson(response["data"]);
        log("Get my budget success ${response["data"]}");
        myBudgetLoading.value = false;
        return true;
      } else {
        log("Get my budget failed ${response["data"]}");
        myBudgetLoading.value = false;
        return false;
      }
    } catch (e) {
      log("Get my budget failed $e");
      myBudgetLoading.value = false;
      return false;
    } finally {
      myBudgetLoading.value = false;
    }
  }

  //add budget
  final RxBool addBudgetLoading = false.obs;
  final budgetTEC = TextEditingController();
  final createBudgetTEC = TextEditingController();
  Future<bool> addBudget() async {
    addBudgetLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.addBudget,
        jsonEncode({"targetAmount": int.parse(createBudgetTEC.text)}),
        is_auth: true,
      );
      if (response != null && response["success"] == true) {
        await getMyBudget();
        AppSnackBar.show(
          message: "Budget added successfully",
          isSuccessful: true,
        );
        Navigator.pop(Get.context!);
        log("Add budget success ${response["data"]}");
        addBudgetLoading.value = false;
        return true;
      } else {
        AppSnackBar.show(message: "Budget added failed", isSuccessful: false);
        log("Add budget failed ${response["data"]}");
        addBudgetLoading.value = false;
        return false;
      }
    } catch (e) {
      log("Add budget failed $e");
      addBudgetLoading.value = false;
      return false;
    } finally {
      addBudgetLoading.value = false;
    }
  }

  //add income
  final RxBool addIncomeLoading = false.obs;
  final incomeTEC = TextEditingController();
  final incomeNameTEC = TextEditingController();
  Future<bool> addIncome(String budgetId) async {
    addIncomeLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.addIncome(budgetId: budgetId),
        jsonEncode({
          "name": incomeNameTEC.text,
          "amount": int.parse(incomeTEC.text),
        }),
        is_auth: true,
      );
      log("Add income response--------- $response");
      if (response != null && response["success"] == true) {
        await getMyBudget();
        AppSnackBar.show(
          message: "Income added successfully",
          isSuccessful: true,
        );
        Navigator.pop(Get.context!);
        log("Add income success ${response["data"]}");
        addIncomeLoading.value = false;
        return true;
      } else {
        AppSnackBar.show(message: "Income added failed", isSuccessful: false);
        log("Add income failed ${response["data"]}");
        addIncomeLoading.value = false;
        return false;
      }
    } catch (e) {
      log("Add income error $e");
      addIncomeLoading.value = false;
      return false;
    } finally {
      addIncomeLoading.value = false;
    }
  }

  //add income
  final RxBool addExpenseLoading = false.obs;
  final expenseTEC = TextEditingController();
  final expenseNameTEC = TextEditingController();
  Future<bool> addExpense(String budgetId) async {
    addExpenseLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.addExpense(budgetId: budgetId),
        jsonEncode({
          "name": expenseNameTEC.text,
          "totalAmount": int.parse(expenseTEC.text),
        }),
        is_auth: true,
      );
      log("Add expense response--------- $response");
      if (response != null && response["success"] == true) {
        await getMyBudget();
        AppSnackBar.show(
          message: "expense added successfully",
          isSuccessful: true,
        );
        Navigator.pop(Get.context!);
        log("Add expense success ${response["data"]}");
        addExpenseLoading.value = false;
        return true;
      } else {
        AppSnackBar.show(message: "expense added failed", isSuccessful: false);
        log("Add expense failed ${response["data"]}");
        addExpenseLoading.value = false;
        return false;
      }
    } catch (e) {
      log("Add expense error $e");
      addExpenseLoading.value = false;
      return false;
    } finally {
      addExpenseLoading.value = false;
    }
  }
}
