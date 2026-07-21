import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';

import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/core/user_info/user_info_controller.dart';

/// A person on the other end of a friendship, request, or search result.
class FriendUser {
  final String id;
  final String name;
  final String? username;
  final String? profile;

  const FriendUser({
    required this.id,
    required this.name,
    this.username,
    this.profile,
  });

  factory FriendUser.fromJson(Map<String, dynamic> j) => FriendUser(
        id: (j['id'] ?? '').toString(),
        name: (j['fullName'] ?? '').toString(),
        username: j['username']?.toString(),
        profile: j['profile']?.toString(),
      );
}

/// A pending friend request (incoming or sent), with its row id so it can be
/// accepted / declined / cancelled.
class FriendRequestItem {
  final String id;
  final FriendUser user;

  const FriendRequestItem({required this.id, required this.user});

  static FriendRequestItem? fromJson(dynamic j) {
    if (j is! Map<String, dynamic>) return null;
    final user = j['user'];
    if (user is! Map<String, dynamic>) return null;
    return FriendRequestItem(
      id: (j['id'] ?? '').toString(),
      user: FriendUser.fromJson(user),
    );
  }
}

/// Friends hub state: friends list, pending requests both ways, and people
/// search. Server is the source of truth (friendships live between accounts,
/// not on one phone) — every mutation refetches the affected lists.
class FriendsController extends GetxController {
  static FriendsController get to => Get.isRegistered<FriendsController>()
      ? Get.find<FriendsController>()
      : Get.put(FriendsController(), permanent: true);

  /// Long-lived singleton profile holder (registered in main/home).
  UserInfoController get _userInfo => Get.isRegistered<UserInfoController>()
      ? Get.find<UserInfoController>()
      : Get.put(UserInfoController(), permanent: true);

  final RxBool isLoading = false.obs;
  final RxList<FriendUser> friends = <FriendUser>[].obs;
  final RxList<FriendRequestItem> incoming = <FriendRequestItem>[].obs;
  final RxList<FriendRequestItem> sent = <FriendRequestItem>[].obs;

  /// Powers the badge on the home-header people icon.
  int get pendingCount => incoming.length;

  // ── people search (Find People tab) ────────────────────────────────────────
  final RxBool isSearching = false.obs;
  final RxList<FriendUser> searchResults = <FriendUser>[].obs;
  Timer? _searchDebounce;

  @override
  void onInit() {
    super.onInit();
    // Warm the lists once at startup so the badge is right without opening
    // the hub. Errors are silent here — the hub refreshes on open anyway.
    refreshAll();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }

  Future<void> refreshAll() async {
    await Future.wait([_fetchFriends(), _fetchRequests()]);
  }

  Future<void> _fetchFriends() async {
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.friends,
        jsonEncode({}),
        is_auth: true,
      );
      if (response != null && response['success'] == true) {
        final data = response['data'];
        if (data is List) {
          friends.assignAll([
            for (final row in data)
              if (row is Map<String, dynamic> &&
                  row['user'] is Map<String, dynamic>)
                FriendUser.fromJson(row['user'] as Map<String, dynamic>),
          ]);
        }
      }
    } catch (e) {
      log('fetchFriends error: $e');
    }
  }

  Future<void> _fetchRequests() async {
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.GET,
        Urls.friendRequests,
        jsonEncode({}),
        is_auth: true,
      );
      if (response != null && response['success'] == true) {
        final data = response['data'];
        if (data is Map<String, dynamic>) {
          incoming.assignAll([
            for (final row in (data['incoming'] as List? ?? []))
              if (FriendRequestItem.fromJson(row) != null)
                FriendRequestItem.fromJson(row)!,
          ]);
          sent.assignAll([
            for (final row in (data['sent'] as List? ?? []))
              if (FriendRequestItem.fromJson(row) != null)
                FriendRequestItem.fromJson(row)!,
          ]);
        }
      }
    } catch (e) {
      log('fetchRequests error: $e');
    }
  }

  // ── actions ────────────────────────────────────────────────────────────────

  /// Send a request. The backend auto-accepts when the other person already
  /// asked us — surface that as the friendlier message.
  Future<void> sendRequest(FriendUser user) async {
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.POST,
        Urls.friendRequests,
        jsonEncode({'toUserId': user.id}),
        is_auth: true,
      );
      if (response != null && response['success'] == true) {
        final became = response['data']?['becameFriends'] == true;
        AppSnackBar.success(became
            ? "You're now friends with ${user.name}!"
            : 'Request sent to ${user.name}');
        await refreshAll();
      } else {
        AppSnackBar.error(
            (response?['message'] ?? 'Could not send request').toString());
      }
    } catch (e) {
      log('sendRequest error: $e');
      AppSnackBar.error('Could not send request — try again.');
    }
  }

  Future<void> accept(FriendRequestItem req) async {
    await _requestAction('${Urls.friendRequests}/${req.id}/accept',
        RequestMethod.POST, "You're now friends with ${req.user.name}!");
  }

  Future<void> decline(FriendRequestItem req) async {
    await _requestAction('${Urls.friendRequests}/${req.id}/decline',
        RequestMethod.POST, 'Request declined');
  }

  Future<void> cancel(FriendRequestItem req) async {
    await _requestAction('${Urls.friendRequests}/${req.id}',
        RequestMethod.DELETE, 'Request cancelled');
  }

  Future<void> removeFriend(FriendUser user) async {
    await _requestAction('${Urls.friends}/${user.id}', RequestMethod.DELETE,
        '${user.name} removed');
  }

  Future<void> _requestAction(
      String url, RequestMethod method, String successMsg) async {
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        method,
        url,
        jsonEncode({}),
        is_auth: true,
      );
      if (response != null && response['success'] == true) {
        AppSnackBar.success(successMsg);
      } else {
        AppSnackBar.error(
            (response?['message'] ?? 'Something went wrong').toString());
      }
    } catch (e) {
      log('friend action error: $e');
      AppSnackBar.error('Something went wrong — try again.');
    }
    await refreshAll();
  }

  // ── search ─────────────────────────────────────────────────────────────────

  /// Debounced people search by username or name (min 2 chars).
  void search(String query) {
    _searchDebounce?.cancel();
    final q = query.trim();
    if (q.length < 2) {
      searchResults.clear();
      isSearching.value = false;
      return;
    }
    isSearching.value = true;
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      try {
        final response = await NetworkConfig.instance.ApiRequestHandler(
          RequestMethod.GET,
          '${Urls.searchUsers}?q=${Uri.encodeQueryComponent(q)}',
          jsonEncode({}),
          is_auth: true,
        );
        if (response != null && response['success'] == true) {
          final data = response['data'];
          final myId = _userInfo.userData.value?.id;
          searchResults.assignAll([
            for (final row in (data is List ? data : const []))
              if (row is Map<String, dynamic> &&
                  (row['id'] ?? '').toString() != (myId ?? ''))
                FriendUser.fromJson(row),
          ]);
        }
      } catch (e) {
        log('searchUsers error: $e');
      } finally {
        isSearching.value = false;
      }
    });
  }

  /// Relationship of a search result to me — drives the row's action button.
  String relationTo(FriendUser user) {
    if (friends.any((f) => f.id == user.id)) return 'friend';
    if (sent.any((r) => r.user.id == user.id)) return 'sent';
    if (incoming.any((r) => r.user.id == user.id)) return 'incoming';
    return 'none';
  }

  // ── username claim (needed so people can find you) ─────────────────────────

  String? get myUsername {
    final u = _userInfo.userData.value?.username;
    return (u == null || u.isEmpty) ? null : u;
  }

  /// Claim/change my handle. Returns true on success.
  Future<bool> claimUsername(String username) async {
    final u = username.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9_.]{3,20}$').hasMatch(u)) {
      AppSnackBar.error(
          '3–20 characters: lowercase letters, numbers, _ or . only');
      return false;
    }
    try {
      final response = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.PUT,
        Urls.setUsername,
        jsonEncode({'username': u}),
        is_auth: true,
      );
      if (response != null && response['success'] == true) {
        AppSnackBar.success('@$u is yours!');
        await _userInfo.loadAndSetUserInfo();
        return true;
      }
      AppSnackBar.error(
          (response?['message'] ?? 'Could not save username').toString());
      return false;
    } catch (e) {
      log('claimUsername error: $e');
      AppSnackBar.error('Could not save username — try again.');
      return false;
    }
  }
}
