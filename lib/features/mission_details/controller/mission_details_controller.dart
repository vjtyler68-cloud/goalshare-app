import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import 'package:get/get.dart';
import 'package:spanx/features/mission/controller/mission_controller.dart';
import 'package:spanx/features/mission_details/model/mission_details_model.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/const/enums.dart';
import '../../../core/global_widgets/goal_tracking_widget.dart';
import '../../../core/network_caller/endpoints.dart';
import '../../../core/network_caller/network_config.dart';

class MissionDetailsController extends GetxController {
  final missionID = Get.arguments;

  @override
  void onInit() {
    super.onInit();

    fetchMission(missionID);
  }

  // ====== time spent with client
  final RxInt selectedClientIndex = 0.obs;

  void changeClientIndex(int i) {
    selectedClientIndex.value = i;
  }

  // ====== sales status
  final RxInt selectedSalesIndex = 0.obs;

  void changeSalesIndex(int i) {
    selectedSalesIndex.value = i;
  }

  // ==========  time
  RxInt seconds = 0.obs;
  RxBool isRunning = false.obs;

  Timer? _timer;

  void toggleTimer() {
    if (isRunning.value) {
      _timer?.cancel();
      isRunning.value = false;
    } else {
      isRunning.value = true;
      _timer = Timer.periodic(Duration(seconds: 1), (_) {
        seconds.value++;
      });
    }
  }

  void resetTimer() {
    _timer?.cancel();
    seconds.value = 0;
    isRunning.value = false;
  }

  void saveTimer() {
    log("Timer saved: ${seconds.value} seconds");
    log("Timer saved: ${seconds.value.runtimeType} seconds");
    _timer?.cancel();
    isRunning.value = false;
    seconds.value = 0;
  }

  String get formattedTime {
    final mins = (seconds.value ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds.value % 60).toString().padLeft(2, '0');
    return "$mins : $secs";
  }

  double get progress => seconds.value % 60 / 60.0;

  // ============== break time
  RxBool isRunningBreak = false.obs;
  RxInt secondsBreak = 0.obs;

  Timer? _breakTimer;

  void toggleBreakTimer() {
    if (isRunningBreak.value) {
      _breakTimer?.cancel();
      isRunningBreak.value = false;
    } else {
      isRunningBreak.value = true;
      _breakTimer = Timer.periodic(Duration(seconds: 1), (_) {
        secondsBreak.value++;
      });
    }
  }

  void resetBreakTimer() {
    _breakTimer?.cancel();
    secondsBreak.value = 0;
    isRunningBreak.value = false;
  }

  void saveBreakTimer() {
    log("Break timer saved: ${secondsBreak.value} seconds");
    log("Break timer saved: ${secondsBreak.value.runtimeType} seconds");
    _breakTimer?.cancel();
    isRunningBreak.value = false;
    secondsBreak.value = 0;
  }

  String get formattedBreakTime {
    final mins = (secondsBreak.value ~/ 60).toString().padLeft(2, '0');
    final secs = (secondsBreak.value % 60).toString().padLeft(2, '0');
    return "$mins : $secs";
  }

  double get breakProgress => secondsBreak.value % 60 / 60.0;

  // =========== get mission details

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
        log('Unknown priority: $str');
        return GoalPriority.LOW;
    }
  }

  SalesStatus parseSalesStatus(dynamic input) {
    if (input == null) return SalesStatus.PENDING;

    final str = input.toString().trim();
    switch (str) {
      case 'PENDING':
        return SalesStatus.PENDING;
      case 'REACHED':
        return SalesStatus.REACHED;
      case 'TALKED_TO':
        return SalesStatus.TALKED_TO;
      case 'COMPLETED':
        return SalesStatus.COMPLETED;
      default:
        // log('Unknown priority: $str');
        return SalesStatus.PENDING;
    }
  }

  final RxBool isLoading = false.obs;

  final Rxn<MissionDetailsModel> missionDetails = Rxn<MissionDetailsModel>();

   // ========= fetch mission
  Future<void> fetchMission(String missionID) async {
    isLoading.value = true;
    final response = await NetworkConfig.instance.ApiRequestHandler(
      RequestMethod.GET,
      '${Urls.missionDetails}/$missionID',
      jsonEncode({}),
      is_auth: true,
    );

    try {
      if (response != null && response['success'] == true) {
        missionDetails.value = MissionDetailsModel.fromJson(response['data']);
        isLoading.value = false;
      } else {
        Get.snackbar(
          'Failed',
          'Mission Fetching Failed',
          backgroundColor: AppColors.redColor,
        );
      }
    } catch (e) {
      log("Mission fetching error: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  // ========= create customer/client ============
  final clientName = TextEditingController();
  final clientPhoneNumber = TextEditingController();
  final clientNotes = TextEditingController();

  Future<void> createClient() async {
    isLoading.value = true;
    final response = await NetworkConfig.instance.ApiRequestHandler(
      RequestMethod.POST,
      '${Urls.createClient}/$missionID/clients',
      jsonEncode({
        "name": clientName.text.trim(),
        "phone": clientPhoneNumber.text.trim(),
        "notes": clientNotes.text.trim(),
      }),
      is_auth: true,
    );

    try {
      if (response != null && response['success'] == true) {
        Get.back();
        isLoading.value = false;
        Get.find<MissionController>().fetchMission();
        clearClient();
      } else {
        Get.snackbar(
          'Failed',
          'Client Creation Failed',
          backgroundColor: AppColors.redColor,
        );
      }
    } catch (e) {
      log("Client Creation error: ${e.toString()}");
    } finally {
      isLoading.value = false;
      fetchMission(missionID);
    }
  }

  // ========== my why & affirmations =============
  final myWhyAffirmation = TextEditingController();

  Future<void> createMyWhy() async {
    isLoading.value = true;
    final response = await NetworkConfig.instance.ApiRequestHandler(
      RequestMethod.POST,
      '${Urls.createMYWHY}/$missionID/my-why',
      jsonEncode({"text": myWhyAffirmation.text.trim()}),
      is_auth: true,
    );

    try {
      if (response != null && response['success'] == true) {
        Get.back();
        isLoading.value = false;
      } else {
        Get.snackbar(
          'Failed',
          'My Why Creation Failed',
          backgroundColor: AppColors.redColor,
        );
      }
    } catch (e) {
      log("My Why Creation error: ${e.toString()}");
    } finally {
      isLoading.value = false;
      fetchMission(missionID);
    }
  }

  // ========== my why & affirmations =============
  Future<void> createAffirmation() async {
    isLoading.value = true;
    final response = await NetworkConfig.instance.ApiRequestHandler(
      RequestMethod.POST,
      '${Urls.createAffirmation}/$missionID/affirmation',
      jsonEncode({"text": myWhyAffirmation.text.trim()}),
      is_auth: true,
    );

    try {
      if (response != null && response['success'] == true) {
        Get.back();
        isLoading.value = false;
      } else {
        Get.snackbar(
          'Failed',
          'My Why Creation Failed',
          backgroundColor: AppColors.redColor,
        );
      }
    } catch (e) {
      log("My Why Creation error: ${e.toString()}");
    } finally {
      isLoading.value = false;
      fetchMission(missionID);
    }
  }

  // ============== update sales status ==============
  Future<void> updateSalesStatus(String clientID, String status) async {
    isLoading.value = true;
    final response = await NetworkConfig.instance.ApiRequestHandler(
      RequestMethod.PATCH,
      "${Urls.updateClientStatus}/$clientID/status",
      jsonEncode({
        "status" : status
      }),
      is_auth: true,
    );
    try {
      if (response != null && response['success'] == true) {

        isLoading.value = false;
      } else {
        Get.snackbar(
          'Failed',
          'Sales Status Update Failed',
          backgroundColor: AppColors.redColor,
        );
      }
    } catch (e) {
      log("Sales Status Update error: ${e.toString()}");
    } finally {
      isLoading.value = false;
      fetchMission(missionID);
    }
  }

  void clearClient(){
    clientName.clear();
    clientPhoneNumber.clear();
    clientNotes.clear();
  }

  @override
  void dispose() {
    clientName.dispose();
    clientPhoneNumber.dispose();
    clientNotes.dispose();
    myWhyAffirmation.dispose();

    _timer?.cancel();
    _breakTimer?.cancel();

    super.dispose();
  }
}
