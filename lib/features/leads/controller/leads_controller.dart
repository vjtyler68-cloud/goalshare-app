import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/search/fuzzy_match.dart';
import '../model/lead.dart';

/// Stores the user's client/lead list on-device with Hive so it is available
/// at all times, offline, and survives app restarts. Persistence follows the
/// same readiness pattern used elsewhere in the app: box opening is wrapped so
/// a storage failure degrades to an empty in-memory list instead of throwing a
/// LateInitializationError.
class LeadsController extends GetxController {
  static const String _boxName = 'leads_v1';

  Box<String>? _box;
  bool _boxReady = false;

  /// Absolute path to the app documents directory, cached on init. Photos are
  /// stored here by file name only (see [Lead.photoFileName]).
  String? _docsPath;

  final RxList<Lead> leads = <Lead>[].obs;
  final RxBool isLoading = false.obs;

  /// Search text and status filter for the list screen.
  final RxString searchQuery = ''.obs;
  final RxString statusFilter = 'All'.obs;

  // ── CRM settings (persisted) ────────────────────────────────────────────────
  /// Monthly revenue target ($) and commission rate (%) — power pace + earnings.
  final RxDouble monthlyGoal = 0.0.obs;
  final RxDouble commissionRate = 0.0.obs;
  static const String _kMonthlyGoal = 'leads_monthly_goal_v1';
  static const String _kCommission = 'leads_commission_rate_v1';

  @override
  void onInit() {
    super.onInit();
    _openAndLoad();
  }

  Future<void> _openAndLoad() async {
    isLoading.value = true;
    try {
      // Hive.initFlutter() is called in main(); calling it again is a no-op and
      // keeps us safe if this controller ever runs before that.
      await Hive.initFlutter();
      _box = await Hive.openBox<String>(_boxName);
      _boxReady = true;
      _loadFromBox();
    } catch (e) {
      log('LeadsController: failed to open box — $e');
      _boxReady = false;
    } finally {
      isLoading.value = false;
    }
    // Resolve the documents directory for photo storage. Best-effort: if it
    // fails, photo save/read simply no-ops and the rest of the feature works.
    try {
      _docsPath = (await getApplicationDocumentsDirectory()).path;
    } catch (e) {
      log('LeadsController: could not resolve documents dir — $e');
    }
    _loadCrmPrefs();
  }

  Future<void> _loadCrmPrefs() async {
    try {
      final p = await SharedPreferences.getInstance();
      monthlyGoal.value = p.getDouble(_kMonthlyGoal) ?? 0;
      commissionRate.value = p.getDouble(_kCommission) ?? 0;
    } catch (_) {}
  }

  Future<void> setMonthlyGoal(double v) async {
    monthlyGoal.value = v < 0 ? 0 : v;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setDouble(_kMonthlyGoal, monthlyGoal.value);
    } catch (_) {}
  }

  Future<void> setCommissionRate(double v) async {
    commissionRate.value = v.clamp(0, 100);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setDouble(_kCommission, commissionRate.value);
    } catch (_) {}
  }

  void _loadFromBox() {
    if (!_boxReady || _box == null) return;
    final parsed = <Lead>[];
    for (final raw in _box!.values) {
      try {
        parsed.add(Lead.fromJsonString(raw));
      } catch (e) {
        log('LeadsController: skipping unreadable lead — $e');
      }
    }
    _sortAndAssign(parsed);
  }

  void _sortAndAssign(List<Lead> list) {
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    leads.assignAll(list);
  }

  bool get isSearching => searchQuery.value.trim().isNotEmpty;

  /// Number of results for the current search + filter (for the live count).
  int get matchCount => filteredLeads.length;

  /// Leads after status filtering, then typo-tolerant fuzzy search over name,
  /// phone, status and notes — ranked most-relevant first. With no query, the
  /// status-filtered list keeps its newest-first order.
  List<Lead> get filteredLeads {
    final status = statusFilter.value;
    final statusFiltered = status == 'All'
        ? leads.toList()
        : leads.where((l) => l.status == status).toList();

    final q = searchQuery.value.trim();
    if (q.isEmpty) return statusFiltered;

    return fuzzySearch<Lead>(
      statusFiltered,
      q,
      fields: (l) => [l.name, l.phone, l.status, l.notes],
      threshold: 0.45,
    );
  }

  int countForStatus(String status) {
    if (status == 'All') return leads.length;
    return leads.where((l) => l.status == status).length;
  }

  Future<bool> addLead(Lead lead) async {
    leads.insert(0, lead);
    return _persist(lead);
  }

  Future<bool> updateLead(Lead lead) async {
    // Keep closedAt in sync with the stage so production math is always right:
    // stamp it when a deal is Won/Lost, clear it if the lead is re-opened.
    var next = lead;
    final closed = lead.isWon || lead.isLost;
    if (closed && lead.closedAt == null) {
      next = lead.copyWith(closedAt: DateTime.now());
    } else if (!closed && lead.closedAt != null) {
      next = lead.copyWith(clearClosedAt: true);
    }
    final idx = leads.indexWhere((l) => l.id == next.id);
    if (idx != -1) {
      leads[idx] = next;
    } else {
      leads.insert(0, next);
    }
    _sortAndAssign(leads.toList());
    return _persist(next);
  }

  /// Quickly move a lead to a new stage (used by the dashboard / swipe actions).
  Future<bool> setStatus(String id, String status) async {
    final lead = byId(id);
    if (lead == null) return false;
    return updateLead(lead.copyWith(status: status));
  }

  Future<bool> deleteLead(String id) async {
    // Clean up the lead's photo file and any pending follow-up reminder so we
    // don't leave orphaned files or fire a reminder for a deleted lead.
    final lead = byId(id);
    if (lead != null && lead.hasPhoto) {
      await _deletePhotoFile(lead.photoFileName);
    }
    await NotificationService.instance.cancelLeadReminder(id);

    leads.removeWhere((l) => l.id == id);
    if (!_boxReady || _box == null) return false;
    try {
      await _box!.delete(id);
      return true;
    } catch (e) {
      log('LeadsController: delete failed — $e');
      return false;
    }
  }

  // ── Photos ────────────────────────────────────────────────────────────────

  bool get canStorePhotos => _docsPath != null;

  /// Absolute path to a lead's photo, or null if none / storage unavailable.
  String? photoPathFor(Lead lead) {
    if (_docsPath == null || !lead.hasPhoto) return null;
    return '$_docsPath/${lead.photoFileName}';
  }

  /// Copy a picked image into the documents directory under a unique name and
  /// return that file name (to store on the lead). Deletes [previousFileName]
  /// if given. Returns null if storage is unavailable or the copy fails.
  Future<String?> saveLeadPhoto({
    required String leadId,
    required String sourcePath,
    String? previousFileName,
  }) async {
    if (_docsPath == null) return null;
    try {
      final fileName = 'lead_${leadId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(sourcePath).copy('$_docsPath/$fileName');
      if (previousFileName != null && previousFileName.trim().isNotEmpty) {
        await _deletePhotoFile(previousFileName);
      }
      return fileName;
    } catch (e) {
      log('LeadsController: photo save failed — $e');
      return null;
    }
  }

  /// Delete a stored photo file by name (e.g. when the user removes it).
  Future<void> removeLeadPhoto(String fileName) => _deletePhotoFile(fileName);

  Future<void> _deletePhotoFile(String fileName) async {
    if (_docsPath == null || fileName.trim().isEmpty) return;
    try {
      final f = File('$_docsPath/$fileName');
      if (await f.exists()) await f.delete();
    } catch (e) {
      log('LeadsController: photo delete failed — $e');
    }
  }

  // ── Follow-up reminders ─────────────────────────────────────────────────────

  /// Set (or move) a follow-up reminder for a lead. Requests notification
  /// permission on the spot — this is an explicit user opt-in moment. Returns
  /// true if the OS reminder was scheduled.
  Future<bool> setReminder(String leadId, DateTime when) async {
    final lead = byId(leadId);
    if (lead == null) return false;

    final granted = await NotificationService.instance.requestPermission();
    final scheduled = granted &&
        await NotificationService.instance.scheduleLeadReminder(
          leadId: leadId,
          name: lead.name,
          when: when,
        );

    // Persist the chosen time regardless of OS permission so the UI still shows
    // it; the notification simply won't fire if permission was denied.
    await updateLead(lead.copyWith(reminderAt: when));
    return scheduled;
  }

  Future<void> clearReminder(String leadId) async {
    await NotificationService.instance.cancelLeadReminder(leadId);
    final lead = byId(leadId);
    if (lead != null) {
      await updateLead(lead.copyWith(clearReminder: true));
    }
  }

  Future<bool> _persist(Lead lead) async {
    if (!_boxReady || _box == null) {
      log('LeadsController: storage unavailable, lead kept in memory only');
      return false;
    }
    try {
      await _box!.put(lead.id, lead.toJsonString());
      return true;
    } catch (e) {
      log('LeadsController: save failed — $e');
      return false;
    }
  }

  Lead? byId(String id) {
    final matches = leads.where((l) => l.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  // ── Sales CRM production metrics ─────────────────────────────────────────────

  List<Lead> get openLeads => leads.where((l) => l.isOpen).toList();

  /// Total dollar value of every open lead in the pipeline.
  double get pipelineValue =>
      openLeads.fold(0.0, (s, l) => s + l.dealValue);

  /// Stage-weighted forecast — a realistic expected value of the open pipeline.
  double get weightedPipeline =>
      openLeads.fold(0.0, (s, l) => s + l.dealValue * _stageWeight(l.status));

  double _stageWeight(String status) {
    switch (status) {
      case 'Appointment':
        return 0.6;
      case 'Contacted':
        return 0.3;
      case 'New':
        return 0.1;
      default:
        return 0.0;
    }
  }

  double valueForStatus(String status) => leads
      .where((l) => l.status == status)
      .fold(0.0, (s, l) => s + l.dealValue);

  bool _sameMonth(DateTime? d) {
    if (d == null) return false;
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month;
  }

  bool _thisWeek(DateTime? d) {
    if (d == null) return false;
    final n = DateTime.now();
    final start = DateTime(n.year, n.month, n.day)
        .subtract(Duration(days: n.weekday - 1));
    return !d.isBefore(start);
  }

  List<Lead> get wonThisMonth =>
      leads.where((l) => l.isWon && _sameMonth(l.closedAt)).toList();

  double get revenueThisMonth =>
      wonThisMonth.fold(0.0, (s, l) => s + l.dealValue);
  int get dealsWonThisMonth => wonThisMonth.length;

  double get revenueThisWeek => leads
      .where((l) => l.isWon && _thisWeek(l.closedAt))
      .fold(0.0, (s, l) => s + l.dealValue);

  int get wonCount => leads.where((l) => l.isWon).length;
  int get lostCount => leads.where((l) => l.isLost).length;

  /// Close rate = won / (won + lost), as a percent.
  double get closeRate {
    final decided = wonCount + lostCount;
    return decided == 0 ? 0 : wonCount / decided * 100;
  }

  /// Average won-deal size this month.
  double get avgDealThisMonth =>
      dealsWonThisMonth == 0 ? 0 : revenueThisMonth / dealsWonThisMonth;

  /// Estimated commission earned this month.
  double get earningsThisMonth => revenueThisMonth * commissionRate.value / 100;

  /// Straight-line projection of month-end revenue at the current pace.
  double get projectedRevenue {
    final n = DateTime.now();
    final daysInMonth = DateTime(n.year, n.month + 1, 0).day;
    if (n.day <= 0) return revenueThisMonth;
    return revenueThisMonth / n.day * daysInMonth;
  }

  double get goalProgress =>
      monthlyGoal.value <= 0 ? 0 : (revenueThisMonth / monthlyGoal.value).clamp(0.0, 1.0);

  /// Follow-ups that are due (today or overdue) on still-open leads.
  List<Lead> get followUpsDue {
    final endToday = DateTime.now();
    final end = DateTime(endToday.year, endToday.month, endToday.day, 23, 59, 59);
    final due = leads
        .where((l) =>
            l.isOpen && l.reminderAt != null && !l.reminderAt!.isAfter(end))
        .toList()
      ..sort((a, b) => a.reminderAt!.compareTo(b.reminderAt!));
    return due;
  }

  int get followUpsDueCount => followUpsDue.length;

  // ── Activity log ─────────────────────────────────────────────────────────────

  /// Append a touch (call/text/email/meeting/note) to a lead's timeline.
  Future<void> logActivity(String id, String type, {String note = ''}) async {
    final lead = byId(id);
    if (lead == null) return;
    final act = LeadActivity(type: type, note: note.trim(), at: DateTime.now());
    await updateLead(lead.copyWith(activities: [...lead.activities, act]));
  }

  /// Open leads that haven't been touched in [days]+ days — never drop a lead.
  List<Lead> staleLeads({int days = 7}) => leads
      .where((l) => l.isOpen && l.daysSinceTouch >= days)
      .toList()
    ..sort((a, b) => b.daysSinceTouch.compareTo(a.daysSinceTouch));

  int staleCount({int days = 7}) => staleLeads(days: days).length;

  // ── Records ──────────────────────────────────────────────────────────────────

  /// The best sales month on record (label + revenue). Empty label if none.
  MapEntry<String, double> get bestMonth {
    final byMonth = <String, double>{};
    for (final l in leads) {
      if (l.isWon && l.closedAt != null) {
        final k =
            '${l.closedAt!.year}-${l.closedAt!.month.toString().padLeft(2, '0')}';
        byMonth[k] = (byMonth[k] ?? 0) + l.dealValue;
      }
    }
    if (byMonth.isEmpty) return const MapEntry('', 0);
    final best =
        byMonth.entries.reduce((a, b) => a.value >= b.value ? a : b);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final parts = best.key.split('-');
    final y = parts[0];
    final m = int.tryParse(parts[1]) ?? 1;
    return MapEntry('${months[(m - 1).clamp(0, 11)]} $y', best.value);
  }
}
