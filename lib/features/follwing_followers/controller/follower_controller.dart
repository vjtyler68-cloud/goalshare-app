import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../model/follower_model.dart';

class FollowingsFollowersController extends GetxController
    with GetSingleTickerProviderStateMixin {
  // Tab Controller
  late TabController tabController;

  // Observable variables
  final RxList<UserFollowModel> followingsList = <UserFollowModel>[].obs;
  final RxList<UserFollowModel> followersList = <UserFollowModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxInt currentTabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(_handleTabSelection);
    loadUsersData();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  void _handleTabSelection() {
    currentTabIndex.value = tabController.index;
  }

  void loadUsersData() {
    isLoading.value = true;

    // Mock followings data
    final List<UserFollowModel> followings = [
      UserFollowModel(
        id: '1',
        name: 'Andre Sophia',
        email: 'bill.sanders@example.com',
        profileImage:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?fm=jpg&q=60&w=500',
        isFollowing: true,
      ),
      UserFollowModel(
        id: '2',
        name: 'Michael Tony',
        email: 'georgia.young@example.com',
        profileImage:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?fm=jpg&q=60&w=500',
        isFollowing: true,
      ),
      UserFollowModel(
        id: '3',
        name: 'Joseph Ray',
        email: 'tim.jennings@example.com',
        profileImage:
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?fm=jpg&q=60&w=500',
        isFollowing: true,
      ),
      UserFollowModel(
        id: '4',
        name: 'Thomas Adison',
        email: 'nevaeh.simmons@example.com',
        profileImage:
            'https://images.unsplash.com/photo-1519244703995-f4e0f30006d5?fm=jpg&q=60&w=500',
        isFollowing: true,
      ),
    ];

    // Mock followers data
    final List<UserFollowModel> followers = [
      UserFollowModel(
        id: '5',
        name: 'Jira',
        email: 'jackson.graham@example.com',
        profileImage:
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?fm=jpg&q=60&w=500',
        isFollowing: false,
      ),
      UserFollowModel(
        id: '6',
        name: 'Michael Tony',
        email: 'debbie.baker@example.com',
        profileImage:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?fm=jpg&q=60&w=500',
        isFollowing: false,
      ),
      UserFollowModel(
        id: '7',
        name: 'Joseph Ray',
        email: 'willie.jennings@example.com',
        profileImage:
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?fm=jpg&q=60&w=500',
        isFollowing: false,
      ),
      UserFollowModel(
        id: '8',
        name: 'Sarah Wilson',
        email: 'sarah.wilson@example.com',
        profileImage:
            'https://images.unsplash.com/photo-1494790108755-2616b612b5c7?fm=jpg&q=60&w=500',
        isFollowing: true,
      ),
      UserFollowModel(
        id: '9',
        name: 'David Chen',
        email: 'david.chen@example.com',
        profileImage:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?fm=jpg&q=60&w=500',
        isFollowing: false,
      ),
    ];

    // Simulate loading delay
    Future.delayed(const Duration(milliseconds: 500), () {
      followingsList.assignAll(followings);
      followersList.assignAll(followers);
      isLoading.value = false;
    });
  }

  void onUserTap(UserFollowModel user) {
    Get.snackbar('User Selected', user.name);
    // Add navigation or profile view logic here
  }

  void onFollowToggle(UserFollowModel user) {
    if (currentTabIndex.value == 0) {
      // Followings tab - toggle unfollow/follow
      final index = followingsList.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        followingsList[index] = user.copyWith(isFollowing: !user.isFollowing);
        if (!followingsList[index].isFollowing) {
          // If unfollowed, show snackbar
          Get.snackbar('Unfollowed', 'You unfollowed ${user.name}');
        } else {
          Get.snackbar('Following', 'You are now following ${user.name}');
        }
      }
    } else {
      // Followers tab - toggle follow back
      final index = followersList.indexWhere((u) => u.id == user.id);
      if (index != -1) {
        followersList[index] = user.copyWith(isFollowing: !user.isFollowing);
        if (followersList[index].isFollowing) {
          Get.snackbar('Follow Back', 'You followed back ${user.name}');
        } else {
          Get.snackbar('Unfollowed', 'You unfollowed ${user.name}');
        }
      }
    }
  }

  void onBackPressed() {
    Get.back();
  }

  void removeUser(String userId) {
    followingsList.removeWhere((user) => user.id == userId);
    followersList.removeWhere((user) => user.id == userId);
  }

  void refreshData() {
    loadUsersData();
  }

  // Get current list based on selected tab
  List<UserFollowModel> get currentList {
    return currentTabIndex.value == 0 ? followingsList : followersList;
  }

  // Get counts
  int get followingsCount => followingsList.length;
  int get followersCount => followersList.length;
}
