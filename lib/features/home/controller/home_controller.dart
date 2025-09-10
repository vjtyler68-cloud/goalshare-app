import 'package:get/get.dart';

class HomeController extends GetxController{
  // Observable selected value
  var selectedCategory = 'Daily'.obs;

  void selectCategory(String value) {
    selectedCategory.value = value;
  }
  final List<String> categoryList = ['Daily', 'Weekly', 'Monthly', 'Yearly'];
  final List<String> priorityList = ['High', 'Medium,', 'Low'];
  var selectedPriority = 'High'.obs;

  void selectPriority(String value) {
    selectedPriority.value = value;
  }
}