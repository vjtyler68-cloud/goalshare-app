import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../const/app_colors.dart';
import '../const/app_fonts.dart';
import '../const/app_size.dart';

class SubPageAppbarWidget extends StatelessWidget {
  final String appbarTitle;
  final VoidCallback onPressed;
  const SubPageAppbarWidget({
    super.key, required this.appbarTitle, required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // IconButton(icon: Icon(Icons.arrow_back_ios_outlined), onPressed: (){},),
        InkWell(
          onTap: onPressed,
          child: Icon(Icons.arrow_back_ios_outlined),
        ),
        SizedBox(width: 10.w),
        Text(
          appbarTitle,
          // overflow: TextOverflow.ellipsis,
          style: AppFonts.spaceGrotesk.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 20.sp,
            color: AppColors.greyColor70,

          ),
        ),
      ],
    );
  }
}