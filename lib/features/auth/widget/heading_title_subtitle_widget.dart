import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_size.dart';

class HeadingTitleSubtitleWidget extends StatelessWidget {
  final String headingTitle;
  final String headingSubTitle;
  const HeadingTitleSubtitleWidget({
    super.key,
    required this.headingTitle,
    required this.headingSubTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      // crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          headingTitle,
          style: AppFonts.spaceGrotesk.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: AppSizes.sp(30),
            color: AppColors.greyColor,
          ),
        ),
        SizedBox(height: AppSizes.h(5)),
        Text(
        headingSubTitle,
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
