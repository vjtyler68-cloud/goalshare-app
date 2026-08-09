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

  /// Richer (still summary-level) partner context — never raw logs:
  ///  • [daysUntilPeriod]: countdown to the next expected period.
  ///  • [fertileNow]: whether today falls in the fertile window.
  ///  • [pregnancyWeek]: gestational week when in pregnancy mode.
  final int? daysUntilPeriod;
  final bool fertileNow;
  final int? pregnancyWeek;

  final int updatedAtMs;

  const GoFlowSummary({
    this.phase,
    this.customStatus,
    this.daysUntilPeriod,
    this.fertileNow = false,
    this.pregnancyWeek,
    this.updatedAtMs = 0,
  });

  bool get hasAny =>
      (phase != null && phase!.isNotEmpty) ||
      (customStatus != null && customStatus!.trim().isNotEmpty) ||
      pregnancyWeek != null;

  Map<String, dynamic> toJson() => {
        'phase': phase,
        'customStatus': customStatus,
        'daysUntilPeriod': daysUntilPeriod,
        'fertileNow': fertileNow,
        'pregnancyWeek': pregnancyWeek,
        'updatedAtMs': updatedAtMs,
      };

  factory GoFlowSummary.fromJson(Map<String, dynamic> j) => GoFlowSummary(
        phase: (j['phase'] as String?),
        customStatus: (j['customStatus'] as String?),
        daysUntilPeriod: (j['daysUntilPeriod'] as num?)?.toInt(),
        fertileNow: j['fertileNow'] == true,
        pregnancyWeek: (j['pregnancyWeek'] as num?)?.toInt(),
        updatedAtMs: (j['updatedAtMs'] as num?)?.toInt() ?? 0,
      );

  String toJsonString() => jsonEncode(toJson());
  factory GoFlowSummary.fromJsonString(String s) =>
      GoFlowSummary.fromJson(Map<String, dynamic>.from(jsonDecode(s) as Map));
}
