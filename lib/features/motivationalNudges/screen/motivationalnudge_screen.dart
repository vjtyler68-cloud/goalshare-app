import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/motivation_card_widget.dart';
import 'package:spanx/core/global_widgets/profile_card_widget.dart';

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
          padding: EdgeInsets.symmetric(
            horizontal: 20.w,
            vertical: 30.h,
          ),
          child: Column(
            children: [
              // appbar
              SubPageAppbarWidget(appbarTitle: 'Motivational Nudges', onPressed: (){Get.back();}),
              SizedBox(height: 10.h),
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


