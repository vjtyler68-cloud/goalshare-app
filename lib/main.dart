import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/bindings/bindings.dart';
import 'package:spanx/core/services/no_internet/controller.dart';
import 'package:spanx/features/onboarding/controller/splash_controller.dart';
import 'package:spanx/routes/app_pages.dart';
import 'package:spanx/routes/app_routes.dart';

import 'core/firebase/firebase_service.dart';
import 'core/monitoring/crash_reporter.dart';
import 'core/network_caller/endpoints.dart';
import 'core/network_caller/network_config.dart';
import 'core/notifications/notification_service.dart';
import 'features/home/subflow/todo/core/hive_setup.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Catch Flutter framework errors without crashing — and report them so
    // field crashes are visible (self-hosted, POST /data/crash).
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      CrashReporter.report(details.exception, details.stack);
    };

    try {
      await initHive();
    } catch (_) {
      // Hive failure is non-fatal — app runs without local todo cache
    }

    // Initialise Firebase for real-time chat. Never throws: if Firebase isn't
    // configured yet, chat transparently falls back to on-device storage.
    await FirebaseService.instance.init();

    runApp(const MainApp());

    // Wait for the first frame so the navigator is ready before we start
    // connectivity monitoring or attempt any navigation from controllers.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.put(ConnectivityController(), permanent: true);
      Get.put(SplashScreenController());

      // Wake the backend (Railway cold start) while the splash shows, so the
      // user's first real request isn't the one that pays the wake-up cost.
      NetworkConfig.warmUp(Urls.baseUrl);

      // Set up local reminder notifications. Opt-in: nothing fires until the
      // user enables them in Settings. Re-scheduling on launch keeps the copy
      // (streak count, goal, cold-lead count) fresh.
      NotificationService.instance.init().then((_) {
        NotificationService.instance.rescheduleIfEnabled();
      });
    });
  }, (error, stack) {
    // Catch any uncaught async errors — prevents hard crash in release mode
    debugPrint('Unhandled error: $error');
    CrashReporter.report(error, stack);
  });
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 640),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => GetMaterialApp(
        defaultTransition: Transition.leftToRight,
        debugShowCheckedModeBanner: false,
        initialBinding: AppBindings(),
        initialRoute: AppRoutes.splash,
        getPages: AppPages.routes,
      ),
    );
  }
}
