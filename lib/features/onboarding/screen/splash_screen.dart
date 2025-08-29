import 'package:flutter/material.dart';
import 'package:spanx/core/const/app_images.dart';
import 'package:spanx/core/const/app_size.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_loading.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundScreen(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: getWidth(50)),
          child: Stack(
            children: [
              // logo
              Center(
                child: SizedBox(
                  height: getWidth(300),
                  child: Image.asset(AppImages.splashIcon),
                ),
              ),

              // loader
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: getWidth(20)),
                  child: SizedBox(
                    width: getWidth(50),
                    child: CustomLoadingAnimationWidget(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
