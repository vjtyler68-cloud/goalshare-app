import 'package:get/route_manager.dart';
import 'package:spanx/features/auth/screen/forget_password_screen.dart';
import 'package:spanx/features/auth/screen/login_screen.dart';
import 'package:spanx/features/auth/screen/reset_password_screen.dart';
import 'package:spanx/features/auth/screen/signup_screen.dart';
import 'package:spanx/features/home/screen/home_screen.dart';
import 'package:spanx/features/mainnavbar/screen/main_navbar_screen.dart';
import 'package:spanx/features/motivationalNudges/screen/motivationalnudge_screen.dart';
import 'package:spanx/features/onboarding/screen/onboarding_screen.dart';
import 'package:spanx/features/onboarding/screen/splash_screen.dart';
import 'package:spanx/features/profile/screen/setup_profile_screen.dart';
import 'package:spanx/features/profile/screen/upload_profile_picture.dart';
import 'package:spanx/features/subscriptions/screen/subscription_screen.dart';
import 'package:spanx/routes/app_routes.dart';

import '../features/auth/screen/apply_code_screen.dart';
import '../features/auth/screen/reset_code_screen.dart';

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
    GetPage(name: AppRoutes.resetPasswordScreen, page: () => ResetPasswordScreen()),
    GetPage(name: AppRoutes.setUpProfileScreen, page: () => SetupProfileScreen()),
    GetPage(name: AppRoutes.uploadProfilePictureScreen, page: ()=> UploadProfilePicture()),
    GetPage(name: AppRoutes.mainNavBarScreen, page: ()=> MainNavbarScreen()),
    GetPage(name: AppRoutes.homeScreen, page: ()=> HomeScreen()),
    GetPage(name: AppRoutes.motivationalNudgeScreen, page: ()=> MotivationalNudgeScreen()),
  ];
}
