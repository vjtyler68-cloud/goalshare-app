import 'package:get/route_manager.dart';
import 'package:spanx/bindings/bindings.dart';
import 'package:spanx/features/auth/screen/change_password_screen.dart';
import 'package:spanx/features/auth/screen/forget_password_screen.dart';
import 'package:spanx/features/auth/screen/login_screen.dart';
import 'package:spanx/features/auth/screen/reset_password_screen.dart';
import 'package:spanx/features/auth/screen/signup_screen.dart';
import 'package:spanx/features/community_profile/screen/community_profile_screen.dart';
import 'package:spanx/features/create_motivation/screen/create_motivation_screen.dart';
import 'package:spanx/features/customer_details/ui/customer_details_page.dart';
import 'package:spanx/features/editprofile/screen/edit_profile_screen.dart';
import 'package:spanx/features/home/screen/home_screen.dart';
import 'package:spanx/features/mainnavbar/screen/main_navbar_screen.dart';
import 'package:spanx/features/motivationalNudges/screen/motivationalnudge_screen.dart';
import 'package:spanx/features/mybudget/screen/my_budget_screen.dart';
import 'package:spanx/features/onboarding/screen/onboarding_screen.dart';
import 'package:spanx/features/onboarding/screen/splash_screen.dart';
import 'package:spanx/features/pending_user_approve/ui/pending_user_screen.dart';
import 'package:spanx/features/priming/screen/priming_screen.dart';
import 'package:spanx/features/subscription_page/ui/subscription_page.dart';
import 'package:spanx/features/subscriptions/screen/subscription_screen.dart';
import 'package:spanx/features/vision_board/ui/vision_ui.dart';
import 'package:spanx/features/vision_board_create/screen/vision_board_create_screen.dart';
import 'package:spanx/routes/app_routes.dart';

import '../features/auth/screen/apply_code_screen.dart';
import '../features/auth/screen/reset_code_screen.dart';
import '../features/mission/screen/mission_screen.dart';
import '../features/profile_tab/ui/profile_tab.dart';
import '../features/signup_update_profile/screen/setup_profile_screen.dart';
import '../features/signup_update_profile/screen/upload_profile_picture.dart';

class AppPages {
  static final routes = [
    GetPage(name: AppRoutes.splash, page: () => SplashScreen()),
    GetPage(name: AppRoutes.onboardingScreen, page: () => OnboardingScreen()),
    GetPage(
      name: AppRoutes.subscriptionScreen,
      page: () => SubscriptionScreen(),
    ),
    GetPage(name: AppRoutes.loginScreen, page: () => LoginScreen()),
    GetPage(name: AppRoutes.signUpScreen, page: () => SignupScreen()),
    GetPage(
      name: AppRoutes.forgetPasswordScreen,
      page: () => ForgetPasswordScreen(),
    ),
    GetPage(name: AppRoutes.resetCodeScreen, page: () => ResetCodeScreen()),
    GetPage(name: AppRoutes.applyCodeScreen, page: () => ApplyCodeScreen()),
    GetPage(
      name: AppRoutes.resetPasswordScreen,
      page: () => ResetPasswordScreen(),
    ),
    GetPage(
      name: AppRoutes.changePasswordScreen,
      page: () => ChangePasswordScreen(),
    ),
    GetPage(
      name: AppRoutes.setUpProfileScreen,
      page: () => SetupProfileScreen(),
    ),
    GetPage(
      name: AppRoutes.uploadProfilePictureScreen,
      page: () => UploadProfilePicture(),
    ),
    GetPage(name: AppRoutes.mainNavBarScreen, page: () => MainNavbarScreen(), binding: AppBindings()),
    GetPage(name: AppRoutes.homeScreen, page: () => HomeScreen()),
    GetPage(
      name: AppRoutes.motivationalNudgeScreen,
      page: () => MotivationalNudgeScreen(),
    ),
    GetPage(name: AppRoutes.missionScreen, page: () => MissionScreen()),
    GetPage(name: AppRoutes.primingScreen, page: () => PrimingScreen()),
    GetPage(name: AppRoutes.myBudgetScreen, page: () => MyBudgetScreen()),
    GetPage(name: AppRoutes.profilePageTabScreen, page: () => ProfileTabPage()),
    GetPage(name: AppRoutes.visionPageScreen, page: () => VisionBoardPage()),
    GetPage(name: AppRoutes.visionPageCreateScreen, page: () => VisionBoardCreateScreen()),
    GetPage(name: AppRoutes.motivationPageCreateScreen, page: () => CreateMotivationScreen()),
    GetPage(name: AppRoutes.communityProfileScreen, page: () => CommunityProfileScreen()),
    GetPage(name: AppRoutes.customerDetailsScreen, page: () => CustomerDetailsPage()),
    GetPage(name: AppRoutes.editProfileScreen, page: () => EditProfileScreen()),
    GetPage(name: AppRoutes.subscriptionPage, page: () => SubscriptionPage()),
    GetPage(name: AppRoutes.pendingUser, page: () => PendingUserScreen()),
  ];
}
