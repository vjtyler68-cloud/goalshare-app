import 'package:get/get.dart';

import '../local/local_data.dart';

/// App-wide block list. Blocking someone here hides them everywhere — the
/// Activity Feed, chat, and stories all filter by this single source of truth.
/// Stored on-device ({userId: displayName}) so it's instant, works offline and
/// survives restarts. (Apple App Review Guideline 1.2 — block abusive users.)
class BlockController extends GetxController {
  static BlockController get to => Get.isRegistered<BlockController>()
      ? Get.find<BlockController>()
      : Get.put(BlockController(), permanent: true);

  final _local = LocalService();

  /// Reactive {userId: name}. Screens watch this to re-filter live.
  final RxMap<String, String> blocked = <String, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    blocked.assignAll(await _local.getBlockedUsers());
  }

  bool isBlocked(String userId) =>
      userId.isNotEmpty && blocked.containsKey(userId);

  Future<void> block(String userId, String name) async {
    if (userId.isEmpty) return;
    blocked[userId] = name.trim().isEmpty ? 'user' : name.trim();
    await _local.setBlockedUsers(Map<String, String>.of(blocked));
  }

  Future<void> unblock(String userId) async {
    blocked.remove(userId);
    await _local.setBlockedUsers(Map<String, String>.of(blocked));
  }
}
