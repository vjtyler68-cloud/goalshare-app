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
import 'package:spanx/features/home/model/home_screen_model.dart';

class CommunityProfileScreen extends StatelessWidget {
  CommunityProfileScreen({super.key});

  final CommunityProfileController controller = Get.put(
    CommunityProfileController(),
  );

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),

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
                alignment: AlignmentGeometry.topRight,
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

              //  community profiles
              CarouselSlider(
                items: CommunityProfileModel.profiles
                    .map(
                      (profile) => ProfileCardWidget(
                        imgPath: profile.imgPath,
                        name: profile.name,
                        designation: profile.designation,
                        location: profile.location,
                      ),
                    )
                    .toList(),

                options: CarouselOptions(
                  autoPlay: false,
                  viewportFraction: 0.8,
                  aspectRatio: 16 / 9,
                  initialPage: 0,
                  height: 190.h,
                ),
              ),

              // user data
              // Obx(() {
              //   return controller.isLoading.value
              //       ? LoadingAnimationWidget.staggeredDotsWave(
              //           color: AppColors.primaryColor,
              //           size: 30.h,
              //         )
              //       : SizedBox(
              //           height: 200.h,
              //           child: ListView.builder(
              //             itemCount: controller.userData.length,
              //             itemBuilder: (_, index) {
              //               final users = controller.userData[index];
              //               return Text("${users.fullName}");
              //             },
              //           ),
              //         );
              // }),
            ],
          ),
        ),
      ),
    );
  }
}
