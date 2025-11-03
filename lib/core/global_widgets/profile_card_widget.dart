import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:spanx/features/community_profile/controller/community_profile_controller.dart';
import 'package:spanx/features/community_profile/model/community_profile_model.dart';

import '../const/app_colors.dart';
import '../const/app_fonts.dart';
import '../const/app_icons.dart';

class ProfileCardWidget extends StatelessWidget {

final CommunityProfileModel profileModel;
final user = Get.find<CommunityProfileController>();
   ProfileCardWidget({
    super.key,
    required this.profileModel

  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5.h),
        padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 5.w),
        decoration: BoxDecoration(
          color: AppColors.whiteColor.withAlpha(95),

          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          children: [
            // image
            SizedBox(
          height: 35.h,
          width: 35.h,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25.r),
            child: Image.network(profileModel.profile ?? 'https://tanzolymp.com/images/default-non-user-no-photo-1.jpg', fit: BoxFit.cover,),
          )
        ),
            SizedBox(width: 10.w),
            // info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // name
                Text(
                  profileModel.fullName ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16.sp,
                    color: AppColors.greyColor70,
                  ),
                ),
                // designation
                Text(
                  profileModel.businessType ?? "",
                  style: AppFonts.spaceGrotesk.copyWith(
                    // fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                    color: AppColors.greyColor70,
                  ),
                ),
                // location
                Row(
                  children: [
                    SvgPicture.asset(
                      AppIcons.location,
                      color: AppColors.primaryColor,
                    ),
                    SizedBox(width: 3.h),
                    Text(
                      profileModel.address ?? "",
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 11.sp,
                        color: AppColors.greyColor70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Spacer(),

            // follow
            ElevatedButton(
              onPressed: (){},
              style: ElevatedButton.styleFrom(
                backgroundColor:  AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Follow',
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 10.sp,
                      color: AppColors.whiteColor,
                    ),
                  ),
                  Icon(Icons.add, color: AppColors.whiteColor, size: 10.h),
                ],
              ),
            ),
            // GestureDetector(
            //   onTap: () {},
            //   child:
            //   Container(
            //     padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            //     decoration: BoxDecoration(
            //       color: AppColors.primaryColor,
            //       borderRadius: BorderRadius.circular(5.r),
            //     ),
            //     child: Row(
            //       children: [
            //         Text(
            //           'Follow',
            //           style: AppFonts.spaceGrotesk.copyWith(
            //             fontWeight: FontWeight.w500,
            //             fontSize: 10.sp,
            //             color: AppColors.whiteColor,
            //           ),
            //         ),
            //         Icon(Icons.add, color: AppColors.whiteColor, size: 10.h),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

/*
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
*/
