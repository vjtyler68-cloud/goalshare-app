import 'dart:convert';
import 'dart:ui';

/// Goalendar — a beautiful, local-first calendar module for Goalshare.
///
/// Stored as plain JSON in a Hive `Box<String>` (the same zero-codegen pattern
/// as the workout / leads / budget modules) so there are NO Hive typeIds or
/// generated adapters to collide — sidestepping the storage/naming issues the
/// app has hit before. Native iPhone Calendar (EventKit) two-way sync is a
/// later phase; Hive stays the source of truth.

/// Event category — drives the colour swatch and the month-grid dots.
enum GoalCategory { health, business, relationships, personal, other }

extension GoalCategoryX on GoalCategory {
  String get id => name;

  String get label {
    switch (this) {
      case GoalCategory.health:
        return 'Health';
      case GoalCategory.business:
        return 'Business';
      case GoalCategory.relationships:
        return 'Relationships';
      case GoalCategory.personal:
        return 'Personal';
      case GoalCategory.other:
        return 'Other';
    }
  }

  /// Vibrant-but-premium palette: teal / violet / coral / gold / sky.
  int get colorValue {
    switch (this) {
      case GoalCategory.health:
        return 0xff14B8A6;
      case GoalCategory.business:
        return 0xff7C3AED;
      case GoalCategory.relationships:
        return 0xffFB7185;
      case GoalCategory.personal:
        return 0xffF59E0B;
      case GoalCategory.other:
        return 0xff38BDF8;
    }
  }

  Color get color => Color(colorValue);

  static GoalCategory fromId(String? s) => GoalCategory.values
      .firstWhere((e) => e.name == s, orElse: () => GoalCategory.personal);
}

/// How an event repeats. Kept simple (not full RFC5545).
enum GoalRecur { none, daily, weekly, monthly }

extension GoalRecurX on GoalRecur {
  String get id => name;
  String get label {
    switch (this) {
      case GoalRecur.none:
        return 'Does not repeat';
      case GoalRecur.daily:
        return 'Daily';
      case GoalRecur.weekly:
        return 'Weekly';
      case GoalRecur.monthly:
        return 'Monthly';
    }
  }

  static GoalRecur fromId(String? s) => GoalRecur.values
      .firstWhere((e) => e.name == s, orElse: () => GoalRecur.none);
}

class GoalendarEvent {
  String id;
  String title;
  DateTime start;
  DateTime end;
  bool allDay;
  String? location;
  String? notes;
  GoalCategory category;

  // Recurrence (simple).
  GoalRecur recurrence;
  List<int> recurDaysOfWeek; // 1=Mon..7=Sun (for weekly)
  DateTime? recurEnd;

  // Reminders — minutes before start (e.g. [15, 60]).
  List<int> reminderMinutes;

  // Optional Goalshare goal link — never required.
  String? linkedGoalId;

  bool isCompleted;
  DateTime? completedAt;
  DateTime createdAt;
  DateTime updatedAt;

  GoalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    this.allDay = false,
    this.location,
    this.notes,
    this.category = GoalCategory.personal,
    this.recurrence = GoalRecur.none,
    List<int>? recurDaysOfWeek,
    this.recurEnd,
    List<int>? reminderMinutes,
    this.linkedGoalId,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  })  : recurDaysOfWeek = recurDaysOfWeek ?? <int>[],
        reminderMinutes = reminderMinutes ?? <int>[];

  Color get color => category.color;
  Duration get duration => end.difference(start);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'start': start.millisecondsSinceEpoch,
        'end': end.millisecondsSinceEpoch,
        'allDay': allDay,
        'location': location,
        'notes': notes,
        'cat': category.id,
        'recur': recurrence.id,
        'recurDays': recurDaysOfWeek,
        'recurEnd': recurEnd?.millisecondsSinceEpoch,
        'remind': reminderMinutes,
        'goalId': linkedGoalId,
        'done': isCompleted,
        'doneAt': completedAt?.millisecondsSinceEpoch,
        'created': createdAt.millisecondsSinceEpoch,
        'updated': updatedAt.millisecondsSinceEpoch,
      };

  static DateTime _ms(dynamic v) =>
      DateTime.fromMillisecondsSinceEpoch((v as num?)?.toInt() ?? 0);

  factory GoalendarEvent.fromJson(Map<String, dynamic> j) => GoalendarEvent(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        start: _ms(j['start']),
        end: _ms(j['end']),
        allDay: j['allDay'] == true,
        location: j['location'] as String?,
        notes: j['notes'] as String?,
        category: GoalCategoryX.fromId(j['cat'] as String?),
        recurrence: GoalRecurX.fromId(j['recur'] as String?),
        recurDaysOfWeek: ((j['recurDays'] as List?) ?? [])
            .map((e) => (e as num).toInt())
            .toList(),
        recurEnd: j['recurEnd'] == null ? null : _ms(j['recurEnd']),
        reminderMinutes: ((j['remind'] as List?) ?? [])
            .map((e) => (e as num).toInt())
            .toList(),
        linkedGoalId: j['goalId'] as String?,
        isCompleted: j['done'] == true,
        completedAt: j['doneAt'] == null ? null : _ms(j['doneAt']),
        createdAt: _ms(j['created']),
        updatedAt: _ms(j['updated']),
      );

  GoalendarEvent copy() => GoalendarEvent.fromJson(toJson());
  String toJsonString() => jsonEncode(toJson());
  factory GoalendarEvent.fromJsonString(String s) =>
      GoalendarEvent.fromJson(Map<String, dynamic>.from(jsonDecode(s) as Map));
}

/// User settings for the calendar.
class GoalendarSettings {
  bool deviceSyncEnabled; // EventKit — phase 2
  String defaultView; // 'month' | 'agenda'
  int weekStartDay; // 0 = Sunday, 1 = Monday
  bool showSuggestedActions;

  GoalendarSettings({
    this.deviceSyncEnabled = false,
    this.defaultView = 'month',
    this.weekStartDay = 0,
    this.showSuggestedActions = true,
  });

  Map<String, dynamic> toJson() => {
        'sync': deviceSyncEnabled,
        'view': defaultView,
        'weekStart': weekStartDay,
        'suggested': showSuggestedActions,
      };

  factory GoalendarSettings.fromJson(Map<String, dynamic> j) =>
      GoalendarSettings(
        deviceSyncEnabled: j['sync'] == true,
        defaultView: (j['view'] ?? 'month').toString(),
        weekStartDay: (j['weekStart'] as num?)?.toInt() ?? 0,
        showSuggestedActions: j['suggested'] != false,
      );
}
