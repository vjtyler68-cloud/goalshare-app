import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/core/user_info/model/user_data_model.dart';

class UserInfoController extends GetxController {

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
    // setUserInfo();
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

      log("=== USER INFO API RESPONSE ===");
      log("Full response: ${response.toString()}");
      log("Response data: ${response?['data']}");
      log("subscriptionStart in response: ${response?['data']?['subscriptionStart']}");
      log("subscriptionEnd in response: ${response?['data']?['subscriptionEnd']}");
      log("============================");

      if (response != null && response['success'] == true) {
        userData.value = UserDataModel.fromJson(response['data']);
        log("Parsed UserData - subscriptionEnd: ${userData.value?.subscriptionEnd}");
        log("Parsed UserData - subscriptionStart: ${userData.value?.subscriptionStart}");
      }
    } catch (e) {
      log("❌ user info error: ${e.toString()}");
      log("Error stack trace: ${StackTrace.current}");
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




  // void setUserInfo() {
  //   if (userData.value != null) {
  //     id.value = userData.value!.id ?? '';
  //     fullName.value = userData.value!.fullName ?? '';
  //     email.value = userData.value!.email ?? '';
  //     phoneNumber.value = userData.value!.phoneNumber ?? '';
  //     city.value = userData.value!.city ?? '';
  //     fullAddress.value = userData.value!.address ?? '';
  //     profileImage.value = userData.value!.profile ?? '';
  //     profession.value = userData.value!.describe ?? '';
  //     businessType.value = userData.value!.businessType ?? '';
  //   }
  // }



}
