import 'package:flutter/material.dart';
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
            horizontal: AppSizes.w(30),
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
                    _progressBackground(_progressInfo('Sales', AppImages.flame, '\$ 500', '(80% completed)')),
                    _progressBackground(_progressInfo('Client Sessions', AppImages.handshake, '10', '(Total 16 Client)')),
                    _progressBackground(_progressInfo('Time Management', AppImages.time, '8.5Hr', '(Total 9 hours)')),
                    _progressBackground(_addNewTask('ADD NEW TASK', (){})),
                  ],
                ),
              ),

              // Row(
              //   children: [
              //     Container(
              //       padding: EdgeInsets.symmetric(horizontal: AppSizes.w(10), vertical: AppSizes.w(15)),
              //       width: AppSizes.w(220),
              //       decoration: BoxDecoration(
              //         image: DecorationImage(image: AssetImage(AppImages.bg_minicard), fit: BoxFit.cover),
              //         // color: AppColors.lightPinkColor,
              //         borderRadius: BorderRadius.circular(AppSizes.w(15)),
              //       ),
              //       child: Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           // title
              //           Text(
              //             'Sales',
              //             style: AppFonts.spaceGrotesk.copyWith(
              //               fontWeight: FontWeight.bold,
              //               fontSize: AppSizes.sp(15),
              //               color: AppColors.greyColor70,
              //             ),
              //           ),
              //           SizedBox(height: AppSizes.h(10)),
              //           // row
              //           Row(
              //             crossAxisAlignment: CrossAxisAlignment.center,
              //             children: [
              //               SizedBox(
              //                 height: AppSizes.h(40),
              //                 child: Image.asset(
              //                   AppImages.flame,
              //                   fit: BoxFit.cover,
              //                 ),
              //               ),
              //               Text('\$ 500',style: AppFonts.spaceGrotesk.copyWith(
              //                 fontWeight: FontWeight.bold,
              //                 fontSize: AppSizes.sp(22),
              //                 color: AppColors.greyColor70,
              //               )),
              //               SizedBox(width: AppSizes.w(5)),
              //               Text('(80% completed)',style: AppFonts.spaceGrotesk.copyWith(
              //                 fontWeight: FontWeight.bold,
              //                 fontSize: AppSizes.sp(10),
              //                 color: AppColors.blackColor.withAlpha(90),
              //               )),
              //             ],
              //           ),
              //         ],
              //       ),
              //     ),
              //
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _progressInfo(String heading, String iconPath, String title, String subtitle) {
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
          ),SizedBox(width: AppSizes.w(5)),
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
      horizontal: AppSizes.w(5),
      vertical: AppSizes.w(15),
    ),
    width: AppSizes.w(220),
    decoration: BoxDecoration(
      image: DecorationImage(
        image: AssetImage(AppImages.bg_minicard),
        fit: BoxFit.cover,
      ),
      // color: AppColors.lightPinkColor,
      borderRadius: BorderRadius.circular(AppSizes.w(15)),
    ),
    child: widget,
  );
}

Widget _addNewTask(String title, VoidCallback onTap){
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
