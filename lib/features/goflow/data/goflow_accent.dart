import 'package:flutter/material.dart';

import '../../../core/const/app_colors.dart';

/// A GoFlow-specific accent preset. These recolor ONLY GoFlow surfaces
/// (progress ring, flow icons, phase chips) — they never touch the global app
/// theme. `null` accentId in settings means "match app theme".
class GoFlowAccent {
  final String id;
  final String name;
  final Color color;
  const GoFlowAccent(this.id, this.name, this.color);

  /// Presets offered in the picker. Chosen to feel calm and personal for a more
  /// intimate module; the app-theme option is handled separately (id == null).
  static const List<GoFlowAccent> presets = [
    GoFlowAccent('blush', 'Blush', Color(0xffE85D8A)),
    GoFlowAccent('coral', 'Coral', Color(0xffF56A5A)),
    GoFlowAccent('lavender', 'Lavender', Color(0xff9B7EDE)),
    GoFlowAccent('sage', 'Sage', Color(0xff5FA98A)),
    GoFlowAccent('plum', 'Plum', Color(0xff8E4585)),
  ];

  static GoFlowAccent? byId(String? id) {
    if (id == null) return null;
    for (final a in presets) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Resolve the effective accent color: the picked preset, or the current app
  /// theme accent when none is set.
  static Color resolve(String? accentId) =>
      byId(accentId)?.color ?? AppColors.primaryColor;
}
