import 'package:get/get.dart';

class MyBudgetController extends GetxController{
  final RxBool isSwitched = false.obs;

  void toggleSwitch(bool value) {
    isSwitched.value = value;
  }
}