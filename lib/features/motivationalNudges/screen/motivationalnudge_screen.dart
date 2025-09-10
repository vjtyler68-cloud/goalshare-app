import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/motivation_card_widget.dart';
import 'package:spanx/core/global_widgets/profile_card_widget.dart';

import '../../../core/const/app_images.dart';
import '../../../core/const/app_size.dart';

class MotivationalNudgeScreen extends StatelessWidget {
  const MotivationalNudgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.w(20),
            vertical: AppSizes.h(30),
          ),
          child: Column(
            children: [
              // appbar
              Row(
                children: [
                  // IconButton(icon: Icon(Icons.arrow_back_ios_outlined), onPressed: (){},),
                  InkWell(
                    onTap: () {
                      Get.back();
                    },
                    child: Icon(Icons.arrow_back_ios_outlined),
                  ),
                  SizedBox(width: AppSizes.w(10)),
                  Text(
                    'Motivational Nudges',
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: AppSizes.sp(24),
                      color: AppColors.greyColor70,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.h(10)),
              ...List.generate(3, (index) {
                return MotivationCardWidget( title: 'Every great business starts with one small sale.',
                  buttonText: 'Set new >>',
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
