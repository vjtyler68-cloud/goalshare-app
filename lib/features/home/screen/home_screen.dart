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
              // Progress
              Row(
                children: [
                  Text(
                    'Progress',
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: AppSizes.sp(18),
                      color: AppColors.greyColor70,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'Today',
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: AppSizes.sp(18),
                      color: AppColors.greyColor70,
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down_rounded, size: AppSizes.h(30)),
                ],
              ),
              SizedBox(height: AppSizes.h(20)),
              // grids
              SizedBox(
                height: AppSizes.h(230),
                child: GridView(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSizes.w(10),
                    mainAxisSpacing: AppSizes.h(10),
                    childAspectRatio: 1.8,
                  ),
                  children: [
                    // all the widgets are written down of this file
                    _progressBackground(
                      _progressInfo(
                        'Sales',
                        AppImages.flame,
                        '\$ 500',
                        '(80% completed)',
                      ),
                    ),
                    _progressBackground(
                      _progressInfo(
                        'Client Sessions',
                        AppImages.handshake,
                        '10',
                        '(Total 16 Client)',
                      ),
                    ),
                    _progressBackground(
                      _progressInfo(
                        'Time Management',
                        AppImages.time,
                        '8.5Hr',
                        '(Total 9 hours)',
                      ),
                    ),
                    _progressBackground(_addNewTask('ADD NEW TASK', () {
                      // Get.toNamed(AppRoutes.motivationalNudgeScreen);
                      CreateNewGoal.show(onContinue: (){});
                    })),
                  ],
                ),
              ),
              SizedBox(height: AppSizes.h(10)),
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

Widget _progressInfo(
  String heading,
  String iconPath,
  String title,
  String subtitle,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // title
      Text(
        heading,
        style: AppFonts.spaceGrotesk.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: AppSizes.sp(15),
          color: AppColors.greyColor70,
        ),
      ),
      SizedBox(height: AppSizes.h(10)),
      // row
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: AppSizes.h(30),
            child: Image.asset(iconPath, fit: BoxFit.cover),
          ),
          SizedBox(width: AppSizes.w(5)),
          Text(
            title,
            style: AppFonts.spaceGrotesk.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: AppSizes.sp(18),
              color: AppColors.greyColor70,
            ),
          ),
          SizedBox(width: AppSizes.w(5)),
          Text(
            subtitle,
            style: AppFonts.spaceGrotesk.copyWith(
              // fontWeight: FontWeight.bold,
              fontSize: AppSizes.sp(9),
              color: AppColors.blackColor,
            ),
          ),
        ],
      ),
    ],
  );
}

Widget _progressBackground(Widget widget) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: AppSizes.w(6),
      vertical: AppSizes.w(15),
    ),
    width: AppSizes.w(220),
    decoration: BoxDecoration(
      image: DecorationImage(
        image: AssetImage(AppImages.bg_minicard),
        fit: BoxFit.fill,
      ),
      // color: AppColors.lightPinkColor,
      borderRadius: BorderRadius.circular(AppSizes.w(15)),
    ),
    child: widget,
  );
}

Widget _addNewTask(String title, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: AppSizes.h(30),
          child: Image.asset(AppImages.add, fit: BoxFit.cover),
        ),
        SizedBox(width: AppSizes.w(10)),
        // Image.asset(AppImages.add),
        Text(
          title,
          style: AppFonts.spaceGrotesk.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: AppSizes.sp(15),
            color: AppColors.greyColor70,
          ),
        ),
      ],
    ),
  );
}
