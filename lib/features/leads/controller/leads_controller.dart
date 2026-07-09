import 'dart:async';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

  /// Leads after search + status filtering, newest first.
  List<Lead> get filteredLeads {
    final q = searchQuery.value.trim().toLowerCase();
    final status = statusFilter.value;
    return leads.where((l) {
      final matchesStatus = status == 'All' || l.status == status;
      if (!matchesStatus) return false;
      if (q.isEmpty) return true;
      return l.name.toLowerCase().contains(q) ||
          l.phone.toLowerCase().contains(q) ||
          l.email.toLowerCase().contains(q) ||
          l.company.toLowerCase().contains(q) ||
          l.address.toLowerCase().contains(q);
    }).toList();
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
