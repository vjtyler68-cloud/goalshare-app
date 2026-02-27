import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_icons.dart';
import 'package:spanx/core/const/app_size.dart';

class OAuthButtonWidget extends StatelessWidget {
  const OAuthButtonWidget({
    super.key,
    required this.onPressed,
  });


  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.formBackgroundColor,
          side: BorderSide(color: AppColors.whiteColor, width: 1),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.h(15)),
          ),
        ),
        onPressed: onPressed,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSizes.h(15)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // icon
              SvgPicture.asset(AppIcons.google_icon, height: AppSizes.h(20)),
              SizedBox(width: AppSizes.w(10)),
              // text
              Text(
                'Google Login',
                style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: AppSizes.sp(15),
                  color: AppColors.greyColor70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
