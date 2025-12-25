import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/custom_text.dart';
import 'package:spanx/features/customer_details/controller/customer_details_controller.dart';

class CustomerDetailsPage extends StatelessWidget {
  CustomerDetailsPage({Key? key}) : super(key: key);
  final customerDetailsController = Get.put(CustomerDetailsController());

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(child: SafeArea(
      minimum: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      child: Obx(() {
        final customer = customerDetailsController.customerDetails.value;
        return customerDetailsController.isLoading.value
            ? Center(
          child: LoadingAnimationWidget.staggeredDotsWave(
            color: AppColors.primaryColor,
            size: 30.h,
          ),
        )
            : Column(
          children: [
            // Header
            _buildHeader(context),
            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Info Card
                    _buildCustomerInfoCard(
                      customer?.name ?? "",
                      customer?.phone ?? "",
                      customer?.notes ?? "",
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    ));
  }

  /*


   */

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
            'Customer Details',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              // Handle edit action
            },
            child: Row(
              children: [
                Icon(Icons.edit_outlined, color: Colors.black87, size: 18.w),
                SizedBox(width: 4.w),
                smallText(text: 'Edit'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard(
    String clientName,
    String phoneNumber,
    String notes,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Client Name:', clientName),
          SizedBox(height: 16.h),
          _buildInfoRow('Phone Number:', phoneNumber),
          SizedBox(height: 16.h),
          _buildInfoRow('Notes:', ''),
          SizedBox(height: 8.h),
          Text(
            notes,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        smallerText(text: label),
        if (value.isNotEmpty) ...[
          SizedBox(height: 4.h),
          smallText(text: value),
        ],
      ],
    );
  }
}
