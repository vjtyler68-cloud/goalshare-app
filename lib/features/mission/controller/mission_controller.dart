import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';

import '../../../core/alertdialogs/task_created_successful.dart';

class MissionController extends GetxController {
  final RxBool isLoading = false.obs;

  final RxBool isStartYourDayClicked = false.obs;

  void startYourDayClicked() {
    isStartYourDayClicked.value = !isStartYourDayClicked.value;
  }

  // ====== create mission dialog
  final RxString selectedDate = ''.obs;

  Future<void> pickDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2026),
    );
    if (picked != null) {
      selectedDate.value = "${picked.toLocal()}".split(' ')[0];
    }
  }

  final missionTitle = TextEditingController();
  final clientTarget = TextEditingController();
  final description = TextEditingController();

  // Observable selected value
  var selectedCategory = 'Daily'.obs;

  void selectCategory(String value) {
    selectedCategory.value = value;
  }

  final List<String> categoryList = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
  final List<String> priorityList = ['High', 'Medium', 'Low'];
  var selectedPriority = 'High'.obs;

  void selectPriority(String value) {
    selectedPriority.value = value;
  }

  @override
  void dispose() {
    super.dispose();
    missionTitle.dispose();
    clientTarget.dispose();
    description.dispose();
    // selectedDate.value = DateTime.now().toString();
  }

  // ========== Api Integration

  late final createMissionBody =  jsonEncode({
    "title": missionTitle.text,
    "clientTarget": int.parse(clientTarget.text),
    "description": description.text,
    "category": selectedCategory.value,
    "priority": selectedPriority.value,
    "dueDate": selectedDate.value,
  });


  Future<void> createMission() async {
    isLoading.value = true;
    final response = await NetworkConfig.instance.ApiRequestHandler(
      RequestMethod.POST,
      Urls.createMission,
      createMissionBody,
      is_auth: true,
    );

    try {
      if(response != null && response['success']==true){
        Get.back();
        TaskCreatedSuccessful.show(onContinue: () {});
      }
      else{
        Get.snackbar('Failed', 'Mission Created Failed', backgroundColor: AppColors.redColor);
      }
    } catch (e) {
      log("Mission created error: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  // ================ get missions
  Future<void> fetchMission() async {
    isLoading.value = true;
    final response = await NetworkConfig.instance.ApiRequestHandler(
      RequestMethod.POST,
      Urls.createMission,
      createMissionBody,
      is_auth: true,
    );

    try {
      if(response != null && response['success']==true){
        Get.back();
        TaskCreatedSuccessful.show(onContinue: () {});
      }
      else{
        Get.snackbar('Failed', 'Mission Created Failed', backgroundColor: AppColors.redColor);
      }
    } catch (e) {
      log("Mission created error: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }
}
