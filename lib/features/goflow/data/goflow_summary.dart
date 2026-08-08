import 'dart:convert';

/// The privacy-preserving snapshot a friend receives when GoFlow sharing is on:
/// only the current phase label and an optional custom status line — NEVER raw
/// logs, dates, flow, or symptoms.
class GoFlowSummary {
  /// Phase id (see [GoFlowPhase.id]) or null when there's nothing to show.
  final String? phase;

  /// A short line the owner chose to share (e.g. "low energy this week"), or
  /// null. Capped in the UI.
  final String? customStatus;

  final int updatedAtMs;

  const GoFlowSummary({
    this.phase,
    this.customStatus,
    this.updatedAtMs = 0,
  });

  bool get hasAny =>
      (phase != null && phase!.isNotEmpty) ||
      (customStatus != null && customStatus!.trim().isNotEmpty);

  Map<String, dynamic> toJson() => {
        'phase': phase,
        'customStatus': customStatus,
        'updatedAtMs': updatedAtMs,
      };

  factory GoFlowSummary.fromJson(Map<String, dynamic> j) => GoFlowSummary(
        phase: (j['phase'] as String?),
        customStatus: (j['customStatus'] as String?),
        updatedAtMs: (j['updatedAtMs'] as num?)?.toInt() ?? 0,
      );

  String toJsonString() => jsonEncode(toJson());
  factory GoFlowSummary.fromJsonString(String s) =>
      GoFlowSummary.fromJson(Map<String, dynamic>.from(jsonDecode(s) as Map));
}
