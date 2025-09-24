import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';

class MissionDetailsController extends GetxController{
    // with GetTickerProviderStateMixin {
  final RxInt selectedClientIndex = 0.obs;
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

  void changeClientIndex(int i) {
    selectedClientIndex.value = i;
  }

  // ========== time
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
}
