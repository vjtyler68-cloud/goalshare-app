import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/const/app_fonts.dart';
import '../../../core/global_widgets/app_snackbar.dart';
import '../controller/feed_controller.dart';

Color get _kRed => AppColors.primaryColor;
Color get _kRedDk => AppColors.primaryDarkColor;
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// Compose + share a manual "win" to the Friends Activity Feed — text, a photo,
/// or both, so people can visualise the moment.
class ShareWinSheet {
  ShareWinSheet._();

  static void show(FeedController controller) {
    Get.bottomSheet(
      _Body(controller: controller),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _Body extends StatefulWidget {
  final FeedController controller;
  const _Body({required this.controller});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final TextEditingController textC = TextEditingController();
  Uint8List? _photoBytes;
  String _photoB64 = '';

  FeedController get controller => widget.controller;

  @override
  void dispose() {
    textC.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    XFile? image;
    try {
      image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1350,
        imageQuality: 45,
      );
    } catch (_) {
      AppSnackBar.show(
          message: "Couldn't open your photo library", isSuccessful: false);
      return;
    }
    if (image == null) return;
    final bytes = await File(image.path).readAsBytes();
    final b64 = base64Encode(bytes);
    if (b64.length > 950000) {
      AppSnackBar.show(
          message: 'That photo is a bit large — try a different one',
          isSuccessful: false);
      return;
    }
    setState(() {
      _photoBytes = bytes;
      _photoB64 = b64;
    });
  }

  Future<void> _share() async {
    final text = textC.text.trim();
    if (text.isEmpty && _photoB64.isEmpty) return;
    await controller.shareWin(text, base64Image: _photoB64);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 20.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.r)),
                ),
              ),
              Text('Share a win 🎉',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: _kText)),
              SizedBox(height: 6.h),
              Text('What did you accomplish? Add a photo if you want — your '
                  'friends will see it and cheer.',
                  style: AppFonts.spaceGrotesk
                      .copyWith(fontSize: 12.sp, color: _kMuted)),
              SizedBox(height: 14.h),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xffF6F4F2),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: TextField(
                  controller: textC,
                  autofocus: true,
                  maxLength: 200,
                  minLines: 2,
                  maxLines: 5,
                  style: AppFonts.spaceGrotesk
                      .copyWith(fontSize: 15.sp, color: _kText),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'e.g. Hit 40 doors and closed 2 deals today! 🔥',
                    hintStyle: AppFonts.spaceGrotesk
                        .copyWith(fontSize: 13.sp, color: _kMuted),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              // Photo: preview + remove, or an "Add photo" button.
              if (_photoBytes != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14.r),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 260.h),
                        child: Image.memory(
                          _photoBytes!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8.r,
                      right: 8.r,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _photoBytes = null;
                          _photoB64 = '';
                        }),
                        child: Container(
                          padding: EdgeInsets.all(5.r),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close,
                              color: Colors.white, size: 16.r),
                        ),
                      ),
                    ),
                  ],
                )
              else
                GestureDetector(
                  onTap: _pickPhoto,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: 12.h, horizontal: 14.w),
                    decoration: BoxDecoration(
                      color: _kRed.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: _kRed.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            color: _kRed, size: 20.r),
                        SizedBox(width: 10.w),
                        Text('Add a photo (optional)',
                            style: AppFonts.spaceGrotesk.copyWith(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: _kRed)),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 16.h),
              Obx(() => GestureDetector(
                    onTap: controller.posting.value ? null : _share,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 15.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [_kRed, _kRedDk]),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Center(
                        child: controller.posting.value
                            ? SizedBox(
                                width: 20.r,
                                height: 20.r,
                                child: const CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text('Share',
                                style: AppFonts.spaceGrotesk.copyWith(
                                    color: Colors.white,
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w800)),
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
