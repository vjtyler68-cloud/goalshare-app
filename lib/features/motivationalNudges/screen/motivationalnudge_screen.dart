import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/motivation_card_widget.dart';
import 'package:spanx/core/global_widgets/profile_card_widget.dart';
import 'package:spanx/routes/app_routes.dart';

import '../../../core/const/app_icons.dart';
import '../../../core/const/app_images.dart';
import '../../../core/const/app_size.dart';
import '../../../core/global_widgets/subpage_appbar_widget.dart';

class MotivationalNudgeScreen extends StatelessWidget {
  const MotivationalNudgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // appbar
              SubPageAppbarWidget(appbarTitle: 'Motivational Nudges', onPressed: (){Get.back();}),
              SizedBox(height: 10.h),
              // create new motivation
              InkWell(
                onTap: (){
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
              ...List.generate(3, (index) {
                return MotivationCardWidget( title: 'Every great business starts with one small sale.',
                  buttonText: 'Edit',
                  imgPath:  'assets/images/motivation${index + 1}.png',
                  onTap: () {});
              })
            ],
          ),
        ),
      ),
    );
  }
}


