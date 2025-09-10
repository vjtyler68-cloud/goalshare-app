import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_images.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';
import 'package:spanx/core/global_widgets/subpage_appbar_widget.dart';
import 'package:spanx/features/priming/controller/priming_controller.dart';
import 'package:spanx/features/priming/screen/overlay.dart';
import 'package:video_player/video_player.dart';

import '../../../core/const/app_size.dart';

class PrimingScreen extends StatelessWidget {
  PrimingScreen({super.key});

  final PrimingController primingController = Get.put(PrimingController());

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.w(20),
            vertical: AppSizes.h(30),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // app bar
              SubPageAppbarWidget(appbarTitle: 'Priming', onPressed: (){
                Get.back();
              }),
              SizedBox(height: AppSizes.h(20)),

              // here i am using an image. but you need to implement a actual video player
              // video player
              Container(
                height: AppSizes.h(200),
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.w(15))
                ),
                child: Image.asset(AppImages.demoVideoImg, fit: BoxFit.fill)
              ),
              SizedBox(height: AppSizes.h(20)),
              
              // button
              CustomButtonWidget(onTap: (){}, buttonText: 'Completed Watching',)
              
              
              
              // Expanded( // 👈 Allows video to take available space
              //   child: FutureBuilder(
              //     future: primingController.initializeFuture,
              //     builder: (context, snapshot) {
              //       if (snapshot.connectionState == ConnectionState.waiting) {
              //         return const Center(child: CircularProgressIndicator());
              //       } else if (snapshot.hasError) {
              //         return Center(child: Text('Error: ${snapshot.error}'));
              //       } else if (!primingController.videoPlayerController.value.isInitialized) {
              //         return const Center(child: Text('Video not initialized.'));
              //       } else {
              //         return Container(
              //           // ✅ Wrapped in Container as requested
              //           decoration: BoxDecoration(
              //             borderRadius: BorderRadius.circular(12),
              //             boxShadow: [
              //               BoxShadow(
              //                 color: Colors.black.withOpacity(0.3),
              //                 blurRadius: 8,
              //                 offset: const Offset(0, 4),
              //               ),
              //             ],
              //           ),
              //           child: AspectRatio(
              //             aspectRatio: primingController.videoPlayerController.value.aspectRatio,
              //             child: Stack(
              //               alignment: Alignment.bottomCenter,
              //               children: [
              //                 VideoPlayer(primingController.videoPlayerController),
              //                 ControlsOverlay(controller: primingController.videoPlayerController),
              //                 VideoProgressIndicator(
              //                   primingController.videoPlayerController,
              //                   allowScrubbing: true,
              //                 ),
              //               ],
              //             ),
              //           ),
              //         );
              //       }
              //     },
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
