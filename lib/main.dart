import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get/instance_manager.dart';
import 'package:spanx/bindings/bindings.dart';
import 'package:spanx/features/customer_details/ui/customer_details_page.dart';
import 'package:spanx/features/onboarding/controller/splash_controller.dart';
import 'package:spanx/features/onboarding/screen/splash_screen.dart';
import 'package:spanx/features/profile_tab/ui/profile_tab.dart';
import 'package:spanx/routes/app_pages.dart';
import 'package:spanx/routes/app_routes.dart';

import 'features/analytics_tab/ui/analytics_ui.dart';
import 'features/chat_tab/ui/chat_message.dart';
import 'features/follwing_followers/ui/following_followup.dart';
import 'features/subscription_page/ui/subscription_page.dart';
import 'features/vision_board/ui/vision_ui.dart';
import 'package:device_preview/device_preview.dart';

// void main() {
//   Get.put(SplashScreenController());
//   runApp(const MainApp());
// }

void main() {
  // Initialize the controller before the app starts
  Get.put(SplashScreenController());

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => MainApp(), // Will now have access to the controller
    ),
  );
}


class MainApp extends StatelessWidget {
  const MainApp({super.key});

/*
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 640),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return child ?? SizedBox.shrink();
        },

        // home: FollowingsFollowersPage(),

        // home: ProfileTabPage(),
        // home: VisionBoardPage(),
        // initialBinding: InitialBinding(), // Set initial binding
        // getPages: AppRoute.routes,
        // initialRoute: AppRoute.onboardingScreen,
        // builder: EasyLoading.init(),
        // home: LoginPage(),
        //home: SignUpPage(),
        //home: VerificationCodeScreen(),
        // home: ForgetPasswordPage(),
        //  home: SetForgetPasswordPage(),
        // home: EditPasswordPage(),
        home: SplashScreen(),
        //  home: ChallengesPage(),
        //  home: FriendsPage(),
        // home: SearchPage(),
        // home: ProfilePage(),
        // home: RankingPage(),
        // home: EarlyRisingPage(),
        //  home: ProfilePage(),
      ),
    );
  } */

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 640),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => GetMaterialApp(
      debugShowCheckedModeBanner: false,
        useInheritedMediaQuery: true,
        locale: DevicePreview.locale(context),
        builder: DevicePreview.appBuilder,
      initialBinding: AppBindings(),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
    ),
    );
  }
}
