import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_icons.dart';
import 'package:spanx/core/const/app_images.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/profile_header_widget.dart';
import 'package:spanx/features/home/model/home_screen_model.dart';
import 'package:spanx/features/home/alertdialogs/create_new_goal.dart';
import 'package:spanx/routes/app_routes.dart';

import '../../../core/const/app_size.dart';
import '../../../core/global_widgets/motivation_card_widget.dart';
import '../../../core/global_widgets/profile_card_widget.dart';
import '../../chat_tab/ui/chat_message.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // void _showCreateGoalPopup() {
  //   CreateNewGoal.show(
  //     onContinue: () {
  //       Get.back();
  //       // Get.off(() => SignInScreen()); // Navigate to SignInScreen
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSizes.w(20),
            vertical: AppSizes.h(30),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [


              // profile header
              ProfileHeaderWidget(ontap: (){
                  Get.to(()=> MessagesPage());
              },),
              SizedBox(height: AppSizes.h(20)),


              // motivational card
              MotivationCardWidget(
                title: 'Every great business starts with one small sale.',
                buttonText: 'Set new >>',
                imgPath: AppImages.motivation1,
                onTap: () {},
              ),
              SizedBox(height: AppSizes.h(20)),

              // priming and vision board
              _goalsButton(
                "Start Priming >>",
                    () {
                  Get.toNamed(AppRoutes.primingScreen);
                },
                true,
                AppImages.priming,
              ),
              SizedBox(height: AppSizes.h(20)),
              _goalsButton(
                "Vision Board >>",
                    () {
                  Get.toNamed(AppRoutes.visionPageScreen);
                },
                false,
                AppImages.priming,
              ),

              SizedBox(height: AppSizes.h(20)),


              // Community Profiles
              Row(
                children: [
                  Text(
                    'Community Profiles ',
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: AppSizes.sp(18),
                      color: AppColors.greyColor70,
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSizes.w(10),
                      vertical: AppSizes.h(5),
                    ),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(AppImages.bg_minicard),
                        fit: BoxFit.fill,
                      ),
                    ),
                    child: Row(
                      children: [
                        Image.asset(AppIcons.box_add, height: AppSizes.h(20)),
                        SizedBox(width: AppSizes.w(5)),
                        Text(
                          'Create Community',
                          style: AppFonts.spaceGrotesk.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: AppSizes.sp(12),
                            color: AppColors.greyColor70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.h(20)),
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
                  // enlargeCenterPage: true,
                  viewportFraction: 0.8,
                  aspectRatio: 16 / 9,
                  initialPage: 0,
                  height: AppSizes.h(400),
                ),
              ),
              SizedBox(height: AppSizes.h(20)),
              // Recent Activity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Activity',
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: AppSizes.sp(18),
                      color: AppColors.greyColor70,
                    ),
                  ),
                  Text(
                    'View All',
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: AppSizes.sp(18),
                      color: AppColors.greyColor70,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSizes.h(20)),
              ...List.generate(RecentActivityModel.recentActivity.length, (index){
                final activity = RecentActivityModel.recentActivity[index];
                return Container(
                  margin: EdgeInsets.symmetric(vertical: AppSizes.h(5)),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSizes.w(10),
                    vertical: AppSizes.h(15),
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.whiteColor),
                    image: DecorationImage(
                      image: AssetImage(AppImages.bg_profiles),
                      fit: BoxFit.fill,
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.w(15)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: AppSizes.w(30),
                        height: AppSizes.h(30),
                        child: Image.asset(activity.iconPath),
                      ),
                      SizedBox(width: AppSizes.w(15)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.title,
                            style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: AppSizes.sp(15),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            activity.time,
                            style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: AppSizes.sp(10),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              SizedBox(height: AppSizes.h(100)),


            ],
          ),
        ),
      ),
    );
  }
}



// this is the widget of two buttons here start priming
Widget _goalsButton(
    String text,
    VoidCallback ontap,
    bool isImage,
    String? imgPath,
    ) {
  return GestureDetector(
    onTap: ontap,
    child: Container(
      height: AppSizes.h(60),
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.w(20),
        vertical: AppSizes.w(12),
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.whiteColor),
        borderRadius: BorderRadius.circular(AppSizes.w(20)),
        image: DecorationImage(
          image: AssetImage(AppImages.bg_minicard),
          fit: BoxFit.fill,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // image
          isImage ? Image.asset(imgPath!) : SizedBox(),
          SizedBox(width: AppSizes.w(10)),
          // text
          Text(
            text,
            style: AppFonts.spaceGrotesk.copyWith(
              fontSize: AppSizes.sp(16),
              fontWeight: FontWeight.w700,
              color: AppColors.greyColor70,
            ),
          ),
        ],
      ),
    ),
  );
}
