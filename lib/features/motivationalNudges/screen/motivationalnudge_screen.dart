import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/motivation_card_widget.dart';
import 'package:spanx/features/motivationalNudges/controller/motivational_nudges_controller.dart';
import 'package:spanx/routes/app_routes.dart';

import '../../../core/const/app_icons.dart';
import '../../../core/const/app_images.dart';
import '../../../core/const/app_size.dart';
import '../../../core/global_widgets/subpage_appbar_widget.dart';

class MotivationalNudgeScreen extends StatelessWidget {
  MotivationalNudgeScreen({super.key});
  final motivationController = Get.find<MotivationalNudgesController>();

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
        minimum: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // appbar
            SubPageAppbarWidget(
              appbarTitle: 'Motivational Nudges',
              onPressed: () {
                Get.back();
              },
            ),
            SizedBox(height: 10.h),
            // create new motivation
            InkWell(
              onTap: () {
                Get.toNamed(AppRoutes.motivationPageCreateScreen);
              },
              child: Container(
                width: 100.w,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSizes.w(10),
                  vertical: AppSizes.h(5),
                ),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(AppImages.bg_minicard),
                    fit: BoxFit.fill,
                  ),
                ),
                child: Row(
                  children: [
                    Image.asset(AppIcons.box_add, height: AppSizes.h(20)),
                    SizedBox(width: AppSizes.w(5)),
                    Text(
                      'Create New',
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: AppSizes.sp(12),
                        color: AppColors.greyColor70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.h),

            Obx(() {
              return motivationController.isLoading.value
                  ? Center(
                      child: LoadingAnimationWidget.staggeredDotsWave(
                        color: AppColors.primaryColor,
                        size: 30.h,
                      ),
                    )
                  : Expanded(
                      child: ListView.builder(
                        itemCount:
                            motivationController.motivationNudgesList.length,
                        itemBuilder: (context, index) {
                          final motivations =
                              motivationController.motivationNudgesList[index];
                          return MotivationCardWidget(
                            title: motivations.title!,
                            buttonText: 'Delete',
                            // imgPath:  'assets/images/motivation${index + 1}.png',
                            imgPath: motivations.image ?? AppImages.motivation2,
                            onTap: () {
                              motivationController.deleteMotivation(
                                motivations.id.toString(),
                              );
                            },
                          );
                        },
                      ),
                    );
            }),

            // ...List.generate(3, (index) {
            //   return MotivationCardWidget( title: 'Every great business starts with one small sale.',
            //     buttonText: 'Edit',
            //     imgPath:  'assets/images/motivation${index + 1}.png',
            //     onTap: () {});
            // })
          ],
        ),
      ),
    );
  }
}
