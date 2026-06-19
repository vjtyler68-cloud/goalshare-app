import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/global_widgets/app_loading.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_text.dart';
import 'package:spanx/features/subscription_page/controller/subscription_page_controller.dart';
import 'package:spanx/routes/app_routes.dart';

// Subscription Page
class SubscriptionPage extends StatelessWidget {
  SubscriptionPage({super.key});

  // final subsPageController = Get.find<SubscriptionPageController>();
  final subsPageController = Get.put(SubscriptionPageController());

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
          child:
          Obx(() {
            if (subsPageController.isSubLoading.value) {
              return loading();
            }

            final sub = subsPageController.subsModel.value;

            // ✅ Check if there’s no subscription data
            if (sub?.id == null) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, size: 60.w, color: Colors.grey),
                      SizedBox(height: 16.h),
                      Text(
                        "You don’t have an active subscription yet.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16.sp, color: Colors.black54),
                      ),
                      SizedBox(height: 24.h),
                      ElevatedButton(
                        onPressed: () =>
                            Get.toNamed(AppRoutes.subscriptionScreen),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          padding: EdgeInsets.symmetric(
                              horizontal: 24.w, vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                        child: Text("Subscribe Now", style: TextStyle(
                            color: Colors.white)),
                      )
                    ],
                  ),
                ),
              );
            }

            // ✅ Otherwise show the active subscription details
            return Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((subsPageController.subsModel.value?.remainingDays ?? 0) <
                            7) _buildWarningSection(),
                        SizedBox(height: 24.h),
                        smallerText(
                          text:
                          'Keep tracking your goals, building better habits, and accessing all premium features.',
                          maxLines: 3,
                        ),
                        SizedBox(height: 24.h),
                        _buildPlanDetails(),
                        SizedBox(height: 32.h),
                        _buildRenewButton(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          })

      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(8.w),
              child: Icon(
                Icons.arrow_back_ios,
                color: Colors.black87,
                size: 20.w,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            'Subscription',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 20.w),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Your Access is About to Expire',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(
          'Plan :',
          subsPageController.subsModel.value?.title ?? 'No Plan',
        ),
        SizedBox(height: 12.h),
        _buildDetailRow(
          'Expiration Date :',
          subsPageController.formatDate(
            subsPageController.subsModel.value?.endDate.toString() ?? "",
          ),
        ),
        SizedBox(height: 12.h),
        _buildDetailRow(
          'Days Left :',
          // '${subsPageController.subsModel.value?.remainingDays ?? 0} days',
          '${subsPageController.remainingDays()} days',
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120.w,
          child: smallerText(text: label),
        ),
        Expanded(child: smallText(text: value)),
      ],
    );
  }

  Widget _buildRenewButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: subsPageController.subsModel.value!.remainingDays! < 7 ? () {
          // Handle renew action

          Get.toNamed(AppRoutes.subscriptionScreen);
        } : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF5722),
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 2,
        ),
        child: smallText(text: 'Renew Plan', color: Colors.white),
      ),
    );
  }
}
