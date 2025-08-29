import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get/instance_manager.dart';
import 'package:get/utils.dart';
import 'package:spanx/core/const/app_size.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_loading.dart';
import 'package:spanx/features/onboarding/controller/splash_controller.dart';
import 'package:spanx/features/onboarding/screen/splash_screen.dart';

void main() {
  // Get.put(SplashScreenController());
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    AppSizes().init(context);
    return  GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: SplashScreen(),
        ),
      ),
    );
  }
}
