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

/// One person on an org roster.
class OrgMember {
  final String userId;
  final String name;
  final String avatar;
  final String role;
  final DateTime? joinedAt;

  const OrgMember({
    required this.userId,
    required this.name,
    this.avatar = '',
    this.role = 'member',
    this.joinedAt,
  });

  bool get isAdmin => role == 'admin';

  factory OrgMember.fromJson(Map<String, dynamic> j) => OrgMember(
        userId: (j['userId'] ?? '').toString(),
        name: (j['name'] ?? 'Member').toString(),
        avatar: (j['avatar'] ?? '').toString(),
        role: (j['role'] ?? 'member').toString(),
        joinedAt: DateTime.tryParse('${j['joinedAt'] ?? ''}'),
      );
}
