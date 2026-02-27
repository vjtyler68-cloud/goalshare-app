import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import '../../../core/global_widgets/app_loading.dart';
import '../../../core/global_widgets/app_network_image.dart';
import '../../../core/global_widgets/custom_text.dart';
import '../controller/vision_controller.dart';
import '../model/vision_model.dart';

class VisionBoardPage extends StatelessWidget {
  VisionBoardPage({super.key});

  final controller = Get.find<VisionBoardController>();

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
        minimum: EdgeInsets.symmetric(vertical: 20.h),
        child: Column(
          children: [
            // Header Section
            _buildHeader(controller, context),

            // Vision Board Content
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return Center(child: loading());
                }

                if (controller.visionBoardItems.isEmpty) {
                  return _buildEmptyState(controller);
                }

                return _buildVisionBoardGrid(controller);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(VisionBoardController controller, BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          // Back Button
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

          SizedBox(width: 8.w),

          // Title
          Expanded(
            child: headingText(text: 'Vision Board', color: Colors.black87),
          ),

          // Create New Button
          GestureDetector(
            onTap: controller.onCreateNewTap,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.36),
                  width: 1.w,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.black87, size: 16.w),
                  SizedBox(width: 4.w),
                  smallText(text: 'Create New', color: Colors.black87),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(VisionBoardController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dashboard_outlined, size: 80.w, color: Colors.black54),
          SizedBox(height: 16.h),
          normalText(text: 'No Vision Board Items', color: Colors.black54),
          SizedBox(height: 8.h),
          smallText(
            text: 'Create your first vision board item',
            color: Colors.black38,
          ),
          SizedBox(height: 24.h),
          // ElevatedButton(
          //   onPressed: controller.onCreateNewTap,
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: Colors.white.withOpacity(0.3),
          //     foregroundColor: Colors.black87,
          //     elevation: 0,
          //     padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(25.r),
          //       side: BorderSide(
          //         color: Colors.white.withOpacity(0.36),
          //         width: 1.w,
          //       ),
          //     ),
          //   ),
          //   child: Row(
          //     mainAxisSize: MainAxisSize.min,
          //     children: [
          //       Icon(Icons.add, size: 20.w),
          //       SizedBox(width: 8.w),
          //       smallText(text: 'Create New', color: Colors.black87),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildVisionBoardGrid(VisionBoardController controller) {
    return RefreshIndicator(
      onRefresh: () async => controller.refreshVisionBoard(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 5.h,
          crossAxisSpacing: 5.w,
          itemCount: controller.visionBoardItems.length,
          itemBuilder: (context, index) {
            final item = controller.visionBoardItems[index];
            return _buildVisionBoardItem(item, controller);
          },
        ),
      ),
    );
  }

  Widget _buildVisionBoardItem(
    VisionBoardModel item,
    VisionBoardController controller,
  ) {
    // Calculate height based on aspect ratio for staggered effect
    final baseHeight = 180.h;
    final itemHeight = baseHeight / 0.75;

    return GestureDetector(
      // onTap: () => controller.onVisionItemTap(item),
      child: Container(
        height: itemHeight,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withOpacity(0.36), width: 1.w),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Image
              ResponsiveNetworkImage(
                // imageUrl: item.imageUrl,
                imageUrl: item.image ?? "",
                shape: ImageShape.roundedRectangle,
                borderRadius: 0,
                // Already clipped by container
                fit: BoxFit.cover,
                errorWidget: Container(
                  color: Colors.grey[300],
                  child: Icon(
                    Icons.image_outlined,
                    color: Colors.grey[600],
                    size: 40.w,
                  ),
                ),
              ),

              // Gradient Overlay for better text readability
              // Container(
              //   decoration: BoxDecoration(
              //     gradient: LinearGradient(
              //       begin: Alignment.topCenter,
              //       end: Alignment.bottomCenter,
              //       colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
              //       stops: const [0.6, 1.0],
              //     ),
              //   ),
              // ),

              // Title Overlay
              Positioned(
                bottom: 12.h,
                left: 12.w,
                right: 12.w,
                child: smallText(
                  text: DateFormat('MMM dd, yyyy').format(item.year!),
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  maxLines: 2,
                ),
              ),

              // Delete button with loading indicator
              Positioned(
                top: 8.h,
                right: 8.w,
                child: Obx(() {
                  // final isDeleting = controller.deletedIDs.contains(item.id);
                  return GestureDetector(
                    onTap: controller.isDeleting(item.id!)
                        ? null
                        : () => controller.deleteVisionBoardItem(item.id!),
                    child: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: controller.isDeleting(item.id!)
                          ? SizedBox(
                              width: 16.w,
                              height: 16.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.delete_forever,
                              color: Colors.white,
                              size: 16.w,
                            ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
