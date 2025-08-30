import 'package:get/get.dart';
import 'package:get/get_state_manager/get_state_manager.dart';

class SubscriptionController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  void selectedPlan(int i) {
    selectedIndex.value = i;
  }
}
