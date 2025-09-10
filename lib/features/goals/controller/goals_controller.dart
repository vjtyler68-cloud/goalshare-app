import 'package:get/get.dart';

class GoalsController extends GetxController{
  final RxBool isStartYourDayClicked = false.obs;
  void startYourDayClicked(){
    isStartYourDayClicked.value = !isStartYourDayClicked.value;
  }
}