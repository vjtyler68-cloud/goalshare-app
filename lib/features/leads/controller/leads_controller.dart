import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

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
    final idx = leads.indexWhere((l) => l.id == lead.id);
    if (idx != -1) {
      leads[idx] = lead;
    } else {
      leads.insert(0, lead);
    }
    _sortAndAssign(leads.toList());
    return _persist(lead);
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
}
