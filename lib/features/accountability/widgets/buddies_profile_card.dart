import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';

import '../controller/buddies_controller.dart';
import '../ui/accountability_match_screen.dart';
import '../ui/buddies_hub_screen.dart';
import '../ui/buddy_questionnaire_screen.dart';

const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// The Profile-tab "Buddies" stat card — the rolling ★ average + cycles, shown
/// directly under the QR/Add area, and the entry point into the whole feature.
///
/// Matches the app's white rounded-card styling so it doesn't look bolted-on.
/// Tapping deep-links to the right place for the user's current state.
class BuddiesProfileCard extends StatelessWidget {
  const BuddiesProfileCard({super.key});

  void _open() {
    final c = BuddiesController.to;
    if (c.needsOnboarding) {
      Get.to(() => const BuddyQuestionnaireScreen());
    } else if (c.isMatched) {
      Get.to(() => const AccountabilityMatchScreen());
    } else {
      Get.to(() => const BuddiesHubScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primaryColor;
    return Obx(() {
      final c = BuddiesController.to;
      final p = c.profile.value;
      final rated = (p?.totalRatings ?? 0) > 0;

      final String value;
      if (p == null || !p.isComplete) {
        value = 'Set up your buddy profile';
      } else if (!rated) {
        value = c.isMatched ? 'Matched · not rated yet' : 'Not rated yet';
      } else {
        value = '${p.starLabel}  •  ${p.cyclesCompleted} '
            '${p.cyclesCompleted == 1 ? 'cycle' : 'cycles'}';
      }
      final showTier = p?.isReliableBuddy ?? false;

      return GestureDetector(
        onTap: _open,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42.r,
                height: 42.r,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.handshake_outlined, color: accent, size: 22.r),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Buddies',
                            style: AppFonts.spaceGrotesk.copyWith(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w800,
                                color: _kText)),
                        if (showTier) ...[
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text('Reliable Buddy 🤝',
                                style: AppFonts.spaceGrotesk.copyWith(
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.w800,
                                    color: accent)),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w600,
                            color: _kMuted)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: const Color(0xffB0AAAA)),
            ],
          ),
        ),
      );
    });
  }
}
