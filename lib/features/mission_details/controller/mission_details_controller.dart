import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:intl/intl.dart';

import 'package:get/get.dart';
import 'package:spanx/features/mission_details/model/mission_details_model.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/global_widgets/goal_tracking_widget.dart';
import '../../../core/network_caller/endpoints.dart';
import '../../../core/network_caller/network_config.dart';

class MissionDetailsController extends GetxController{
    // with GetTickerProviderStateMixin {

  // late AnimationController controller;

  // @override
  // void onInit() {
  //   controller = AnimationController(
  //     vsync: this,
  //   );
  //   super.onInit();
  // }
  //
  // @override
  // void dispose() {
  //   controller.dispose();
  //   super.dispose();
  // }

  @override
  void onInit() {
    super.onInit();
    final missionID = Get.arguments;
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
  RxInt secondsBreak = 0.obs;
  RxBool isRunning = false.obs;
  RxBool isRunningBreak = false.obs;

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
  }

  String get formattedTime {
    final mins = (seconds.value ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds.value % 60).toString().padLeft(2, '0');
    return "$mins : $secs";
  }

  double get progress => seconds.value % 60 / 60.0;

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
      case 'High': return GoalPriority.HIGH;
      case 'Medium': return GoalPriority.MEDIUM;
      case 'Low': return GoalPriority.LOW;
      default:
        log('Unknown priority: $str');
        return GoalPriority.LOW;
    }
  }



  final RxBool isLoading = false.obs;

  final Rxn<MissionDetailsModel> missionDetails = Rxn<MissionDetailsModel>();

  Future<void> fetchMission(String missionID) async {
    isLoading.value = true;
    final response = await NetworkConfig.instance.ApiRequestHandler(
      RequestMethod.GET,
      '${Urls.missionDetails}/$missionID',
      jsonEncode({}),
      is_auth: true,
    );

    try {
      if(response != null && response['success']==true){
        missionDetails.value = MissionDetailsModel.fromJson(response['data']);
        isLoading.value =false;
      }
      else{
        Get.snackbar('Failed', 'Mission Fetching Failed', backgroundColor: AppColors.redColor);
      }
    } catch (e) {
      log("Mission fetching error: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }


    // ========= create customer/client ============

    // ========== fetch client =============


}
