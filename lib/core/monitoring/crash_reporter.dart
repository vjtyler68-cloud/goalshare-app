import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../network_caller/endpoints.dart';
import '../user_info/user_info_controller.dart';

/// Self-hosted crash monitoring: fatal errors are POSTed (fire-and-forget) to
/// the backend's /data/crash endpoint, so crashes in the field are visible
/// without adding a third-party SDK. Never throws, never blocks the UI, and
/// hard-caps its own volume so an error loop can't spam the server.
class CrashReporter {
  CrashReporter._();

  /// Keep in sync with pubspec `version:` when convenient — used only to tag
  /// reports so we know which build a crash came from.
  static const String appBuild = '1.5.0+89';

  static const int _maxReportsPerSession = 10;
  static int _sent = 0;
  static final Set<String> _seenThisSession = <String>{};

  static void report(Object error, StackTrace? stack) {
    try {
      final errorText = error.toString();
      // One report per distinct error per session, capped overall.
      if (_sent >= _maxReportsPerSession) return;
      final key = errorText.length > 200 ? errorText.substring(0, 200) : errorText;
      if (!_seenThisSession.add(key)) return;
      _sent++;

      String userId = '';
      try {
        if (Get.isRegistered<UserInfoController>()) {
          userId = Get.find<UserInfoController>().userData.value?.id ?? '';
        }
      } catch (_) {}

      // Fire-and-forget: a crash report must never cause another failure.
      http
          .post(
            Uri.parse('${Urls.baseUrl}/data/crash'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'error': errorText,
              'stack': (stack ?? StackTrace.empty).toString(),
              'appVersion': appBuild,
              'platform':
                  '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
              'userId': userId,
            }),
          )
          .timeout(const Duration(seconds: 8))
          .catchError((_) => http.Response('', 499));
    } catch (_) {
      // Swallow everything — see class doc.
    }
  }
}
