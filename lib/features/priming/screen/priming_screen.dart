import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';
import 'package:spanx/core/global_widgets/subpage_appbar_widget.dart';
import 'package:spanx/features/priming/controller/priming_controller.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../core/const/app_size.dart';

class PrimingScreen extends StatelessWidget {
  PrimingScreen({super.key});

  final PrimingController primingController = Get.put(PrimingController());

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: primingController.youtubePlayerController,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.red,
        progressColors: const ProgressBarColors(
          playedColor: Colors.red,
          handleColor: Colors.redAccent,
        ),
        onReady: () {
          // Video is ready
        },
        onEnded: (data) {
          // Video ended
        },
      ),
      builder: (context, player) {
        return BackgroundScreen(
          child: SafeArea(
            child: Obx(() {
              // If fullscreen, only show the player
              if (primingController.isFullScreen.value) {
                return Center(child: player);
              }

              // Normal view
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App bar
                    SubPageAppbarWidget(
                      appbarTitle: 'Priming',
                      onPressed: () {
                        Get.back();
                      },
                    ),
                    SizedBox(height: AppSizes.h(20)),

                    // Video player
                    Container(
                      height: AppSizes.h(250),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSizes.w(15)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSizes.w(15)),
                        child: player,
                      ),
                    ),
                    SizedBox(height: AppSizes.h(20)),

                    // Button
                    CustomButtonWidget(
                      onTap: () {
                        AppSnackBar.show(
                          message: 'this feature is coming soon',
                          isSuccessful: false,
                        );
                      },
                      buttonText: 'Completed Watching',
                    )
                  ],
                ),
              );
            }),
          ),
        );
      },
      onEnterFullScreen: () {
        primingController.enterFullScreen();
      },
      onExitFullScreen: () {
        primingController.exitFullScreen();
      },
    );
  }
}