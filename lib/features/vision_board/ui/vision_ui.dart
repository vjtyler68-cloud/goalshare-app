import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spanx/core/const/app_fonts.dart';
import '../../../core/global_widgets/app_loading.dart';
import '../../../core/global_widgets/app_network_image.dart';
import '../controller/vision_controller.dart';
import '../model/vision_model.dart';

const _kRed   = Color(0xffE84040);
const _kRedDk = Color(0xff9B1414);
const _kBg    = Color(0xffF6F4F2);
const _kCard  = Color(0xffFFFFFF);
const _kText  = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

class VisionBoardPage extends StatelessWidget {
  VisionBoardPage({super.key});

  final controller = Get.find<VisionBoardController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kRed, _kRedDk],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: Get.back,
                      child: Container(
                        width: 38.r, height: 38.r,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.2)),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your Dreams', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white70, fontSize: 12.sp)),
                          Text('Vision Board', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: controller.onCreateNewTap,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.add, color: Colors.white, size: 18),
                            SizedBox(width: 4.w),
                            Text('Add', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Motivational subtitle
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 4.h),
            child: Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: _kRed.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: _kRed.withOpacity(0.15)),
              ),
              child: Row(children: [
                const Icon(Icons.wb_sunny_outlined, color: _kRed, size: 18),
                SizedBox(width: 10.w),
                Expanded(child: Text(
                  '"See it. Believe it. Achieve it. Your vision board is proof of what\'s possible."',
                  style: AppFonts.spaceGrotesk.copyWith(color: _kRed, fontSize: 11.sp, fontStyle: FontStyle.italic, height: 1.4),
                )),
              ]),
            ),
          ),

          // ── Grid ──────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(child: loading());
              }
              if (controller.visionBoardItems.isEmpty) {
                return _EmptyState(onAdd: controller.onCreateNewTap);
              }
              return RefreshIndicator(
                onRefresh: () async => controller.refreshVisionBoard(),
                color: _kRed,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 80.h),
                  child: MasonryGridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12.h,
                    crossAxisSpacing: 12.w,
                    itemCount: controller.visionBoardItems.length,
                    itemBuilder: (_, i) => _VisionTile(item: controller.visionBoardItems[i], controller: controller),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80.r, height: 80.r,
              decoration: BoxDecoration(color: _kRed.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.dashboard_outlined, color: _kRed, size: 40),
            ),
            SizedBox(height: 20.h),
            Text('Your Vision Awaits', style: AppFonts.spaceGrotesk.copyWith(fontSize: 20.sp, fontWeight: FontWeight.w800, color: _kText)),
            SizedBox(height: 8.h),
            Text('Add images of your goals, dreams, and the life you\'re building. See it every day.', style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, color: _kMuted, height: 1.6), textAlign: TextAlign.center),
            SizedBox(height: 24.h),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 32.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_kRed, _kRedDk]),
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [BoxShadow(color: _kRed.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add_photo_alternate, color: Colors.white, size: 20),
                  SizedBox(width: 8.w),
                  Text('Add Your First Vision', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisionTile extends StatelessWidget {
  final VisionBoardModel item;
  final VisionBoardController controller;
  const _VisionTile({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    final id = item.id;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: Stack(
        children: [
          // Image — MUST be height-bounded. Inside a MasonryGridView the vertical
          // constraint is unbounded; the network-image placeholder previously
          // sized to double.infinity, throwing "BoxConstraints forces an infinite
          // height" and crashing the whole board. AspectRatio gives the tile a
          // finite height so the placeholder, image, and Stack all lay out cleanly.
          AspectRatio(
            aspectRatio: 3 / 4,
            child: ResponsiveNetworkImage(
              imageUrl: item.image ?? '',
              shape: ImageShape.roundedRectangle,
              borderRadius: 0,
              fit: BoxFit.cover,
              placeholderWidget: Container(color: Colors.grey[200]),
              errorWidget: Container(
                color: Colors.grey[200],
                child: const Center(child: Icon(Icons.image_outlined, color: Colors.grey, size: 40)),
              ),
            ),
          ),

          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),

          // Date
          Positioned(
            bottom: 10.h,
            left: 10.w,
            right: 40.w,
            child: Text(
              DateFormat('MMM d, yyyy').format(item.year ?? DateTime.now()),
              style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w600),
            ),
          ),

          // Delete button — only when the item has an id to delete by, so a
          // record with a missing id can never trigger a null-check crash.
          if (id != null)
            Positioned(
              top: 8.h,
              right: 8.w,
              child: Obx(() => GestureDetector(
                onTap: controller.isDeleting(id) ? null : () => controller.deleteVisionBoardItem(id),
                child: Container(
                  width: 30.r, height: 30.r,
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.4), shape: BoxShape.circle),
                  child: controller.isDeleting(id)
                      ? const Padding(padding: EdgeInsets.all(7), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.close, color: Colors.white, size: 14),
                ),
              )),
            ),
        ],
      ),
    );
  }
}
