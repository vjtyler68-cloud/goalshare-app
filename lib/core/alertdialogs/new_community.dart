import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/alertdialogs/community_upload_picture_dialog.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';
import 'package:spanx/core/global_widgets/custom_textfield_widget.dart';
import 'package:spanx/features/community_profile/controller/community_profile_controller.dart';

class NewCommunity extends StatelessWidget {
  NewCommunity({super.key});

  final CommunityProfileController communityProfileController = Get.put(
    CommunityProfileController(),
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blackColor.withAlpha(35),
      child: Center(
        child: Container(
          width: 320.w,
          height: 500.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.r),
            color: Color(0xffFFDCCD),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // New Community
                Text(
                  'New Community',
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 30.sp,
                    color: AppColors.blackColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 10.h),
                // Community Name
                CustomTextFormWidget(
                  sectionTitle: 'Community Name',
                  textEditingController: TextEditingController(),
                  hintText: 'name',
                ),
                SizedBox(height: 10.h),
                // Description
                CustomTextFormWidget(
                  sectionTitle: 'Description',
                  textEditingController: TextEditingController(),
                  hintText: 'describe about community',
                ),
                SizedBox(height: 10.h),
                // Add People
                CustomTextFormWidget(
                  sectionTitle: 'Add People',
                  textEditingController: TextEditingController(),
                  hintText: 'search by name',
                ),
                SizedBox(height: 20.h),
                Divider(color: AppColors.blackColor),

                // Suggested Peoples
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Suggested Peoples',
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: 15.h),
                Obx(() {
                  return SizedBox(
                    height: 100.h,
                    child: ListView.builder(
                      itemCount:
                          communityProfileController.suggestedPeople.length,
                      itemBuilder: (_, index) {
                        final people =
                            communityProfileController.suggestedPeople[index];

                        return GestureDetector(
                          onTap: () =>
                              communityProfileController.toggleSelection(index),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 5.w,
                              vertical: 5.h,
                            ),
                            child: Row(
                              children: [
                                ClipOval(
                                  child: CircleAvatar(
                                    child: Image.network(people.profile),
                                  ),
                                ),
                                SizedBox(width: 5.w),
                                Text(people.fullName),
                                Spacer(),
                                Container(
                                  height: 15.h,
                                  width: 15.h,
                                  // padding: EdgeInsets.all(5.h),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.blackColor,
                                    ),
                                  ),
                                  child: people.isSelected
                                      ? Icon(
                                          Icons.done_rounded,
                                          size: 10.h,
                                          color: AppColors.blackColor,
                                        )
                                      : SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
                SizedBox(height: 20.h),

                // NEXT >>
                CustomButtonWidget(
                  onTap: () {
                    Get.back();
                    CommunityUploadPictureDialog.show();
                  },
                  buttonText: 'NEXT >>',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Static method to show the popup
  static void show() {
    Get.dialog(NewCommunity(), barrierDismissible: false);
  }
}
