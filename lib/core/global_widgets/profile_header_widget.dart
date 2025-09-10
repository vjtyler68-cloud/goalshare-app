import 'package:flutter/material.dart';

import '../const/app_fonts.dart';
import '../const/app_icons.dart';
import '../const/app_size.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final VoidCallback ontap;
  const ProfileHeaderWidget({
    super.key, required this.ontap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // image
        SizedBox(
          height: AppSizes.h(42),
          width: AppSizes.w(42),
          child: CircleAvatar(
            backgroundImage: NetworkImage(
              'https://randomuser.me/api/portraits/men/10.jpg',
            ),
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
              'Zahirul Piash',
              style: AppFonts.spaceGrotesk.copyWith(
                color: Color(0xff262222),
                fontWeight: FontWeight.w700,
                fontSize: AppSizes.sp(20),
              ),
            ),
          ],
        ),
        Spacer(),
        // message
        SizedBox(
          height: AppSizes.h(42),
          width: AppSizes.w(42),
          child: GestureDetector(
            onTap: ontap,
            child: CircleAvatar(
              backgroundImage: AssetImage(AppIcons.message_large),
            ),
          ),
        ),
      ],
    );
  }
}