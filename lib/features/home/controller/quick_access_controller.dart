import 'package:get/get.dart';

import '../data/quick_access_config.dart';
import '../data/quick_access_module.dart';
import '../data/quick_access_store.dart';

/// Owns the user's customised home "Quick Access" grid: which cards are on the
/// dashboard, in what order, and whether the grid is currently in edit mode.
///
/// Hiding a card is ONLY a visibility flag — no feature data is ever deleted,
/// so re-adding (say) Gratitude Journal brings every past entry back.
class QuickAccessController extends GetxController {
  static QuickAccessController get to =>
      Get.isRegistered<QuickAccessController>()
          ? Get.find<QuickAccessController>()
          : Get.put(QuickAccessController(), permanent: true);

  final QuickAccessStore _store = QuickAccessStore();

  /// Always kept in display order (sortOrder ascending), visible cards first.
  final RxList<QuickAccessCardConfig> configs = <QuickAccessCardConfig>[].obs;

  /// Edit mode is deliberately NOT persisted — it always starts off so nobody
  /// lands on a jiggling dashboard.
  final RxBool isEditMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Seed synchronously with the registry defaults so the grid paints the
    // normal layout on frame 1; the saved layout replaces it once Hive opens.
    configs.assignAll(_reconcile(const <QuickAccessCardConfig>[]));
    _load();
  }

  Future<void> _load() async {
    await _store.open();
    configs.assignAll(_reconcile(_store.load()));
  }

  /// Merges the saved layout with the registry:
  ///  • saved modules keep their order and visibility,
  ///  • saved ids that no longer exist in the registry are dropped,
  ///  • registry modules with no saved config default to VISIBLE, appended at
  ///    the end — so a module added in a future build just shows up.
  List<QuickAccessCardConfig> _reconcile(List<QuickAccessCardConfig> saved) {
    final known = <String, QuickAccessCardConfig>{};
    for (final cfg in saved) {
      if (QuickAccessRegistry.byId(cfg.moduleId) == null) continue;
      known[cfg.moduleId] = cfg;
    }

    final existing = saved
        .where((c) => known[c.moduleId] != null)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final merged = <QuickAccessCardConfig>[...existing];
    for (final m in QuickAccessRegistry.modules) {
      if (known.containsKey(m.id)) continue;
      merged.add(QuickAccessCardConfig(
        moduleId: m.id,
        sortOrder: merged.length,
        isVisible: true,
      ));
    }
    return _normalise(merged);
  }

  /// Visible cards first (grid order), hidden ones parked after them, with
  /// sortOrder renumbered to match.
  List<QuickAccessCardConfig> _normalise(List<QuickAccessCardConfig> list) {
    final ordered = <QuickAccessCardConfig>[
      ...list.where((c) => c.isVisible),
      ...list.where((c) => !c.isVisible),
    ];
    return <QuickAccessCardConfig>[
      for (int i = 0; i < ordered.length; i++) ordered[i].copyWith(sortOrder: i),
    ];
  }

  void _apply(List<QuickAccessCardConfig> list) {
    final next = _normalise(list);
    configs.assignAll(next);
    _store.save(next);
  }

  // ── Reads (reactive inside Obx) ────────────────────────────────────────────

  /// Cards currently ON the dashboard, in display order.
  List<QuickAccessModule> get visibleModules => configs
      .where((c) => c.isVisible)
      .map((c) => QuickAccessRegistry.byId(c.moduleId))
      .whereType<QuickAccessModule>()
      .toList();

  /// Cards available to add back — powers the "Add Card" library.
  List<QuickAccessModule> get hiddenModules => configs
      .where((c) => !c.isVisible)
      .map((c) => QuickAccessRegistry.byId(c.moduleId))
      .whereType<QuickAccessModule>()
      .toList();

  // ── Writes ────────────────────────────────────────────────────────────────

  void enterEditMode() => isEditMode.value = true;
  void exitEditMode() => isEditMode.value = false;
  void toggleEditMode() => isEditMode.value = !isEditMode.value;

  /// Hide a card. Its underlying data is untouched — this is not a delete.
  void hideModule(String moduleId) {
    final index = configs.indexWhere((c) => c.moduleId == moduleId);
    if (index == -1 || !configs[index].isVisible) return;
    final list = configs.toList();
    final item = list.removeAt(index).copyWith(isVisible: false);
    _apply(<QuickAccessCardConfig>[...list, item]);
  }

  /// Put a hidden card back on the dashboard, appended at the end.
  void showModule(String moduleId) {
    final index = configs.indexWhere((c) => c.moduleId == moduleId);
    if (index == -1 || configs[index].isVisible) return;
    final list = configs.toList();
    final item = list.removeAt(index).copyWith(isVisible: true);
    final visible = list.where((c) => c.isVisible).toList()..add(item);
    final hidden = list.where((c) => !c.isVisible).toList();
    _apply(<QuickAccessCardConfig>[...visible, ...hidden]);
  }

  /// Move a visible card from one grid slot to another. Indexes are positions
  /// within [visibleModules], which is what the grid renders.
  void reorder(int fromVisibleIndex, int toVisibleIndex) {
    final visible = configs.where((c) => c.isVisible).toList();
    if (fromVisibleIndex < 0 || fromVisibleIndex >= visible.length) return;
    if (toVisibleIndex < 0 || toVisibleIndex >= visible.length) return;
    if (fromVisibleIndex == toVisibleIndex) return;
    final moved = visible.removeAt(fromVisibleIndex);
    visible.insert(toVisibleIndex, moved);
    final hidden = configs.where((c) => !c.isVisible).toList();
    _apply(<QuickAccessCardConfig>[...visible, ...hidden]);
  }
}
