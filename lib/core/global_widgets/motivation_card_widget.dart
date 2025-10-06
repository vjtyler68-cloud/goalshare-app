import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spanx/core/global_widgets/app_network_image.dart';

import '../const/app_colors.dart';
import '../const/app_fonts.dart';
import '../const/app_images.dart';

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
      height: 130.h,
      child: Stack(
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Image.asset(
              AppImages.bg_motivation,
              width: double.maxFinite,
              fit: BoxFit.fill,
            ),
          ),
          Positioned(
            right: 0.w,
            bottom: 0.h,
            child: SizedBox(
              width: 100.w,
              height: 130.h,
              child: (imgPath.isNotEmpty)
                  ? ResponsiveNetworkImage(imageUrl: imgPath)
                  : Image.asset(AppImages.motivation2, fit: BoxFit.cover),

                  /*
                  Image.network(
                      imgPath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          AppImages.motivation2,
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  */
            ),
          ),
          // text
          Positioned(
            left: 20.w,
            top: 30.h,
            child: SizedBox(
              width: 200.w,
              // height: AppSizes.h(72),
              child: Text(
                title,
                style: AppFonts.playfair.copyWith(fontSize: 17.sp),
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              ),
            ),
          ),
          // button
          Positioned(
            left: 15.w,
            bottom: 8.h,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.lightPinkColor.withAlpha(95),
              ),
              child: Text(
                buttonText,
                style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 10.sp,
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
