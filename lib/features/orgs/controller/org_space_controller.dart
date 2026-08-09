import 'package:get/get.dart';

import '../data/org_api.dart';
import '../data/org_models.dart';

/// Drives an org's private Team HQ (announcements, feed, goals). All calls are
/// membership-enforced on the backend, so this only ever holds the current
/// user's own org content.
class OrgSpaceController extends GetxController {
  static OrgSpaceController get to => Get.isRegistered<OrgSpaceController>()
      ? Get.find<OrgSpaceController>()
      : Get.put(OrgSpaceController(), permanent: true);

  final RxList<OrgPost> announcements = <OrgPost>[].obs;
  final RxList<OrgPost> feed = <OrgPost>[].obs;
  final RxList<OrgGoal> goals = <OrgGoal>[].obs;
  final RxBool loading = false.obs;
  final RxBool posting = false.obs;

  String _orgId = '';

  Future<void> load(String orgId) async {
    _orgId = orgId;
    loading.value = true;
    try {
      final space = await OrgApi.instance.getSpace(orgId);
      if (space != null) {
        announcements.assignAll(space.announcements);
        feed.assignAll(space.feed);
        goals.assignAll(space.goals);
      }
    } finally {
      loading.value = false;
    }
  }

  Future<void> _reload() async {
    if (_orgId.isNotEmpty) await load(_orgId);
  }

  /// Returns an error message on failure, or null on success.
  Future<String?> post(String kind, String text) async {
    if (_orgId.isEmpty) return 'No organization.';
    posting.value = true;
    try {
      final err = await OrgApi.instance.createPost(_orgId, kind, text);
      if (err == null) await _reload();
      return err;
    } finally {
      posting.value = false;
    }
  }

  Future<void> like(OrgPost p) async {
    await OrgApi.instance.toggleLike(p.id);
    await _reload();
  }

  Future<void> removePost(OrgPost p) async {
    await OrgApi.instance.deletePost(p.id);
    await _reload();
  }

  Future<String?> createGoal(String title, int target, String metricKey) async {
    if (_orgId.isEmpty) return 'No organization.';
    final err = await OrgApi.instance.createGoal(_orgId, title, target, metricKey);
    if (err == null) await _reload();
    return err;
  }

  Future<void> bumpGoal(OrgGoal g, int delta) async {
    await OrgApi.instance.bumpGoal(g.id, delta);
    await _reload();
  }

  Future<void> removeGoal(OrgGoal g) async {
    await OrgApi.instance.deleteGoal(g.id);
    await _reload();
  }
}
