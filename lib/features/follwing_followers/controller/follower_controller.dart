import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/core/user_info/user_info_controller.dart';

import '../../../core/network_caller/endpoints.dart';
import '../../../core/network_caller/network_config.dart';
import '../../public_profile/model/profile_view.dart';
import '../../public_profile/screen/public_profile_screen.dart';
import '../model/follower_model.dart';

class FollowingsFollowersController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // Tab Controller
  late TabController tabController;

  // Text Controllers
  final searchController = TextEditingController();

  final userController = Get.find<UserInfoController>();

  // Observable variables
  final RxList<UserFollowModel> followingsList = <UserFollowModel>[].obs;
  final RxList<UserFollowModel> followersList = <UserFollowModel>[].obs;
  final RxList<UserFollowModel> allUsersList = <UserFollowModel>[].obs;
  final RxList<UserFollowModel> searchResults = <UserFollowModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSearchLoading = false.obs;
  final RxInt currentTabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(_handleTabSelection);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    isLoading.value = true;
    try {
      getFollowerList();
      getFollowingList();
      getAllUsers();
    } catch (e) {
      log('Error loading data: ${e.toString()}');
      Get.snackbar('Error', 'Failed to load data');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getAllUsers() async {
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.allUsers,
        jsonEncode({}),
        is_auth: true,
      );
      if (response != null && response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        final List<UserFollowModel> users = data.map((user) {
          return UserFollowModel(
            id: user['id'] ?? '',
            name: user['fullName'] ?? '',
            email: user['email'] ?? '',
            profileImage: user['profile'] ?? '',
            isFollowing: _isUserFollowing(user['id']),
          );
        }).toList();
        allUsersList.assignAll(users);
      } else {
        log('Failed to get all users: ${response?['message']}');
      }
    } catch (e) {
      log('Error getting all users: ${e.toString()}');
      Get.snackbar('Error', 'Failed to load users');
    }
  }

  final local = LocalService();

  Future<void> getFollowerList() async {
    final uid = await local.getUID();
    log("${Urls.getFollowersList}/${uid.toString()}");

    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        "${Urls.getFollowersList}/${uid.toString()}",
        jsonEncode({}),
        is_auth: true,
      );
      if (response != null && response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        final List<UserFollowModel> followers = data.map((user) {
          return UserFollowModel(
            id: user['id'] ?? '',
            name: user['fullName'] ?? '',
            email: user['email'] ?? '',
            profileImage: user['profile'] ?? '',
            isFollowing: true,
          );
        }).toList();
        followersList.assignAll(followers);
      } else {
        log('Failed to get followers: ${response?['message']}');
      }
    } catch (e) {
      log('Error getting followers: ${e.toString()}');
      Get.snackbar('Error', 'Failed to load followers');
    }
  }

  Future<void> getFollowingList() async {
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.getFollowingList,
        jsonEncode({}),
        is_auth: true,
      );
      if (response != null && response['success'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        final List<UserFollowModel> followings = data.map((user) {
          return UserFollowModel(
            id: user['id'] ?? '',
            name: user['fullName'] ?? '',
            email: user['email'] ?? '',
            profileImage: user['profile'] ?? '',
            isFollowing: true,
          );
        }).toList();
        followingsList.assignAll(followings);
      } else {
        log('Failed to get followings: ${response?['message']}');
      }
    } catch (e) {
      log('Error getting followings: ${e.toString()}');
      Get.snackbar('Error', 'Failed to load followings');
    }
  }

  Future<bool> followUser(String userId) async {
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.followUser,
        jsonEncode({"followingId": userId}),
        is_auth: true,
      );
      if (response != null && response['success'] == true) {
        // Update the user in all lists
        _updateUserInLists(userId, true);
        Get.snackbar('Success', 'User followed successfully');
        return true;
      } else {
        Get.snackbar('Error', response?['message'] ?? 'Failed to follow user');
        return false;
      }
    } catch (e) {
      log('Error following user: ${e.toString()}');
      Get.snackbar('Error', 'Failed to follow user');
      return false;
    }
  }

  Future<void> unfollowUser(String userId) async {
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.unFollowUser,
        jsonEncode({"followingId": userId}),
        is_auth: true,
      );
      if (response != null && response['success'] == true) {
        // Remove user from following list
        followingsList.removeWhere((user) => user.id == userId);
        // Update in other lists
        _updateUserInLists(userId, false);
        Get.snackbar('Success', 'User unfollowed successfully');
      } else {
        Get.snackbar(
          'Error',
          response?['message'] ?? 'Failed to unfollow user',
        );
      }
    } catch (e) {
      log('Error unfollowing user: ${e.toString()}');
      Get.snackbar('Error', 'Failed to unfollow user');
    }
  }

  void searchUsers(String query) {
    if (query.isEmpty) {
      searchResults.clear();
      return;
    }

    isSearchLoading.value = true;
    try {
      final filtered = allUsersList.where((user) {
        return user.name.toLowerCase().contains(query.toLowerCase()) ||
            user.email.toLowerCase().contains(query.toLowerCase());
      }).toList();
      searchResults.assignAll(filtered);
    } catch (e) {
      log('Error searching users: ${e.toString()}');
    } finally {
      isSearchLoading.value = false;
    }
  }

  void clearSearch() {
    searchResults.clear();
    searchController.clear();
  }

  void _updateUserInLists(String userId, bool isFollowing) {
    // Update in all users list
    final allUsersIndex = allUsersList.indexWhere((u) => u.id == userId);
    if (allUsersIndex != -1) {
      allUsersList[allUsersIndex] = allUsersList[allUsersIndex].copyWith(
        isFollowing: isFollowing,
      );
    }

    // Update in search results
    final searchIndex = searchResults.indexWhere((u) => u.id == userId);
    if (searchIndex != -1) {
      searchResults[searchIndex] = searchResults[searchIndex].copyWith(
        isFollowing: isFollowing,
      );
    }
  }

  bool _isUserFollowing(String userId) {
    return followingsList.any((user) => user.id == userId);
  }

  @override
  void onClose() {
    tabController.dispose();
    searchController.dispose();
    super.onClose();
  }

  void _handleTabSelection() {
    currentTabIndex.value = tabController.index;
  }

  void onUserTap(UserFollowModel user) {
    // Open the person's "View Profile" page — a bigger look at them, with a
    // Message button and Follow toggle right there. `following` is captured in
    // the closure so repeated follow/unfollow taps stay correct.
    bool following = user.isFollowing;
    Get.to(() => PublicProfileScreen(
          user: ProfileView(
            id: user.id,
            name: user.name,
            email: user.email,
            image: user.profileImage,
            isVerified: user.isVerified ?? false,
            bio: user.bio,
          ),
          isFollowing: user.isFollowing,
          onFollowToggle: () {
            if (following) {
              unfollowUser(user.id);
            } else {
              followUser(user.id);
            }
            following = !following;
          },
        ));
  }

  void onFollowToggle(
    UserFollowModel user,
    bool isFollowingsTab,
    bool isSearch,
  ) {
    log("message ${user.id}");
    if (user.isFollowing) {
      unfollowUser(user.id);
    } else {
      followUser(user.id);
    }
  }

  void onBackPressed() {
    Get.back();
  }

  void refreshData() {
    _loadAllData();
  }

  // Getters
  int get followingsCount => followingsList.length;
  int get followersCount => followersList.length;
  int get allUsersCount => allUsersList.length;
}
