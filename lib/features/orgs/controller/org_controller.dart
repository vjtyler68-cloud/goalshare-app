import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../data/org_api.dart';
import '../data/org_metrics.dart';
import '../data/org_models.dart';

/// Holds the current user's org membership (from the backend) and the admin
/// roster. Everyone has this controller; it's simply empty for individuals.
class OrgController extends GetxController with WidgetsBindingObserver {
  static OrgController get to => Get.isRegistered<OrgController>()
      ? Get.find<OrgController>()
      : Get.put(OrgController(), permanent: true);

  final Rxn<OrgSummary> myOrg = Rxn<OrgSummary>();
  final RxList<OrgMember> roster = <OrgMember>[].obs;
  final RxBool loading = false.obs;
  final RxBool rosterLoading = false.obs;

  /// Sales leaderboard view (default OFF) — sorts the roster by lead count.
  final RxBool leaderboard = false.obs;

  bool get inOrg => myOrg.value != null;
  bool get isAdmin => myOrg.value?.isAdmin ?? false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    refreshMine();
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

  Future<void> refreshMine() async {
    loading.value = true;
    try {
      myOrg.value = await OrgApi.instance.mine();
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
      myOrg.value = r.org;
      await pushMyMetrics();
      await refreshRoster();
    }
    return r;
  }

  /// Join an org by invite code (become member).
  Future<OrgResult> join(String inviteCode) async {
    final r = await OrgApi.instance.join(inviteCode);
    if (r.ok && r.org != null) {
      myOrg.value = r.org;
      await pushMyMetrics();
    }
    return r;
  }

  Future<void> leave() async {
    final ok = await OrgApi.instance.leave();
    if (ok) {
      myOrg.value = null;
      roster.clear();
    }
  }
}
