import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:spanx/core/alertdialogs/new_community.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_icons.dart';
import 'package:spanx/core/const/app_images.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/profile_card_widget.dart';
import 'package:spanx/core/global_widgets/subpage_appbar_widget.dart';
import 'package:spanx/features/community_profile/controller/community_profile_controller.dart';
import 'package:spanx/features/community_profile/model/community_profile_model.dart';
import 'package:spanx/features/home/model/home_screen_model.dart';

import '../../../core/global_widgets/app_loading.dart';

class CommunityProfileScreen extends StatelessWidget {
  CommunityProfileScreen({super.key});

  final CommunityProfileController controller = Get.put(
    CommunityProfileController(),
  );

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
        minimum: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // appbar
            SubPageAppbarWidget(
              appbarTitle: 'Community Profile',
              onPressed: () {
                Get.back();
              },
            ),
            SizedBox(height: 10.h),

            // Community Profiles
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () {
                  NewCommunity.show();
                },
                child: Container(
                  width: 150.w,
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(AppImages.bg_minicard),
                      fit: BoxFit.fill,
                    ),
                  ),
                  child: Row(
                    children: [
                      Image.asset(AppIcons.box_add, height: 15.h),
                      SizedBox(width: 5.w),
                      Text(
                        'Create Community',
                        style: AppFonts.spaceGrotesk.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 10.sp,
                          color: AppColors.greyColor70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20.h),

            Expanded(
              child: Obx(() {return controller.isLoading.value ? Center(child: loading()) : ListView.builder(
                itemCount: controller.allUserList.length,
                itemBuilder: (context, index) {
                  return ProfileCardWidget(
                    profileModel: controller.allUserList[index],
                  );
                },
              );})
            ),

          ],
        ),
      ),
    );
  }
}
