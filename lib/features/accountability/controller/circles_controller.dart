import 'package:get/get.dart';

import '../data/circle_models.dart';
import '../data/circles_api.dart';

/// Owns the signed-in user's Goal Circle (3–5 person squad): membership, the
/// shared streak, shields, and daily circle check-ins.
class CirclesController extends GetxController {
  static CirclesController get to => Get.isRegistered<CirclesController>()
      ? Get.find<CirclesController>()
      : Get.put(CirclesController(), permanent: true);

  final Rxn<CircleData> circle = Rxn<CircleData>();
  final RxBool ready = false.obs;

  bool get hasCircle => circle.value != null;

  Future<void>? _initFuture;

  @override
  void onInit() {
    super.onInit();
    _initFuture = _init();
  }

  /// Completes once the first load is done, so an entry point can route on the
  /// real state (in a circle vs not) instead of racing it.
  Future<void> ensureLoaded() => _initFuture ?? Future<void>.value();

  Future<void> _init() async {
    await load();
    ready.value = true;
  }

  Future<void> load() async {
    circle.value = await CirclesApi.instance.getMyCircle();
  }

  String todayDateString() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${n.year}-${two(n.month)}-${two(n.day)}';
  }

  Future<bool> createCircle(String name, List<String> memberIds) async {
    final ok = await CirclesApi.instance.createCircle(name, memberIds);
    if (ok) await load();
    return ok;
  }

  Future<void> checkinToday({String? proofUrl}) async {
    if (!hasCircle) return;
    await CirclesApi.instance
        .checkin(date: todayDateString(), proofUrl: proofUrl);
    await load();
  }

  Future<int?> burnShield() async {
    if (!hasCircle) return null;
    final shields = await CirclesApi.instance.burnShield();
    await load();
    return shields;
  }

  Future<void> leaveCircle() async {
    await CirclesApi.instance.leave();
    circle.value = null;
  }
}
