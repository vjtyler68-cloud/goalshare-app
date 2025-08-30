import 'dart:math';

import 'package:get/get.dart';
import 'package:spanx/core/const/country_list.dart';

class SetupProfileController extends GetxController {
  Map<String, String> country = countryList.firstWhere(
    (e) => e['name'] == "UK",
  );
  String get flag => country['icon'] ?? '';
}
