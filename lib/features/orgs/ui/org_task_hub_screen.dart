import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';

import '../controller/org_controller.dart';
import '../controller/org_task_controller.dart';
import '../data/org_models.dart';
import '../data/org_task_models.dart';

const _kBg = Color(0xffF6F4F2);
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);
const _kCard = Colors.white;

/// The org Task Hub — a shared, assignable command center for the whole
/// capture → organize → prioritize → schedule → assign → follow-up → review →
/// report workflow. Members-only (the backend gates every call on membership).
class OrgTaskHubScreen extends StatefulWidget {
  const OrgTaskHubScreen({super.key});

  @override
  State<OrgTaskHubScreen> createState() => _OrgTaskHubScreenState();
}

class _OrgTaskHubScreenState extends State<OrgTaskHubScreen> {
  final _capture = TextEditingController();
  int _view = 0; // 0 = Focus, 1 = Board, 2 = Report
  Color get _accent => AppColors.primaryColor;

  OrgTaskController get c => OrgTaskController.to;

  @override
  void initState() {
    super.initState();
    final org = OrgController.to.myOrg.value;
    if (org != null) {
      c.load(org.id);
      // Load the roster (admin-only) so the assignee picker has teammates.
      if (org.isAdmin) OrgController.to.refreshRoster();
    }
  }

  @override
  void dispose() {
    _capture.dispose();
    super.dispose();
  }

  Future<void> _quickAdd() async {
    final title = _capture.text.trim();
    if (title.isEmpty) return;
    _capture.clear();
    FocusScope.of(context).unfocus();
    final t = await c.create({'title': title});
    if (t == null) AppSnackBar.error('Could not add the task.');
  }

  @override
  Widget build(BuildContext context) {
    final org = OrgController.to.myOrg.value;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back, color: _kText)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Task Hub',
                style: AppFonts.spaceGrotesk
                    .copyWith(color: _kText, fontWeight: FontWeight.w800)),
            if (org != null)
              Text(org.name,
                  style: AppFonts.spaceGrotesk
                      .copyWith(color: _kMuted, fontSize: 11.sp)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: c.refresh,
              icon: const Icon(Icons.refresh_rounded, color: _kText)),
        ],
      ),
      body: Column(
        children: [
          _captureBar(),
          _filterRow(),
          Expanded(
            child: Obx(() {
              if (c.loading.value && c.tasks.isEmpty) {
                return Center(
                    child: CircularProgressIndicator(color: _accent));
              }
              switch (_view) {
                case 1:
                  return _boardView();
                case 2:
                  return _calendarView();
                case 3:
                  return _meetingsView();
                case 4:
                  return _reportView();
                default:
                  return _focusView();
              }
            }),
          ),
        ],
      ),
    );
  }

  // ── quick capture ──────────────────────────────────────────────────────────
  Widget _captureBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 6.h),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: _kCard, borderRadius: BorderRadius.circular(14.r)),
              child: TextField(
                controller: _capture,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _quickAdd(),
                style: AppFonts.spaceGrotesk
                    .copyWith(color: _kText, fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: 'Capture a task…',
                  hintStyle: AppFonts.spaceGrotesk
                      .copyWith(color: _kMuted, fontSize: 14.sp),
                  prefixIcon: Icon(Icons.bolt_rounded, color: _accent, size: 20.r),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 4.w, vertical: 14.h),
                ),
              ),
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: _quickAdd,
            child: Container(
              width: 46.r,
              height: 46.r,
              decoration:
                  BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(14.r)),
              child: Icon(Icons.add_rounded, color: Colors.white, size: 24.r),
            ),
          ),
        ],
      ),
    );
  }

  // ── filters + view switch ───────────────────────────────────────────────────
  Widget _filterRow() {
    return SizedBox(
      height: 42.h,
      child: Obx(
        () => ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          children: [
            _seg('Focus', 0),
            _seg('Board', 1),
            _seg('Calendar', 2),
            _seg('Meetings', 3),
            _seg('Report', 4),
            SizedBox(width: 8.w),
            Container(width: 1, color: Colors.black12, margin: EdgeInsets.symmetric(vertical: 10.h)),
            SizedBox(width: 8.w),
            _filterChip(
              'Mine',
              c.mineOnly.value,
              () => c.mineOnly.toggle(),
              icon: Icons.person_rounded,
            ),
            SizedBox(width: 8.w),
            ...c.projects.map((p) => Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: _filterChip(
                    p.name,
                    c.filterProjectId.value == p.id,
                    () => c.filterProjectId.value =
                        c.filterProjectId.value == p.id ? null : p.id,
                    dot: p.colorOrNull ?? _accent,
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _seg(String label, int i) {
    final on = _view == i;
    return Padding(
      padding: EdgeInsets.only(right: 8.w),
      child: GestureDetector(
        onTap: () => setState(() => _view = i),
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: on ? _kText : _kCard,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(label,
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w800,
                  color: on ? Colors.white : _kText)),
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool on, VoidCallback onTap,
      {IconData? icon, Color? dot}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: on ? _accent.withOpacity(0.14) : _kCard,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: on ? _accent : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13.r, color: on ? _accent : _kMuted),
              SizedBox(width: 5.w),
            ],
            if (dot != null) ...[
              Container(
                  width: 8.r,
                  height: 8.r,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
              SizedBox(width: 5.w),
            ],
            Text(label,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: on ? _accent : _kText)),
          ],
        ),
      ),
    );
  }

  // ── FOCUS view (smart buckets) ──────────────────────────────────────────────
  Widget _focusView() {
    final buckets = <(String, Color, List<OrgTask>)>[
      ('Overdue', const Color(0xffDC2626), c.overdue),
      ('Today', _accent, c.today),
      ('Tomorrow', const Color(0xff0EA5E9), c.tomorrow),
      ('This Week', const Color(0xff2563EB), c.thisWeek),
      ('Upcoming', const Color(0xff7C3AED), c.upcoming),
      ('No date', _kMuted, c.noDate),
      ('Waiting on', const Color(0xffF59E0B), c.waiting),
      ('Needs approval', const Color(0xff7C3AED), c.approvals),
    ];
    final nonEmpty = buckets.where((b) => b.$3.isNotEmpty).toList();
    final done = c.doneTasks;

    return RefreshIndicator(
      onRefresh: c.refresh,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 40.h),
        children: [
          Row(
            children: [
              Expanded(
                child: _actionBtn('Daily Review', Icons.rate_review_rounded,
                    c.overdue.isNotEmpty || c.today.isNotEmpty, _openDailyReview),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _actionBtn(
                    'Notes → Tasks', Icons.notes_rounded, false, _openNotesToTasks),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          if (nonEmpty.isEmpty && done.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 40.h),
              child: _empty(),
            )
          else ...[
            for (final b in nonEmpty) ...[
              _bucketHeader(b.$1, b.$2, b.$3.length),
              ...b.$3.map(_taskTile),
              SizedBox(height: 8.h),
            ],
            if (done.isNotEmpty) ...[
              _bucketHeader('Done', const Color(0xff16A34A), done.length),
              ...done.take(20).map(_taskTile),
            ],
          ],
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, bool highlight, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 11.h),
        decoration: BoxDecoration(
          color: highlight ? _accent.withOpacity(0.12) : _kCard,
          borderRadius: BorderRadius.circular(12.r),
          border:
              Border.all(color: highlight ? _accent : Colors.transparent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16.r, color: highlight ? _accent : _kText),
            SizedBox(width: 6.w),
            Text(label,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w800,
                    color: highlight ? _accent : _kText)),
          ],
        ),
      ),
    );
  }

  Widget _bucketHeader(String title, Color color, int count) {
    return Padding(
      padding: EdgeInsets.only(top: 10.h, bottom: 8.h),
      child: Row(
        children: [
          Container(
              width: 8.r,
              height: 8.r,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          SizedBox(width: 8.w),
          Text(title.toUpperCase(),
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: _kText)),
          SizedBox(width: 6.w),
          Text('$count',
              style: AppFonts.spaceGrotesk
                  .copyWith(fontSize: 11.sp, color: _kMuted)),
        ],
      ),
    );
  }

  // ── task tile ────────────────────────────────────────────────────────────
  Widget _taskTile(OrgTask t) {
    final blocked = c.isBlocked(t);
    final overdue = t.dueAt != null &&
        !t.isDone &&
        t.dueAt!.isBefore(DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day));
    return GestureDetector(
      onTap: () => _openEditor(t),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.fromLTRB(10.w, 10.h, 12.w, 10.h),
        decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(14.r),
            border: Border(
                left: BorderSide(color: t.priority.color, width: 4.w))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => c.toggleDone(t),
              child: Padding(
                padding: EdgeInsets.only(top: 1.h, right: 10.w),
                child: Icon(
                    t.isDone
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: t.isDone ? const Color(0xff16A34A) : _kMuted,
                    size: 22.r),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title,
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: t.isDone ? _kMuted : _kText,
                          decoration:
                              t.isDone ? TextDecoration.lineThrough : null)),
                  if (_hasMeta(t)) SizedBox(height: 6.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 4.h,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (t.dueAt != null)
                        _metaChip(
                            _fmtDate(t.dueAt!),
                            Icons.event_rounded,
                            overdue ? const Color(0xffDC2626) : _kMuted),
                      if (blocked)
                        _metaChip('Blocked', Icons.lock_outline_rounded,
                            const Color(0xffDC2626)),
                      if (t.status == TaskStatus.waiting &&
                          t.waitingOn.isNotEmpty)
                        _metaChip(t.waitingOn, Icons.hourglass_empty_rounded,
                            const Color(0xffF59E0B)),
                      if (t.isRecurring)
                        _metaChip(t.recurRule.label, Icons.repeat_rounded,
                            const Color(0xff2563EB)),
                      if (t.followUpAt != null)
                        _metaChip('Follow-up ${_fmtDate(t.followUpAt!)}',
                            Icons.notifications_active_rounded, _kMuted),
                      if (t.projectId != null)
                        _projectChip(t.projectId!),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            if (t.isAssigned) _assigneeAvatar(t.assigneeName),
          ],
        ),
      ),
    );
  }

  bool _hasMeta(OrgTask t) =>
      t.dueAt != null ||
      c.isBlocked(t) ||
      (t.status == TaskStatus.waiting && t.waitingOn.isNotEmpty) ||
      t.isRecurring ||
      t.followUpAt != null ||
      t.projectId != null;

  Widget _metaChip(String label, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(8.r)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.r, color: color),
          SizedBox(width: 4.w),
          Text(label,
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _projectChip(String projectId) {
    final p = c.projectById(projectId);
    if (p == null) return const SizedBox.shrink();
    final col = p.colorOrNull ?? _accent;
    return _metaChip(p.name, Icons.folder_rounded, col);
  }

  Widget _assigneeAvatar(String name) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: 28.r,
      height: 28.r,
      alignment: Alignment.center,
      decoration:
          BoxDecoration(color: _accent.withOpacity(0.14), shape: BoxShape.circle),
      child: Text(initial,
          style: AppFonts.spaceGrotesk.copyWith(
              color: _accent, fontSize: 12.sp, fontWeight: FontWeight.w800)),
    );
  }

  // ── BOARD view (grouped by project) ─────────────────────────────────────────
  Widget _boardView() {
    final groups = <(String, String?, List<OrgTask>)>[];
    for (final p in c.projects) {
      final list = c.tasks
          .where((t) => t.projectId == p.id && !t.isDone)
          .toList()
        ..sort((a, b) => b.priority.weight.compareTo(a.priority.weight));
      groups.add((p.name, p.id, list));
    }
    final noProject =
        c.tasks.where((t) => t.projectId == null && !t.isDone).toList()
          ..sort((a, b) => b.priority.weight.compareTo(a.priority.weight));

    return RefreshIndicator(
      onRefresh: c.refresh,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 40.h),
        children: [
          GestureDetector(
            onTap: _newProject,
            child: Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: _accent.withOpacity(0.4))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.create_new_folder_rounded,
                      color: _accent, size: 18.r),
                  SizedBox(width: 8.w),
                  Text('New project',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: _accent)),
                ],
              ),
            ),
          ),
          for (final g in groups) ...[
            Row(
              children: [
                Expanded(child: _bucketHeader(g.$1, _accent, g.$3.length)),
                GestureDetector(
                  onTap: () => _confirmDeleteProject(g.$2!, g.$1),
                  child: Icon(Icons.more_horiz_rounded,
                      color: _kMuted, size: 20.r),
                ),
              ],
            ),
            if (g.$3.isEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: 10.h, left: 16.w),
                child: Text('No open tasks',
                    style: AppFonts.spaceGrotesk
                        .copyWith(fontSize: 12.sp, color: _kMuted)),
              )
            else
              ...g.$3.map(_taskTile),
            SizedBox(height: 6.h),
          ],
          _bucketHeader('No project', _kMuted, noProject.length),
          if (noProject.isEmpty)
            Padding(
              padding: EdgeInsets.only(left: 16.w),
              child: Text('Nothing here',
                  style: AppFonts.spaceGrotesk
                      .copyWith(fontSize: 12.sp, color: _kMuted)),
            )
          else
            ...noProject.map(_taskTile),
        ],
      ),
    );
  }

  // ── REPORT view ─────────────────────────────────────────────────────────────
  Widget _reportView() {
    final byAssignee = c.openByAssignee.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 40.h),
      children: [
        Row(
          children: [
            _statCard('${c.activeCount}', 'Open', _accent),
            SizedBox(width: 10.w),
            _statCard('${c.overdueCount}', 'Overdue', const Color(0xffDC2626)),
            SizedBox(width: 10.w),
            _statCard('${c.doneThisWeekCount}', 'Done · 7d',
                const Color(0xff16A34A)),
          ],
        ),
        SizedBox(height: 20.h),
        Text('OPEN BY PERSON',
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: _kMuted)),
        SizedBox(height: 10.h),
        if (byAssignee.isEmpty)
          Text('No open tasks.',
              style: AppFonts.spaceGrotesk
                  .copyWith(fontSize: 13.sp, color: _kMuted))
        else
          ...byAssignee.map((e) => Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                    color: _kCard, borderRadius: BorderRadius.circular(12.r)),
                child: Row(
                  children: [
                    _assigneeAvatar(e.key == 'Unassigned' ? '?' : e.key),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(e.key,
                          style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: _kText)),
                    ),
                    Text('${e.value}',
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w900,
                            color: _accent)),
                    SizedBox(width: 4.w),
                    Text('open',
                        style: AppFonts.spaceGrotesk
                            .copyWith(fontSize: 11.sp, color: _kMuted)),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _statCard(String value, String label, Color color) => Expanded(
        child: Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
              color: _kCard, borderRadius: BorderRadius.circular(14.r)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      color: color)),
              SizedBox(height: 2.h),
              Text(label,
                  style: AppFonts.spaceGrotesk
                      .copyWith(fontSize: 11.sp, color: _kMuted)),
            ],
          ),
        ),
      );

  Widget _empty() => Center(
        child: Padding(
          padding: EdgeInsets.all(30.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.checklist_rounded, size: 44.r, color: _kMuted),
              SizedBox(height: 12.h),
              Text('No tasks yet',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: _kText)),
              SizedBox(height: 6.h),
              Text('Capture your first task above — assign it, set a due date,\nand it shows up for the whole team.',
                  textAlign: TextAlign.center,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 12.5.sp, color: _kMuted, height: 1.5)),
            ],
          ),
        ),
      );

  // ── project creation / deletion ─────────────────────────────────────────────
  void _newProject() {
    final ctrl = TextEditingController();
    Get.dialog(AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
      title: Text('New project',
          style: AppFonts.spaceGrotesk
              .copyWith(fontWeight: FontWeight.w900, color: _kText)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        style: AppFonts.spaceGrotesk.copyWith(color: _kText),
        decoration: const InputDecoration(hintText: 'Project name'),
      ),
      actions: [
        TextButton(
            onPressed: Get.back,
            child: Text('Cancel',
                style: AppFonts.spaceGrotesk.copyWith(color: _kMuted))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: _accent, foregroundColor: Colors.white),
          onPressed: () async {
            final name = ctrl.text.trim();
            if (name.isEmpty) return;
            Get.back();
            final p = await c.createProject(name, '');
            if (p == null) AppSnackBar.error('Could not create the project.');
          },
          child: const Text('Create'),
        ),
      ],
    ));
  }

  void _confirmDeleteProject(String projectId, String name) {
    Get.dialog(AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
      title: Text('Delete "$name"?',
          style: AppFonts.spaceGrotesk
              .copyWith(fontWeight: FontWeight.w900, color: _kText, fontSize: 16.sp)),
      content: Text(
          'The project is removed. Its tasks are kept and just lose the project tag.',
          style: AppFonts.spaceGrotesk
              .copyWith(color: _kText, fontSize: 13.sp, height: 1.4)),
      actions: [
        TextButton(
            onPressed: Get.back,
            child: Text('Cancel',
                style: AppFonts.spaceGrotesk.copyWith(color: _kMuted))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffC0392B),
              foregroundColor: Colors.white),
          onPressed: () {
            Get.back();
            c.removeProject(projectId);
          },
          child: const Text('Delete'),
        ),
      ],
    ));
  }

  // ── CALENDAR / TIMELINE view ────────────────────────────────────────────────
  Widget _calendarView() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final overdue = c.overdue;
    final days = <DateTime>[];
    for (int i = 0; i < 60; i++) {
      final d = today.add(Duration(days: i));
      if (c.tasksOn(d).isNotEmpty || c.meetingsOn(d).isNotEmpty) days.add(d);
    }
    if (overdue.isEmpty && days.isEmpty) return _empty();
    return RefreshIndicator(
      onRefresh: c.refresh,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 40.h),
        children: [
          if (overdue.isNotEmpty) ...[
            _bucketHeader('Overdue', const Color(0xffDC2626), overdue.length),
            ...overdue.map(_taskTile),
            SizedBox(height: 10.h),
          ],
          for (final d in days) ...[
            _dayHeader(d),
            ...c.meetingsOn(d).map(_meetingRow),
            ...c.tasksOn(d).map(_taskTile),
            SizedBox(height: 8.h),
          ],
        ],
      ),
    );
  }

  Widget _dayHeader(DateTime d) {
    final rel = _fmtDate(d);
    return Padding(
      padding: EdgeInsets.only(top: 10.h, bottom: 8.h),
      child: Text(_fullDate(d).toUpperCase(),
          style: AppFonts.spaceGrotesk.copyWith(
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: rel == 'Today' ? _accent : _kText)),
    );
  }

  static String _fullDate(DateTime d) {
    final rel = _fmtDate(d);
    if (rel == 'Today' || rel == 'Tomorrow') return rel;
    const wk = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${wk[d.weekday - 1]}, ${m[d.month - 1]} ${d.day}';
  }

  static String _timeLabel(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    return '$h:${d.minute.toString().padLeft(2, '0')} $ampm';
  }

  Widget _meetingRow(OrgMeeting m) {
    final actions = c.tasksForMeeting(m.id);
    final openCount = actions.where((t) => !t.isDone).length;
    return GestureDetector(
      onTap: () => _openMeeting(m),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: _accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: _accent.withOpacity(0.30)),
        ),
        child: Row(
          children: [
            Icon(Icons.groups_rounded, color: _accent, size: 20.r),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: _kText)),
                  Text(
                      m.startAt != null
                          ? '${_fmtDate(m.startAt!)} · ${_timeLabel(m.startAt!)}'
                          : 'No time set',
                      style: AppFonts.spaceGrotesk
                          .copyWith(fontSize: 11.sp, color: _kMuted)),
                ],
              ),
            ),
            if (actions.isNotEmpty)
              Text('$openCount/${actions.length}',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: _accent)),
            Icon(Icons.chevron_right, color: _kMuted, size: 20.r),
          ],
        ),
      ),
    );
  }

  // ── MEETINGS view ────────────────────────────────────────────────────────────
  Widget _meetingsView() {
    final list = c.meetings.toList()
      ..sort((a, b) =>
          (b.startAt ?? DateTime(0)).compareTo(a.startAt ?? DateTime(0)));
    return RefreshIndicator(
      onRefresh: c.refresh,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 40.h),
        children: [
          GestureDetector(
            onTap: _newMeeting,
            child: Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(14.r)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 20.r),
                  SizedBox(width: 8.w),
                  Text('New meeting',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
          if (list.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 30.h),
              child: Column(
                children: [
                  Icon(Icons.groups_rounded, size: 40.r, color: _kMuted),
                  SizedBox(height: 10.h),
                  Text('No meetings yet',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: _kText)),
                  SizedBox(height: 4.h),
                  Text('Schedule one, build an agenda, and turn decisions into\naction items the team can track.',
                      textAlign: TextAlign.center,
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 12.sp, color: _kMuted, height: 1.5)),
                ],
              ),
            )
          else
            ...list.map(_meetingRow),
        ],
      ),
    );
  }

  void _newMeeting() {
    Get.bottomSheet(
      const _MeetingSheet(meeting: null),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _openMeeting(OrgMeeting m) {
    Get.bottomSheet(
      _MeetingSheet(meeting: m),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // ── Notes → Tasks (bulk capture) ─────────────────────────────────────────────
  void _openNotesToTasks() {
    final ctrl = TextEditingController();
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notes → Tasks',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: _kText)),
            SizedBox(height: 4.h),
            Text('Paste your meeting notes or a list — each line becomes a task.',
                style: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 12.sp, color: _kMuted)),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                  color: _kCard, borderRadius: BorderRadius.circular(14.r)),
              child: TextField(
                controller: ctrl,
                maxLines: 8,
                autofocus: true,
                style: AppFonts.spaceGrotesk
                    .copyWith(color: _kText, fontSize: 14.sp, height: 1.5),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText:
                      'Call vendor about invoice\nSend proposal to Acme\nFollow up with Jordan',
                  hintStyle: AppFonts.spaceGrotesk
                      .copyWith(color: _kMuted, fontSize: 14.sp, height: 1.5),
                  contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r))),
                onPressed: () async {
                  final lines = ctrl.text
                      .split('\n')
                      .map((l) => l.replaceFirst(RegExp(r'^\s*[-*•\d.]+\s*'), '').trim())
                      .where((l) => l.isNotEmpty)
                      .toList();
                  if (lines.isEmpty) {
                    Get.back();
                    return;
                  }
                  Get.back();
                  final n = await c.createMany(lines);
                  AppSnackBar.success(
                      '$n task${n == 1 ? '' : 's'} created');
                },
                child: Text('Create tasks',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 15.sp, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // ── Daily Review & carryover ─────────────────────────────────────────────────
  void _openDailyReview() {
    Get.bottomSheet(
      const _DailyReviewSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // ── task editor ─────────────────────────────────────────────────────────────
  void _openEditor(OrgTask t) {
    Get.bottomSheet(
      _TaskEditorSheet(task: t),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // ── date format ─────────────────────────────────────────────────────────────
  static String _fmtDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = that.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${m[d.month - 1]} ${d.day}';
  }
}

/// Full editor for one task — every field the workflow needs.
class _TaskEditorSheet extends StatefulWidget {
  final OrgTask task;
  const _TaskEditorSheet({required this.task});

  @override
  State<_TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<_TaskEditorSheet> {
  late TextEditingController _title;
  late TextEditingController _notes;
  late TextEditingController _waitingOn;
  late TaskStatus _status;
  late TaskPriority _priority;
  late TaskRecur _recur;
  DateTime? _due;
  DateTime? _followUp;
  String? _assigneeId;
  String _assigneeName = '';
  String? _projectId;
  String? _dependsOnId;
  bool _saving = false;

  Color get _accent => AppColors.primaryColor;
  OrgTaskController get c => OrgTaskController.to;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _title = TextEditingController(text: t.title);
    _notes = TextEditingController(text: t.notes);
    _waitingOn = TextEditingController(text: t.waitingOn);
    _status = t.status;
    _priority = t.priority;
    _recur = t.recurRule;
    _due = t.dueAt;
    _followUp = t.followUpAt;
    _assigneeId = t.assigneeId;
    _assigneeName = t.assigneeName;
    _projectId = t.projectId;
    _dependsOnId = t.dependsOnId;
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _waitingOn.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      AppSnackBar.error('The task needs a title.');
      return;
    }
    setState(() => _saving = true);
    await c.updateTask(widget.task.id, {
      'title': _title.text.trim(),
      'notes': _notes.text.trim(),
      'status': _status.id,
      'priority': _priority.id,
      'recurRule': _recur.id,
      'waitingOn': _waitingOn.text.trim(),
      'dueAt': _due?.toUtc().toIso8601String(),
      'followUpAt': _followUp?.toUtc().toIso8601String(),
      'assigneeId': _assigneeId ?? '',
      'assigneeName': _assigneeName,
      'projectId': _projectId ?? '',
      'dependsOnId': _dependsOnId ?? '',
    });
    if (mounted) Get.back();
  }

  Future<void> _pickDate(bool forDue) async {
    final now = DateTime.now();
    final init = (forDue ? _due : _followUp) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: init.isBefore(now.subtract(const Duration(days: 1)))
          ? now
          : init,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        if (forDue) {
          _due = picked;
        } else {
          _followUp = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: 0.92.sh),
      decoration: const BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.only(bottom: 12.h),
            decoration: BoxDecoration(
                color: Colors.black12, borderRadius: BorderRadius.circular(4.r)),
          ),
          Expanded(
            child: ListView(
              children: [
                TextField(
                  controller: _title,
                  maxLines: null,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: _kText),
                  decoration: InputDecoration(
                      hintText: 'Task title',
                      border: InputBorder.none,
                      hintStyle:
                          AppFonts.spaceGrotesk.copyWith(color: _kMuted)),
                ),
                Divider(color: Colors.black12, height: 8.h),
                SizedBox(height: 8.h),

                _label('STATUS'),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: TaskStatus.values
                      .map((s) => _choice(s.label, s == _status, s.color,
                          () => setState(() => _status = s)))
                      .toList(),
                ),
                SizedBox(height: 16.h),

                _label('PRIORITY'),
                Wrap(
                  spacing: 8.w,
                  children: TaskPriority.values
                      .map((p) => _choice(p.label, p == _priority, p.color,
                          () => setState(() => _priority = p)))
                      .toList(),
                ),
                SizedBox(height: 16.h),

                Row(
                  children: [
                    Expanded(
                      child: _dateField('Due date', _due, () => _pickDate(true),
                          () => setState(() => _due = null)),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _dateField('Follow-up', _followUp,
                          () => _pickDate(false),
                          () => setState(() => _followUp = null)),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                _label('ASSIGNED TO'),
                _assigneePicker(),
                SizedBox(height: 16.h),

                _label('PROJECT'),
                _projectPicker(),
                SizedBox(height: 16.h),

                _label('BLOCKED BY'),
                _dependencyField(),
                SizedBox(height: 16.h),

                _label('REPEATS'),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: TaskRecur.values
                      .map((r) => _choice(r.label, r == _recur, _accent,
                          () => setState(() => _recur = r)))
                      .toList(),
                ),
                SizedBox(height: 16.h),

                if (_status == TaskStatus.waiting) ...[
                  _label('WAITING ON'),
                  _textBox(_waitingOn, 'Who / what are you waiting on?'),
                  SizedBox(height: 16.h),
                ],

                _label('NOTES'),
                _textBox(_notes, 'Details, links, context…', lines: 4),
                SizedBox(height: 20.h),

                GestureDetector(
                  onTap: () {
                    Get.back();
                    Get.dialog(AlertDialog(
                      backgroundColor: Colors.white,
                      title: Text('Delete task?',
                          style: AppFonts.spaceGrotesk.copyWith(
                              fontWeight: FontWeight.w900, color: _kText)),
                      actions: [
                        TextButton(
                            onPressed: Get.back,
                            child: Text('Cancel',
                                style: AppFonts.spaceGrotesk
                                    .copyWith(color: _kMuted))),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffC0392B),
                              foregroundColor: Colors.white),
                          onPressed: () {
                            Get.back();
                            c.remove(widget.task.id);
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ));
                  },
                  child: Center(
                    child: Text('Delete task',
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xffC0392B))),
                  ),
                ),
                SizedBox(height: 8.h),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r))),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? SizedBox(
                      width: 20.r,
                      height: 20.r,
                      child: const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text('Save',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 15.sp, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Text(t,
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: _kMuted)),
      );

  Widget _choice(String label, bool on, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
            color: on ? color : Colors.white,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: on ? color : Colors.black12)),
        child: Text(label,
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w700,
                color: on ? Colors.white : _kText)),
      ),
    );
  }

  Widget _dateField(
      String label, DateTime? value, VoidCallback onTap, VoidCallback onClear) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12.r)),
        child: Row(
          children: [
            Icon(Icons.event_rounded, size: 16.r, color: _accent),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                  value == null
                      ? label
                      : _OrgTaskHubScreenState._fmtDate(value),
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: value == null ? _kMuted : _kText)),
            ),
            if (value != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close_rounded, size: 16.r, color: _kMuted),
              ),
          ],
        ),
      ),
    );
  }

  Widget _textBox(TextEditingController ctrl, String hint, {int lines = 1}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12.r)),
      child: TextField(
        controller: ctrl,
        maxLines: lines,
        style: AppFonts.spaceGrotesk.copyWith(color: _kText, fontSize: 13.5.sp),
        decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
            hintStyle: AppFonts.spaceGrotesk.copyWith(color: _kMuted),
            contentPadding: EdgeInsets.symmetric(vertical: 12.h)),
      ),
    );
  }

  Widget _assigneePicker() {
    final roster = OrgController.to.roster;
    final myId = OrgController.to.myUserId.value;
    final options = <(String?, String)>[
      (null, 'Unassigned'),
      if (roster.isEmpty && myId != null) (myId, 'Me'),
      for (final OrgMember m in roster) (m.userId, m.name),
    ];
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: options.map((o) {
        final on = _assigneeId == o.$1;
        return _choice(o.$2, on, _accent, () {
          setState(() {
            _assigneeId = o.$1;
            _assigneeName = o.$1 == null ? '' : o.$2;
          });
        });
      }).toList(),
    );
  }

  Widget _projectPicker() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        _choice('None', _projectId == null, _kMuted,
            () => setState(() => _projectId = null)),
        for (final p in c.projects)
          _choice(p.name, _projectId == p.id, p.colorOrNull ?? _accent,
              () => setState(() => _projectId = p.id)),
      ],
    );
  }

  /// "Blocked by" — pick another task this one depends on (it's marked Blocked
  /// until that one is done).
  Widget _dependencyField() {
    final dep = c.taskById(_dependsOnId);
    return GestureDetector(
      onTap: _pickDependency,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12.r)),
        child: Row(
          children: [
            Icon(Icons.link_rounded, size: 16.r, color: _accent),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(dep == null ? 'Not blocked' : dep.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: dep == null ? _kMuted : _kText)),
            ),
            if (dep != null)
              GestureDetector(
                onTap: () => setState(() => _dependsOnId = null),
                child: Icon(Icons.close_rounded, size: 16.r, color: _kMuted),
              ),
          ],
        ),
      ),
    );
  }

  void _pickDependency() {
    final candidates = c.tasks
        .where((t) => t.id != widget.task.id && !t.isDone)
        .toList();
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: 0.7.sh),
        decoration: const BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Blocked by…',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w900,
                    color: _kText)),
            SizedBox(height: 12.h),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.block_flipped, color: _kMuted, size: 20.r),
                    title: Text('Not blocked',
                        style: AppFonts.spaceGrotesk
                            .copyWith(color: _kText, fontWeight: FontWeight.w600)),
                    onTap: () {
                      setState(() => _dependsOnId = null);
                      Get.back();
                    },
                  ),
                  for (final t in candidates)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.circle_outlined,
                          color: t.priority.color, size: 18.r),
                      title: Text(t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.spaceGrotesk.copyWith(
                              color: _kText, fontWeight: FontWeight.w600)),
                      onTap: () {
                        setState(() => _dependsOnId = t.id);
                        Get.back();
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

/// Create / edit a meeting — title, time, agenda, notes — and manage its action
/// items (tasks linked to this meeting).
class _MeetingSheet extends StatefulWidget {
  final OrgMeeting? meeting;
  const _MeetingSheet({required this.meeting});

  @override
  State<_MeetingSheet> createState() => _MeetingSheetState();
}

class _MeetingSheetState extends State<_MeetingSheet> {
  late TextEditingController _title;
  late TextEditingController _agenda;
  late TextEditingController _notes;
  final _actionCtrl = TextEditingController();
  DateTime? _startAt;
  bool _saving = false;

  Color get _accent => AppColors.primaryColor;
  OrgTaskController get c => OrgTaskController.to;
  OrgMeeting? get m => widget.meeting;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: m?.title ?? '');
    _agenda = TextEditingController(text: m?.agenda ?? '');
    _notes = TextEditingController(text: m?.notes ?? '');
    _startAt = m?.startAt;
  }

  @override
  void dispose() {
    _title.dispose();
    _agenda.dispose();
    _notes.dispose();
    _actionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickWhen() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _startAt ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (date == null) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startAt ?? now),
    );
    setState(() => _startAt = DateTime(
        date.year, date.month, date.day, t?.hour ?? 9, t?.minute ?? 0));
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      AppSnackBar.error('Add a meeting title.');
      return;
    }
    setState(() => _saving = true);
    final body = {
      'title': _title.text.trim(),
      'agenda': _agenda.text.trim(),
      'notes': _notes.text.trim(),
      'startAt': _startAt?.toUtc().toIso8601String() ?? '',
    };
    if (m == null) {
      await c.createMeeting(body);
    } else {
      await c.updateMeeting(m!.id, body);
    }
    if (mounted) Get.back();
  }

  Future<void> _addAction() async {
    final title = _actionCtrl.text.trim();
    if (title.isEmpty || m == null) return;
    _actionCtrl.clear();
    FocusScope.of(context).unfocus();
    await c.create({'title': title, 'meetingId': m!.id});
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: 0.92.sh),
      decoration: const BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.only(bottom: 12.h),
            decoration: BoxDecoration(
                color: Colors.black12, borderRadius: BorderRadius.circular(4.r)),
          ),
          Expanded(
            child: ListView(
              children: [
                TextField(
                  controller: _title,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: _kText),
                  decoration: InputDecoration(
                      hintText: 'Meeting title',
                      border: InputBorder.none,
                      hintStyle: AppFonts.spaceGrotesk.copyWith(color: _kMuted)),
                ),
                Divider(color: Colors.black12, height: 8.h),
                SizedBox(height: 10.h),
                GestureDetector(
                  onTap: _pickWhen,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r)),
                    child: Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 16.r, color: _accent),
                        SizedBox(width: 8.w),
                        Text(
                            _startAt == null
                                ? 'Set date & time'
                                : '${_OrgTaskHubScreenState._fmtDate(_startAt!)} · ${_OrgTaskHubScreenState._timeLabel(_startAt!)}',
                            style: AppFonts.spaceGrotesk.copyWith(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: _startAt == null ? _kMuted : _kText)),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                _miniLabel('AGENDA'),
                _box(_agenda, 'Topics to cover…', lines: 4),
                SizedBox(height: 14.h),
                _miniLabel('NOTES / DECISIONS'),
                _box(_notes, 'What was decided…', lines: 3),
                SizedBox(height: 16.h),
                if (m != null) ...[
                  _miniLabel('ACTION ITEMS'),
                  Obx(() {
                    final items = c.tasksForMeeting(m!.id);
                    return Column(
                      children: [
                        for (final t in items)
                          GestureDetector(
                            onTap: () => Get.bottomSheet(
                                _TaskEditorSheet(task: t),
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent),
                            child: Container(
                              margin: EdgeInsets.only(bottom: 8.h),
                              padding: EdgeInsets.all(12.r),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12.r)),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => c.toggleDone(t),
                                    child: Icon(
                                        t.isDone
                                            ? Icons.check_circle_rounded
                                            : Icons.circle_outlined,
                                        color: t.isDone
                                            ? const Color(0xff16A34A)
                                            : _kMuted,
                                        size: 20.r),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(t.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppFonts.spaceGrotesk.copyWith(
                                            fontSize: 13.5.sp,
                                            color: t.isDone ? _kMuted : _kText,
                                            decoration: t.isDone
                                                ? TextDecoration.lineThrough
                                                : null)),
                                  ),
                                  if (t.assigneeName.isNotEmpty)
                                    Text(t.assigneeName,
                                        style: AppFonts.spaceGrotesk.copyWith(
                                            fontSize: 10.5.sp, color: _kMuted)),
                                ],
                              ),
                            ),
                          ),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12.r)),
                                child: TextField(
                                  controller: _actionCtrl,
                                  onSubmitted: (_) => _addAction(),
                                  style: AppFonts.spaceGrotesk.copyWith(
                                      color: _kText, fontSize: 13.5.sp),
                                  decoration: InputDecoration(
                                    hintText: 'Add an action item…',
                                    hintStyle: AppFonts.spaceGrotesk
                                        .copyWith(color: _kMuted, fontSize: 13.sp),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12.w, vertical: 12.h),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            GestureDetector(
                              onTap: _addAction,
                              child: Container(
                                width: 44.r,
                                height: 44.r,
                                decoration: BoxDecoration(
                                    color: _accent,
                                    borderRadius: BorderRadius.circular(12.r)),
                                child: Icon(Icons.add_rounded,
                                    color: Colors.white, size: 22.r),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                  SizedBox(height: 18.h),
                  GestureDetector(
                    onTap: () {
                      Get.back();
                      c.removeMeeting(m!.id);
                    },
                    child: Center(
                      child: Text('Delete meeting',
                          style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xffC0392B))),
                    ),
                  ),
                ] else
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    child: Text('Save the meeting to start adding action items.',
                        style: AppFonts.spaceGrotesk
                            .copyWith(fontSize: 12.sp, color: _kMuted)),
                  ),
                SizedBox(height: 8.h),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r))),
              onPressed: _saving ? null : _save,
              child: Text(m == null ? 'Create meeting' : 'Save',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 15.sp, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniLabel(String t) => Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Text(t,
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: _kMuted)),
      );

  Widget _box(TextEditingController ctrl, String hint, {int lines = 1}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12.r)),
      child: TextField(
        controller: ctrl,
        maxLines: lines,
        style: AppFonts.spaceGrotesk.copyWith(color: _kText, fontSize: 13.5.sp),
        decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
            hintStyle: AppFonts.spaceGrotesk.copyWith(color: _kMuted),
            contentPadding: EdgeInsets.symmetric(vertical: 12.h)),
      ),
    );
  }
}

/// End-of-day review — walk overdue + today's open tasks and one-tap complete,
/// push to today, or push to tomorrow.
class _DailyReviewSheet extends StatelessWidget {
  const _DailyReviewSheet();

  @override
  Widget build(BuildContext context) {
    final c = OrgTaskController.to;
    final accent = AppColors.primaryColor;
    String iso(DateTime d) =>
        DateTime(d.year, d.month, d.day).toUtc().toIso8601String();
    return Container(
      constraints: BoxConstraints(maxHeight: 0.85.sh),
      decoration: const BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily Review',
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 19.sp, fontWeight: FontWeight.w900, color: _kText)),
          SizedBox(height: 4.h),
          Text('Clear the decks — finish it, keep it today, or push it out.',
              style: AppFonts.spaceGrotesk
                  .copyWith(fontSize: 12.sp, color: _kMuted)),
          SizedBox(height: 14.h),
          Flexible(
            child: Obx(() {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final tomorrow = today.add(const Duration(days: 1));
              final items = [...c.overdue, ...c.today];
              if (items.isEmpty) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 30.h),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.verified_rounded,
                            color: const Color(0xff16A34A), size: 40.r),
                        SizedBox(height: 10.h),
                        Text('All clear — nothing overdue or due today.',
                            textAlign: TextAlign.center,
                            style: AppFonts.spaceGrotesk.copyWith(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: _kText)),
                      ],
                    ),
                  ),
                );
              }
              return ListView(
                shrinkWrap: true,
                children: [
                  for (final t in items)
                    Container(
                      margin: EdgeInsets.only(bottom: 8.h),
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title,
                              style: AppFonts.spaceGrotesk.copyWith(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: _kText)),
                          if (t.dueAt != null &&
                              t.dueAt!.isBefore(today))
                            Padding(
                              padding: EdgeInsets.only(top: 2.h),
                              child: Text(
                                  'Overdue · ${_OrgTaskHubScreenState._fmtDate(t.dueAt!)}',
                                  style: AppFonts.spaceGrotesk.copyWith(
                                      fontSize: 10.5.sp,
                                      color: const Color(0xffDC2626))),
                            ),
                          SizedBox(height: 10.h),
                          Row(
                            children: [
                              _rev('Done', Icons.check_rounded,
                                  const Color(0xff16A34A),
                                  () => c.updateTask(t.id, {'status': 'done'})),
                              SizedBox(width: 8.w),
                              _rev('Today', Icons.today_rounded, accent,
                                  () => c.updateTask(t.id, {'dueAt': iso(today)})),
                              SizedBox(width: 8.w),
                              _rev('Tomorrow', Icons.east_rounded,
                                  const Color(0xff0EA5E9),
                                  () => c.updateTask(
                                      t.id, {'dueAt': iso(tomorrow)})),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _rev(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10.r)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14.r, color: color),
              SizedBox(width: 4.w),
              Text(label,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
