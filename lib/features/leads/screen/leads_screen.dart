import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/bg_screen_widget.dart';
import 'package:spanx/core/global_widgets/smart_search_bar.dart';
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
  Worker? _searchWorker;
  bool _hadResults = true;

  @override
  void initState() {
    super.initState();
    // Give a gentle haptic "beat" the moment a search hits a dead end, so an
    // empty result set feels intentional rather than broken.
    _searchWorker = ever(controller.searchQuery, (_) {
      final hasResults = controller.matchCount > 0;
      if (controller.isSearching && !hasResults && _hadResults) {
        HapticFeedback.lightImpact();
      }
      _hadResults = hasResults;
    });
  }

  @override
  void dispose() {
    _searchWorker?.dispose();
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

            // Smart search — typo-tolerant, debounced live filtering over
            // name / phone / status / notes.
            SmartSearchBar(
              margin: EdgeInsets.symmetric(horizontal: 20.w),
              hintText: 'Search name, phone, status, notes…',
              onChanged: (v) => controller.searchQuery.value = v,
            ),

            // Live, animated match count — only while searching.
            Obx(() {
              final searching = controller.isSearching;
              final n = controller.matchCount;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: !searching
                    ? const SizedBox(key: ValueKey('no-count'), height: 0)
                    : Padding(
                        key: ValueKey('count-$n'),
                        padding: EdgeInsets.only(left: 22.w, top: 8.h),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            n == 0 ? 'No matches' : '$n match${n == 1 ? '' : 'es'}',
                            style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: n == 0
                                  ? AppColors.primaryColor
                                  : AppColors.greyColor70.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ),
              );
            }),
            SizedBox(height: 10.h),

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
                      onTap: () {
                        HapticFeedback.selectionClick();
                        controller.statusFilter.value = s;
                      },
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

            // List — results glide in when the query or filter changes.
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.leads.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                final query = controller.searchQuery.value;
                final items = controller.filteredLeads;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: items.isEmpty
                      ? _emptyState(key: const ValueKey('empty'))
                      : ListView.separated(
                          key: ValueKey(
                              '${query}_${controller.statusFilter.value}_${items.length}'),
                          padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 100.h),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => SizedBox(height: 10.h),
                          itemBuilder: (_, i) => _leadCard(items[i], query),
                        ),
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

  Widget _emptyState({Key? key}) {
    final noLeadsAtAll = controller.leads.isEmpty;
    final query = controller.searchQuery.value.trim();
    final searching = query.isNotEmpty;

    final title = noLeadsAtAll
        ? 'No leads yet'
        : searching
            ? 'No match for “$query”'
            : 'No leads in this filter';
    final subtitle = noLeadsAtAll
        ? 'Tap the + button to add your first client.'
        : searching
            ? 'Try fewer letters or check the status filter.'
            : 'Pick a different status above.';

    return Center(
      key: key,
      child: Padding(
        padding: EdgeInsets.all(30.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(searching ? Icons.search_off_rounded : Icons.contacts_outlined,
                size: 60.sp, color: AppColors.primaryColor.withOpacity(0.5)),
            SizedBox(height: 16.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.blackColor,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              subtitle,
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


  Widget _leadCard(Lead lead, String query) {
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
