import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';


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

  // url launcher
  Future<void> launchBibleSite(String webLink) async {
    final Uri url = Uri.parse(webLink);

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }


}