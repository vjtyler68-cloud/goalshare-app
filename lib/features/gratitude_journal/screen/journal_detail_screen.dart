import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/routes/app_routes.dart';
import '../controller/journal_controller.dart';
import '../widgets/mood_selector.dart';
import 'package:spanx/core/const/app_colors.dart';

Color get _kRed => AppColors.primaryColor;
Color get _kRedDark => AppColors.primaryDarkColor;
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);
const _kBg = Color(0xffF6F4F2);
const _kStar = Color(0xffF59E0B);

/// Read-only view of a single entry, with an Edit button.
/// `Get.arguments` must be the entry's [DateTime].
class JournalDetailScreen extends StatelessWidget {
  const JournalDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = JournalController.to;
    final arg = Get.arguments;
    final DateTime date = arg is DateTime ? arg : DateTime.now();

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: Get.back,
        ),
        title: Text(
          DateFormat('MMM d, y').format(date),
          style: AppFonts.spaceGrotesk.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () =>
                Get.toNamed(AppRoutes.gratitudeScreen, arguments: date),
            icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
            label: Text('Edit',
                style: AppFonts.spaceGrotesk.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.sp)),
          ),
        ],
      ),
      body: Obx(() {
        // track reactive list so re-renders after edits
        final _ = c.entries.length;
        final entry = c.entryFor(date);
        if (entry == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_busy_rounded,
                    color: _kRed.withOpacity(0.3), size: 44.r),
                SizedBox(height: 12.h),
                Text('No entry for this day',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 14.sp, fontWeight: FontWeight.w700, color: _kText)),
                SizedBox(height: 16.h),
                GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.gratitudeScreen,
                      arguments: date),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [_kRed, _kRedDark]),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text('Write this entry',
                        style: AppFonts.spaceGrotesk.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13.sp)),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 40.h),
          children: [
            Row(
              children: [
                Text(DateFormat('EEEE, MMMM d, y').format(entry.date),
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: _kText)),
                if (entry.edited) ...[
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: _kMuted.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text('edited',
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 9.sp,
                            fontStyle: FontStyle.italic,
                            color: _kMuted)),
                  ),
                ],
              ],
            ),
            SizedBox(height: 16.h),
            if (entry.starRating > 0 || entry.mood != null)
              Row(
                children: [
                  if (entry.starRating > 0)
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < entry.starRating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 20.r,
                          color: _kStar,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (entry.mood != null)
                    Row(
                      children: [
                        Text(moodEmoji(entry.mood),
                            style: TextStyle(fontSize: 20.sp)),
                        SizedBox(width: 6.w),
                        Text(
                          entry.mood!.replaceRange(0, 1,
                              entry.mood![0].toUpperCase()),
                          style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 12.sp, color: _kMuted),
                        ),
                      ],
                    ),
                ],
              ),
            SizedBox(height: 20.h),
            Text('I AM Happy and Grateful For',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 14.sp, fontWeight: FontWeight.w800, color: _kText)),
            SizedBox(height: 10.h),
            ...entry.gratitudeItems.asMap().entries.map((e) => Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24.r,
                        height: 24.r,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _kRed.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text('${e.key + 1}',
                            style: AppFonts.spaceGrotesk.copyWith(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w800,
                                color: _kRed)),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(e.value,
                            style: AppFonts.spaceGrotesk.copyWith(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: _kText,
                                height: 1.3)),
                      ),
                    ],
                  ),
                )),
            if (entry.dayText.trim().isNotEmpty) ...[
              SizedBox(height: 16.h),
              Text('How the day went',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 14.sp, fontWeight: FontWeight.w800, color: _kText)),
              SizedBox(height: 10.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text(entry.dayText,
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 14.sp, color: _kText, height: 1.5)),
              ),
            ],
          ],
        );
      }),
    );
  }
}
