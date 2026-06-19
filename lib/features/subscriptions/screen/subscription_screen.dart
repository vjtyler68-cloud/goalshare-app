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
import 'package:spanx/core/services/iap/premium_service.dart';
import 'package:spanx/features/privacy_policy/ui/privacy_policy_screen.dart';
import 'package:spanx/features/terms_conditions/ui/terms_conditions_screen.dart';

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
                  'Unlock GoalShare Premium',
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 23.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.greyColor70,
                  ),
                ),

                SizedBox(height: 10.h),

                // text
                Text(
                  'Subscribe to unlock full access to all premium features. Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period; manage or cancel anytime in your App Store settings.',
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
                SizedBox(height: 16.h),
                TextButton(
                  onPressed: () async {
                    Get.snackbar(
                      'Restore Purchases',
                      'Checking for previous purchases...',
                    );
                    await PremiumService.instance.restore();
                  },
                  child: Text(
                    'Restore Purchases',
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => Get.to(
                        () => const TermsConditionsScreen(),
                        transition: Transition.rightToLeft,
                      ),
                      child: Text(
                        'Terms of Use',
                        style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 12.sp,
                          color: AppColors.greyColor70,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      child: Text(
                        '•',
                        style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 12.sp,
                          color: AppColors.greyColor70,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.to(
                        () => const PrivacyPolicyScreen(),
                        transition: Transition.rightToLeft,
                      ),
                      child: Text(
                        'Privacy Policy',
                        style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 12.sp,
                          color: AppColors.greyColor70,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
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
