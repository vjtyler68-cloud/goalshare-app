import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';

import '../controller/quick_access_controller.dart';
import '../data/quick_access_module.dart';

const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// "Add Card" library for the home Quick Access grid: every module the user has
/// hidden, tap to put it back on the dashboard.
///
/// Driven entirely by [QuickAccessRegistry], so a module added there in a
/// future build appears here automatically once hidden.
class AddQuickCardSheet extends StatelessWidget {
  const AddQuickCardSheet({super.key});

  static void show() {
    Get.bottomSheet(
      const AddQuickCardSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final quick = QuickAccessController.to;
    return Container(
      constraints: BoxConstraints(maxHeight: 0.75.sh),
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 24.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 18.h),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          Text(
            'Add a card',
            style: AppFonts.spaceGrotesk.copyWith(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: _kText,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Cards you removed are kept safe — adding one back restores all of '
            'its data.',
            style: AppFonts.spaceGrotesk.copyWith(
              fontSize: 12.sp,
              height: 1.5,
              color: _kMuted,
            ),
          ),
          SizedBox(height: 16.h),
          Flexible(
            child: Obx(() {
              final hidden = quick.hiddenModules;
              if (hidden.isEmpty) return _emptyState();
              return ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: hidden.length,
                separatorBuilder: (_, __) => SizedBox(height: 10.h),
                itemBuilder: (_, i) => _moduleRow(hidden[i], quick),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _moduleRow(QuickAccessModule m, QuickAccessController quick) {
    return GestureDetector(
      onTap: () {
        quick.showModule(m.id);
        // Close once the library is empty, otherwise keep it open so several
        // cards can be added in one go.
        if (quick.hiddenModules.isEmpty) Get.back();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                color: m.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Icon(m.icon, color: m.color, size: 19.r),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: _kText,
                    ),
                  ),
                  Text(
                    m.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 10.sp,
                      color: _kMuted,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              width: 26.r,
              height: 26.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor,
              ),
              child: Icon(Icons.add, color: Colors.white, size: 15.r),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.dashboard_customize_outlined,
              color: AppColors.primaryColor.withOpacity(0.4), size: 32.r),
          SizedBox(height: 8.h),
          Text(
            'All cards are already on your dashboard.',
            textAlign: TextAlign.center,
            style: AppFonts.spaceGrotesk.copyWith(
              fontSize: 13.sp,
              color: _kMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
