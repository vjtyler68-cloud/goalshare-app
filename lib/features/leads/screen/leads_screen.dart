import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/subpage_appbar_widget.dart';

import '../controller/leads_controller.dart';
import '../model/lead.dart';
import 'lead_detail_screen.dart';
import 'lead_form_screen.dart';

/// Consistent colour per pipeline stage. Shared with the detail screen.
Color statusColor(String status) {
  switch (status) {
    case 'New':
      return const Color(0xff6366F1);
    case 'Contacted':
      return const Color(0xffF59E0B);
    case 'Appointment':
      return const Color(0xff0EA5E9);
    case 'Won':
      return const Color(0xff10B981);
    case 'Lost':
      return const Color(0xffEF4444);
    default:
      return const Color(0xff6B7280);
  }
}

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  final controller = Get.find<LeadsController>();
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScreen(
      child: SafeArea(
        child: Stack(
          children: [
            Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: SubPageAppbarWidget(
                appbarTitle: 'My Leads',
                onPressed: () => Get.back(),
              ),
            ),

            // Search
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: TextField(
                controller: _search,
                onChanged: (v) => controller.searchQuery.value = v,
                decoration: InputDecoration(
                  hintText: 'Search leads…',
                  prefixIcon: Icon(Icons.search, color: AppColors.greyColor70),
                  filled: true,
                  fillColor: AppColors.formBackgroundColor,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.r),
                    borderSide: BorderSide(color: AppColors.greyColor70, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.r),
                    borderSide: BorderSide(color: AppColors.greyColor70, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15.r),
                    borderSide: BorderSide(color: AppColors.primaryColor, width: 1),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Status filter chips
            SizedBox(
              height: 38.h,
              child: Obx(() {
                final options = ['All', ...kLeadStatuses];
                final selected = controller.statusFilter.value;
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  itemCount: options.length,
                  separatorBuilder: (_, __) => SizedBox(width: 8.w),
                  itemBuilder: (_, i) {
                    final s = options[i];
                    final isSel = s == selected;
                    return GestureDetector(
                      onTap: () => controller.statusFilter.value = s,
                      child: Container(
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppColors.primaryColor
                              : AppColors.whiteColor,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: isSel
                                ? AppColors.primaryColor
                                : AppColors.greyColor70.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          '$s (${controller.countForStatus(s)})',
                          style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: isSel
                                ? AppColors.whiteColor
                                : AppColors.greyColor70,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
            SizedBox(height: 12.h),

            // List
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.leads.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = controller.filteredLeads;
                if (items.isEmpty) {
                  return _emptyState();
                }
                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 100.h),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (_, i) => _leadCard(items[i]),
                );
              }),
            ),
          ],
            ),

            // Floating "add lead" button. BackgroundScreen already provides a
            // Scaffold, so we overlay the button here instead of nesting one.
            Positioned(
              right: 20.w,
              bottom: 24.h,
              child: GestureDetector(
                onTap: () => Get.to(() => const LeadFormScreen()),
                child: Container(
                  width: 56.r,
                  height: 56.r,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryColor.withOpacity(0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(Icons.add, color: AppColors.whiteColor, size: 28.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(30.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.contacts_outlined,
                size: 60.sp, color: AppColors.primaryColor.withOpacity(0.5)),
            SizedBox(height: 16.h),
            Text(
              controller.leads.isEmpty
                  ? 'No leads yet'
                  : 'No leads match your search',
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.blackColor,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              controller.leads.isEmpty
                  ? 'Tap the + button to add your first client.'
                  : 'Try a different name or status filter.',
              textAlign: TextAlign.center,
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 14.sp,
                color: AppColors.greyColor70.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leadCard(Lead lead) {
    final subtitle = [
      if (lead.company.isNotEmpty) lead.company,
      if (lead.phone.isNotEmpty) lead.phone,
    ].join(' • ');

    return GestureDetector(
      onTap: () => Get.to(() => LeadDetailScreen(leadId: lead.id)),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24.r,
              backgroundColor: statusColor(lead.status).withOpacity(0.15),
              child: Text(
                lead.initials,
                style: AppFonts.spaceGrotesk.copyWith(
                  color: statusColor(lead.status),
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead.name.isEmpty ? 'Unnamed lead' : lead.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blackColor,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    SizedBox(height: 3.h),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 13.sp,
                        color: AppColors.greyColor70.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: statusColor(lead.status).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                lead.status,
                style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: statusColor(lead.status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
