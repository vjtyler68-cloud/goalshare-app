import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/core/user_info/model/user_data_model.dart';

class UserInfoController extends GetxController {
  final RxInt userFollowingCount = 0.obs;
  final RxInt userFollowerCount = 0.obs;
  final Rxn<UserDataModel> userData = Rxn<UserDataModel>();

  @override
  void onInit() {
    super.onInit();
    loadAndSetUserInfo();
    getFollowersCount();
  }

  Future<void> loadAndSetUserInfo() async {
    await getUserInfo();
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
        userData.value = UserDataModel.fromJson(response['data']);
      }
    } catch (e) {
      log('getUserInfo error: $e');
    }
  }

  Future<void> getFollowersCount() async {
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.userFollowersCount,
        jsonEncode({}),
        is_auth: true,
      );

      if (response != null && response['success'] == true) {
        final data = response['data'];
        if (data is Map) {
          userFollowingCount.value =
              (data['followingCount'] as num?)?.toInt() ?? 0;
          userFollowerCount.value =
              (data['followersCount'] as num?)?.toInt() ?? 0;
        }
      }
    } catch (e) {
      log('getFollowersCount error: $e');
    }
  }
}
