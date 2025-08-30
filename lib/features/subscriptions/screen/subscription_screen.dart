import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:get/instance_manager.dart';
import 'package:get/utils.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_icons.dart';
import 'package:spanx/core/const/app_images.dart';
import 'package:spanx/core/const/app_size.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';
import 'package:spanx/features/subscriptions/controller/subscription_controller.dart';
import 'package:spanx/features/subscriptions/model/subscription_model.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SubscriptionController subscriptionController = Get.put(
      SubscriptionController(),
    );
    return BackgroundScreen(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.w(30),
          vertical: AppSizes.h(30),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // subscription image
            Image.asset(AppImages.subscription),
            SizedBox(height: AppSizes.h(50)),
            // text
            Text(
              'Your First 3 Months — On Us!',
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: AppSizes.sp(25),
                fontWeight: FontWeight.bold,
                color: AppColors.greyColor,
              ),
            ),

            SizedBox(height: AppSizes.h(10)),

            // text
            Text(
              'Sign up today and enjoy full access for 90 days. Cancel anytime. When you’re ready, choose a plan that fits your business.',
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: AppSizes.sp(14),
                color: AppColors.greyColor,
              ),
              textAlign: TextAlign.center,
            ),
            // SizedBox(height: AppSizes.h(20)),

            // subscription models
            SizedBox(
              height: AppSizes.h(280),
              child: ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: SubscriptionModel.subscriptionModelList.length,

                itemBuilder: (context, index) {
                  final subscriptionModel =
                      SubscriptionModel.subscriptionModelList[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: AppSizes.h(10)),
                    child: Obx(() {
                      return InkWell(
                        onTap: () {
                          subscriptionController.selectedPlan(index);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.formBackgroundColor,
                            borderRadius: BorderRadius.circular(AppSizes.w(30)),
                            border: Border.all(
                              color:
                                  subscriptionController.selectedIndex.value ==
                                      index
                                  ? AppColors.maroonColor
                                  : Colors.transparent,
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(AppSizes.h(20)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // icon
                                SvgPicture.asset(
                                  subscriptionController.selectedIndex.value ==
                                          index
                                      ? AppIcons.circle_marked
                                      : AppIcons.circle,
                                ),
                                SizedBox(width: AppSizes.w(10)),
                                // txt
                                Text(
                                  subscriptionModel.title,
                                  style: AppFonts.spaceGrotesk.copyWith(
                                    fontSize: AppSizes.sp(16),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: AppSizes.w(5)),

                                // save
                              subscriptionModel.showSave ? Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.blueColor.withAlpha(50),
                                    borderRadius: BorderRadius.circular(
                                      AppSizes.w(10),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppSizes.h(7),
                                      vertical: (AppSizes.h(5)),
                                    ),
                                    child: Text(
                                      subscriptionModel.save,
                                      style: AppFonts.spaceGrotesk.copyWith(
                                        color: AppColors.blueColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: AppSizes.sp(10),
                                      ),
                                    ),
                                  ),
                                ) : SizedBox(),
                                Spacer(),

                                // txt
                                Text(
                                  subscriptionModel.price,
                                  style: AppFonts.spaceGrotesk.copyWith(
                                    fontSize: AppSizes.sp(16),
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),

            SizedBox(height: AppSizes.h(40)),
            // button
            CustomButtonWidget(onTap: () {}, buttonText: 'Continue'),
          ],
        ),
      ),
    );
  }
}
