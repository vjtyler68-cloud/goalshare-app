import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../const/app_colors.dart';

/// A lightweight top-left back button for pushed screens that don't use an
/// [AppBar]. It automatically hides itself when there is nothing to pop (so it
/// never shows a dead button on root/entry screens) unless a custom [onTap] is
/// provided.
class AppBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color? color;

  const AppBackButton({super.key, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    if (!canPop && onTap == null) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        borderRadius: BorderRadius.circular(24.r),
        onTap: onTap ?? () => Get.back(),
        child: Padding(
          padding: EdgeInsets.all(6.r),
          child: Icon(
            Icons.arrow_back_ios_new,
            size: 20.sp,
            color: color ?? AppColors.greyColor70,
          ),
        ),
      ),
    );
  }
}
