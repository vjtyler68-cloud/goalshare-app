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
  final RxInt userFollowingCount = 0.obs;
  final RxInt userFollowerCount = 0.obs;

  // final RxList<UserDataModel> userData = <UserDataModel>[].obs;
  final Rxn<UserDataModel> userData = Rxn<UserDataModel>();

  @override
  void onInit() {
    super.onInit();
    loadAndSetUserInfo();
    getFollowersCount();
  }

  Future<void> loadAndSetUserInfo() async {
    await getUserInfo();
    setUserInfo();
  }

  // ============= USER DATA INFO ================ //

  Future<void> getUserInfo() async {
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.userPersonalData,
        jsonEncode({}),
        is_auth: true,
      );

      if (response != null && response['success'] == true) {
        userData.value = UserDataModel.fromJson(response['data']);
      }
    } catch (e) {
      log("user info error: ${e.toString()}");
    }
  }

  // ============= Followers Following count ================ //
  Future<void> getFollowersCount() async{
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.userFollowersCount,
        jsonEncode({}),
        is_auth: true,
      );

      if (response != null && response['success'] == true) {
        userFollowingCount.value = response['data']['followingCount'];
        userFollowerCount.value = response['data']['followersCount'];
      }
    } catch (e) {
      log("user info error: ${e.toString()}");
    }
  }


  void setUserInfo() {
    if (userData.value != null) {
      fullName.value = userData.value!.fullName ?? '';
      email.value = userData.value!.email ?? '';
      phoneNumber.value = userData.value!.phoneNumber ?? '';
      city.value = userData.value!.city ?? '';
      fullAddress.value = userData.value!.address ?? '';
      profileImage.value = userData.value!.profile ?? '';
    }
  }



}
