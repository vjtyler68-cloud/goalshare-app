/// One member of a Goal Circle, with their status for today.
class CircleMember {
  final String id;
  final String name;
  final String avatar;
  final bool isMe;
  final bool checkedInToday;
  final String proofUrl;

  const CircleMember({
    this.id = '',
    this.name = '',
    this.avatar = '',
    this.isMe = false,
    this.checkedInToday = false,
    this.proofUrl = '',
  });

  factory CircleMember.fromJson(Map<String, dynamic> j) => CircleMember(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        avatar: (j['avatar'] ?? '').toString(),
        isMe: j['isMe'] == true,
        checkedInToday: j['checkedInToday'] == true,
        proofUrl: (j['proofUrl'] ?? '').toString(),
      );
}

/// A Goal Circle squad + its shared state.
class CircleData {
  final String id;
  final String name;
  final String ownerId;
  final int shields;
  final int memberCount;
  final int threshold; // members needed per day to keep the streak
  final int ourStreak;
  final int todayCount; // members checked in today
  final List<CircleMember> members;

  const CircleData({
    this.id = '',
    this.name = '',
    this.ownerId = '',
    this.shields = 0,
    this.memberCount = 0,
    this.threshold = 2,
    this.ourStreak = 0,
    this.todayCount = 0,
    this.members = const [],
  });

  CircleMember? get me {
    for (final m in members) {
      if (m.isMe) return m;
    }
    return null;
  }

  bool get iCheckedInToday => me?.checkedInToday ?? false;

  /// Parse the /circles/mine response. Returns null when not in a circle.
  static CircleData? fromResponse(Map<String, dynamic> j) {
    final c = j['circle'];
    if (c is! Map) return null;
    final circle = Map<String, dynamic>.from(c);
    return CircleData(
      id: (circle['id'] ?? '').toString(),
      name: (circle['name'] ?? '').toString(),
      ownerId: (circle['ownerId'] ?? '').toString(),
      shields: (circle['shields'] as num?)?.toInt() ?? 0,
      memberCount: (circle['memberCount'] as num?)?.toInt() ?? 0,
      threshold: (circle['threshold'] as num?)?.toInt() ?? 2,
      ourStreak: (j['ourStreak'] as num?)?.toInt() ?? 0,
      todayCount: (j['todayCount'] as num?)?.toInt() ?? 0,
      members: (j['members'] as List?)
              ?.whereType<Map>()
              .map((e) => CircleMember.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
    );
  }
}
