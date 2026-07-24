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
import 'core/theme/theme_service.dart';
import 'core/network_caller/network_config.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/services/no_internet/offline_banner.dart';
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

    // Apply the user's saved color theme before the first frame renders.
    await ThemeService.to.init();

    // Initialise Firebase for real-time chat. Never throws: if Firebase isn't
    // configured yet, chat transparently falls back to on-device storage.
    await FirebaseService.instance.init();

    // Start connectivity monitoring BEFORE the first frame so the global
    // offline banner can react from the very first paint. It no longer
    // navigates anywhere (the app is offline-capable), so it's safe to
    // register before the navigator exists.
    Get.put(ConnectivityController(), permanent: true);

    runApp(const MainApp());

    // Wait for the first frame so the navigator is ready before any navigation
    // from controllers.
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

      // Real push notifications (FCM). Registers this device's token if the
      // user is already logged in, and shows incoming friend/message pushes.
      // No-ops when Firebase isn't configured. Best-effort — never awaited.
      PushNotificationService.instance.init();
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
        // Overlay a slim, non-blocking offline banner above every screen. Shows
        // only when there's no connection; slides away when it returns.
        builder: (context, child) => Stack(
          alignment: Alignment.topLeft,
          children: [
            child ?? const SizedBox.shrink(),
            const OfflineBanner(),
          ],
        ),
      ),
    );
  }
}
