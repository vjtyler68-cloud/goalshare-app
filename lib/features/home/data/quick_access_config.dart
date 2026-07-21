/// Per-module dashboard preference for the Quick Access grid.
///
/// Plain JSON (no Hive adapters / codegen) — see [QuickAccessStore].
class QuickAccessCardConfig {
  final String moduleId;
  final int sortOrder;
  final bool isVisible;

  const QuickAccessCardConfig({
    required this.moduleId,
    required this.sortOrder,
    this.isVisible = true,
  });

  QuickAccessCardConfig copyWith({int? sortOrder, bool? isVisible}) {
    return QuickAccessCardConfig(
      moduleId: moduleId,
      sortOrder: sortOrder ?? this.sortOrder,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  Map<String, dynamic> toJson() => {
        'moduleId': moduleId,
        'sortOrder': sortOrder,
        'isVisible': isVisible,
      };

  /// Tolerant of missing/odd fields — a half-written record degrades to a
  /// visible card rather than throwing away the whole layout.
  static QuickAccessCardConfig? fromJson(Map<String, dynamic> json) {
    final id = json['moduleId'];
    if (id is! String || id.isEmpty) return null;
    return QuickAccessCardConfig(
      moduleId: id,
      sortOrder: json['sortOrder'] is int ? json['sortOrder'] as int : 0,
      isVisible: json['isVisible'] is bool ? json['isVisible'] as bool : true,
    );
  }
}
