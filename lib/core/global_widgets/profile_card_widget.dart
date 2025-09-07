import 'package:flutter/material.dart';
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
      child: Container(
        // height: 260.h,
        width: AppSizes.w(340),
        // margin: EdgeInsets.symmetric(horizontal: 10.w),
        decoration: BoxDecoration(
          // color: AppColors.lightPinkColor.withAlpha(90),
          image: DecorationImage(
            image: AssetImage(AppImages.bg_profiles),
            fit: BoxFit.fill,
          ),
          borderRadius: BorderRadius.circular(AppSizes.w(15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: AppSizes.h(15),
                horizontal: AppSizes.w(15),
              ),
              child: Center(
                child: SizedBox(
                  height: AppSizes.h(250),
                  width: double.maxFinite,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
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
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.spaceGrotesk.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: AppSizes.sp(20),
                          color: AppColors.greyColor70,
                        ),
                      ),
                    ),
                    // event Time
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        designation,
                        style: AppFonts.spaceGrotesk.copyWith(
                          // fontWeight: FontWeight.w700,
                          fontSize: AppSizes.sp(15),
                          color: AppColors.greyColor70,
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                    // event location
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            AppIcons.location,
                            color: AppColors.primaryColor,
                          ),
                          SizedBox(width: 5),
                          Text(
                            location,
                            style: AppFonts.spaceGrotesk.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: AppSizes.sp(14),
                              color: AppColors.greyColor70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSizes.w(15),
                        vertical: AppSizes.h(10),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(AppSizes.w(15)),
                      ),
                      child:
                      Row(
                        children: [
                          Text(
                            'Follow',
                            style: AppFonts.spaceGrotesk.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: AppSizes.sp(16),
                              color: AppColors.whiteColor,
                            ),
                          ),
                          Icon(
                            Icons.add,
                            color: AppColors.whiteColor,
                            size: AppSizes.h(20),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSizes.h(30)),
          ],
        ),
      ),
    );
  }
}