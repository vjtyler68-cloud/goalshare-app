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
import '../../../core/global_widgets/goal_tracking_widget.dart';

class MissionController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    fetchMission();
  }

  final RxBool isLoading = false.obs;

  // final RxBool isStartYourDayClicked = false.obs;
  //
  // void startYourDayClicked() {
  //   isStartYourDayClicked.value = !isStartYourDayClicked.value;
  // }

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

  late final createMissionBody = jsonEncode({
    "title": missionTitle.text,
    "clientTarget": int.parse(clientTarget.text),
    "description": description.text,
    "category": selectedCategory.value,
    "priority": selectedPriority.value,
    "dueDate": selectedDate.value,
  });

  // ============ create mission ====

  Future<void> createMission() async {
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

  final RxList<GetAllMissionModel> getAllMissionList =
      <GetAllMissionModel>[].obs;

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
        isLoading.value = false;
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

  // total clients
  final RxInt totalClients = 0.obs;

  // total reached clients
  final RxInt totalReachedClients = 0.obs;

  void clearField() {
    missionTitle.clear();
    clientTarget.clear();
    description.clear();
  }
}
