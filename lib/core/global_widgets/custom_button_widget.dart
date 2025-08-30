import 'package:flutter/material.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_size.dart';

class CustomButtonWidget extends StatelessWidget {
  final VoidCallback onTap;
  final String buttonText;
  final Widget? row2;
  const CustomButtonWidget({
    super.key,
    required this.onTap,
    this.row2,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.w(10)),
        ),
      ),
      onPressed: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.h(18)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              buttonText,
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: AppSizes.sp(16),
                color: AppColors.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: AppSizes.w(5)),
            row2!,
          ],
        ),
      ),
    );
  }
}
