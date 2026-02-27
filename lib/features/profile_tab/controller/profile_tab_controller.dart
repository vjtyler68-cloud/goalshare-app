import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spanx/core/alertdialogs/confirm_account_delete.dart';
import 'package:spanx/core/alertdialogs/confirm_logout_dialog.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/features/about_us/ui/about_us_screen.dart';
import 'package:spanx/features/auth/screen/change_password_screen.dart';
import 'package:spanx/features/editprofile/screen/edit_profile_screen.dart';
import 'package:spanx/features/follwing_followers/ui/following_followup.dart';
import 'package:spanx/features/motivationalNudges/screen/motivationalnudge_screen.dart';
import 'package:spanx/features/privacy_policy/ui/privacy_policy_screen.dart';
import 'package:spanx/features/subscription_page/ui/subscription_page.dart';
import 'package:spanx/features/terms_conditions/ui/terms_conditions_screen.dart';
import 'package:spanx/features/vision_board/ui/vision_ui.dart';
import 'package:spanx/routes/app_routes.dart';

class ProfileTabController extends GetxController {
  // Observable variables
  final RxString userName = 'John Doe'.obs;
  final RxString userEmail = 'johndoe@gmail.com'.obs;
  final RxString userImageUrl =
      'https://images.unsplash.com/photo-1633332755192-727a05c4013d?fm=jpg&q=60&w=3000&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8dXNlcnxlbnwwfHwwfHx8MA%3D%3D'
          .obs;
  final RxInt followingCount = 177.obs;
  final RxInt followersCount = 199.obs;

  LocalService localService = LocalService();

  // Menu items data
  final List<ProfileMenuItem> menuItems = [
    ProfileMenuItem(
      title: 'Edit Profile',
      iconPath: 'assets/icons/editprofile.png',
      onTap: () => _onEditProfileTap(),
    ),
    ProfileMenuItem(
      title: 'Motivational Speech',
      iconPath: 'assets/images/flame.png',
      onTap: () => _onMotivationalSpeechTap(),
    ),
    // ProfileMenuItem(
    //   title: 'Vision Board',
    //   iconPath: 'assets/images/add.png',
    //   onTap: () => _onVisionBoardTap(),
    // ),
    ProfileMenuItem(
      title: 'Following and Followers',
      iconPath: 'assets/icons/followers.png',
      onTap: () => _onFollowingFollowersTap(),
    ),
    ProfileMenuItem(
      title: 'Subscription',
      iconPath: 'assets/icons/subscription.png',
      onTap: () => _onSubscriptionTap(),
    ),
  ];

  final List<ProfileMenuItem> preferencesItems = [
    ProfileMenuItem(
      title: 'Change Password',
      iconPath: 'assets/icons/key.png',
      onTap: () => _onChangePasswordTap(),
    ),
    ProfileMenuItem(
      title: 'About Us',
      iconPath: 'assets/icons/aboutus.png',
      onTap: () => _onAboutUsTap(),
    ),
    ProfileMenuItem(
      title: 'Terms & Conditions',
      iconPath: 'assets/icons/tc.png',
      onTap: () => _onTermsConditionsTap(),
    ),
    ProfileMenuItem(
      title: 'Privacy Policy',
      iconPath: 'assets/icons/pp.png',
      onTap: () => _onPrivacyPolicyTap(),
    ),
    ProfileMenuItem(
      title: 'Delete Account',
      iconPath: 'assets/icons/delete_account.png',
      onTap: () => _onAccountDelete(),
    ),
    ProfileMenuItem(
      title: 'Log out',
      iconPath: 'assets/icons/logout.png',
      onTap: () => _onLogOut(),
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    // Initialize any data here
  }

  // Menu item tap handlers
  static void _onEditProfileTap() {
    // Get.snackbar('Navigation', 'Edit Profile tapped');
    Get.to(() => EditProfileScreen());
    // Add navigation logic here
  }

  static void _onMotivationalSpeechTap() {
    // Get.snackbar('Navigation', 'Motivational Speech tapped', );
    // Add navigation logic here
    Get.to(() => MotivationalNudgeScreen());
  }

  static void _onVisionBoardTap() {
    Get.to(VisionBoardPage(), transition: Transition.rightToLeft);
  }

  static void _onFollowingFollowersTap() {
    // Get.snackbar('Navigation', 'Following and Followers tapped');
    // Add navigation logic here
    Get.to(() => FollowingsFollowersPage());
  }

  static void _onSubscriptionTap() {
    // Get.snackbar('Navigation', 'Subscription tapped');
    // Add navigation logic here
    Get.to(() => SubscriptionPage());
  }

  static void _onChangePasswordTap() {
    // Get.snackbar('Navigation', 'Change Password tapped');
    // Add navigation logic here
    Get.to(() => ChangePasswordScreen());
  }

  static void _onAboutUsTap() {
    Get.to(() => const AboutUsScreen(), transition: Transition.rightToLeft);
  }

  static void _onTermsConditionsTap() {
    Get.to(() => const TermsConditionsScreen(), transition: Transition.rightToLeft);
  }

  static void _onPrivacyPolicyTap() {
    Get.to(() => const PrivacyPolicyScreen(), transition: Transition.rightToLeft);
  }

  static void _onLogOut() {
    ConfirmLogoutDialog.show();
  }

  static void _onAccountDelete() {
    ConfirmAccountDeleteDialog.show();
  }

  final isAccountDeleteLoading = false.obs;
  void deleteAccount() async {
    isAccountDeleteLoading.value = true;
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.DELETE,
        Urls.userSoftDelete,
        jsonEncode({}),
        is_auth: true,
      );
      if (response != null && response['success'] == true) {
        AppSnackbar.show(
          message: 'Account deleted successfully',
          isSuccess: true,
        );
        LocalService localService = LocalService();
        localService.clearUserData();
        Get.offAllNamed(AppRoutes.loginScreen);
      }
    } catch (e) {
      AppSnackbar.show(message: e.toString(), isSuccess: false);
    } finally {
      isAccountDeleteLoading.value = false;
    }
  }

  // Methods to update data
  void updateFollowingCount(int count) {
    followingCount.value = count;
  }

  void updateFollowersCount(int count) {
    followersCount.value = count;
  }

  void updateUserInfo({String? name, String? email, String? imageUrl}) {
    if (name != null) userName.value = name;
    if (email != null) userEmail.value = email;
    if (imageUrl != null) userImageUrl.value = imageUrl;
  }
}

class ProfileMenuItem {
  final String title;
  final String iconPath;
  final VoidCallback onTap;

  ProfileMenuItem({
    required this.title,
    required this.iconPath,
    required this.onTap,
  });
}
