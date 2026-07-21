import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_fonts.dart';

import '../controller/notifications_controller.dart';
import 'package:spanx/core/const/app_colors.dart';

Color get _kRed => AppColors.primaryColor;
Color get _kRedDk => AppColors.primaryDarkColor;
const _kBg = Color(0xffF6F4F2);
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

class NotificationsSettingsScreen extends StatelessWidget {
  NotificationsSettingsScreen({Key? key}) : super(key: key);

  final controller = Get.put(NotificationsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kRed,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Notifications',
          style: AppFonts.spaceGrotesk.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.r),
        child: Obx(() {
          final on = controller.enabled.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _masterCard(on),
              SizedBox(height: 22.h),
              Opacity(
                opacity: on ? 1 : 0.4,
                child: IgnorePointer(
                  ignoring: !on,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "WHAT WE'LL REMIND YOU ABOUT",
                        style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: _kMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      _toggleRow(
                        emoji: '☀️',
                        title: 'Morning motivation',
                        subtitle:
                            'A 6 AM spark to start your day and set your goals',
                        value: controller.morningSpark.value,
                        onChanged: controller.toggleSpark,
                      ),
                      _toggleRow(
                        emoji: '🚪',
                        title: 'Daily goal nudge',
                        subtitle: 'A morning push to hit your knock target',
                        value: controller.morningGoal.value,
                        onChanged: controller.toggleMorning,
                      ),
                      _toggleRow(
                        emoji: '🔥',
                        title: 'Streak protection',
                        subtitle:
                            'An evening reminder so you never break the chain',
                        value: controller.eveningStreak.value,
                        onChanged: controller.toggleEvening,
                      ),
                      _toggleRow(
                        emoji: '📞',
                        title: 'Lead follow-ups',
                        subtitle: 'A heads-up when leads have gone cold',
                        value: controller.leadFollowup.value,
                        onChanged: controller.toggleLeads,
                      ),
                      SizedBox(height: 18.h),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: controller.sendTest,
                          icon: Icon(
                            Icons.notifications_active_outlined,
                            color: _kRed,
                          ),
                          label: Text(
                            'Send a test notification',
                            style: AppFonts.spaceGrotesk.copyWith(
                              color: _kRed,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: _kRed),
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                'We keep it to a few meaningful nudges a day — no spam. Turn any of these off anytime.',
                style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 12.sp,
                  color: _kMuted,
                  height: 1.4,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _masterCard(bool on) {
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kRed, _kRedDk],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: _kRed.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reminders',
                  style: AppFonts.spaceGrotesk.copyWith(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  on
                      ? "You're getting nudges to keep your momentum going."
                      : 'Turn on to get gentle nudges that keep you knocking.',
                  style: AppFonts.spaceGrotesk.copyWith(
                    color: Colors.white70,
                    fontSize: 12.sp,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Obx(
            () => controller.busy.value
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Switch(
                    value: controller.enabled.value,
                    onChanged: controller.toggleMaster,
                    activeColor: Colors.white,
                    activeTrackColor: Colors.white38,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _toggleRow({
    required String emoji,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 22.sp)),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: _kText,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 11.sp,
                    color: _kMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: _kRed),
        ],
      ),
    );
  }
}
