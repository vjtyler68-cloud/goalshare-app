import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/const/app_fonts.dart';
import '../../sharing/ui/buddy_sharing_screen.dart';
import '../controller/goflow_controller.dart';
import '../data/goflow_accent.dart';
import '../data/goflow_models.dart';

const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// GoFlow settings: cycle math inputs, the module-specific accent, the shared
/// status line, a shortcut to Friends sharing, and the privacy note.
class GoFlowSettingsSheet extends StatefulWidget {
  const GoFlowSettingsSheet({super.key});

  static Future<void> show() => Get.bottomSheet(
        const GoFlowSettingsSheet(),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );

  @override
  State<GoFlowSettingsSheet> createState() => _GoFlowSettingsSheetState();
}

class _GoFlowSettingsSheetState extends State<GoFlowSettingsSheet> {
  Color get _accent => GoFlowController.to.accentColor;

  Future<void> _pickLastPeriod() async {
    final c = GoFlowController.to;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: c.settings.value.lastPeriodStart ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked != null) c.setLastPeriodStart(picked);
  }

  Future<void> _editStatus() async {
    final c = GoFlowController.to;
    final ctrl =
        TextEditingController(text: c.settings.value.customStatusMessage ?? '');
    await Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(
            20.w, 16.h, 20.w, MediaQuery.of(context).viewInsets.bottom + 20.h),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status for friends',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
            SizedBox(height: 6.h),
            Text('An optional line shared alongside your phase — like "low '
                'energy this week." Never your raw logs.',
                style: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 12.5.sp, color: _kMuted, height: 1.4)),
            SizedBox(height: 12.h),
            TextField(
              controller: ctrl,
              maxLength: 80,
              style: AppFonts.spaceGrotesk
                  .copyWith(fontSize: 14.sp, color: _kText),
              decoration: InputDecoration(
                hintText: 'How are you this week?',
                filled: true,
                fillColor: const Color(0xffF6F4F2),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none),
              ),
            ),
            SizedBox(height: 8.h),
            GestureDetector(
              onTap: () {
                c.setCustomStatus(ctrl.text);
                Get.back();
                setState(() {});
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: BorderRadius.circular(30.r)),
                child: Center(
                  child: Text('Save',
                      style: AppFonts.spaceGrotesk.copyWith(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: 0.9.sh),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Obx(() {
        final c = GoFlowController.to;
        final s = c.settings.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4.r)),
              ),
            ),
            Text('GoFlow settings',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
            SizedBox(height: 16.h),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _stepper('Average cycle length', '${s.avgCycleLength} days',
                        () => c.setCycleLength(s.avgCycleLength - 1),
                        () => c.setCycleLength(s.avgCycleLength + 1)),
                    SizedBox(height: 10.h),
                    _stepper('Average period length',
                        '${s.avgPeriodLength} days',
                        () => c.setPeriodLength(s.avgPeriodLength - 1),
                        () => c.setPeriodLength(s.avgPeriodLength + 1)),
                    SizedBox(height: 10.h),
                    _row(
                      'Last period start',
                      s.lastPeriodStart == null
                          ? 'Set'
                          : '${s.lastPeriodStart!.month}/${s.lastPeriodStart!.day}/${s.lastPeriodStart!.year}',
                      Icons.event_rounded,
                      _pickLastPeriod,
                    ),
                    SizedBox(height: 22.h),
                    _sectionTitle('Accent'),
                    SizedBox(height: 10.h),
                    _accentPicker(s.accentId),
                    SizedBox(height: 22.h),
                    _sectionTitle('Sharing'),
                    SizedBox(height: 10.h),
                    _row(
                      'Status for friends',
                      (s.customStatusMessage?.isNotEmpty ?? false)
                          ? s.customStatusMessage!
                          : 'Optional',
                      Icons.chat_bubble_outline_rounded,
                      _editStatus,
                    ),
                    SizedBox(height: 10.h),
                    _row(
                      'Who can see GoFlow',
                      'Manage friends',
                      Icons.group_outlined,
                      () => Get.to(() => const BuddySharingScreen()),
                    ),
                    SizedBox(height: 22.h),
                    _sectionTitle('Modes'),
                    SizedBox(height: 10.h),
                    _toggleRow(
                      'Perimenopause tracking',
                      Icons.thermostat_auto_rounded,
                      s.perimenopauseMode,
                      () => c.setPerimenopauseMode(!s.perimenopauseMode),
                    ),
                    if (!c.isPregnant) ...[
                      SizedBox(height: 10.h),
                      _row('Pregnancy mode', 'Start',
                          Icons.child_friendly_rounded, _startPregnancy),
                    ],
                    SizedBox(height: 22.h),
                    _privacy(),
                    SizedBox(height: 14.h),
                    _switchRoleNote(c),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: AppFonts.spaceGrotesk.copyWith(
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: _kMuted));

  Widget _stepper(String label, String value, VoidCallback minus, VoidCallback plus) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
          color: const Color(0xffF6F4F2),
          borderRadius: BorderRadius.circular(12.r)),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: _kText)),
          ),
          _circleBtn(Icons.remove, minus),
          SizedBox(width: 12.w),
          SizedBox(
            width: 62.w,
            child: Text(value,
                textAlign: TextAlign.center,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
          ),
          SizedBox(width: 12.w),
          _circleBtn(Icons.add, plus),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30.r,
          height: 30.r,
          decoration:
              BoxDecoration(color: _accent, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 17.r),
        ),
      );

  Widget _row(String label, String value, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
            color: const Color(0xffF6F4F2),
            borderRadius: BorderRadius.circular(12.r)),
        child: Row(
          children: [
            Icon(icon, size: 18.r, color: _accent),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(label,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: _kText)),
            ),
            SizedBox(width: 8.w),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 140.w),
              child: Text(value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: AppFonts.spaceGrotesk
                      .copyWith(fontSize: 12.5.sp, color: _kMuted)),
            ),
            Icon(Icons.chevron_right, size: 18.r, color: _kMuted),
          ],
        ),
      ),
    );
  }

  Widget _toggleRow(
      String label, IconData icon, bool on, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
            color: const Color(0xffF6F4F2),
            borderRadius: BorderRadius.circular(12.r)),
        child: Row(
          children: [
            Icon(icon, size: 18.r, color: on ? _accent : _kMuted),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(label,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: _kText)),
            ),
            Container(
              width: 44.w,
              height: 26.h,
              padding: EdgeInsets.all(3.r),
              decoration: BoxDecoration(
                color: on ? _accent : const Color(0xffD8D2CF),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Align(
                alignment: on ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20.r,
                  height: 20.r,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startPregnancy() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 28)),
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      helpText: 'First day of your last period',
    );
    if (picked != null) {
      GoFlowController.to.startPregnancy(picked);
      Get.back();
    }
  }

  Widget _accentPicker(String? current) {
    Widget swatch(String? id, Color color, String name) {
      final selected = current == id;
      return GestureDetector(
        onTap: () => GoFlowController.to.setAccent(id),
        child: Column(
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                    color: selected ? _kText : Colors.transparent, width: 2.5),
              ),
              child: selected
                  ? Icon(Icons.check, color: Colors.white, size: 20.r)
                  : null,
            ),
            SizedBox(height: 4.h),
            Text(name,
                style: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 10.sp, color: _kMuted)),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 14.w,
      runSpacing: 12.h,
      children: [
        // "Match app theme" = null accent.
        swatch(null, GoFlowAccent.resolve(null), 'App'),
        for (final a in GoFlowAccent.presets) swatch(a.id, a.color, a.name),
      ],
    );
  }

  Widget _privacy() {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _accent.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, size: 18.r, color: _accent),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'GoFlow data stays on this device unless you choose to share a '
              'summary with a friend. Never sold, never synced to ad networks.',
              style: AppFonts.spaceGrotesk
                  .copyWith(fontSize: 12.sp, color: _kText, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchRoleNote(GoFlowController c) {
    final partner = c.settings.value.role == GoFlowRole.partner;
    return Center(
      child: TextButton(
        onPressed: () {
          c.setRole(partner ? GoFlowRole.self : GoFlowRole.partner);
          Get.back();
        },
        child: Text(
          partner
              ? 'Switch to tracking my own cycle'
              : 'Switch to supporting a partner',
          style: AppFonts.spaceGrotesk.copyWith(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w700,
              color: _accent),
        ),
      ),
    );
  }
}
