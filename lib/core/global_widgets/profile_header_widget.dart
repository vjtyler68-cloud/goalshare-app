import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/global_widgets/app_network_image.dart';

import '../const/app_fonts.dart';
import '../const/app_icons.dart';
import '../const/app_size.dart';
import '../user_info/user_info_controller.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final VoidCallback messageTap;
  final VoidCallback communityTap;
  final String name;
  const ProfileHeaderWidget({
    super.key, 
    required this.messageTap,
    required this.communityTap,
    required this.name
  });

  @override
  Widget build(BuildContext context) {
    final userInfoController = Get.find<UserInfoController>();
    return Row(
      children: [
        // image
        SizedBox(
          height: 30.h,
          width: 30.h,
          child: ResponsiveNetworkImage(imageUrl: userInfoController.userData.value?.profile ?? "loading...",
            shape: ImageShape.circle,
            widthPercent: 0.2,
            heightPercent: 0.1,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(width: AppSizes.w(15)),
        // name and welcome
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome!',
              style: AppFonts.spaceGrotesk.copyWith(
                color: Color(0xff474140),
                fontWeight: FontWeight.w500,
                fontSize: AppSizes.sp(14),
              ),
            ),
            Text(
              name,
              style: AppFonts.spaceGrotesk.copyWith(
                color: Color(0xff262222),
                fontWeight: FontWeight.w700,
                fontSize: AppSizes.sp(20),
              ),
            ),
          ],
        ),
        Spacer(),
        // community profile
         SizedBox(
           height: 25.h,
          width: 25.h,
          child: GestureDetector(
            onTap: communityTap,
            child: CircleAvatar(
              backgroundImage: AssetImage(AppIcons.community_large),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        // message
        SizedBox(
          height: 25.h,
          width: 25.h,
          child: GestureDetector(
            onTap: messageTap,
            child: CircleAvatar(
              backgroundImage: AssetImage(AppIcons.message_large),
            ),
          ),
        ),
      ],
    );
  }
}