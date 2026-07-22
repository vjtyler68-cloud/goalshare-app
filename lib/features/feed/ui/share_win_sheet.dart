import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/const/app_fonts.dart';
import '../controller/feed_controller.dart';

Color get _kRed => AppColors.primaryColor;
Color get _kRedDk => AppColors.primaryDarkColor;
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// Compose + share a manual "win" to the Friends Activity Feed.
class ShareWinSheet {
  ShareWinSheet._();

  static void show(FeedController controller) {
    final textC = TextEditingController();
    Get.bottomSheet(
      _Body(controller: controller, textC: textC),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _Body extends StatelessWidget {
  final FeedController controller;
  final TextEditingController textC;
  const _Body({required this.controller, required this.textC});

  Future<void> _share() async {
    final text = textC.text.trim();
    if (text.isEmpty) return;
    await controller.shareWin(text);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 20.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r)),
              ),
            ),
            Text('Share a win 🎉',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
            SizedBox(height: 6.h),
            Text('What did you accomplish? Your friends will see it and cheer.',
                style: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 12.sp, color: _kMuted)),
            SizedBox(height: 14.h),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xffF6F4F2),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: TextField(
                controller: textC,
                autofocus: true,
                maxLength: 200,
                minLines: 2,
                maxLines: 5,
                style: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 15.sp, color: _kText),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'e.g. Hit 40 doors and closed 2 deals today! 🔥',
                  hintStyle: AppFonts.spaceGrotesk
                      .copyWith(fontSize: 13.sp, color: _kMuted),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Obx(() => GestureDetector(
                  onTap: controller.posting.value ? null : _share,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [_kRed, _kRedDk]),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: Center(
                      child: controller.posting.value
                          ? SizedBox(
                              width: 20.r,
                              height: 20.r,
                              child: const CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text('Share',
                              style: AppFonts.spaceGrotesk.copyWith(
                                  color: Colors.white,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w800)),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
