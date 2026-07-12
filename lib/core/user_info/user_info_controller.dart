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

  /// Reset the cached identity and reload it for whoever is currently
  /// authenticated. MUST be called on every login: this controller is a
  /// long-lived singleton (permanent / fenix), so without an explicit refresh a
  /// newly logged-in account would keep showing the previously logged-in user's
  /// cached profile (e.g. the admin account).
  Future<void> refreshUserData() async {
    clear();
    await getUserInfo();
    await getFollowersCount();
  }

  /// Drop the cached identity (e.g. on logout) so nothing stale lingers.
  void clear() {
    userData.value = null;
    userFollowerCount.value = 0;
    userFollowingCount.value = 0;
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
