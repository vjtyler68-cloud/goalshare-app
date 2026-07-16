import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/profile_photo/profile_photo_updater.dart';
import 'package:spanx/core/user_info/user_info_controller.dart';

/// Round avatar on the Home header. Shows the profile photo when one is set
/// (falls back to initials) and, on tap, lets the user take or choose a new
/// photo which is uploaded to the account immediately.
class EditableAvatar extends StatelessWidget {
  const EditableAvatar({super.key});

  String _initials(String n) {
    final p = n.trim().split(RegExp(r'\s+'));
    if (p.isEmpty || p[0].isEmpty) return 'U';
    if (p.length == 1) return p[0][0].toUpperCase();
    return '${p[0][0]}${p[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = Get.find<UserInfoController>();
    return Obx(() {
      final u = userInfo.userData.value;
      final name = u?.fullName ?? '';
      final photo = (u?.profile ?? '').trim();
      final busy = ProfilePhotoUpdater.uploading.value;
      return GestureDetector(
        onTap: busy ? null : ProfilePhotoUpdater.showOptions,
        child: SizedBox(
          width: 56.r,
          height: 56.r,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52.r,
                height: 52.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: photo.isEmpty
                    ? Center(
                        child: Text(
                          _initials(name),
                          style: AppFonts.spaceGrotesk.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18.sp),
                        ),
                      )
                    : ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: photo,
                          fit: BoxFit.cover,
                          width: 52.r,
                          height: 52.r,
                          errorWidget: (_, __, ___) => Center(
                            child: Text(
                              _initials(name),
                              style: AppFonts.spaceGrotesk.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18.sp),
                            ),
                          ),
                        ),
                      ),
              ),
              if (busy)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.35),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      ),
                    ),
                  ),
                ),
              // camera badge — signals the avatar is editable
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 20.r,
                  height: 20.r,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(Icons.photo_camera_rounded,
                      size: 12.r, color: AppColors.primaryColor),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
