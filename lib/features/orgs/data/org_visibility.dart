import 'org_models.dart';

/// The org permission whitelist. A single source of truth for which member
/// fields an org admin may ever see, hardcoded per the spec (not user-editable
/// yet). Anything not explicitly allowed is private.
///
/// Budget is ALWAYS private regardless of org type. Nutrition detail and any
/// journal/vision/bible text are never exposed — only counts/booleans/streaks.
class OrgVisibility {
  OrgVisibility._();

  /// `{orgType.id : { "moduleKey.fieldKey", ... }}` — the allow set.
  static const Map<String, Set<String>> _allowed = {
    'school': {
      'rpm.goal_set',
      'rpm.goal_completed',
      'gratitude.streak_count',
      'gratitude.entries_logged_count',
      'daily_spark.viewed_today',
      'vision_board.created', // boolean only — never image content
    },
    'salesOrg': {
      'leads.count',
      'leads.pipeline_stage',
      'leads.conversion_rate',
      'territory.doors_today',
      'territory.talked_today',
      'territory.bills_today',
      'rpm.goal_set',
      'rpm.goal_completed',
      'rpm.quota_progress',
      'daily_spark.viewed_today',
    },
    'gym': {
      'nutrition.logged_today', // boolean/count only — never meal contents
      'nutrition.protein_target_met',
      'rpm.goal_set',
      'rpm.goal_completed',
      'daily_spark.viewed_today',
      'accountability_buddies.checkin_streak',
    },
  };

  /// The single permission check used everywhere the admin dashboard reads
  /// member data. Never query raw member data without passing through this.
  static bool isFieldAdminVisible(
      OrgType orgType, String moduleKey, String fieldKey) {
    // Budget is always private, no matter what.
    if (moduleKey == 'budget') return false;
    final set = _allowed[orgType.id];
    if (set == null) return false;
    return set.contains('$moduleKey.$fieldKey');
  }

  /// All allowed `module.field` keys for an org type (drives which member
  /// metrics the dashboard requests / renders).
  static List<String> allowedKeys(OrgType orgType) =>
      (_allowed[orgType.id] ?? const <String>{}).toList();
}
