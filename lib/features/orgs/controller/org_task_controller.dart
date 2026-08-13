import 'package:get/get.dart';

import '../../../core/notifications/notification_service.dart';
import '../data/org_task_api.dart';
import '../data/org_task_models.dart';
import 'org_controller.dart';

/// Owns the current org's Task Hub: tasks + projects, plus the smart buckets
/// (Overdue / Today / This Week / Upcoming / Waiting / Approvals / Done) that
/// power the dashboard, and the filters (mine / by project).
class OrgTaskController extends GetxController {
  static OrgTaskController get to => Get.isRegistered<OrgTaskController>()
      ? Get.find<OrgTaskController>()
      : Get.put(OrgTaskController(), permanent: true);

  final RxList<OrgTask> tasks = <OrgTask>[].obs;
  final RxList<OrgProject> projects = <OrgProject>[].obs;
  final RxList<OrgMeeting> meetings = <OrgMeeting>[].obs;
  final RxBool loading = false.obs;
  final RxString orgId = ''.obs;

  // Filters (reactive so the UI rebuilds).
  final RxBool mineOnly = false.obs;
  final RxnString filterProjectId = RxnString();

  /// Load (or reload) the Task Hub for an org.
  Future<void> load(String id) async {
    if (id.isEmpty) return;
    orgId.value = id;
    loading.value = true;
    try {
      final res = await OrgTaskApi.instance.load(id);
      tasks.assignAll(res.tasks);
      projects.assignAll(res.projects);
      meetings.assignAll(await OrgTaskApi.instance.loadMeetings(id));
      _syncReminders();
    } finally {
      loading.value = false;
    }
  }

  Future<void> refresh() => load(orgId.value);

  // ── lookups ────────────────────────────────────────────────────────────────
  OrgTask? taskById(String? id) {
    if (id == null) return null;
    for (final t in tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  OrgProject? projectById(String? id) {
    if (id == null) return null;
    for (final p in projects) {
      if (p.id == id) return p;
    }
    return null;
  }

  OrgMeeting? meetingById(String? id) {
    if (id == null) return null;
    for (final m in meetings) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Action items (tasks) that came out of a meeting.
  List<OrgTask> tasksForMeeting(String meetingId) =>
      tasks.where((t) => t.meetingId == meetingId).toList()
        ..sort((a, b) {
          if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
          return b.priority.weight.compareTo(a.priority.weight);
        });

  // ── calendar / timeline ────────────────────────────────────────────────────
  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<OrgTask> tasksOn(DateTime day) =>
      tasks.where((t) => t.dueAt != null && _sameDay(t.dueAt!, day)).toList()
        ..sort(_sortByPriorityThenDue);

  List<OrgMeeting> meetingsOn(DateTime day) =>
      meetings.where((m) => m.startAt != null && _sameDay(m.startAt!, day)).toList()
        ..sort((a, b) => a.startAt!.compareTo(b.startAt!));

  /// A task is blocked while the task it depends on isn't done yet.
  bool isBlocked(OrgTask t) {
    final dep = taskById(t.dependsOnId);
    return dep != null && !dep.isDone;
  }

  // ── filtering ────────────────────────────────────────────────────────────
  String? get _myId => OrgController.to.myUserId.value;

  /// All tasks after the active filters (mine / project), minus done.
  List<OrgTask> get _visibleActive {
    return tasks.where((t) {
      if (t.isDone) return false;
      if (mineOnly.value && t.assigneeId != _myId) return false;
      if (filterProjectId.value != null &&
          t.projectId != filterProjectId.value) {
        return false;
      }
      return true;
    }).toList();
  }

  List<OrgTask> get doneTasks {
    final list = tasks.where((t) {
      if (!t.isDone) return false;
      if (mineOnly.value && t.assigneeId != _myId) return false;
      if (filterProjectId.value != null &&
          t.projectId != filterProjectId.value) {
        return false;
      }
      return true;
    }).toList();
    list.sort((a, b) => (b.completedAt ?? b.updatedAt ?? DateTime(0))
        .compareTo(a.completedAt ?? a.updatedAt ?? DateTime(0)));
    return list;
  }

  // ── date helpers ───────────────────────────────────────────────────────────
  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  int _sortByPriorityThenDue(OrgTask a, OrgTask b) {
    final p = b.priority.weight.compareTo(a.priority.weight);
    if (p != 0) return p;
    final ad = a.dueAt ?? DateTime(9999);
    final bd = b.dueAt ?? DateTime(9999);
    return ad.compareTo(bd);
  }

  List<OrgTask> _sorted(Iterable<OrgTask> it) {
    final l = it.toList()..sort(_sortByPriorityThenDue);
    return l;
  }

  // ── the smart buckets ────────────────────────────────────────────────────
  /// Waiting-On + Needs-Approval are their own buckets regardless of date.
  List<OrgTask> get waiting =>
      _sorted(_visibleActive.where((t) => t.status == TaskStatus.waiting));

  List<OrgTask> get approvals =>
      _sorted(_visibleActive.where((t) => t.status == TaskStatus.approval));

  /// Tasks not parked in Waiting/Approval, grouped by their due date.
  Iterable<OrgTask> get _schedulable => _visibleActive.where(
      (t) => t.status != TaskStatus.waiting && t.status != TaskStatus.approval);

  List<OrgTask> get overdue => _sorted(_schedulable.where(
      (t) => t.dueAt != null && t.dueAt!.isBefore(_today)));

  List<OrgTask> get today => _sorted(
      _schedulable.where((t) => t.dueAt != null && _isSameDay(t.dueAt!, _today)));

  List<OrgTask> get tomorrow {
    final tmr = _today.add(const Duration(days: 1));
    return _sorted(_schedulable
        .where((t) => t.dueAt != null && _isSameDay(t.dueAt!, tmr)));
  }

  List<OrgTask> get thisWeek {
    final tmr = _today.add(const Duration(days: 1));
    final weekEnd = _today.add(const Duration(days: 7));
    return _sorted(_schedulable.where((t) =>
        t.dueAt != null &&
        t.dueAt!.isAfter(tmr) &&
        !_isSameDay(t.dueAt!, tmr) &&
        t.dueAt!.isBefore(weekEnd)));
  }

  List<OrgTask> get upcoming {
    final weekEnd = _today.add(const Duration(days: 7));
    return _sorted(_schedulable
        .where((t) => t.dueAt != null && !t.dueAt!.isBefore(weekEnd)));
  }

  List<OrgTask> get noDate =>
      _sorted(_schedulable.where((t) => t.dueAt == null));

  /// Follow-ups due (a follow-up date at/earlier than today) — the follow-up
  /// scheduler / reminder surface.
  List<OrgTask> get followUps => _sorted(_visibleActive.where((t) =>
      t.followUpAt != null &&
      !t.followUpAt!.isAfter(_today.add(const Duration(days: 1)))));

  int get activeCount => _visibleActive.length;

  // ── reporting ──────────────────────────────────────────────────────────────
  int get overdueCount => overdue.length;

  int get doneThisWeekCount {
    final weekStart = _today.subtract(const Duration(days: 7));
    return tasks
        .where((t) =>
            t.isDone &&
            t.completedAt != null &&
            t.completedAt!.isAfter(weekStart))
        .length;
  }

  /// Open task count per assignee name (for the productivity report).
  Map<String, int> get openByAssignee {
    final map = <String, int>{};
    for (final t in tasks) {
      if (t.isDone) continue;
      final name = t.assigneeName.trim().isEmpty ? 'Unassigned' : t.assigneeName;
      map[name] = (map[name] ?? 0) + 1;
    }
    return map;
  }

  // ── mutations ──────────────────────────────────────────────────────────────
  Future<OrgTask?> create(Map<String, dynamic> body) async {
    final t = await OrgTaskApi.instance.create(orgId.value, body);
    if (t != null) {
      tasks.insert(0, t);
      _syncOne(t);
    }
    return t;
  }

  /// Bulk-create tasks from lines of text — powers "Notes → Tasks". Returns the
  /// number created.
  Future<int> createMany(List<String> titles,
      {String? projectId, String? meetingId}) async {
    var n = 0;
    for (final raw in titles) {
      final title = raw.trim();
      if (title.isEmpty) continue;
      final t = await OrgTaskApi.instance.create(orgId.value, {
        'title': title,
        if (projectId != null) 'projectId': projectId,
        if (meetingId != null) 'meetingId': meetingId,
      });
      if (t != null) {
        tasks.insert(0, t);
        n++;
      }
    }
    tasks.refresh();
    return n;
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> body) async {
    final res = await OrgTaskApi.instance.update(taskId, body);
    if (res.task != null) {
      final i = tasks.indexWhere((t) => t.id == taskId);
      if (i >= 0) {
        tasks[i] = res.task!;
      }
      _syncOne(res.task!);
    }
    if (res.spawned != null) {
      tasks.insert(0, res.spawned!);
      _syncOne(res.spawned!);
    }
    tasks.refresh();
  }

  // ── meetings ────────────────────────────────────────────────────────────────
  Future<OrgMeeting?> createMeeting(Map<String, dynamic> body) async {
    final m = await OrgTaskApi.instance.createMeeting(orgId.value, body);
    if (m != null) meetings.insert(0, m);
    return m;
  }

  Future<void> updateMeeting(String id, Map<String, dynamic> body) async {
    final m = await OrgTaskApi.instance.updateMeeting(id, body);
    if (m != null) {
      final i = meetings.indexWhere((x) => x.id == id);
      if (i >= 0) meetings[i] = m;
      meetings.refresh();
    }
  }

  Future<void> removeMeeting(String id) async {
    final ok = await OrgTaskApi.instance.removeMeeting(id);
    if (ok) {
      meetings.removeWhere((m) => m.id == id);
      // Its action items are unlinked server-side — reload to reflect that.
      await refresh();
    }
  }

  // ── reminders (follow-up / due) ─────────────────────────────────────────────
  DateTime? _reminderTime(OrgTask t) {
    final d = t.followUpAt ?? t.dueAt;
    if (d == null) return null;
    return DateTime(d.year, d.month, d.day, 9); // fire at 9am local
  }

  void _syncOne(OrgTask t) {
    final key = 'orgtask_${t.id}';
    final myId = OrgController.to.myUserId.value;
    final mine =
        myId != null && (t.assigneeId == myId || t.createdBy == myId);
    final when = _reminderTime(t);
    if (t.isDone || !mine || when == null || !when.isAfter(DateTime.now())) {
      NotificationService.instance.cancelReminder(key);
      return;
    }
    final isFollow = t.followUpAt != null;
    NotificationService.instance.scheduleReminder(
      key: key,
      title: isFollow ? 'Follow up: ${t.title}' : 'Task due: ${t.title}',
      body: t.notes.trim().isNotEmpty
          ? t.notes.trim()
          : 'Open your Task Hub to take action.',
      when: when,
    );
  }

  void _syncReminders() {
    for (final t in tasks) {
      _syncOne(t);
    }
  }

  /// Toggle a task done / back to todo (the big one-tap checkbox).
  Future<void> toggleDone(OrgTask t) async {
    await updateTask(t.id, {'status': t.isDone ? 'todo' : 'done'});
  }

  Future<void> remove(String taskId) async {
    final ok = await OrgTaskApi.instance.remove(taskId);
    if (ok) {
      tasks.removeWhere((t) => t.id == taskId);
      NotificationService.instance.cancelReminder('orgtask_$taskId');
    }
  }

  Future<OrgProject?> createProject(String name, String color) async {
    final p = await OrgTaskApi.instance.createProject(orgId.value, name, color);
    if (p != null) projects.add(p);
    return p;
  }

  Future<void> removeProject(String projectId) async {
    final ok = await OrgTaskApi.instance.removeProject(projectId);
    if (ok) {
      projects.removeWhere((p) => p.id == projectId);
      // Detach locally to match the server (tasks keep, project cleared).
      for (var i = 0; i < tasks.length; i++) {
        if (tasks[i].projectId == projectId) {
          final t = tasks[i];
          tasks[i] = OrgTask(
            id: t.id,
            orgId: t.orgId,
            title: t.title,
            notes: t.notes,
            status: t.status,
            priority: t.priority,
            dueAt: t.dueAt,
            followUpAt: t.followUpAt,
            waitingOn: t.waitingOn,
            assigneeId: t.assigneeId,
            assigneeName: t.assigneeName,
            projectId: null,
            dependsOnId: t.dependsOnId,
            recurRule: t.recurRule,
            recurEnd: t.recurEnd,
            createdBy: t.createdBy,
            createdByName: t.createdByName,
            completedAt: t.completedAt,
            createdAt: t.createdAt,
            updatedAt: t.updatedAt,
          );
        }
      }
      if (filterProjectId.value == projectId) filterProjectId.value = null;
      tasks.refresh();
    }
  }

  void clearFilters() {
    mineOnly.value = false;
    filterProjectId.value = null;
  }
}
