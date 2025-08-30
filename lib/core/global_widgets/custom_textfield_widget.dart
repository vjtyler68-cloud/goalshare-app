import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_icons.dart';
import 'package:spanx/core/const/app_size.dart';

class CustomTextFormWidget extends StatelessWidget {
  const CustomTextFormWidget({
    super.key,
    required this.sectionTitle,
    required this.textEditingController,
    this.hintText = "",
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onTogglePasswordVisibility,
    this.keyboardType = TextInputType.text,
  });

  final String sectionTitle;
  final TextEditingController textEditingController;
  final String hintText;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback? onTogglePasswordVisibility;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // title
        Text(
          sectionTitle,
          style: AppFonts.spaceGrotesk.copyWith(
            fontSize: AppSizes.sp(16),
            color: AppColors.greyColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        // textfield for email
        SizedBox(height: AppSizes.h(5)),
        TextField(
          obscureText: isPasswordVisible,
          obscuringCharacter: '*',
          controller: textEditingController,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              vertical: AppSizes.h(15),
              horizontal: AppSizes.w(18),
            ),
            filled: true,
            fillColor: AppColors.formBackgroundColor,
            // Only show suffix if it's a password field
            suffixIcon: isPassword
                ? GestureDetector(
                    onTap: onTogglePasswordVisibility,
                    child: Padding(
                      padding:  EdgeInsets.all(11.0),
                      child: SvgPicture.asset(
                        isPasswordVisible ? AppIcons.eye_off : AppIcons.eye_on,
                      ),
                    ),
                  )
                : null,
            hintText: hintText,
            hintStyle: AppFonts.spaceGrotesk.copyWith(
              color: AppColors.greyColor.withAlpha(100),
              fontSize: AppSizes.sp(13),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.h(15)),
              borderSide: BorderSide(color: AppColors.greyColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.h(15)),
              borderSide: BorderSide(color: AppColors.greyColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.h(15)),
              borderSide: BorderSide(color: AppColors.greyColor, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}
