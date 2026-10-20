import 'dart:convert';
import 'dart:developer';

import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';

/// Optional friend accountability for the 75 Challenge, on the app's OWN
/// backend (the same Railway server everything else uses). Because it rides the
/// app's account login (JWT), there's no Firebase / anonymous sign-in and
/// nothing to configure in a console — if you're signed in and online, it works.
///
/// A "crew" is a small invite-code group; each member publishes a lightweight
/// progress summary (day, streak, today's %) that the others can see. Every call
/// is best-effort: a network failure returns null/empty and the UI surfaces it,
/// never a crash, and the local tracker is unaffected.
class Challenge75Crew {
  Challenge75Crew._();
  static final Challenge75Crew instance = Challenge75Crew._();

  Future<Challenge75CrewInfo?> createCrew(String name) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.challenge75CreateCrew,
        jsonEncode({'name': name}),
        is_auth: true,
        showErrors: false,
      );
      return _infoFrom(res);
    } catch (e) {
      log('Challenge75Crew.createCrew: $e');
      return null;
    }
  }

  /// Returns the crew info on success, or null if the code was wrong / offline.
  Future<Challenge75CrewInfo?> joinCrew(String code) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.challenge75JoinCrew,
        jsonEncode({'code': code.trim().toUpperCase()}),
        is_auth: true,
        showErrors: false,
      );
      return _infoFrom(res);
    } catch (e) {
      log('Challenge75Crew.joinCrew: $e');
      return null;
    }
  }

  Future<void> leaveCrew(String code) async {
    try {
      await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.challenge75LeaveCrew,
        jsonEncode({'code': code.trim().toUpperCase()}),
        is_auth: true,
        showErrors: false,
      );
    } catch (e) {
      log('Challenge75Crew.leaveCrew: $e');
    }
  }

  Future<void> pushProgress({
    required String code,
    required String variantId,
    required int day,
    required int daysCompleted,
    required int streak,
    required double completionToday,
    required bool todayComplete,
  }) async {
    if (code.trim().isEmpty) return;
    try {
      await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.challenge75Progress,
        jsonEncode({
          'code': code.trim().toUpperCase(),
          'variantId': variantId,
          'day': day,
          'daysCompleted': daysCompleted,
          'streak': streak,
          'completionToday': completionToday,
          'todayComplete': todayComplete,
        }),
        is_auth: true,
        showErrors: false,
      );
    } catch (e) {
      log('Challenge75Crew.pushProgress: $e');
    }
  }

  Future<List<Challenge75CrewMember>> listMembers(String code) async {
    final c = code.trim().toUpperCase();
    if (c.isEmpty) return const [];
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.challenge75Members(c),
        jsonEncode({}),
        is_auth: true,
        showErrors: false,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        final list = (res['data'] as Map)['members'];
        if (list is List) {
          return [
            for (final m in list)
              if (m is Map)
                Challenge75CrewMember.fromJson(Map<String, dynamic>.from(m)),
          ];
        }
      }
    } catch (e) {
      log('Challenge75Crew.listMembers: $e');
    }
    return const [];
  }

  Challenge75CrewInfo? _infoFrom(Map<String, dynamic>? res) {
    if (res != null && res['success'] == true && res['data'] is Map) {
      final d = Map<String, dynamic>.from(res['data'] as Map);
      final code = (d['code'] as String?)?.trim();
      if (code != null && code.isNotEmpty) {
        return Challenge75CrewInfo(
          code: code,
          name: (d['name'] as String?) ?? 'My 75 Crew',
        );
      }
    }
    return null;
  }
}

/// Result of creating/joining a crew.
class Challenge75CrewInfo {
  final String code;
  final String name;
  const Challenge75CrewInfo({required this.code, required this.name});
}

/// One member's shared progress line in a crew.
class Challenge75CrewMember {
  final String userId;
  final String name;
  final String variantId;
  final int day;
  final int daysCompleted;
  final int streak;
  final double completionToday; // 0..1
  final bool todayComplete;

  const Challenge75CrewMember({
    required this.userId,
    required this.name,
    required this.variantId,
    required this.day,
    required this.daysCompleted,
    required this.streak,
    required this.completionToday,
    required this.todayComplete,
  });

  factory Challenge75CrewMember.fromJson(Map<String, dynamic> d) =>
      Challenge75CrewMember(
        userId: (d['userId'] as String?) ?? '',
        name: (d['name'] as String?) ?? 'Teammate',
        variantId: (d['variantId'] as String?) ?? '',
        day: (d['day'] as num?)?.toInt() ?? 0,
        daysCompleted: (d['daysCompleted'] as num?)?.toInt() ?? 0,
        streak: (d['streak'] as num?)?.toInt() ?? 0,
        completionToday: (d['completionToday'] as num?)?.toDouble() ?? 0,
        todayComplete: d['todayComplete'] as bool? ?? false,
      );
}
