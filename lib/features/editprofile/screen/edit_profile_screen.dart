import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/subpage_appbar_widget.dart';
import 'package:spanx/features/profile_tab/controller/profile_tab_controller.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/const/app_fonts.dart';
import '../../../core/const/app_icons.dart';
import '../../../core/global_widgets/app_network_image.dart';
import '../../../core/global_widgets/custom_button_widget.dart';
import '../../../core/global_widgets/custom_textfield_widget.dart';
import '../../../routes/app_routes.dart';

class EditProfileScreen extends StatelessWidget {
   EditProfileScreen({super.key});
final ProfileTabController controller = Get.find<ProfileTabController>();
  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(child: SafeArea(child: SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
      child: Column(
      children: [
        // top app bar
        SubPageAppbarWidget(appbarTitle: 'Edit Profile', onPressed: (){
          Get.back();
        }),
        SizedBox(height: 15.h,),
        // Profile Image
        ResponsiveNetworkImage(
          imageUrl: controller.userImageUrl.value,
          shape: ImageShape.circle,
          widthPercent: 0.2,
          heightPercent: 0.1,
          fit: BoxFit.cover,
        ),
        // full name
        CustomTextFormWidget(
          sectionTitle: "Full Name",
          hintText: 'full name',
          textEditingController: TextEditingController(),
          keyboardType: TextInputType.text,
        ),
        SizedBox(height: 15.h),
        // Email Address
        CustomTextFormWidget(
          sectionTitle: "Email Address",
          hintText: 'email address',
          textEditingController: TextEditingController(),
          keyboardType: TextInputType.emailAddress,
        ),SizedBox(height: 15.h),

        // Business Type
        CustomTextFormWidget(
          sectionTitle: "Business Type",
          hintText: 'others',
          textEditingController: TextEditingController(),
          keyboardType: TextInputType.text,
        ),
        SizedBox(height: 15.h),
        // Describe Profession
        CustomTextFormWidget(
          sectionTitle: "Describe Profession",
          hintText: 'describe',
          textEditingController: TextEditingController(),
          keyboardType: TextInputType.text,
        ),
        SizedBox(height: 15.h),
        // City
        CustomTextFormWidget(
          sectionTitle: "City",
          hintText: 'city',
          textEditingController: TextEditingController(),
          keyboardType: TextInputType.text,
        ),
        SizedBox(height: 15.h),
        // Full Address
        CustomTextFormWidget(
          sectionTitle: "Full Address",
          hintText: 'address',
          textEditingController: TextEditingController(),
          keyboardType: TextInputType.text,
        ),
        SizedBox(height: 15.h),
        // Phone
        CustomTextFormWidget(
          sectionTitle: "Phone",
          hintText: 'XX XXX XXXX',
          textEditingController: TextEditingController(),
          keyboardType: TextInputType.number,
          prefixWidget: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // flag icon
              Image.asset(
                AppIcons.uk_flag_png,
                height: 20.h,
                width: 20.w,
              ),
              SizedBox(height: 15.h),
              Text(
                "+44 |",
                style: AppFonts.spaceGrotesk.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),SizedBox(height: 15.h),

        // button
        CustomButtonWidget(
          onTap: () {
            // Get.toNamed(AppRoutes.uploadProfilePictureScreen);
          },
          buttonText: "Save Changes",
        ),
        SizedBox(height: 10.h),
        // button
        TextButton(
          onPressed: () {},
          child: Text(
            'Cancel',
            style: AppFonts.spaceGrotesk.copyWith(
              fontSize: 12.sp,
              color: AppColors.blackColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),


      ],
    ),)));
  }
}
