import 'package:flutter/material.dart';

import '../const/app_colors.dart';
import '../const/app_fonts.dart';
import '../const/app_images.dart';
import '../const/app_size.dart';

class MotivationCardWidget extends StatelessWidget {
  final String title;
  final String buttonText;
  final String imgPath;
  final VoidCallback onTap;

  const MotivationCardWidget({
    super.key,
    required this.title,
    required this.buttonText,
    required this.imgPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // width: AppSizes.w(380),
      height: AppSizes.h(200),
      child: Stack(
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.w(15)),
            ),
            child: Image.asset(
              AppImages.bg_motivation,
              width: double.maxFinite,
              fit: BoxFit.fill,
            ),
          ),
          Positioned(
            right: AppSizes.w(10),
            bottom: AppSizes.h(0),
            child: SizedBox(
              width: AppSizes.w(120),
              height: AppSizes.h(200),
              child: Image.asset(imgPath, fit: BoxFit.cover),
            ),
          ),
          // text
          Positioned(
            left: AppSizes.w(30),
            top: AppSizes.h(40),
            child: SizedBox(
              width: AppSizes.w(200),
              // height: AppSizes.h(72),
              child: Text(
                title,
                style: AppFonts.playfair.copyWith(fontSize: AppSizes.sp(20)),
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              ),
            ),
          ),
          // button
          Positioned(
            left: AppSizes.w(30),
            top: AppSizes.h(130),
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.lightPinkColor.withAlpha(95),
              ),
              child: Text(
                buttonText,
                style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: AppSizes.sp(12),
                  fontWeight: FontWeight.w600,
                  color: AppColors.greyColor70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
