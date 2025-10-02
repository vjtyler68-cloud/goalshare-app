import 'dart:convert';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import '../../../core/global_widgets/app_snackbar.dart';
import '../model/my_budget_model.dart';

class MyBudgetController extends GetxController{
  final RxBool isSwitched = false.obs;

  void toggleSwitch(bool value) {
    isSwitched.value = value;
  }

  @override
  void onInit() {
    super.onInit();
    getMyBudget();
  }
  final RxBool myBudgetLoading = false.obs;
  final Rx<MyBudgetModel> myBudgetModel = MyBudgetModel().obs;
  Future<bool>getMyBudget()async{
    myBudgetLoading.value = true;
    try{
      final response = await NetworkConfig.instance.ApiRequestHandler(RequestMethod.GET, Urls.getMyBudget,
          {},is_auth: true);
      log("Get my budget response $response");
      if(response != null && response["success"]== true){
        myBudgetModel.value = MyBudgetModel.fromJson(response["data"]);
        log("Get my budget success ${response["data"]}");
        myBudgetLoading.value = false;
        return true;
      }else{
        log("Get my budget failed ${response["data"]}");
        myBudgetLoading.value = false;
        return false;
      }
    }catch(e){
      log("Get my budget failed $e");
      myBudgetLoading.value = false;
      return false;
    }finally{
      myBudgetLoading.value = false;
    }
  }

  //add budget
  final RxBool addBudgetLoading = false.obs;
  final createBudgetTEC = TextEditingController();
  Future<bool>addBudget()async{
    addBudgetLoading.value = true;
    try{
      final response = await NetworkConfig.instance.ApiRequestHandler(RequestMethod.POST, Urls.addBudget,
          jsonEncode({
            "targetAmount": int.parse(createBudgetTEC.text),
          }),is_auth: true);
      if(response != null && response["success"]== true){
        AppSnackbar.show(message: "Budget added successfully", isSuccess: true);
        log("Add budget success ${response["data"]}");
        addBudgetLoading.value = false;
        return true;
      }else{
        AppSnackbar.show(message: "Budget added failed", isSuccess: false);
        log("Add budget failed ${response["data"]}");
        addBudgetLoading.value = false;
        return false;
      }
    }catch(e){
      log("Add budget failed $e");
      addBudgetLoading.value = false;
      return false;
    }finally{
      addBudgetLoading.value = false;
    }
  }

}