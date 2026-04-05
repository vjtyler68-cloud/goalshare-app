import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
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
import 'package:spanx/routes/app_routes.dart';

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
          } else if (subscriptionController.isSubscribed.value) {
            // User is already subscribed
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(AppImages.subscription),
                SizedBox(height: 40.sp),
                Text(
                  'You are Premium Member!',
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 23.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Your subscription is active until ${subscriptionController.subscriptionEndDate.value?.toString().split(' ')[0] ?? 'N/A'}',
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.greyColor70,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 35.h),
                CustomButtonWidget(
                  onTap: () => Get.offAllNamed(AppRoutes.mainNavBarScreen),
                  buttonText: 'Continue',
                ),
              ],
            );
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
                            if (subscriptionController.useIAP.value) {
                              // Use IAP purchase
                              final selectedProduct =
                                  subscriptionController
                                      .iapProducts[subscriptionController
                                      .selectedIndex
                                      .value];
                              await subscriptionController.buySubscriptionIAP(
                                selectedProduct.id,
                              );
                            } else {
                              // Use API subscription
                              subscriptionController.createSubscriptionPackages(
                                subscriptionController
                                    .subscriptionList[subscriptionController
                                        .selectedIndex
                                        .value]
                                    .id
                                    .toString(),
                              );
                            }
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
    return Obx(() {
      // Show IAP products if available, otherwise show API subscriptions
      final displayList = subscriptionController.useIAP.value
          ? subscriptionController.iapProducts
          : subscriptionController.subscriptionList;

      return SizedBox(
        height: 250.h,
        child: ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: displayList.length,
          itemBuilder: (context, index) {
            // Handle both ProductDetails (IAP) and SubscriptionModel (API)
            final isIAP = subscriptionController.useIAP.value;
            final itemId = isIAP
                ? (displayList[index] as dynamic).id
                : (displayList[index] as dynamic).id;

            // Extract title - only text before parenthesis
            String getDisplayTitle(dynamic item, bool isIap) {
              if (isIap) {
                final fullTitle = (item as dynamic).title ?? "";
                // Extract text before first parenthesis
                final beforeParen = fullTitle.split('(').first.trim();
                return beforeParen.isEmpty ? fullTitle : beforeParen;
              } else {
                return (item as dynamic).name ?? "";
              }
            }

            // Format price with currency and plan duration
            String getDisplayPrice(dynamic item, bool isIap) {
              if (isIap) {
                final product = item as dynamic;
                final price = product.price ?? "0";
                final productId = product.id ?? "";
                // Extract duration from product ID (monthly/yearly)
                String duration = "Month";
                if (productId.contains("yearly") ||
                    productId.contains("annual")) {
                  duration = "Year";
                }
                return "$price/$duration";
              } else {
                final model = item as dynamic;
                final amount = model.amount ?? 0;
                if (amount == 0) return "FREE";
                final duration = subscriptionController.getPackageString(
                  model.interval ?? "",
                );
                return "$amount/$duration";
              }
            }

            final itemName = getDisplayTitle(displayList[index], isIAP);
            final itemPrice = getDisplayPrice(displayList[index], isIAP);

            return Padding(
              padding: EdgeInsets.only(bottom: AppSizes.h(10)),
              child: Obx(() {
                return InkWell(
                  onTap: () {
                    subscriptionController.selectedPlan(index);
                    logger.d(itemId);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.formBackgroundColor,
                      borderRadius: BorderRadius.circular(AppSizes.w(30)),
                      border: Border.all(
                        color:
                            subscriptionController.selectedIndex.value == index
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
                            itemName,
                            style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: AppSizes.sp(16),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Spacer(),
                          // txt
                          Text(
                            itemPrice.toString(),
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
    });
  }
}
