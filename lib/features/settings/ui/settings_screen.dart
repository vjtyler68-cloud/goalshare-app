import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/features/profile_tab/controller/profile_tab_controller.dart';

/// Settings sub-page (Profile → Settings): the rarely-used account and legal
/// items, kept off the main Profile list so it stays short and scannable.
/// Rows reuse the exact card style of the Profile menu for a seamless feel.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ProfileTabController>()
        ? Get.find<ProfileTabController>()
        : Get.put(ProfileTabController());

    return Scaffold(
      backgroundColor: const Color(0xffF6F4F2),
      appBar: AppBar(
        backgroundColor: const Color(0xffF6F4F2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xff1A1010), size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Settings',
          style: AppFonts.spaceGrotesk.copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
            color: const Color(0xff1A1010),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...controller.settingsItems.map((item) => _SettingsRow(item: item)),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final ProfileMenuItem item;
  const _SettingsRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(children: [
              item.icon != null
                  ? Icon(item.icon, size: 22, color: const Color(0xff9E9090))
                  : Image.asset(item.iconPath,
                      width: 22.w,
                      height: 22.h,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.settings_outlined,
                          size: 22,
                          color: Color(0xff9E9090))),
              SizedBox(width: 14.w),
              Expanded(
                child: Text(
                  item.title,
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff1A1010),
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: Color(0xffB0AAAA)),
            ]),
          ),
        ),
      ),
    );
  }
}
