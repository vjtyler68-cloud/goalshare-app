import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/subpage_appbar_widget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controller/leads_controller.dart';
import '../model/lead.dart';
import 'lead_form_screen.dart';
import 'leads_screen.dart' show statusColor;

class LeadDetailScreen extends StatelessWidget {
  final String leadId;
  const LeadDetailScreen({super.key, required this.leadId});

  LeadsController get controller => Get.find<LeadsController>();

  Future<void> _launch(String scheme, String value) async {
    if (value.trim().isEmpty) {
      Fluttertoast.showToast(msg: 'Nothing to open here');
      return;
    }
    final uri = Uri(scheme: scheme, path: value.trim());
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        Fluttertoast.showToast(msg: 'Could not open $scheme');
      }
    } catch (_) {
      Fluttertoast.showToast(msg: 'Could not open $scheme');
    }
  }

  /// Open the lead's address in Apple Maps with driving directions from the
  /// user's current location ("take me there").
  Future<void> _openMaps(String address) async {
    if (address.trim().isEmpty) {
      Fluttertoast.showToast(msg: 'No address to open');
      return;
    }
    // daddr = destination, dirflg=d = driving directions. Apple Maps opens
    // straight into navigation on iOS; on other platforms it falls back to the
    // Apple Maps web page.
    final uri = Uri.https('maps.apple.com', '/', {
      'daddr': address.trim(),
      'dirflg': 'd',
    });
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) Fluttertoast.showToast(msg: 'Could not open Maps');
    } catch (_) {
      Fluttertoast.showToast(msg: 'Could not open Maps');
    }
  }

  void _confirmDelete(Lead lead) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete lead?'),
        content: Text('Remove ${lead.name} from your list? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final ok = await controller.deleteLead(lead.id);
              Get.back(); // close dialog
              Get.back(); // leave detail screen
              Fluttertoast.showToast(
                msg: ok ? 'Lead deleted' : 'Removed (on-device storage was unavailable)',
              );
            },
            child: Text('Delete', style: TextStyle(color: AppColors.redColor)),
          ),
        ],
      ),
    );
  }

  // ── Reminder flow ────────────────────────────────────────────────────────────

  Future<void> _pickReminder(BuildContext context, Lead lead) async {
    final now = DateTime.now();
    final initial = (lead.reminderAt != null && lead.reminderAt!.isAfter(now))
        ? lead.reminderAt!
        : now.add(const Duration(days: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      helpText: 'Remind me to reach out on',
    );
    if (date == null) return;

    if (!context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'At what time',
    );
    if (time == null) return;

    final when =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (!when.isAfter(DateTime.now())) {
      Fluttertoast.showToast(msg: 'Please pick a time in the future');
      return;
    }

    final scheduled = await controller.setReminder(lead.id, when);
    Fluttertoast.showToast(
      msg: scheduled
          ? 'Reminder set for ${DateFormat('EEE, d MMM • h:mm a').format(when)}'
          : 'Saved, but enable notifications to get the reminder',
      backgroundColor:
          scheduled ? AppColors.greenColor : AppColors.redColor,
    );
  }

  Future<void> _clearReminder(Lead lead) async {
    await controller.clearReminder(lead.id);
    Fluttertoast.showToast(msg: 'Reminder cleared');
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
        child: Obx(() {
          final lead = controller.byId(leadId);
          if (lead == null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Text(
                  'This lead is no longer available.',
                  style: AppFonts.spaceGrotesk.copyWith(fontSize: 15.sp),
                ),
              ),
            );
          }
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                child: SubPageAppbarWidget(
                  appbarTitle: 'Lead Details',
                  onPressed: () => Get.back(),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _card(child: _header(lead)),
                      SizedBox(height: 14.h),
                      _card(child: _quickActions(lead)),
                      SizedBox(height: 14.h),
                      _reminderCard(context, lead),
                      SizedBox(height: 14.h),
                      _activityCard(lead),
                      SizedBox(height: 14.h),
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoTile(Icons.phone_outlined, 'Phone', lead.phone),
                            _infoTile(Icons.email_outlined, 'Email', lead.email),
                            _infoTile(
                                Icons.business_outlined, 'Company', lead.company),
                            _infoTile(Icons.location_on_outlined, 'Address',
                                lead.address,
                                onTap: () => _openMaps(lead.address)),
                            _infoTile(Icons.notes_outlined, 'Notes', lead.notes),
                            _infoTile(
                              Icons.schedule_outlined,
                              'Added',
                              DateFormat('dd MMM yyyy').format(lead.createdAt),
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  Get.to(() => LeadFormScreen(lead: lead)),
                              icon: Icon(Icons.edit_outlined,
                                  color: AppColors.primaryColor),
                              label: Text('Edit',
                                  style: TextStyle(color: AppColors.primaryColor)),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                side: BorderSide(color: AppColors.primaryColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _confirmDelete(lead),
                              icon: Icon(Icons.delete_outline,
                                  color: AppColors.redColor),
                              label: Text('Delete',
                                  style: TextStyle(color: AppColors.redColor)),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                side: BorderSide(color: AppColors.redColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  /// Frosted card that sits cohesively over the app's peachy background.
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.whiteColor.withOpacity(0.6),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.whiteColor.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _avatar(Lead lead) {
    final photoPath = controller.photoPathFor(lead);
    if (photoPath != null && File(photoPath).existsSync()) {
      return CircleAvatar(
        radius: 32.r,
        backgroundColor: AppColors.primaryColor.withOpacity(0.12),
        backgroundImage: FileImage(File(photoPath)),
      );
    }
    return CircleAvatar(
      radius: 32.r,
      backgroundColor: AppColors.primaryColor,
      child: Text(
        lead.initials,
        style: AppFonts.spaceGrotesk.copyWith(
          color: AppColors.whiteColor,
          fontSize: 22.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _header(Lead lead) {
    return Row(
      children: [
        _avatar(lead),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lead.name.isEmpty ? 'Unnamed lead' : lead.name,
                style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blackColor,
                ),
              ),
              SizedBox(height: 6.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor(lead.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  lead.status,
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: statusColor(lead.status),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quickActions(Lead lead) {
    // Launch the contact method AND log the touch (only when there's something
    // to contact), so the timeline reflects real outreach automatically.
    void tap(String scheme, String value, String type) {
      _launch(scheme, value);
      if (value.trim().isNotEmpty) controller.logActivity(lead.id, type);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionButton(Icons.call, 'Call', () => tap('tel', lead.phone, 'call')),
        _actionButton(
            Icons.sms_outlined, 'Text', () => tap('sms', lead.phone, 'text')),
        _actionButton(Icons.email_outlined, 'Email',
            () => tap('mailto', lead.email, 'email')),
        _actionButton(
            Icons.add_comment_outlined, 'Log', () => _logActivitySheet(lead)),
      ],
    );
  }

  static IconData _activityIcon(String type) {
    switch (type) {
      case 'call':
        return Icons.call;
      case 'text':
        return Icons.sms_outlined;
      case 'email':
        return Icons.email_outlined;
      case 'meeting':
        return Icons.groups_outlined;
      default:
        return Icons.notes_outlined;
    }
  }

  void _logActivitySheet(Lead lead) {
    final noteCtrl = TextEditingController();
    var type = 'note';
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheet) => Container(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w,
              MediaQuery.of(context).viewInsets.bottom + 20.h),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log activity',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 17.sp, fontWeight: FontWeight.w800)),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  for (final t in const [
                    'call',
                    'text',
                    'email',
                    'meeting',
                    'note'
                  ])
                    GestureDetector(
                      onTap: () => setSheet(() => type = t),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 8.h),
                        decoration: BoxDecoration(
                            color: type == t
                                ? AppColors.primaryColor
                                : const Color(0xffF1EEEC),
                            borderRadius: BorderRadius.circular(20.r)),
                        child: Text(t[0].toUpperCase() + t.substring(1),
                            style: AppFonts.spaceGrotesk.copyWith(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w700,
                                color: type == t
                                    ? Colors.white
                                    : AppColors.greyColor70)),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Optional note…',
                  filled: true,
                  fillColor: const Color(0xffF6F4F2),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none),
                ),
              ),
              SizedBox(height: 14.h),
              GestureDetector(
                onTap: () {
                  controller.logActivity(lead.id, type,
                      note: noteCtrl.text.trim());
                  Get.back();
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(30.r)),
                  child: Center(
                    child: Text('Save',
                        style: AppFonts.spaceGrotesk.copyWith(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _activityCard(Lead lead) {
    final acts = lead.activities.reversed.toList(); // newest first
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Activity',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.greyColor70)),
              const Spacer(),
              if (lead.daysSinceTouch >= 7)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                      color: AppColors.redColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20.r)),
                  child: Text('${lead.daysSinceTouch}d cold',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.redColor)),
                ),
            ],
          ),
          SizedBox(height: 10.h),
          if (acts.isEmpty)
            Text('No touches logged yet — Call/Text/Email or tap Log.',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 12.5.sp, color: AppColors.greyColor70))
          else
            for (final a in acts.take(15))
              Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_activityIcon(a.type),
                        size: 16.r, color: AppColors.primaryColor),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${a.type[0].toUpperCase()}${a.type.substring(1)}'
                              '  ·  ${DateFormat('d MMM, h:mm a').format(a.at)}',
                              style: AppFonts.spaceGrotesk.copyWith(
                                  fontSize: 12.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.greyColor70)),
                          if (a.note.isNotEmpty)
                            Text(a.note,
                                style: AppFonts.spaceGrotesk.copyWith(
                                    fontSize: 12.sp,
                                    color: AppColors.greyColor70
                                        .withOpacity(0.7))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primaryColor, size: 22.sp),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: AppFonts.spaceGrotesk.copyWith(
              fontSize: 12.sp,
              color: AppColors.greyColor70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reminderCard(BuildContext context, Lead lead) {
    final reminder = lead.reminderAt;
    final now = DateTime.now();
    final isActive = reminder != null && reminder.isAfter(now);
    final isPast = reminder != null && !reminder.isAfter(now);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_outlined,
                  size: 20.sp, color: AppColors.primaryColor),
              SizedBox(width: 10.w),
              Text(
                'Follow-up reminder',
                style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.greyColor70,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          if (reminder == null)
            Text(
              "Set a reminder to reach out and you won't let this one go cold.",
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 13.sp,
                color: AppColors.greyColor70.withOpacity(0.7),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    (isPast ? 'Was due ' : 'Reminding you ') +
                        DateFormat('EEE, d MMM • h:mm a').format(reminder),
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isPast
                          ? AppColors.redColor
                          : AppColors.greyColor70,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: AppColors.greenColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      'On',
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.greenColor,
                      ),
                    ),
                  ),
              ],
            ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickReminder(context, lead),
                  icon: Icon(Icons.event_outlined,
                      size: 18.sp, color: AppColors.primaryColor),
                  label: Text(
                    reminder == null ? 'Set reminder' : 'Change',
                    style: TextStyle(color: AppColors.primaryColor),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 11.h),
                    side: BorderSide(color: AppColors.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ),
              if (reminder != null) ...[
                SizedBox(width: 12.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _clearReminder(lead),
                    icon: Icon(Icons.notifications_off_outlined,
                        size: 18.sp, color: AppColors.redColor),
                    label: Text('Clear',
                        style: TextStyle(color: AppColors.redColor)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 11.h),
                      side: BorderSide(color: AppColors.redColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value,
      {bool isLast = false, VoidCallback? onTap}) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    final tappable = onTap != null;
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20.sp, color: AppColors.primaryColor),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.greyColor70.withOpacity(0.6),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 15.sp,
                  color:
                      tappable ? AppColors.primaryColor : AppColors.blackColor,
                  fontWeight: tappable ? FontWeight.w600 : null,
                ),
              ),
            ],
          ),
        ),
        // A tappable tile (e.g. the address) shows a Directions affordance.
        if (tappable) ...[
          SizedBox(width: 8.w),
          Icon(Icons.directions, size: 20.sp, color: AppColors.primaryColor),
        ],
      ],
    );
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16.h),
      child: tappable
          ? GestureDetector(
              behavior: HitTestBehavior.opaque, onTap: onTap, child: row)
          : row,
    );
  }
}
