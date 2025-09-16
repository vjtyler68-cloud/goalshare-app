import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

import '../const/app_colors.dart';
import '../const/app_fonts.dart';
import '../const/app_icons.dart';
import '../const/app_images.dart';
import '../const/app_size.dart';

class ProfileCardWidget extends StatelessWidget {
  final String imgPath;
  final String name;
  final String designation;
  final String location;

  const ProfileCardWidget({
    super.key,
    required this.imgPath,
    required this.name,
    required this.designation,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child:
      Container(
        // height: 260.h,
        width: 210.w,
        // margin: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          // color: AppColors.lightPinkColor.withAlpha(90),
          image: DecorationImage(
            image: AssetImage(AppImages.bg_profiles),
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.circular(AppSizes.w(15)),
        ),
        child:
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
              child: Center(
                child: SizedBox(
                  height: 100.h,
                  width: double.maxFinite,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16.r),
                    child: Image.network(imgPath, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
            // event title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15.w),
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.spaceGrotesk.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16.sp,
                          color: AppColors.greyColor70,
                        ),
                      ),
                    ),
                    // event Time
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15.w),
                      child: Text(
                        designation,
                        style: AppFonts.spaceGrotesk.copyWith(
                          // fontWeight: FontWeight.w700,
                          fontSize: 12.sp,
                          color: AppColors.greyColor70,
                        ),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    // event location
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15.w),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            AppIcons.location,
                            color: AppColors.primaryColor,
                          ),
                          SizedBox(width: 3.h),
                          Text(
                            location,
                            style: AppFonts.spaceGrotesk.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 11.sp,
                              color: AppColors.greyColor70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.w),
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Follow',
                            style: AppFonts.spaceGrotesk.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 10.sp,
                              color: AppColors.whiteColor,
                            ),
                          ),
                          Icon(
                            Icons.add,
                            color: AppColors.whiteColor,
                            size: 10.h,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // SizedBox(height: .h),
          ],
        ),
      ),
    );
  }
}
