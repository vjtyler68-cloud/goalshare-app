import 'dart:convert';
import 'dart:developer';

import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';

import 'org_task_models.dart';

/// Backend client for the org Task Hub (tasks + projects). All endpoints are
/// membership-gated server-side, so only members of the org get its tasks.
class OrgTaskApi {
  OrgTaskApi._();
  static final OrgTaskApi instance = OrgTaskApi._();

  /// Fetch all tasks + projects for an org.
  Future<({List<OrgTask> tasks, List<OrgProject> projects})> load(
      String orgId) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.orgTasks(orgId),
        jsonEncode({}),
        is_auth: true,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        final data = Map<String, dynamic>.from(res['data'] as Map);
        final tasks = <OrgTask>[
          if (data['tasks'] is List)
            for (final t in data['tasks'] as List)
              if (t is Map) OrgTask.fromJson(Map<String, dynamic>.from(t)),
        ];
        final projects = <OrgProject>[
          if (data['projects'] is List)
            for (final p in data['projects'] as List)
              if (p is Map) OrgProject.fromJson(Map<String, dynamic>.from(p)),
        ];
        return (tasks: tasks, projects: projects);
      }
    } catch (e) {
      log('OrgTaskApi.load: $e');
    }
    return (tasks: <OrgTask>[], projects: <OrgProject>[]);
  }

  /// Create a task. Returns the created task, or null on failure.
  Future<OrgTask?> create(String orgId, Map<String, dynamic> body) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.orgCreateTask(orgId),
        jsonEncode(body),
        is_auth: true,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        return OrgTask.fromJson(Map<String, dynamic>.from(res['data'] as Map));
      }
    } catch (e) {
      log('OrgTaskApi.create: $e');
    }
    return null;
  }

  /// Update a task. Returns (updated task, spawned recurring task or null).
  Future<({OrgTask? task, OrgTask? spawned})> update(
      String taskId, Map<String, dynamic> body) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.PATCH,
        Urls.orgUpdateTask(taskId),
        jsonEncode(body),
        is_auth: true,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        final data = Map<String, dynamic>.from(res['data'] as Map);
        final t = data['task'] is Map
            ? OrgTask.fromJson(Map<String, dynamic>.from(data['task'] as Map))
            : null;
        final s = data['spawned'] is Map
            ? OrgTask.fromJson(Map<String, dynamic>.from(data['spawned'] as Map))
            : null;
        return (task: t, spawned: s);
      }
    } catch (e) {
      log('OrgTaskApi.update: $e');
    }
    return (task: null, spawned: null);
  }

  Future<bool> remove(String taskId) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.DELETE,
        Urls.orgDeleteTask(taskId),
        jsonEncode({}),
        is_auth: true,
      );
      return res != null && res['success'] == true;
    } catch (e) {
      log('OrgTaskApi.remove: $e');
      return false;
    }
  }

  Future<OrgProject?> createProject(
      String orgId, String name, String color) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.orgCreateProject(orgId),
        jsonEncode({'name': name, 'color': color}),
        is_auth: true,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        return OrgProject.fromJson(
            Map<String, dynamic>.from(res['data'] as Map));
      }
    } catch (e) {
      log('OrgTaskApi.createProject: $e');
    }
    return null;
  }

  Future<bool> removeProject(String projectId) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.DELETE,
        Urls.orgDeleteProject(projectId),
        jsonEncode({}),
        is_auth: true,
      );
      return res != null && res['success'] == true;
    } catch (e) {
      log('OrgTaskApi.removeProject: $e');
      return false;
    }
  }

  // ── Meetings ───────────────────────────────────────────────────────────────
  Future<List<OrgMeeting>> loadMeetings(String orgId) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.orgMeetings(orgId),
        jsonEncode({}),
        is_auth: true,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        final list = (res['data'] as Map)['meetings'];
        if (list is List) {
          return [
            for (final m in list)
              if (m is Map) OrgMeeting.fromJson(Map<String, dynamic>.from(m)),
          ];
        }
      }
    } catch (e) {
      log('OrgTaskApi.loadMeetings: $e');
    }
    return const [];
  }

  Future<OrgMeeting?> createMeeting(
      String orgId, Map<String, dynamic> body) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.orgCreateMeeting(orgId),
        jsonEncode(body),
        is_auth: true,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        return OrgMeeting.fromJson(Map<String, dynamic>.from(res['data'] as Map));
      }
    } catch (e) {
      log('OrgTaskApi.createMeeting: $e');
    }
    return null;
  }

  Future<OrgMeeting?> updateMeeting(
      String meetingId, Map<String, dynamic> body) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.PATCH,
        Urls.orgUpdateMeeting(meetingId),
        jsonEncode(body),
        is_auth: true,
      );
      if (res != null && res['success'] == true && res['data'] is Map) {
        return OrgMeeting.fromJson(Map<String, dynamic>.from(res['data'] as Map));
      }
    } catch (e) {
      log('OrgTaskApi.updateMeeting: $e');
    }
    return null;
  }

  Future<bool> removeMeeting(String meetingId) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.DELETE,
        Urls.orgDeleteMeeting(meetingId),
        jsonEncode({}),
        is_auth: true,
      );
      return res != null && res['success'] == true;
    } catch (e) {
      log('OrgTaskApi.removeMeeting: $e');
      return false;
    }
  }
}
