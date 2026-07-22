import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/const/app_fonts.dart';
import '../controller/stories_controller.dart';

/// Preview the chosen photo, add an optional caption, and share it to your
/// story. Kept deliberately simple: one photo, one caption, one tap to post.
class StoryComposeScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String base64Image;

  const StoryComposeScreen({
    super.key,
    required this.imageBytes,
    required this.base64Image,
  });

  @override
  State<StoryComposeScreen> createState() => _StoryComposeScreenState();
}

class _StoryComposeScreenState extends State<StoryComposeScreen> {
  final _caption = TextEditingController();
  final StoriesController _c = Get.find<StoriesController>();

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    try {
      await _c.publish(widget.base64Image, _caption.text);
      Get.back(); // leave the compose screen
    } catch (_) {
      // publish() already surfaced the error snackbar.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Photo preview
          Center(
            child: Image.memory(widget.imageBytes, fit: BoxFit.contain),
          ),
          // Top bar
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              child: Row(
                children: [
                  _circleBtn(Icons.close_rounded, () => Get.back()),
                  const Spacer(),
                  Text(
                    'New story',
                    style: AppFonts.spaceGrotesk.copyWith(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(width: 40.w),
                ],
              ),
            ),
          ),
          // Bottom: caption + share
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                ),
              ),
              padding: EdgeInsets.fromLTRB(16.w, 40.h, 16.w, 0),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _caption,
                      maxLength: 140,
                      minLines: 1,
                      maxLines: 3,
                      style: AppFonts.spaceGrotesk.copyWith(
                          color: Colors.white, fontSize: 15.sp),
                      cursorColor: Colors.white,
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'Add a caption…',
                        hintStyle: TextStyle(color: Colors.white60),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.12),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 12.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Obx(() => SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _c.posting.value ? null : _share,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                              disabledBackgroundColor:
                                  AppColors.primaryColor.withOpacity(0.5),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.r),
                              ),
                            ),
                            icon: _c.posting.value
                                ? SizedBox(
                                    width: 18.r,
                                    height: 18.r,
                                    child: const CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.send_rounded,
                                    color: Colors.white),
                            label: Text(
                              _c.posting.value ? 'Sharing…' : 'Share to your story',
                              style: AppFonts.spaceGrotesk.copyWith(
                                color: Colors.white,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )),
                    SizedBox(height: 8.h),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.w,
        height: 40.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.35),
        ),
        child: Icon(icon, color: Colors.white, size: 22.r),
      ),
    );
  }
}
