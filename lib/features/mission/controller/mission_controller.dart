import 'package:get/get.dart';

class MissionController extends GetxController{
  final RxBool isStartYourDayClicked = false.obs;
  void startYourDayClicked(){
    isStartYourDayClicked.value = !isStartYourDayClicked.value;
  }
}