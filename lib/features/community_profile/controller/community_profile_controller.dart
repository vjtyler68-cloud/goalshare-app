
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spanx/features/community_profile/model/community_profile_model.dart';

class CommunityProfileController extends GetxController {

 var suggestedPeople = <SuggestedPeople>[
    SuggestedPeople(name: "Gáspár Gréta", imageUrl: "https://randomuser.me/api/portraits/men/1.jpg"),
    SuggestedPeople(name: "Pintér Beatrix", imageUrl: "https://randomuser.me/api/portraits/men/2.jpg"),
    SuggestedPeople(name: "Veres Panna", imageUrl: "https://randomuser.me/api/portraits/men/3.jpg"),
    SuggestedPeople(name: "Halász Emese", imageUrl: "https://randomuser.me/api/portraits/men/4.jpg"),
  ].obs; 

   void toggleSelection(int index) {
    suggestedPeople[index].isSelected = !suggestedPeople[index].isSelected;
    suggestedPeople.refresh(); 
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