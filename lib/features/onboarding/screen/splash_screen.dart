import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spanx/core/const/app_images.dart';
import 'package:spanx/core/const/app_size.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_loading.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
     AppSizes.init(context);
  //  final SplashScreenController splashScreenController =  Get.put(SplashScreenController());
    return BackgroundScreen(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSizes.h(50)),
          child: Stack(
            children: [
              // logo
              Center(
                child: SizedBox(
                  height: 250.h,
                  child: Image.asset(AppImages.splash_logo),
                ),
              ),

              // loader
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: AppSizes.w(30)),
                  child: SizedBox(
                    width: AppSizes.w(50),
                    child: CustomLoadingAnimationWidget(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
