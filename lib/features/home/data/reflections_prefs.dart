import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where "My Why" and "Affirmations" live — a user-flippable layout choice.
///
///  • [onHome] == false (default): they appear as their own Quick Access cards.
///  • [onHome] == true: they render as the original inline sections on the Home
///    feed, and the two Quick Access cards auto-hide (so they're never in two
///    places at once).
///
/// Persisted to SharedPreferences and reactive, so both the Home feed and the
/// Quick Access grid update the instant it's toggled.
class ReflectionsPrefs extends GetxController {
  static ReflectionsPrefs get to => Get.isRegistered<ReflectionsPrefs>()
      ? Get.find<ReflectionsPrefs>()
      : Get.put(ReflectionsPrefs(), permanent: true);

  final RxBool onHome = false.obs;
  static const String _key = 'reflections_on_home_v1';

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      onHome.value = p.getBool(_key) ?? false;
    } catch (_) {
      // Missing/unreadable pref just leaves the default (cards) in place.
    }
  }

  Future<void> setOnHome(bool value) async {
    onHome.value = value;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_key, value);
    } catch (_) {}
  }

  void toggle() => setOnHome(!onHome.value);
}
