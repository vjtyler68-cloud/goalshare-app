import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/core/user_info/model/user_data_model.dart';

class UserInfoController extends GetxController {
  final RxString fullName = "".obs;
  final RxString email = "".obs;
  final RxString businessType = "".obs;
  final RxString profession = "".obs;
  final RxString city = "".obs;
  final RxString fullAddress = "".obs;
  final RxString phoneNumber = "".obs;
  final RxString profileImage = "".obs;

  final RxList<UserDataModel> userData = <UserDataModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    getUserInfo();
    setUserInfo();
  }

  Future<void> getUserInfo() async {
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.userPersonalData,
        jsonEncode({}),
        is_auth: true,
      );

      if (response != null && response['success'] == true) {
        userData.assignAll(
          (response['data'] as List).map((e) => UserDataModel.fromJson(e)),
        );
      }
    } catch (e) {
      log("user info error: ${e.toString()}");
    }
  }

  void setUserInfo() {
    fullName.value = userData.first.fullName!;
    email.value = userData.first.email!;
    phoneNumber.value = userData.first.phoneNumber!;
    city.value = userData.first.city!;
    fullAddress.value = userData.first.address!;
    profileImage.value = userData.first.profile!;
  }
}
