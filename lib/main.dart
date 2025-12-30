import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/bindings/bindings.dart';
import 'package:spanx/core/const/app_size.dart';
import 'package:spanx/core/services/no_internet/controller.dart';
import 'package:spanx/features/onboarding/controller/splash_controller.dart';
import 'package:spanx/routes/app_pages.dart';
import 'package:spanx/routes/app_routes.dart';

import 'features/home/subflow/todo/core/hive_setup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initHive();

  runApp(const MainApp());

  // put controllers after app mounts OR inside AppBindings
  Get.put(ConnectivityController(), permanent: true);
  Get.put(SplashScreenController());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);
    return ScreenUtilInit(
      designSize: const Size(360, 640), // 360, 640
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => GetMaterialApp(
        defaultTransition: Transition.leftToRight,
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
