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

  Future<bool> leave() async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.orgLeave,
        jsonEncode({}),
        is_auth: true,
      );
      return res != null && res['success'] == true;
    } catch (e) {
      log('OrgApi.leave: $e');
      return false;
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
