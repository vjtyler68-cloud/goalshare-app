import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/org_api.dart';
import '../data/org_metrics.dart';
import '../data/org_models.dart';

/// Holds the current user's org membership(s) (from the backend) and the admin
/// roster. Everyone has this controller; it's simply empty for individuals.
///
/// Owners can belong to MULTIPLE orgs: [myOrgs] holds them all and [myOrg] is
/// the currently-selected one that the dashboard / HQ act on.
class OrgController extends GetxController with WidgetsBindingObserver {
  static OrgController get to => Get.isRegistered<OrgController>()
      ? Get.find<OrgController>()
      : Get.put(OrgController(), permanent: true);

  /// The currently-selected org (drives the dashboard, HQ, profile card).
  final Rxn<OrgSummary> myOrg = Rxn<OrgSummary>();

  /// Every org the user belongs to (usually one; several for owners).
  final RxList<OrgSummary> myOrgs = <OrgSummary>[].obs;

  /// True when this account may hold multiple orgs (owner allowlist).
  final RxBool isOwner = false.obs;

  final RxList<OrgMember> roster = <OrgMember>[].obs;
  final RxBool loading = false.obs;
  final RxBool rosterLoading = false.obs;

  /// Sales leaderboard view (default OFF) — sorts the roster by lead count.
  final RxBool leaderboard = false.obs;

  static const String _kCurrentOrg = 'org_current_id_v1';
  String? _currentOrgId;

  bool get inOrg => myOrg.value != null;
  bool get isAdmin => myOrg.value?.isAdmin ?? false;
  bool get hasMultipleOrgs => myOrgs.length > 1;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    try {
      final p = await SharedPreferences.getInstance();
      _currentOrgId = p.getString(_kCurrentOrg);
    } catch (_) {}
    await refreshMine();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh my membership + re-report my (whitelisted) metrics on resume.
    if (state == AppLifecycleState.resumed && inOrg) refreshMine();
  }

  OrgSummary? _find(String? id) {
    if (id == null) return null;
    for (final o in myOrgs) {
      if (o.id == id) return o;
    }
    return null;
  }

  OrgSummary? _resolveCurrent() {
    if (myOrgs.isEmpty) return null;
    return _find(_currentOrgId) ?? myOrgs.first;
  }

  Future<void> _saveCurrent(String? id) async {
    _currentOrgId = id;
    try {
      final p = await SharedPreferences.getInstance();
      if (id == null) {
        await p.remove(_kCurrentOrg);
      } else {
        await p.setString(_kCurrentOrg, id);
      }
    } catch (_) {}
  }

  /// Switch which org the dashboard / HQ act on (owners with several).
  Future<void> switchOrg(String orgId) async {
    final target = _find(orgId);
    if (target == null) return;
    await _saveCurrent(orgId);
    myOrg.value = target;
    roster.clear();
    if (isAdmin) await refreshRoster();
  }

  Future<void> refreshMine() async {
    loading.value = true;
    try {
      final res = await OrgApi.instance.myOrgs();
      myOrgs.assignAll(res.orgs);
      isOwner.value = res.isOwner;
      myOrg.value = _resolveCurrent();
      if (myOrg.value != null) _currentOrgId = myOrg.value!.id;
      // Everyone in an org reports their own scoped metrics so aggregates and
      // per-member views are complete; push before pulling the roster so an
      // admin sees their own fresh numbers too.
      await pushMyMetrics();
      if (isAdmin) await refreshRoster();
    } finally {
      loading.value = false;
    }
  }

  /// Build my whitelist-scoped engagement summary and send it. No-op when not
  /// in an org.
  Future<void> pushMyMetrics() async {
    final org = myOrg.value;
    if (org == null) return;
    final summary = OrgMetrics.build(org.orgType);
    await OrgApi.instance.pushSummary(summary);
  }

  Future<void> refreshRoster() async {
    final org = myOrg.value;
    if (org == null || !org.isAdmin) return;
    rosterLoading.value = true;
    try {
      roster.assignAll(await OrgApi.instance.roster(org.id));
    } finally {
      rosterLoading.value = false;
    }
  }

  /// Create an org (become admin). Returns the result so the UI can route /
  /// show the invite code or the error.
  Future<OrgResult> create(String name, OrgType type) async {
    final r = await OrgApi.instance.create(name: name, type: type);
    if (r.ok && r.org != null) {
      // Make the new org the selected one, then reload the full list.
      await _saveCurrent(r.org!.id);
      await refreshMine();
    }
    return r;
  }

  /// Join an org by invite code (become member).
  Future<OrgResult> join(String inviteCode) async {
    final r = await OrgApi.instance.join(inviteCode);
    if (r.ok && r.org != null) {
      await _saveCurrent(r.org!.id);
      await refreshMine();
    }
    return r;
  }

  /// Set (or clear) the current org's Territory Map. Admin only — returns null
  /// on success or an error message. Refreshes so the new map shows immediately.
  Future<String?> setMap(String mapUrl, String mapLabel) async {
    final org = myOrg.value;
    if (org == null) return 'No organization selected.';
    final err = await OrgApi.instance.setMap(org.id, mapUrl, mapLabel);
    if (err == null) await refreshMine();
    return err;
  }

  /// Set (or clear) the current org's appointment scheduler. Admin only —
  /// returns null on success or an error message. Refreshes on success.
  Future<String?> setBooking(String bookingUrl, String bookingLabel) async {
    final org = myOrg.value;
    if (org == null) return 'No organization selected.';
    final err =
        await OrgApi.instance.setBooking(org.id, bookingUrl, bookingLabel);
    if (err == null) await refreshMine();
    return err;
  }

  /// Leave the currently-selected org (owners keep their others).
  Future<void> leave() async {
    final current = myOrg.value;
    final ok = await OrgApi.instance.leave(orgId: current?.id);
    if (ok) {
      // Deselect so refreshMine falls back to another org (or none).
      await _saveCurrent(null);
      await refreshMine();
    }
  }
}
