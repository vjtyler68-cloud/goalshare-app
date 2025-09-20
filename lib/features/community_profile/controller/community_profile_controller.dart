import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/features/community_profile/model/community_profile_model.dart';

class CommunityProfileController extends GetxController {
  final RxList<UserData> userData = <UserData>[].obs;
  final networkConfig = NetworkConfig();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      isLoading.value = true;
      final response = await networkConfig.ApiRequestHandler(
        RequestMethod.GET,
        Urls.userData,
        {},
        is_auth: true,
      );
      if (response != null && response['success'] == true) {
        final List<dynamic> userList = response['data']['data'];
        userData.value = userList.map((e) => UserData.fromJson(e)).toList();
      }
      isLoading.value = false;
    } catch (e) {
      log('Login error ${e.toString()}');
      Get.snackbar('Error', '$e', snackPosition: SnackPosition.TOP);
    } finally {
      isLoading.value = false;
    }
  }
}
