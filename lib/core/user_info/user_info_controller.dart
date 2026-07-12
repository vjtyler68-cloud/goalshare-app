import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/core/user_info/model/user_data_model.dart';

class UserInfoController extends GetxController {
  /// Offline-first: the last successful /user/me payload is cached locally so
  /// a rep standing in a driveway with no signal can still open the app with
  /// a valid session instead of being dumped at the login screen.
  static const String _kCachedUserKey = 'cached_user_data_v1';
  final RxInt userFollowingCount = 0.obs;
  final RxInt userFollowerCount = 0.obs;
  final Rxn<UserDataModel> userData = Rxn<UserDataModel>();

  @override
  void onInit() {
    super.onInit();
    loadAndSetUserInfo();
    getFollowersCount();
  }

  Future<void> loadAndSetUserInfo() async {
    await getUserInfo();
  }

  /// Reset the cached identity and reload it for whoever is currently
  /// authenticated. MUST be called on every login: this controller is a
  /// long-lived singleton (permanent / fenix), so without an explicit refresh a
  /// newly logged-in account would keep showing the previously logged-in user's
  /// cached profile (e.g. the admin account).
  Future<void> refreshUserData() async {
    clear();
    await getUserInfo();
    await getFollowersCount();
  }

  /// Drop the cached identity (e.g. on logout) so nothing stale lingers.
  /// Also wipes the offline cache so an account switch can never resurrect
  /// the previous user's profile.
  void clear() {
    userData.value = null;
    userFollowerCount.value = 0;
    userFollowingCount.value = 0;
    SharedPreferences.getInstance()
        .then((p) => p.remove(_kCachedUserKey))
        .catchError((_) => false);
  }

  Future<void> getUserInfo() async {
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.userPersonalData,
        jsonEncode({}),
        is_auth: true,
      );

      if (response != null && response['success'] == true) {
        userData.value = UserDataModel.fromJson(response['data']);
        // Persist for offline sessions (best-effort).
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kCachedUserKey, jsonEncode(response['data']));
        } catch (_) {}
        return;
      }
      await _loadFromCacheIfNeeded();
    } catch (e) {
      log('getUserInfo error: $e');
      await _loadFromCacheIfNeeded();
    }
  }

  /// Public offline restore for callers that time out on the network path
  /// (e.g. the splash screen). True if a profile is available afterwards.
  Future<bool> restoreFromCache() async {
    await _loadFromCacheIfNeeded();
    return userData.value != null;
  }

  /// Offline fallback: if the network fetch failed and we have nothing in
  /// memory, restore the last known profile from local storage so the session
  /// (and the splash subscription check) can proceed without signal.
  Future<void> _loadFromCacheIfNeeded() async {
    if (userData.value != null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCachedUserKey);
      if (raw == null || raw.isEmpty) return;
      userData.value = UserDataModel.fromJson(jsonDecode(raw));
      log('UserInfo: restored profile from offline cache');
    } catch (e) {
      log('UserInfo: offline cache restore failed — $e');
    }
  }

  Future<void> getFollowersCount() async {
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.userFollowersCount,
        jsonEncode({}),
        is_auth: true,
      );

      if (response != null && response['success'] == true) {
        final data = response['data'];
        if (data is Map) {
          userFollowingCount.value =
              (data['followingCount'] as num?)?.toInt() ?? 0;
          userFollowerCount.value =
              (data['followersCount'] as num?)?.toInt() ?? 0;
        }
      }
    } catch (e) {
      log('getFollowersCount error: $e');
    }
  }
}
