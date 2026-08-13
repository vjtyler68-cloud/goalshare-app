import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/routes/app_routes.dart';

import '../controller/org_controller.dart';
import '../data/org_models.dart';

const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// Bottom sheet for owners with multiple orgs: switch the active org, or create
/// / join another. Regular members never see this (they have a single org).
class OrgSwitcher {
  OrgSwitcher._();

  static void show() {
    final c = OrgController.to;
    final accent = AppColors.primaryColor;
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your organizations',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
            SizedBox(height: 14.h),
            Obx(() => Column(
                  children: [
                    for (final o in c.myOrgs)
                      GestureDetector(
                        onTap: () {
                          c.switchOrg(o.id);
                          Get.back();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          margin: EdgeInsets.only(bottom: 10.h),
                          padding: EdgeInsets.all(14.r),
                          decoration: BoxDecoration(
                            color: c.myOrg.value?.id == o.id
                                ? accent.withOpacity(0.08)
                                : const Color(0xffF6F4F2),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                                color: c.myOrg.value?.id == o.id
                                    ? accent
                                    : Colors.transparent,
                                width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.workspaces_rounded,
                                  color: accent, size: 20.r),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(o.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppFonts.spaceGrotesk.copyWith(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w800,
                                            color: _kText)),
                                    Text(
                                        '${o.orgType.label} · ${o.isAdmin ? o.orgType.adminLabel : o.orgType.memberLabel}',
                                        style: AppFonts.spaceGrotesk.copyWith(
                                            fontSize: 11.sp, color: _kMuted)),
                                  ],
                                ),
                              ),
                              if (c.myOrg.value?.id == o.id)
                                Icon(Icons.check_circle_rounded,
                                    color: accent, size: 20.r),
                            ],
                          ),
                        ),
                      ),
                  ],
                )),
            Obx(() => c.canHoldMultiple
                ? GestureDetector(
                    onTap: () {
                      Get.back();
                      Get.toNamed(AppRoutes.orgOnboardingScreen,
                          arguments: {'fromProfile': true});
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: EdgeInsets.all(15.r),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_business_rounded,
                              color: Colors.white, size: 20.r),
                          SizedBox(width: 10.w),
                          Text('Create a new organization',
                              style: AppFonts.spaceGrotesk.copyWith(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink()),
            SizedBox(height: 6.h),
            Center(
              child: Text('You stay in your other organizations — switch anytime.',
                  textAlign: TextAlign.center,
                  style: AppFonts.spaceGrotesk
                      .copyWith(fontSize: 10.5.sp, color: _kMuted)),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
