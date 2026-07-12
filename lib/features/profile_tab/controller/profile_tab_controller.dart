import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
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
import 'package:spanx/features/notifications/ui/notifications_settings_screen.dart';
import 'package:spanx/features/privacy_policy/ui/privacy_policy_screen.dart';
import 'package:spanx/features/subscription_page/ui/subscription_page.dart';
import 'package:spanx/features/terms_conditions/ui/terms_conditions_screen.dart';
import 'package:spanx/features/vision_board/ui/vision_ui.dart';
import 'package:spanx/routes/app_routes.dart';

class ProfileTabController extends GetxController {
  // Observable variables
  final RxString userName = ''.obs;
  final RxString userEmail = ''.obs;
  final RxString userImageUrl = ''.obs;
  final RxInt followingCount = 0.obs;
  final RxInt followersCount = 0.obs;

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
      title: 'Notifications & Reminders',
      iconPath: 'assets/icons/notification.png',
      onTap: () => _onNotificationsTap(),
    ),
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
      title: 'Contact Support',
      iconPath: 'assets/icons/aboutus.png',
      onTap: () => _onContactSupport(),
    ),
    ProfileMenuItem(
      title: 'Export My Data',
      iconPath: 'assets/icons/tc.png',
      onTap: () => _onExportData(),
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
    _syncFromUserInfo();
  }

  void _syncFromUserInfo() {
    try {
      final userInfo = Get.find<dynamic>(tag: 'UserInfoController');
      final u = userInfo?.userData?.value;
      if (u != null) {
        userName.value = u.fullName ?? '';
        userEmail.value = u.email ?? '';
        userImageUrl.value = u.profile ?? '';
      }
    } catch (_) {
      // UserInfoController not yet ready; profile UI will pull directly from it
    }
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

  static void _onNotificationsTap() {
    Get.to(
      () => NotificationsSettingsScreen(),
      transition: Transition.rightToLeft,
    );
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
    Get.to(
      () => const TermsConditionsScreen(),
      transition: Transition.rightToLeft,
    );
  }

  static void _onPrivacyPolicyTap() {
    Get.to(
      () => const PrivacyPolicyScreen(),
      transition: Transition.rightToLeft,
    );
  }

  /// Opens the user's mail app addressed to support (privacy policy promises
  /// this contact; keep the address in sync with site/privacy.html).
  static Future<void> _onContactSupport() async {
    final uri = Uri.parse(
        'mailto:support@goalsharewin.com?subject=GoalShare%20Support');
    try {
      if (await launchUrl(uri)) return;
      AppSnackBar.error('Email support@goalsharewin.com');
    } catch (_) {
      AppSnackBar.error('Email support@goalsharewin.com');
    }
  }

  /// GDPR/CCPA-style export: fetches everything the server stores for this
  /// account (GET /data/export) and hands it to the share sheet as a JSON
  /// file the user can save, AirDrop, or email to themselves.
  static Future<void> _onExportData() async {
    AppSnackBar.success('Preparing your data export…');
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        '${Urls.baseUrl}/data/export',
        jsonEncode({}),
        is_auth: true,
      );
      if (response == null || response['success'] != true) {
        AppSnackBar.error(response?['message'] ?? 'Export failed. Try again.');
        return;
      }
      final pretty =
          const JsonEncoder.withIndent('  ').convert(response['data']);
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/goalshare_export_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(pretty);
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: 'My GoalShare data export',
      ));
    } catch (_) {
      AppSnackBar.error('Export failed. Please try again.');
    }
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
        AppSnackBar.success('Account deleted successfully');
        LocalService localService = LocalService();
        localService.clearUserData();
        Get.offAllNamed(AppRoutes.loginScreen);
      }
    } catch (e) {
      AppSnackBar.error('Failed to delete account');
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
