import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/user_info/user_info_controller.dart';

/// One shared flow for changing the account profile photo, used by every
/// avatar in the app (home header, profile tab, …): bottom sheet → camera or
/// library → upload via PUT /user/update-profile-image → refresh user info.
class ProfilePhotoUpdater {
  ProfilePhotoUpdater._();

  static final ImagePicker _picker = ImagePicker();

  /// True while an upload is in flight — avatars watch this to show a spinner.
  static final RxBool uploading = false.obs;

  /// Open the "Profile photo" sheet (camera / library).
  static void showOptions() {
    if (uploading.value) return;
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 28.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 14.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            Text('Profile photo',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xff1A1010))),
            SizedBox(height: 14.h),
            _optionRow(Icons.photo_camera_rounded, 'Take a photo', () {
              Get.back();
              _pickAndUpload(ImageSource.camera);
            }),
            _optionRow(Icons.photo_library_rounded, 'Choose from library', () {
              Get.back();
              _pickAndUpload(ImageSource.gallery);
            }),
          ],
        ),
      ),
    );
  }

  static Widget _optionRow(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: const Color(0xffF6F4F2),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          children: [
            Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Icon(icon, color: AppColors.primaryColor, size: 19.r),
            ),
            SizedBox(width: 12.w),
            Text(label,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff1A1010))),
          ],
        ),
      ),
    );
  }

  static Future<void> _pickAndUpload(ImageSource source) async {
    XFile? image;
    try {
      image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
    } catch (_) {
      AppSnackBar.show(
          message:
              "Couldn't open the ${source == ImageSource.camera ? 'camera' : 'photo library'}",
          isSuccessful: false);
      return;
    }
    if (image == null) return; // user cancelled

    uploading.value = true;
    try {
      final token = await LocalService().getToken() ?? '';
      if (token.isEmpty) throw Exception('Not signed in');

      final request =
          http.MultipartRequest('PUT', Uri.parse(Urls.userUploadPhoto));
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': token, // raw JWT — backend rejects "Bearer " prefix
      });
      final bytes = await File(image.path).readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));

      final streamed =
          await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      final ok = response.statusCode >= 200 && response.statusCode < 300;
      final body = ok ? json.decode(response.body) : null;
      if (ok && body?['success'] == true) {
        await Get.find<UserInfoController>().loadAndSetUserInfo();
        AppSnackBar.show(
            message: 'Profile photo updated ✨', isSuccessful: true);
      } else {
        throw Exception('Upload failed');
      }
    } catch (_) {
      AppSnackBar.show(
          message: "Couldn't update your photo — try again",
          isSuccessful: false);
    } finally {
      uploading.value = false;
    }
  }
}
