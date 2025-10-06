import 'package:flutter/material.dart';
import 'package:spanx/core/const/app_images.dart';

class BackgroundScreen extends StatelessWidget {
  final Widget child;
  final String? bgImg;

  const BackgroundScreen({
    super.key,
    required this.child,
    this.bgImg = AppImages.backgroundScreenGrid,
  });

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Reactive background
          Image.asset(
            bgImg!,

            width: screenSize.width,
            height: screenSize.height,
            fit: BoxFit.cover,
          ),

          // Foreground content
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
