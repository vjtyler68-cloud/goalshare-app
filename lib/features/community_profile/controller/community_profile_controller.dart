import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:spanx/features/community_profile/model/community_profile_model.dart';

import '../../../core/network_caller/endpoints.dart';
import '../../../core/network_caller/network_config.dart';

class CommunityProfileController extends GetxController {
  var suggestedPeople = <SuggestedPeopleModel>[
    SuggestedPeopleModel(
      fullName: "Gáspár Gréta",
      profile: "https://randomuser.me/api/portraits/men/1.jpg",
    ),
    SuggestedPeopleModel(
      fullName: "Pintér Beatrix",
      profile: "https://randomuser.me/api/portraits/men/2.jpg",
    ),
    SuggestedPeopleModel(
      fullName: "Veres Panna",
      profile: "https://randomuser.me/api/portraits/men/3.jpg",
    ),
    SuggestedPeopleModel(
      fullName: "Halász Emese",
      profile: "https://randomuser.me/api/portraits/men/4.jpg",
    ),
  ].obs;

  void toggleSelection(int index) {
    suggestedPeople[index].isSelected = !suggestedPeople[index].isSelected;
    suggestedPeople.refresh();
  }

  // ============= api ================
  final logger = Logger();
  final RxList<CommunityProfileModel> allUserList = <CommunityProfileModel>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCommunityProfile();
  }

  Future<void> fetchCommunityProfile() async {
    isLoading.value = true;
    final response = await NetworkConfig.instance.ApiRequestHandler(
      RequestMethod.GET,
      Urls.allUsers,
      jsonEncode({}),
      is_auth: true,
    );

    try {
      if (response != null && response['success'] == true) {
        final userList = response['data'];
        if (userList is List) {
          final List<CommunityProfileModel> validUsers = [];
          for (var i in userList) {
            try {
              final user = CommunityProfileModel.fromJson(i);
              if (user.isApproved == true) {
                validUsers.add(user);
              }
            } catch (e) {
              logger.e('Failed to insert user at $i');
            }
          }
          allUserList.assignAll(validUsers);
          logger.i(
            'Successfully Parsed ${validUsers.length} out of ${userList.length} Users',
          );
        }
      }
    } catch (e) {
      log('Fetching Community People Error: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }
}

/*
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
*/
