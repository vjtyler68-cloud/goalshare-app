import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import '../../../core/global_widgets/app_loading.dart';
import '../../../core/global_widgets/app_network_image.dart';
import '../../../core/global_widgets/custom_text.dart';
import '../controller/vision_controller.dart';
import '../model/vision_model.dart';
import 'package:flutter_masonry_view/flutter_masonry_view.dart';

class VisionBoardPage extends StatelessWidget {
  const VisionBoardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VisionBoardController());

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFB6B6), // Light pink at top
              Color(0xFFFFA07A), // Light salmon at bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header Section
              _buildHeader(controller),

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
      ),
    );
  }

  Widget _buildHeader(VisionBoardController controller) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Get.back(),
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
          ElevatedButton(
            onPressed: controller.onCreateNewTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.3),
              foregroundColor: Colors.black87,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.r),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.36),
                  width: 1.w,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 20.w),
                SizedBox(width: 8.w),
                smallText(text: 'Create New', color: Colors.black87),
              ],
            ),
          ),
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
          mainAxisSpacing: 12.h,
          crossAxisSpacing: 12.w,
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
    VisionBoardItem item,
    VisionBoardController controller,
  ) {
    // Calculate height based on aspect ratio for staggered effect
    final baseHeight = 180.h;
    final itemHeight = baseHeight / item.aspectRatio;

    return GestureDetector(
      onTap: () => controller.onVisionItemTap(item),
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
                imageUrl: item.imageUrl,
                shape: ImageShape.roundedRectangle,
                borderRadius: 0, // Already clipped by container
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
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),

              // Title Overlay
              Positioned(
                bottom: 12.h,
                left: 12.w,
                right: 12.w,
                child: smallText(
                  text: item.title,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  maxLines: 2,
                ),
              ),

              // Optional: Add favorite or menu button
              Positioned(
                top: 8.h,
                right: 8.w,
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.more_vert, color: Colors.white, size: 16.w),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
