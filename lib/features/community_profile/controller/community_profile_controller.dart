import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:spanx/core/const/paginator.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/core/user_info/user_info_controller.dart';
import 'package:spanx/features/community_profile/model/community_profile_model.dart';

import '../../../core/network_caller/endpoints.dart';
import '../../../core/network_caller/network_config.dart';

class CommunityProfileController extends GetxController
    with PagedController<CommunityProfileModel> {
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
  final RxList<CommunityProfileModel> allUserList =
      <CommunityProfileModel>[].obs;
  final RxBool isLoading = false.obs;

  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    limit = 10;
    fetchFirstPage();
  }

  @override
  Future<PageResult<CommunityProfileModel>> loadPage(
    int page,
    int limit,
  ) async {
    // ✅ Same endpoint
    final url = "${Urls.allUsers}?page=$page&limit=$limit";

    // ✅ Same API call
    final response = await NetworkConfig.instance.ApiRequestHandler(
      RequestMethod.GET,
      url,
      jsonEncode({}),
      is_auth: true,
    );

    // ✅ Same null/success check
    if (response == null || response['success'] != true) {
      throw Exception('Failed to fetch users');
    }

    // ✅ Gets pagination metadata
    final meta = response['meta'] ?? {};
    final totalPage = (meta['totalPage'] ?? 1) as int;

    // ✅ Same parsing logic
    final raw = response['data'];
    final List<CommunityProfileModel> items = [];
    if (raw is List) {
      for (final i in raw) {
        try {
          final u = CommunityProfileModel.fromJson(i);
          // ✅ Same isApproved filter
          if (u.isApproved == true) {
            /// to remove my profile
            if(u.id != Get.find<UserInfoController>().userData.value!.id!){
              items.add(u);
            }
          }
        } catch (e) {
          logger.e('Parse error: $e  item: $i');
        }
      }
    }

    logger.i("Loaded page $page (${items.length} items)");
    return PageResult(items: items, totalPage: totalPage);
  }


  /// follow user
  final RxBool isLoadingFollow = false.obs;
  Future<void> followUser (String userID) async{
    isLoadingFollow.value = true;
    try{
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.followUser,
        jsonEncode({"followingId": userID}),
        is_auth: true,
      );
      if (response != null && response['success'] == true) {
      }

    }catch(e){
      AppSnackbar.show(message: 'Following Failed', isSuccess: false);
      logger.e("Follow Unsuccessful: ${e.toString()}");
    }finally{isLoadingFollow.value = false;}
  }

  // Future<void> fetchCommunityProfile() async {
  //   isLoading.value = true;
  //   final response = await NetworkConfig.instance.ApiRequestHandler(
  //     RequestMethod.GET,
  //     Urls.allUsers,
  //     jsonEncode({}),
  //     is_auth: true,
  //   );
  //
  //   try {
  //     if (response != null && response['success'] == true) {
  //       final userList = response['data'];
  //       if (userList is List) {
  //         final List<CommunityProfileModel> validUsers = [];
  //         for (var i in userList) {
  //           try {
  //             final user = CommunityProfileModel.fromJson(i);
  //             if (user.isApproved == true) {
  //               validUsers.add(user);
  //             }
  //           } catch (e) {
  //             logger.e('Failed to insert user at $i');
  //           }
  //         }
  //         allUserList.assignAll(validUsers);
  //         logger.i(
  //           'Successfully Parsed ${validUsers.length} out of ${userList
  //               .length} Users',
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     log('Fetching Community People Error: ${e.toString()}');
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  void onRefresh() {
    loadPage(page, limit);
  }
}
