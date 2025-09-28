import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get/instance_manager.dart';
import 'package:spanx/bindings/bindings.dart';
import 'package:spanx/core/const/app_size.dart';
import 'package:spanx/features/motivationalNudges/controller/motivational_nudges_controller.dart';
import 'package:spanx/features/onboarding/controller/splash_controller.dart';
import 'package:spanx/routes/app_pages.dart';
import 'package:spanx/routes/app_routes.dart';

void main() {
  Get.put(SplashScreenController());
  Get.put(MotivationalNudgesController(), permanent: true);
  runApp(const MainApp());
}

// void configEasyLoading() {
//   EasyLoading.instance
//     ..loadingStyle = EasyLoadingStyle.custom
//     ..backgroundColor = AppColors.greyColor70
//     ..textColor = Colors.white
//     ..indicatorColor = Colors.white
//     ..maskColor = Colors.green
//     ..userInteractions = false
//     ..dismissOnTap = false;
// }

// void main() {
//   // Initialize the controller before the app starts
//   Get.put(SplashScreenController());

//   runApp(
//     DevicePreview(
//       enabled: !kReleaseMode,
//       builder: (context) => MainApp(), // Will now have access to the controller
//     ),
//   );
// }


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
    AppSizes.init(context);
    return ScreenUtilInit(
      designSize: const Size(360, 640), // 360, 640
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => GetMaterialApp(
      debugShowCheckedModeBanner: false,
        useInheritedMediaQuery: true,
        // locale: DevicePreview.locale(context),
        // builder: DevicePreview.appBuilder,
        
      initialBinding: AppBindings(),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
    ),
    );
  }
}
