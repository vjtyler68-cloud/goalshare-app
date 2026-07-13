import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/alertdialogs/create_new_mission.dart';
import 'package:spanx/features/mission/controller/mission_controller.dart';
import 'package:spanx/features/mission/model/get_all_mission_model.dart';
import 'package:spanx/features/mission_details/screen/mission_details_screen.dart';

// ─── Brand colours ───────────────────────────────────────────────────────────
const _kRed   = Color(0xffE84040);
const _kRedDk = Color(0xff9B1414);
const _kBg    = Color(0xffF6F4F2);
const _kCard  = Color(0xffFFFFFF);
const _kText  = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// The "My Goals" tab. Groups the user's goals (stored on the backend `/goals`
/// endpoints via [MissionController]) into Today / This Week / This Month /
/// This Year buckets so they can see the macro-to-micro picture at a glance.
class GoalsScreen extends StatelessWidget {
  GoalsScreen({super.key});

  final MissionController c = Get.find<MissionController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              color: _kRed,
              onRefresh: () => c.fetchMission(),
              child: Obx(() {
                final goals = c.getAllMissionList;
                if (c.isLoading.value && goals.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: _kRed));
                }

                final daily   = goals.where((g) => g.category == 'Daily').toList();
                final weekly  = goals.where((g) => g.category == 'Weekly').toList();
                final monthly = goals.where((g) => g.category == 'Monthly').toList();
                final yearly  = goals.where((g) => g.category == 'Yearly').toList();

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 110.h),
                  children: [
                    if (daily.isNotEmpty) ...[
                      _section('Today', 'daily goals', daily),
                      SizedBox(height: 22.h),
                    ],
                    _section('This Week', 'weekly goals', weekly),
                    SizedBox(height: 22.h),
                    _section('This Month', 'monthly goals', monthly),
                    SizedBox(height: 22.h),
                    _section('This Year', 'yearly goals', yearly),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kRed, _kRedDk],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Weekly · Monthly · Yearly', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white70, fontSize: 12.sp)),
                      Text('My Goals', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 26.sp, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  GestureDetector(
                    onTap: CreateNewMission.show,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add, color: Colors.white, size: 18),
                          SizedBox(width: 4.w),
                          Text('New', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              // Quick summary
              Obx(() {
                final goals = c.getAllMissionList;
                final total = goals.length;
                final completed = goals.where((g) => g.status == 'COMPLETED').length;
                return Row(
                  children: [
                    _headerChip('Active', '${total - completed}'),
                    SizedBox(width: 10.w),
                    _headerChip('Completed', '$completed'),
                    SizedBox(width: 10.w),
                    _headerChip('Total', '$total'),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerChip(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12.r)),
      child: Column(
        children: [
          Text(value, style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w800)),
          Text(label, style: AppFonts.spaceGrotesk.copyWith(color: Colors.white70, fontSize: 10.sp)),
        ],
      ),
    );
  }

  // ── Section ────────────────────────────────────────────────────────────────
  Widget _section(String title, String emptyNoun, List<GetAllMissionModel> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: AppFonts.spaceGrotesk.copyWith(fontSize: 17.sp, fontWeight: FontWeight.w800, color: _kText)),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(color: _kRed.withOpacity(0.1), borderRadius: BorderRadius.circular(20.r)),
              child: Text('${items.length}', style: AppFonts.spaceGrotesk.copyWith(fontSize: 11.sp, fontWeight: FontWeight.w700, color: _kRed)),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        if (items.isEmpty)
          _emptyState(emptyNoun)
        else
          ...items.map((g) => _GoalCard(goal: g, controller: c)),
      ],
    );
  }

  Widget _emptyState(String noun) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.add_circle_outline, color: _kRed.withOpacity(0.4), size: 30.r),
          SizedBox(height: 8.h),
          Text('No $noun yet — tap “New” to add one.',
              textAlign: TextAlign.center,
              style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, color: _kMuted, height: 1.5)),
        ],
      ),
    );
  }
}

// ─── Goal card ────────────────────────────────────────────────────────────────
class _GoalCard extends StatelessWidget {
  final GetAllMissionModel goal;
  final MissionController controller;
  const _GoalCard({required this.goal, required this.controller});

  Color _priorityColor(String? p) {
    switch (p) {
      case 'High': return _kRed;
      case 'Medium': return const Color(0xffF59E0B);
      default: return const Color(0xff10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = goal.clientTarget ?? 0;
    final reached = goal.totalReached ?? 0;
    final progress = target > 0 ? (reached / target).clamp(0.0, 1.0) : 0.0;
    final isDone = goal.status == 'COMPLETED';
    final pColor = _priorityColor(goal.priority);
    final due = goal.dueDate != null ? DateFormat('dd MMM yyyy').format(goal.dueDate!) : null;

    return GestureDetector(
      onTap: () => Get.to(() => MissionDetailsScreen(), arguments: goal.id),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 3))],
          border: Border(left: BorderSide(color: pColor, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _chip(goal.category ?? '', const Color(0xff6366F1)),
                SizedBox(width: 6.w),
                _chip(goal.priority ?? 'Low', pColor),
                const Spacer(),
                if (isDone)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(color: const Color(0xff22C55E).withOpacity(0.12), borderRadius: BorderRadius.circular(20.r)),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xff22C55E), size: 12),
                        SizedBox(width: 3.w),
                        Text('Done', style: AppFonts.spaceGrotesk.copyWith(fontSize: 10.sp, fontWeight: FontWeight.w700, color: const Color(0xff22C55E))),
                      ],
                    ),
                  )
                else
                  GestureDetector(
                    onTap: () => _confirmDelete(goal.id),
                    child: Icon(Icons.delete_outline, color: _kMuted, size: 20.r),
                  ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(goal.title ?? 'Untitled goal', style: AppFonts.spaceGrotesk.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w800, color: _kText)),
            if ((goal.description ?? '').isNotEmpty) ...[
              SizedBox(height: 4.h),
              Text(goal.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppFonts.spaceGrotesk.copyWith(fontSize: 12.sp, color: _kMuted, height: 1.4)),
            ],
            SizedBox(height: 12.h),
            // Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Progress', style: AppFonts.spaceGrotesk.copyWith(fontSize: 11.sp, color: _kMuted)),
                Text('$reached / $target', style: AppFonts.spaceGrotesk.copyWith(fontSize: 11.sp, fontWeight: FontWeight.w700, color: _kText)),
              ],
            ),
            SizedBox(height: 6.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 8,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: pColor.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(isDone ? const Color(0xff22C55E) : pColor),
                ),
              ),
            ),
            if (due != null) ...[
              SizedBox(height: 10.h),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 13.r, color: _kMuted),
                  SizedBox(width: 5.w),
                  Text('Due $due', style: AppFonts.spaceGrotesk.copyWith(fontSize: 11.sp, color: _kMuted)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8.r)),
      child: Text(text, style: AppFonts.spaceGrotesk.copyWith(fontSize: 10.sp, fontWeight: FontWeight.w700, color: color)),
    );
  }

  void _confirmDelete(String? id) {
    if (id == null) return;
    Get.defaultDialog(
      backgroundColor: Colors.white,
      title: 'Delete Goal?',
      middleText: 'Are you sure you want to delete this goal?',
      confirm: TextButton(
        onPressed: () { Get.back(); controller.deleteMotivation(id); },
        child: const Text('Delete', style: TextStyle(color: Colors.red)),
      ),
      cancel: TextButton(onPressed: Get.back, child: const Text('Cancel')),
    );
  }
}
