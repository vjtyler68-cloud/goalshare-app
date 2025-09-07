import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_icons.dart';
import 'package:spanx/core/const/app_images.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/profile_header_widget.dart';

import '../../../core/const/app_size.dart';
import '../../../core/global_widgets/motivation_card_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              ProfileHeaderWidget(),
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
                    _progressBackground(_addNewTask('ADD NEW TASK', () {})),
                  ],
                ),
              ),
              SizedBox(height: AppSizes.h(10)),
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
                items: [
                  ProfileCardWidget(
                    imgPath: 'https://randomuser.me/api/portraits/men/14.jpg',
                    name: 'John Doe',
                    designation: 'Salesperson',
                    location: 'Birmingham,UK',
                  ),
                  ProfileCardWidget(
                    imgPath: 'https://randomuser.me/api/portraits/men/14.jpg',
                    name: 'John Doe',
                    designation: 'Salesperson',
                    location: 'Birmingham,UK',
                  ),
                ],

                options: CarouselOptions(
                  autoPlay: false,
                  enlargeCenterPage: true,
                  viewportFraction: 0.8,
                  aspectRatio: 2.0,
                  initialPage: 2,
                  height: AppSizes.h(400),
                ),
              ),
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
              fontSize: AppSizes.sp(20),
              color: AppColors.greyColor70,
            ),
          ),
          SizedBox(width: AppSizes.w(5)),
          Text(
            subtitle,
            style: AppFonts.spaceGrotesk.copyWith(
              // fontWeight: FontWeight.bold,
              fontSize: AppSizes.sp(8),
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
