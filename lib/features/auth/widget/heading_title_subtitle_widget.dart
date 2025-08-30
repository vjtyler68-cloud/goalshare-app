import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_size.dart';

class HeadingTitleSubtitleWidget extends StatelessWidget {
  const HeadingTitleSubtitleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      // crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Welcome Back",
          style: AppFonts.spaceGrotesk.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: AppSizes.sp(30),
            color: AppColors.greyColor,
          ),
        ),
        SizedBox(height: AppSizes.h(5)),
        Text(
          "Log in to continue managing your clients and boosting your sales.",
          style: AppFonts.spaceGrotesk.copyWith(
            // fontWeight: FontWeight.bold,
            fontSize: AppSizes.sp(14),
            color: AppColors.greyColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
