import 'dart:ui';

/// Org Task Hub models — a shared, assignable task + its project. The backend
/// (org-membership-gated) is the source of truth; these mirror its JSON shape.

enum TaskStatus { todo, inProgress, waiting, approval, done }

extension TaskStatusX on TaskStatus {
  String get id {
    switch (this) {
      case TaskStatus.todo:
        return 'todo';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.waiting:
        return 'waiting';
      case TaskStatus.approval:
        return 'approval';
      case TaskStatus.done:
        return 'done';
    }
  }

  String get label {
    switch (this) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.waiting:
        return 'Waiting On';
      case TaskStatus.approval:
        return 'Needs Approval';
      case TaskStatus.done:
        return 'Done';
    }
  }

  int get colorValue {
    switch (this) {
      case TaskStatus.todo:
        return 0xff64748B;
      case TaskStatus.inProgress:
        return 0xff2563EB;
      case TaskStatus.waiting:
        return 0xffF59E0B;
      case TaskStatus.approval:
        return 0xff7C3AED;
      case TaskStatus.done:
        return 0xff16A34A;
    }
  }

  Color get color => Color(colorValue);

  static TaskStatus fromId(String? s) => TaskStatus.values.firstWhere(
      (e) => e.id == s,
      orElse: () => TaskStatus.todo);
}

enum TaskPriority { low, medium, high, urgent }

extension TaskPriorityX on TaskPriority {
  String get id => name;
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  /// Higher = more urgent, for sorting.
  int get weight => index;

  int get colorValue {
    switch (this) {
      case TaskPriority.low:
        return 0xff94A3B8;
      case TaskPriority.medium:
        return 0xff2563EB;
      case TaskPriority.high:
        return 0xffF59E0B;
      case TaskPriority.urgent:
        return 0xffDC2626;
    }
  }

  Color get color => Color(colorValue);

  static TaskPriority fromId(String? s) => TaskPriority.values
      .firstWhere((e) => e.name == s, orElse: () => TaskPriority.medium);
}

enum TaskRecur { none, daily, weekly, monthly, quarterly }

extension TaskRecurX on TaskRecur {
  String get id => name;
  String get label {
    switch (this) {
      case TaskRecur.none:
        return 'Does not repeat';
      case TaskRecur.daily:
        return 'Daily';
      case TaskRecur.weekly:
        return 'Weekly';
      case TaskRecur.monthly:
        return 'Monthly';
      case TaskRecur.quarterly:
        return 'Quarterly';
    }
  }

  static TaskRecur fromId(String? s) => TaskRecur.values
      .firstWhere((e) => e.name == s, orElse: () => TaskRecur.none);
}

class OrgProject {
  final String id;
  final String name;
  final String color;

  const OrgProject({required this.id, required this.name, this.color = ''});

  factory OrgProject.fromJson(Map<String, dynamic> j) => OrgProject(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        color: (j['color'] ?? '').toString(),
      );

  Color? get colorOrNull {
    final c = color.trim();
    if (c.isEmpty) return null;
    final hex = c.replaceFirst('#', '');
    final v = int.tryParse(hex.length == 6 ? 'ff$hex' : hex, radix: 16);
    return v == null ? null : Color(v);
  }
}

/// A meeting in the Task Hub — title, time, agenda, notes. Its action items are
/// [OrgTask]s that carry this meeting's id.
class OrgMeeting {
  final String id;
  final String title;
  final DateTime? startAt;
  final String agenda;
  final String notes;
  final String createdByName;

  const OrgMeeting({
    required this.id,
    required this.title,
    this.startAt,
    this.agenda = '',
    this.notes = '',
    this.createdByName = '',
  });

  static DateTime? _d(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

  factory OrgMeeting.fromJson(Map<String, dynamic> j) => OrgMeeting(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        startAt: _d(j['startAt']),
        agenda: (j['agenda'] ?? '').toString(),
        notes: (j['notes'] ?? '').toString(),
        createdByName: (j['createdByName'] ?? '').toString(),
      );
}

class OrgTask {
  final String id;
  final String orgId;
  final String title;
  final String notes;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueAt;
  final DateTime? followUpAt;
  final String waitingOn;
  final String? assigneeId;
  final String assigneeName;
  final String? projectId;
  final String? dependsOnId;
  final String? meetingId;
  final TaskRecur recurRule;
  final DateTime? recurEnd;
  final String createdBy;
  final String createdByName;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OrgTask({
    required this.id,
    required this.orgId,
    required this.title,
    this.notes = '',
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.dueAt,
    this.followUpAt,
    this.waitingOn = '',
    this.assigneeId,
    this.assigneeName = '',
    this.projectId,
    this.dependsOnId,
    this.meetingId,
    this.recurRule = TaskRecur.none,
    this.recurEnd,
    this.createdBy = '',
    this.createdByName = '',
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  bool get isDone => status == TaskStatus.done;
  bool get hasDue => dueAt != null;
  bool get isRecurring => recurRule != TaskRecur.none;
  bool get isAssigned => (assigneeId ?? '').isNotEmpty;

  static DateTime? _d(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

  factory OrgTask.fromJson(Map<String, dynamic> j) => OrgTask(
        id: (j['id'] ?? '').toString(),
        orgId: (j['orgId'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        notes: (j['notes'] ?? '').toString(),
        status: TaskStatusX.fromId(j['status']?.toString()),
        priority: TaskPriorityX.fromId(j['priority']?.toString()),
        dueAt: _d(j['dueAt']),
        followUpAt: _d(j['followUpAt']),
        waitingOn: (j['waitingOn'] ?? '').toString(),
        assigneeId: (j['assigneeId'] ?? '').toString().isEmpty
            ? null
            : j['assigneeId'].toString(),
        assigneeName: (j['assigneeName'] ?? '').toString(),
        projectId: (j['projectId'] ?? '').toString().isEmpty
            ? null
            : j['projectId'].toString(),
        dependsOnId: (j['dependsOnId'] ?? '').toString().isEmpty
            ? null
            : j['dependsOnId'].toString(),
        meetingId: (j['meetingId'] ?? '').toString().isEmpty
            ? null
            : j['meetingId'].toString(),
        recurRule: TaskRecurX.fromId(j['recurRule']?.toString()),
        recurEnd: _d(j['recurEnd']),
        createdBy: (j['createdBy'] ?? '').toString(),
        createdByName: (j['createdByName'] ?? '').toString(),
        completedAt: _d(j['completedAt']),
        createdAt: _d(j['createdAt']),
        updatedAt: _d(j['updatedAt']),
      );
}
