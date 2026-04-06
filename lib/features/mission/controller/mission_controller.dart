import 'dart:convert';
import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/features/mission/model/get_all_mission_model.dart';

import '../../../core/alertdialogs/task_created_successful.dart';
import '../../../core/const/enums.dart';

class MissionController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    fetchMission();
    fetchProgressInfo();
  }

  final RxBool isLoading = false.obs;

  // final RxBool isStartYourDayClicked = false.obs;
  //
  // void startYourDayClicked() {
  //   isStartYourDayClicked.value = !isStartYourDayClicked.value;
  // }

  // time formating
  String formattedClientTime(int? sec) {
    if (sec == null || sec <= 0) {
      return "00 : 00";
    }
    final hours = (sec ~/ 3600).toString().padLeft(2, '0');
    final mins = ((sec % 3600) ~/ 60).toString().padLeft(2, '0');
    return "$hours : $mins";
  }

  // ====== create mission dialog
  final RxString selectedDate = ''.obs;

  Future<void> pickDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      // Create a DateTime at noon local time to avoid timezone offset issues
      // This ensures the date remains the same across all timezones
      final dateAtNoon = DateTime(
        picked.year,
        picked.month,
        picked.day,
        12,
        0,
        0,
      );
      final isoDate = dateAtNoon.toIso8601String();
      selectedDate.value = isoDate;
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
  void onClose() {
    missionTitle.dispose();
    clientTarget.dispose();
    description.dispose();
    super.onClose();
  }

  // ========== Api Integration ==============

  // ============ create mission ====

  Future<void> createMission() async {
    final createMissionBody = jsonEncode({
      "title": missionTitle.text,
      "clientTarget": int.parse(clientTarget.text),
      "description": description.text,
      "category": selectedCategory.value,
      "priority": selectedPriority.value,
      "dueDate": selectedDate.value,
    });

    isLoading.value = true;
    final response = await NetworkConfig.instance.ApiRequestHandler(
      RequestMethod.POST,
      Urls.createMission,
      createMissionBody,
      is_auth: true,
    );

    try {
      if (response != null && response['success'] == true) {
        fetchMission();
        Get.back();
        TaskCreatedSuccessful.show(onContinue: () {});
      } else {
        Get.snackbar(
          'Failed',
          'Mission Created Failed',
          backgroundColor: AppColors.redColor,
        );
      }
    } catch (e) {
      log("Mission created error: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  // ================ get missions

  String formatDate(String isoDateString) {
    final DateTime dateTime = DateTime.parse(isoDateString);
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(dateTime);
  }

  GoalPriority parsePriority(dynamic input) {
    if (input == null) return GoalPriority.LOW;

    final str = input.toString().trim();
    switch (str) {
      case 'High':
        return GoalPriority.HIGH;
      case 'Medium':
        return GoalPriority.MEDIUM;
      case 'Low':
        return GoalPriority.LOW;
      default:
        // Log error or use fallback
        debugPrint('Unknown priority: $str');
        return GoalPriority.LOW;
    }
  }

  // list of all missions and details
  final RxList<GetAllMissionModel> getAllMissionList =
      <GetAllMissionModel>[].obs;

  late final RxInt totalClient = 0.obs;
  late final RxInt totalReachedClient = 0.obs;
  late final RxInt totalSales = 0.obs;
  late final RxInt totalSalesPercentage = 0.obs;
  late final RxString totalTimeSpent = '0 Sec'.obs;

  Future<void> fetchProgressInfo() async {
    totalClient.value = getAllMissionList.fold(
      0,
      (sum, mission) => sum + (mission.clientTarget ?? 0),
    );
    totalReachedClient.value = getAllMissionList.fold(
      0,
      (sum, mission) => sum + (mission.totalReached ?? 0),
    );

    totalSalesPercentage.value = totalClient.value > 0
        ? ((totalReachedClient.value / totalClient.value) * 100).toInt()
        : 0;

    // Calculate total time spent
    getTotalTimeSpent();
  }

  // Calculate and format total time spent from all missions
  void getTotalTimeSpent() {
    // Sum all reachedClientsTime from all missions
    int totalSeconds = getAllMissionList.fold(
      0,
      (sum, mission) => sum + (mission.reachedClientsTime ?? 0),
    );

    // Format based on duration
    if (totalSeconds < 60) {
      // Less than a minute - show in seconds
      totalTimeSpent.value = '$totalSeconds Sec';
    } else if (totalSeconds < 3600) {
      // Less than an hour - show in minutes
      int minutes = totalSeconds ~/ 60;
      totalTimeSpent.value = '$minutes Min';
    } else {
      // An hour or more - show in hours
      int hours = totalSeconds ~/ 3600;
      totalTimeSpent.value = '$hours Hr';
    }
  }

  Future<void> fetchMission() async {
    isLoading.value = true;
    final response = await NetworkConfig.instance.ApiRequestHandler(
      RequestMethod.GET,
      Urls.getMission,
      jsonEncode({}),
      is_auth: true,
    );

    try {
      if (response != null && response['success'] == true) {
        getAllMissionList.assignAll(
          (response['data']['goals'] as List).map(
            (e) => GetAllMissionModel.fromJson(e),
          ),
        );
        fetchProgressInfo();
        isLoading.value = false;
      } else {}
    } catch (e) {
      log("Mission created error: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  // ============ delete ====

  final RxBool isDeleteLoading = false.obs;

  Future<void> deleteMotivation(String missionID) async {
    isDeleteLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.DELETE,
        "${Urls.deleteMission}/$missionID",
        jsonEncode({}),
        is_auth: true,
      );

      if (response != null && response['success'] == true) {
        log("DELETE SUCCESSFUL------:");
        fetchMission();
        Get.snackbar(
          'Success',
          '${response['message']}',
          colorText: AppColors.blackColor,
          backgroundColor: AppColors.greenColor,
        );
      }
    } catch (e) {
      log("DELETE ERROR: ${e.toString()}");
    } finally {
      isDeleteLoading.value = false;
    }
  }

  // get total clients
  int get totalClients {
    return getAllMissionList.fold(
      0,
      (sum, element) => sum + (element.clientTarget ?? 0),
    );
  }

  void clearField() {
    missionTitle.clear();
    clientTarget.clear();
    description.clear();
  }
}
