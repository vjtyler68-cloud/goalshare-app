import 'package:get/route_manager.dart';
import 'package:spanx/features/onboarding/screen/onboarding_screen.dart';
import 'package:spanx/features/onboarding/screen/splash_screen.dart';
import 'package:spanx/routes/app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(name: AppRoutes.splash, page: () => SplashScreen()),
    GetPage(name: AppRoutes.onboardingScreen, page: () => OnboardingScreen()),
  ];
}
