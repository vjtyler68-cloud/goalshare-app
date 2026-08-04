import 'package:get/get.dart';

import 'package:spanx/core/user_info/user_info_controller.dart';
import 'package:spanx/features/goals/controller/goals_controller.dart';

import '../data/accountability_match.dart';
import '../data/accountability_profile.dart';
import '../data/accountability_store.dart';
import '../data/buddies_api.dart';
import '../data/checkin_models.dart';

/// Owns the Accountability Buddies state for the signed-in user: their profile,
/// their current 7-day match, opt-in status, check-ins and ratings.
///
/// Works fully on-device (friends-based buddies + local testing). The backend
/// hooks for random weekly pairing + cross-user rating exchange are marked with
/// TODOs and land with the Railway matcher — nothing here blocks on them.
class BuddiesController extends GetxController {
  static BuddiesController get to => Get.isRegistered<BuddiesController>()
      ? Get.find<BuddiesController>()
      : Get.put(BuddiesController(), permanent: true);

  final AccountabilityStore _store = AccountabilityStore();

  final Rxn<AccountabilityProfile> profile = Rxn<AccountabilityProfile>();
  final Rxn<AccountabilityMatch> currentMatch = Rxn<AccountabilityMatch>();
  final RxBool ready = false.obs;

  // Daily Proof / shared streak (backend-driven).
  final RxInt ourStreak = 0.obs;
  final RxList<CheckinDay> checkinDays = <CheckinDay>[].obs;

  // The buddy's shared goals (so you can see what they're working toward).
  final RxList<Map<String, dynamic>> buddyGoals =
      <Map<String, dynamic>>[].obs;

  // ── Derived state the UI reads ─────────────────────────────────────────────
  bool get hasProfile => profile.value?.isComplete ?? false;
  bool get needsOnboarding => !hasProfile;
  bool get isMatched => currentMatch.value != null;
  bool get isOptedIn => profile.value?.optedInForNextCycle ?? false;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    await _store.open();
    await reload();
    ready.value = true;
  }

  /// The signed-in user's stable backend id (empty when logged out / offline
  /// before the first /user/me — callers no-op safely on empty).
  String get _uid {
    if (!Get.isRegistered<UserInfoController>()) return '';
    return Get.find<UserInfoController>().userData.value?.id ?? '';
  }

  /// Public read of the current user's id for the UI's per-side match accessors.
  String get myUserId => _uid;

  UserDataModelLike get _me {
    final u = Get.isRegistered<UserInfoController>()
        ? Get.find<UserInfoController>().userData.value
        : null;
    final fullName = (u?.fullName ?? '').trim();
    final username = (u?.username ?? '').trim();
    final name = fullName.isNotEmpty
        ? fullName
        : (username.isNotEmpty ? username : 'You');
    return UserDataModelLike(name: name, avatar: u?.profile ?? '');
  }

  /// Re-read the profile + current match from disk and roll an expired cycle
  /// into "completed" so the rating prompt can surface.
  Future<void> reload() async {
    final uid = _uid;
    if (uid.isEmpty) {
      profile.value = null;
      currentMatch.value = null;
      return;
    }
    profile.value = _store.getProfile(uid);

    AccountabilityMatch? match;
    final mid = profile.value?.currentMatchId;
    if (mid != null && mid.isNotEmpty) match = _store.getMatch(mid);
    match ??= _store
        .matchesFor(uid)
        .firstWhereOrNull((m) => m.status == 'active');
    currentMatch.value = match;

    await _completeExpiredMatch();
    await _syncFromBackend();
    if (isMatched) {
      await loadCheckins();
      await syncMyGoals();
      await loadBuddyGoals();
    }
  }

  /// Push my goals so my buddy can see them (best-effort; skips an empty list so
  /// a freshly-created GoalsController never clears what I previously shared).
  Future<void> syncMyGoals() async {
    if (!Get.isRegistered<GoalsController>()) return;
    final gc = Get.find<GoalsController>();
    if (gc.goals.isEmpty) return;
    final list = gc.goals
        .map((g) => {
              'title': g.title,
              'emoji': g.emoji,
              'timeframe': g.timeframe,
              'progress': g.progress,
              'target': g.target,
              'done': g.completedAt != null,
            })
        .toList();
    await BuddiesApi.instance.syncGoals(list);
  }

  Future<void> loadBuddyGoals() async {
    buddyGoals.assignAll(await BuddiesApi.instance.getBuddyGoals());
  }

  // ── Daily Proof / shared streak ────────────────────────────────────────────
  /// The current user's local calendar day as yyyy-mm-dd (streaks are per-day).
  String todayDateString() {
    final n = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${n.year}-${two(n.month)}-${two(n.day)}';
  }

  Future<void> loadCheckins() async {
    final data = await BuddiesApi.instance.getCheckins();
    ourStreak.value = data.ourStreak;
    checkinDays.assignAll(data.days);
  }

  /// Today's day from the shared timeline (my + buddy proof), or null.
  CheckinDay? get today {
    final t = todayDateString();
    for (final d in checkinDays) {
      if (d.date == t) return d;
    }
    return null;
  }

  /// Check in for today (once), optionally with a proof photo URL + note.
  Future<void> checkInToday({String? proofUrl, String? note}) async {
    if (!isMatched) return;
    await BuddiesApi.instance
        .checkIn(date: todayDateString(), proofUrl: proofUrl, note: note);
    await loadCheckins();
    await _syncFromBackend(); // refresh the match's check-in counts (rating gate)
  }

  /// Review the buddy's proof for a day: verified (true) or "doesn't count".
  Future<void> verifyBuddyProof(String checkinId, bool verified) async {
    if (checkinId.isEmpty) return;
    await BuddiesApi.instance.verifyProof(checkinId, verified);
    await loadCheckins();
  }

  bool _isObjectId(String s) =>
      RegExp(r'^[a-f0-9]{24}$', caseSensitive: false).hasMatch(s);

  /// Best-effort backend pull: refreshes reputation stats and surfaces a match
  /// the weekly pairing job created (or one the buddy started). Never throws —
  /// a failed request just leaves the local state untouched.
  Future<void> _syncFromBackend() async {
    if (_uid.isEmpty) return;

    final bp = await BuddiesApi.instance.getProfile();
    final local = profile.value;
    if (bp != null && local != null) {
      final merged = local.copyWith(
        avgRating: (bp['avgRating'] as num?)?.toDouble() ?? local.avgRating,
        totalRatings:
            (bp['totalRatings'] as num?)?.toInt() ?? local.totalRatings,
        cyclesCompleted:
            (bp['cyclesCompleted'] as num?)?.toInt() ?? local.cyclesCompleted,
        currentMatchId: bp['currentMatchId'] as String?,
      );
      await _store.saveProfile(merged);
      profile.value = merged;
    }

    final bm = await BuddiesApi.instance.getMatch();
    if (bm != null && (bm['id']?.toString().isNotEmpty ?? false)) {
      try {
        final m = AccountabilityMatch.fromJson(bm);
        await _store.saveMatch(m);
        currentMatch.value = m;
        final p = profile.value;
        if (p != null && p.currentMatchId != m.id) {
          final up = p.copyWith(currentMatchId: m.id);
          await _store.saveProfile(up);
          profile.value = up;
        }
      } catch (_) {
        // ignore an unreadable payload — local state stands.
      }
    }
  }

  // ── Profile ────────────────────────────────────────────────────────────────
  /// Write the questionnaire answers, preserving the computed stats + any active
  /// match on an edit. Also stamps the user's current name/avatar so a buddy
  /// card can render them without a second lookup.
  Future<void> saveProfile(AccountabilityProfile answers) async {
    final uid = _uid;
    if (uid.isEmpty) return;
    final existing = profile.value;
    final me = _me;
    final merged = answers.copyWith(
      userId: uid,
      displayName: me.name,
      avatarUrl: me.avatar,
      avgRating: existing?.avgRating ?? 0.0,
      totalRatings: existing?.totalRatings ?? 0,
      cyclesCompleted: existing?.cyclesCompleted ?? 0,
      optedInForNextCycle: existing?.optedInForNextCycle ?? false,
      currentMatchId: existing?.currentMatchId,
      lastUpdated: DateTime.now(),
    );
    await _store.saveProfile(merged);
    profile.value = merged;
    BuddiesApi.instance.upsertProfile(merged.toJson());
  }

  Future<void> setOptIn(bool value) async {
    final p = profile.value;
    if (p == null) return;
    final updated = p.copyWith(
        optedInForNextCycle: value, lastUpdated: DateTime.now());
    await _store.saveProfile(updated);
    profile.value = updated;
    BuddiesApi.instance.setOptIn(value);
  }

  // ── Match lifecycle ──────────────────────────────────────────────────────
  /// Create a fresh 7-day pairing with a chosen buddy (Friends-based path, and
  /// the local test path). The current user is always side A.
  Future<AccountabilityMatch?> createMatchWithBuddy({
    required String buddyId,
    required String buddyName,
    String buddyAvatar = '',
    String buddyFocus = '',
    String buddyGoal = '',
    String buddyFunFact = '',
    double buddyRatingAvg = 0.0,
    int buddyCycles = 0,
  }) async {
    final uid = _uid;
    final me = profile.value;
    if (uid.isEmpty || me == null) return null;

    // A real friend → create the match on the backend so daily proof + Our
    // Streak sync to both phones. Falls back to a local match if that fails.
    if (_isObjectId(buddyId)) {
      final res = await BuddiesApi.instance.createFriendMatch(
          buddyId: buddyId, buddyName: buddyName, buddyAvatar: buddyAvatar);
      if (res != null && (res['id']?.toString().isNotEmpty ?? false)) {
        final m = AccountabilityMatch.fromJson(res);
        await _store.saveMatch(m);
        final up = me.copyWith(
            currentMatchId: m.id,
            optedInForNextCycle: false,
            lastUpdated: DateTime.now());
        await _store.saveProfile(up);
        profile.value = up;
        currentMatch.value = m;
        await loadCheckins();
        return m;
      }
    }

    final now = DateTime.now();
    final match = AccountabilityMatch(
      id: _newMatchId(uid),
      userAId: uid,
      userBId: buddyId,
      weekStartDate: now,
      weekEndDate: now.add(const Duration(days: 7)),
      status: 'active',
      userAName: me.displayName,
      userBName: buddyName,
      userAAvatar: me.avatarUrl,
      userBAvatar: buddyAvatar,
      userAFocus: me.focusArea,
      userBFocus: buddyFocus,
      userAGoal: me.monthlyGoal,
      userBGoal: buddyGoal,
      userAFunFact: me.funFact,
      userBFunFact: buddyFunFact,
      userARatingAvg: me.avgRating,
      userBRatingAvg: buddyRatingAvg,
      userACycles: me.cyclesCompleted,
      userBCycles: buddyCycles,
    );
    await _store.saveMatch(match);
    final updated = me.copyWith(
        currentMatchId: match.id,
        optedInForNextCycle: false,
        lastUpdated: now);
    await _store.saveProfile(updated);
    profile.value = updated;
    currentMatch.value = match;
    return match;
  }

  /// Tap-to-check-in — increments the current user's count toward the
  /// rating-unlock minimum.
  Future<void> logCheckIn() async {
    final m = currentMatch.value;
    final uid = _uid;
    if (m == null || uid.isEmpty) return;
    final updated = m.isA(uid)
        ? m.copyWith(checkInCountA: m.checkInCountA + 1)
        : m.copyWith(checkInCountB: m.checkInCountB + 1);
    await _store.saveMatch(updated);
    currentMatch.value = updated;
    BuddiesApi.instance.checkIn();
  }

  Future<void> requestExtend(bool value) async {
    final m = currentMatch.value;
    final uid = _uid;
    if (m == null || uid.isEmpty) return;
    final updated = m.isA(uid)
        ? m.copyWith(extendRequestedByA: value)
        : m.copyWith(extendRequestedByB: value);
    await _store.saveMatch(updated);
    currentMatch.value = updated;
    BuddiesApi.instance.requestExtend(value);
  }

  /// Submit the current user's 1–5 star rating of their buddy for this cycle.
  /// Locked after submit. Frees the user to be matched again next cycle.
  Future<void> submitRating(int stars, {String? comment}) async {
    final m = currentMatch.value;
    final uid = _uid;
    final p = profile.value;
    if (m == null || uid.isEmpty || p == null) return;
    if (!m.canRate(uid)) return; // guard: needs >= 2 check-ins, once only

    final now = DateTime.now();
    final rated = m.isA(uid)
        ? m.copyWith(
            userARating: stars, userARatedAt: now, userAComment: comment ?? '')
        : m.copyWith(
            userBRating: stars, userBRatedAt: now, userBComment: comment ?? '');
    await _store.saveMatch(rated);

    // Close out this cycle for me so I can opt back in.
    final freed = p.copyWith(currentMatchId: null, lastUpdated: now);
    await _store.saveProfile(freed);
    profile.value = freed;
    currentMatch.value = null;
    BuddiesApi.instance.rate(stars, comment ?? '');
  }

  /// Apply a rating this user RECEIVED from a buddy — recomputes the running
  /// average shown on their Profile "Buddies" stat. Called by the backend sync
  /// when a buddy rates them (and by the local test helper).
  Future<void> applyIncomingRating(int stars) async {
    final p = profile.value;
    if (p == null) return;
    final newAvg =
        ((p.avgRating * p.totalRatings) + stars) / (p.totalRatings + 1);
    final updated = p.copyWith(
      avgRating: double.parse(newAvg.toStringAsFixed(3)),
      totalRatings: p.totalRatings + 1,
      cyclesCompleted: p.cyclesCompleted + 1,
      lastUpdated: DateTime.now(),
    );
    await _store.saveProfile(updated);
    profile.value = updated;
  }

  /// Leave the current match without rating (e.g. a test match, or backing out).
  Future<void> leaveMatch() async {
    final p = profile.value;
    if (p == null) return;
    final updated = p.copyWith(currentMatchId: null, lastUpdated: DateTime.now());
    await _store.saveProfile(updated);
    profile.value = updated;
    currentMatch.value = null;
  }

  Future<void> _completeExpiredMatch() async {
    final m = currentMatch.value;
    if (m == null) return;
    if (m.status == 'active' && m.isOver) {
      final done = m.copyWith(status: 'completed');
      await _store.saveMatch(done);
      currentMatch.value = done;
    }
  }

  String _newMatchId(String uid) {
    final salt = uid.isEmpty ? 'x' : uid.hashCode.toRadixString(16);
    return 'm_${DateTime.now().millisecondsSinceEpoch}_$salt';
  }

  // ── Local testing ─────────────────────────────────────────────────────────
  /// Spin up a fake buddy so the Match + Rating screens can be exercised before
  /// a real second user exists (the spec's "fake a match locally" step).
  Future<void> debugCreateTestBuddy() async {
    await createMatchWithBuddy(
      buddyId: 'test_buddy',
      buddyName: 'Jordan (test)',
      buddyFocus: 'Fitness',
      buddyGoal: 'Run a 5K without stopping',
      buddyFunFact: 'Collects vintage sneakers 👟',
      buddyRatingAvg: 4.8,
      buddyCycles: 12,
    );
  }
}

/// Tiny value holder so the controller doesn't leak the app's UserDataModel
/// shape into every call site.
class UserDataModelLike {
  final String name;
  final String avatar;
  const UserDataModelLike({required this.name, required this.avatar});
}
