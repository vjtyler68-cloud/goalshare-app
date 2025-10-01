import 'dart:ffi';
import 'dart:math';

import 'package:get/get.dart';
import 'package:spanx/features/motivationalNudges/controller/motivational_nudges_controller.dart';
import 'package:url_launcher/url_launcher.dart';


class HomeController extends GetxController{

  final motivations = Get.find<MotivationalNudgesController>();

  // url launcher
  Future<void> launchBibleSite(String webLink) async {
    final Uri url = Uri.parse(webLink);

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  final RxString randomMotivationLine = "Every great business starts with one small sale.".obs;

  int randomIndex() {
    final totalMotivations =motivations.motivationNudgesList.length;
    final int randomNumber = Random().nextInt(totalMotivations-1);
    return randomNumber;
  }


}