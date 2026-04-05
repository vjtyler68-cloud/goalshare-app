import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:get/instance_manager.dart';
import 'package:logger/logger.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_icons.dart';
import 'package:spanx/core/const/app_images.dart';
import 'package:spanx/core/const/app_size.dart';
import 'package:spanx/core/global_widgets/app_loading.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_button_widget.dart';
import 'package:spanx/features/subscriptions/controller/subscription_controller.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    SubscriptionController subscriptionController =
        Get.find<SubscriptionController>();

    return BackgroundScreen(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: Obx(() {
          if (subscriptionController.isLoading.value) {
            return loading();
          } else {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // subscription image
                Image.asset(AppImages.subscription),
                SizedBox(height: 40.sp),
                // text
                Text(
                  'Your First 3 Month — On Us!',
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 23.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.greyColor70,
                  ),
                ),

                SizedBox(height: 10.h),

                // text
                Text(
                  'Sign up today and enjoy full access for 90 days. Cancel anytime. When you’re ready, choose a plan that fits your business.',
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.greyColor70,
                  ),
                  textAlign: TextAlign.center,
                ),
                // SizedBox(height: AppSizes.h(20)),

                // subscription models
                Subscriptions(subscriptionController: subscriptionController),

                SizedBox(height: 35.h),
                // button
                Obx(() {
                  return subscriptionController
                          .isCreateSubscriptionLoading
                          .value
                      ? loading()
                      : CustomButtonWidget(
                          onTap: () async {
                            subscriptionController.createSubscriptionPackages(
                              subscriptionController
                                  .subscriptionList[subscriptionController
                                      .selectedIndex
                                      .value]
                                  .id
                                  .toString(),
                            );
                          },
                          buttonText: 'Continue',
                        );
                }),
              ],
            );
          }
        }),
      ),
    );
  }
}

class Subscriptions extends StatelessWidget {
  Subscriptions({super.key, required this.subscriptionController});

  final SubscriptionController subscriptionController;
  final logger = Logger();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250.h,
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: subscriptionController.subscriptionList.length,

        itemBuilder: (context, index) {
          final subscriptionModel =
              subscriptionController.subscriptionList[index];
          return Padding(
            padding: EdgeInsets.only(bottom: AppSizes.h(10)),
            child: Obx(() {
              return InkWell(
                onTap: () {
                  subscriptionController.selectedPlan(index);

                  logger.d(
                    subscriptionController
                        .subscriptionList[subscriptionController
                            .selectedIndex
                            .value]
                        .id,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.formBackgroundColor,
                    borderRadius: BorderRadius.circular(AppSizes.w(30)),
                    border: Border.all(
                      color: subscriptionController.selectedIndex.value == index
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
                          subscriptionController.selectedIndex.value == index
                              ? AppIcons.circle_marked
                              : AppIcons.circle,
                        ),
                        SizedBox(width: AppSizes.w(10)),
                        // txt
                        Text(
                          subscriptionModel.title ?? "",
                          style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: AppSizes.sp(16),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: AppSizes.w(5)),

                        // save
                        // subscriptionModel.showSave
                        //     ? Container(
                        //         decoration: BoxDecoration(
                        //           color: AppColors.blueColor.withAlpha(50),
                        //           borderRadius: BorderRadius.circular(
                        //             AppSizes.w(10),
                        //           ),
                        //         ),
                        //         child: Padding(
                        //           padding: EdgeInsets.symmetric(
                        //             horizontal: AppSizes.h(7),
                        //             vertical: (AppSizes.h(5)),
                        //           ),
                        //           child: Text(
                        //             subscriptionModel.save,
                        //             style: AppFonts.spaceGrotesk.copyWith(
                        //               color: AppColors.blueColor,
                        //               fontWeight: FontWeight.bold,
                        //               fontSize: AppSizes.sp(10),
                        //             ),
                        //           ),
                        //         ),
                        //       )
                        //     : SizedBox(),
                        Spacer(),

                        // txt
                        Text(
                          subscriptionModel.price == 0
                              ? "FREE"
                              : "${subscriptionModel.price ?? 0}/${subscriptionController.getPackageString(subscriptionModel.subscriptionType!)}",
                          style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 13.sp,
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
    );
  }
}
