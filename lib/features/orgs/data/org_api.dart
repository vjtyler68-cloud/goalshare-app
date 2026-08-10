import 'dart:convert';
import 'dart:developer';

import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';

import 'org_models.dart';

/// Backend client for organizations. Returns a small result record so the
/// caller can show the exact error message the server sent (invite code
/// invalid, already in an org, etc.).
class OrgResult {
  final bool ok;
  final String message;
  final OrgSummary? org;
  const OrgResult(this.ok, this.message, {this.org});
}

class OrgApi {
  OrgApi._();
  static final OrgApi instance = OrgApi._();

  Future<OrgResult> create({required String name, required OrgType type}) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.orgCreate,
        jsonEncode({'name': name, 'orgType': type.id}),
        is_auth: true,
      );
      if (res == null) {
        return const OrgResult(
            false, 'Couldn\'t reach the server. Check your connection and try again.');
      }
      return _orgResult(res, 'Could not create organization');
    } catch (e) {
      log('OrgApi.create: $e');
      return const OrgResult(false, 'Something went wrong — try again.');
    }
  }

  Future<OrgResult> join(String inviteCode) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.orgJoin,
        jsonEncode({'inviteCode': inviteCode}),
        is_auth: true,
      );
      if (res == null) {
        return const OrgResult(
            false, 'Couldn\'t reach the server. Check your connection and try again.');
      }
      return _orgResult(res, 'Could not join organization');
    } catch (e) {
      log('OrgApi.join: $e');
      return const OrgResult(false, 'Something went wrong — try again.');
    }
  }

  Future<OrgSummary?> mine() async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.orgMine,
        jsonEncode({}),
        is_auth: true,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        final org = (res['data'] as Map)['org'];
        if (org is Map) {
          return OrgSummary.fromJson(Map<String, dynamic>.from(org));
        }
      }
    } catch (e) {
      log('OrgApi.mine: $e');
    }
    return null;
  }

  /// All of the current user's orgs + whether they're an owner (multi-org).
  Future<OrgList> myOrgs() async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.orgAll,
        jsonEncode({}),
        is_auth: true,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        final data = Map<String, dynamic>.from(res['data'] as Map);
        final list = data['orgs'];
        final orgs = <OrgSummary>[
          if (list is List)
            for (final o in list)
              if (o is Map) OrgSummary.fromJson(Map<String, dynamic>.from(o)),
        ];
        return OrgList(orgs, data['isOwner'] == true);
      }
    } catch (e) {
      log('OrgApi.myOrgs: $e');
    }
    return const OrgList([], false);
  }

  Future<List<OrgMember>> roster(String orgId) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.orgRoster(orgId),
        jsonEncode({}),
        is_auth: true,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        final list = (res['data'] as Map)['members'];
        if (list is List) {
          return [
            for (final m in list)
              if (m is Map) OrgMember.fromJson(Map<String, dynamic>.from(m)),
          ];
        }
      }
    } catch (e) {
      log('OrgApi.roster: $e');
    }
    return const [];
  }

  /// Push my whitelist-scoped engagement summary. Fire-and-forget.
  Future<void> pushSummary(Map<String, dynamic> summary) async {
    try {
      await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.orgSummary,
        jsonEncode({'summary': summary}),
        is_auth: true,
      );
    } catch (e) {
      log('OrgApi.pushSummary: $e');
    }
  }

  Future<bool> leave({String? orgId}) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.orgLeave,
        jsonEncode({if (orgId != null) 'orgId': orgId}),
        is_auth: true,
      );
      return res != null && res['success'] == true;
    } catch (e) {
      log('OrgApi.leave: $e');
      return false;
    }
  }

  /// Set (or clear — pass an empty url) the org's Territory Map. Admin only.
  /// Returns null on success, or an error message.
  Future<String?> setMap(String orgId, String mapUrl, String mapLabel) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.orgMap(orgId),
        jsonEncode({'mapUrl': mapUrl, 'mapLabel': mapLabel}),
        is_auth: true,
      );
      if (res == null) {
        return 'Couldn\'t reach the server. Check your connection and try again.';
      }
      if (res['success'] == true) return null;
      return (res['message'] ?? 'Could not save the map').toString();
    } catch (e) {
      log('OrgApi.setMap: $e');
      return 'Something went wrong — try again.';
    }
  }

  /// Set (or clear — pass an empty url) the org's appointment scheduler. Admin
  /// only. Returns null on success, or an error message.
  Future<String?> setBooking(
      String orgId, String bookingUrl, String bookingLabel) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.orgBooking(orgId),
        jsonEncode({'bookingUrl': bookingUrl, 'bookingLabel': bookingLabel}),
        is_auth: true,
      );
      if (res == null) {
        return 'Couldn\'t reach the server. Check your connection and try again.';
      }
      if (res['success'] == true) return null;
      return (res['message'] ?? 'Could not save the scheduler').toString();
    } catch (e) {
      log('OrgApi.setBooking: $e');
      return 'Something went wrong — try again.';
    }
  }

  // ── Team HQ ──────────────────────────────────────────────────────────────

  Future<OrgSpace?> getSpace(String orgId) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.orgSpace(orgId),
        jsonEncode({}),
        is_auth: true,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        return OrgSpace.fromJson(Map<String, dynamic>.from(res['data'] as Map));
      }
    } catch (e) {
      log('OrgApi.getSpace: $e');
    }
    return null;
  }

  Future<String?> createPost(String orgId, String kind, String text) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.orgPost(orgId),
        jsonEncode({'kind': kind, 'text': text}),
        is_auth: true,
      );
      if (res != null && res['success'] == true) return null;
      return (res?['message'] ?? 'Could not post').toString();
    } catch (e) {
      log('OrgApi.createPost: $e');
      return 'Something went wrong — try again.';
    }
  }

  Future<void> toggleLike(String postId) async {
    try {
      await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST, Urls.orgPostLike(postId), jsonEncode({}),
        is_auth: true);
    } catch (e) {
      log('OrgApi.toggleLike: $e');
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.DELETE, Urls.orgPostDelete(postId), jsonEncode({}),
        is_auth: true);
    } catch (e) {
      log('OrgApi.deletePost: $e');
    }
  }

  Future<String?> createGoal(
      String orgId, String title, int target, String metricKey) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.orgGoal(orgId),
        jsonEncode({'title': title, 'target': target, 'metricKey': metricKey}),
        is_auth: true,
      );
      if (res != null && res['success'] == true) return null;
      return (res?['message'] ?? 'Could not create goal').toString();
    } catch (e) {
      log('OrgApi.createGoal: $e');
      return 'Something went wrong — try again.';
    }
  }

  Future<void> bumpGoal(String goalId, int delta) async {
    try {
      await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST, Urls.orgGoalBump(goalId), jsonEncode({'delta': delta}),
        is_auth: true);
    } catch (e) {
      log('OrgApi.bumpGoal: $e');
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.DELETE, Urls.orgGoalDelete(goalId), jsonEncode({}),
        is_auth: true);
    } catch (e) {
      log('OrgApi.deleteGoal: $e');
    }
  }

  OrgResult _orgResult(Map<String, dynamic>? res, String fallback) {
    if (res != null && res['success'] == true && res['data'] is Map) {
      final org = (res['data'] as Map)['org'];
      final role = (res['data'] as Map)['role']?.toString();
      if (org is Map) {
        final map = Map<String, dynamic>.from(org);
        if (role != null) map['role'] = role;
        return OrgResult(true, 'Success', org: OrgSummary.fromJson(map));
      }
    }
    return OrgResult(false, (res?['message'] ?? fallback).toString());
  }
}
