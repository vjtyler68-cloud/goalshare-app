/// Organizations feature — a School / Sales / Gym org with one admin (a trainer
/// for gyms) and members. The server is the source of truth (memberships live
/// between accounts, not on one phone), so these are network models.

enum OrgType { school, salesOrg, gym }

extension OrgTypeX on OrgType {
  /// Wire value shared with the backend.
  String get id {
    switch (this) {
      case OrgType.school:
        return 'school';
      case OrgType.salesOrg:
        return 'salesOrg';
      case OrgType.gym:
        return 'gym';
    }
  }

  static OrgType fromId(String? id) {
    switch (id) {
      case 'salesOrg':
        return OrgType.salesOrg;
      case 'gym':
        return OrgType.gym;
      default:
        return OrgType.school;
    }
  }

  /// Onboarding card title.
  String get label {
    switch (this) {
      case OrgType.school:
        return 'School';
      case OrgType.salesOrg:
        return 'Sales Organization';
      case OrgType.gym:
        return 'Personal Training / Gym';
    }
  }

  /// Role labels shown in UI copy (gym uses trainer/trainee).
  String get adminLabel => this == OrgType.gym ? 'Trainer' : 'Admin';
  String get memberLabel => this == OrgType.gym ? 'Trainee' : 'Member';

  /// "Create" choice copy per type.
  String get createLabel {
    switch (this) {
      case OrgType.gym:
        return "I'm a trainer setting up for my clients";
      case OrgType.school:
        return 'Create a school group (you become admin)';
      case OrgType.salesOrg:
        return 'Create a sales org (you become admin)';
    }
  }

  /// "Join" choice copy per type.
  String get joinLabel {
    switch (this) {
      case OrgType.gym:
        return "I'm a trainee joining my trainer";
      default:
        return 'Join with an invite code';
    }
  }
}

/// The current user's org membership summary.
class OrgSummary {
  final String id;
  final String name;
  final OrgType orgType;
  final String inviteCode;
  final String role; // 'admin' | 'member'

  const OrgSummary({
    required this.id,
    required this.name,
    required this.orgType,
    required this.inviteCode,
    required this.role,
  });

  bool get isAdmin => role == 'admin';

  factory OrgSummary.fromJson(Map<String, dynamic> j) => OrgSummary(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        orgType: OrgTypeX.fromId(j['orgType']?.toString()),
        inviteCode: (j['inviteCode'] ?? '').toString(),
        role: (j['role'] ?? 'member').toString(),
      );
}

/// The user's orgs plus whether they're an owner (owners may belong to several).
class OrgList {
  final List<OrgSummary> orgs;
  final bool isOwner;
  const OrgList(this.orgs, this.isOwner);
}

/// One person on an org roster.
class OrgMember {
  final String userId;
  final String name;
  final String avatar;
  final String role;
  final DateTime? joinedAt;

  /// Whitelist-scoped engagement values keyed by "module.field" — what this
  /// member last reported. Empty until they've used the app since joining.
  final Map<String, dynamic> summary;
  final DateTime? summaryAt;

  const OrgMember({
    required this.userId,
    required this.name,
    this.avatar = '',
    this.role = 'member',
    this.joinedAt,
    this.summary = const {},
    this.summaryAt,
  });

  bool get isAdmin => role == 'admin';
  bool get hasSummary => summary.isNotEmpty;

  factory OrgMember.fromJson(Map<String, dynamic> j) => OrgMember(
        userId: (j['userId'] ?? '').toString(),
        name: (j['name'] ?? 'Member').toString(),
        avatar: (j['avatar'] ?? '').toString(),
        role: (j['role'] ?? 'member').toString(),
        joinedAt: DateTime.tryParse('${j['joinedAt'] ?? ''}'),
        summary: j['summary'] is Map
            ? Map<String, dynamic>.from(j['summary'] as Map)
            : const {},
        summaryAt: DateTime.tryParse('${j['summaryAt'] ?? ''}'),
      );
}

/// A Team HQ post — an announcement (admin-only) or a feed post (any member).
class OrgPost {
  final String id;
  final String kind; // 'announcement' | 'feed'
  final String text;
  final String authorId;
  final String authorName;
  final String authorAvatar;
  final int likeCount;
  final bool likedByMe;
  final DateTime? createdAt;

  const OrgPost({
    required this.id,
    required this.kind,
    required this.text,
    this.authorId = '',
    this.authorName = 'Member',
    this.authorAvatar = '',
    this.likeCount = 0,
    this.likedByMe = false,
    this.createdAt,
  });

  bool get isAnnouncement => kind == 'announcement';

  factory OrgPost.fromJson(Map<String, dynamic> j) => OrgPost(
        id: (j['id'] ?? '').toString(),
        kind: (j['kind'] ?? 'feed').toString(),
        text: (j['text'] ?? '').toString(),
        authorId: (j['authorId'] ?? '').toString(),
        authorName: (j['authorName'] ?? 'Member').toString(),
        authorAvatar: (j['authorAvatar'] ?? '').toString(),
        likeCount: (j['likeCount'] as num?)?.toInt() ?? 0,
        likedByMe: j['likedByMe'] == true,
        createdAt: DateTime.tryParse('${j['createdAt'] ?? ''}'),
      );
}

/// A shared team goal/target with computed progress.
class OrgGoal {
  final String id;
  final String title;
  final int target;
  final String metricKey; // 'leads.count' | 'rpm.goal_completed' | 'manual'
  final int progress;

  const OrgGoal({
    required this.id,
    required this.title,
    this.target = 0,
    this.metricKey = 'manual',
    this.progress = 0,
  });

  bool get isManual => metricKey == 'manual';
  double get fraction =>
      target <= 0 ? 0 : (progress / target).clamp(0.0, 1.0);

  factory OrgGoal.fromJson(Map<String, dynamic> j) => OrgGoal(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        target: (j['target'] as num?)?.toInt() ?? 0,
        metricKey: (j['metricKey'] ?? 'manual').toString(),
        progress: (j['progress'] as num?)?.toInt() ?? 0,
      );
}

/// The whole Team HQ payload for an org.
class OrgSpace {
  final List<OrgPost> announcements;
  final List<OrgPost> feed;
  final List<OrgGoal> goals;

  const OrgSpace({
    this.announcements = const [],
    this.feed = const [],
    this.goals = const [],
  });

  factory OrgSpace.fromJson(Map<String, dynamic> j) {
    List<OrgPost> posts(dynamic v) => v is List
        ? [
            for (final e in v)
              if (e is Map) OrgPost.fromJson(Map<String, dynamic>.from(e))
          ]
        : const [];
    return OrgSpace(
      announcements: posts(j['announcements']),
      feed: posts(j['feed']),
      goals: j['goals'] is List
          ? [
              for (final e in (j['goals'] as List))
                if (e is Map) OrgGoal.fromJson(Map<String, dynamic>.from(e))
            ]
          : const [],
    );
  }
}
