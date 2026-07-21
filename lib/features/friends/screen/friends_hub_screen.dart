import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import '../controller/friends_controller.dart';

Color get _kRed => AppColors.primaryColor;
Color get _kRedDk => AppColors.primaryDarkColor;
const _kBg = Color(0xffF6F4F2);
const _kCard = Color(0xffFFFFFF);
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// Friends Hub — 3 tabs: Friends / Requests / Find People.
/// Friendships are mutual and consent-based (request → accept), backed by the
/// server so they work across phones — unlike follow, which is one-way.
class FriendsHubScreen extends StatelessWidget {
  FriendsHubScreen({super.key});

  final FriendsController c = FriendsController.to;

  @override
  Widget build(BuildContext context) {
    // Fresh data every time the hub is opened.
    c.refreshAll();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: _kRed,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: Get.back,
          ),
          title: Text('Friends',
              style: AppFonts.spaceGrotesk.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18.sp)),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_kRed, _kRedDk],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: AppFonts.spaceGrotesk.copyWith(
                fontSize: 13.sp, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Friends'),
              Tab(text: 'Requests'),
              Tab(text: 'Find People'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FriendsTab(c: c),
            _RequestsTab(c: c),
            _FindPeopleTab(c: c),
          ],
        ),
      ),
    );
  }
}

// ── shared row pieces ─────────────────────────────────────────────────────────

Widget _avatar(FriendUser u) {
  final hasPhoto = (u.profile ?? '').trim().isNotEmpty;
  final initials = u.name.trim().isEmpty
      ? 'U'
      : u.name
          .trim()
          .split(RegExp(r'\s+'))
          .take(2)
          .map((p) => p[0])
          .join()
          .toUpperCase();
  return Container(
    width: 44.r,
    height: 44.r,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: _kRed.withOpacity(0.12),
      image: hasPhoto
          ? DecorationImage(
              image: NetworkImage(u.profile!), fit: BoxFit.cover)
          : null,
    ),
    child: hasPhoto
        ? null
        : Center(
            child: Text(initials,
                style: AppFonts.spaceGrotesk.copyWith(
                    color: _kRed,
                    fontWeight: FontWeight.w800,
                    fontSize: 15.sp)),
          ),
  );
}

Widget _personCard({
  required FriendUser user,
  required Widget trailing,
  VoidCallback? onLongPress,
}) {
  return GestureDetector(
    onLongPress: onLongPress,
    child: Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          _avatar(user),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: _kText)),
                if ((user.username ?? '').isNotEmpty)
                  Text('@${user.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 11.sp, color: _kMuted)),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          trailing,
        ],
      ),
    ),
  );
}

Widget _pillButton(String label, VoidCallback onTap,
    {bool filled = true, Color? color}) {
  final c = color ?? _kRed;
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: filled ? c : c.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(label,
          style: AppFonts.spaceGrotesk.copyWith(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.white : c)),
    ),
  );
}

Widget _emptyState(IconData icon, String title, String sub) {
  return Center(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 44.r, color: _kMuted.withOpacity(0.6)),
          SizedBox(height: 12.h),
          Text(title,
              textAlign: TextAlign.center,
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: _kText)),
          SizedBox(height: 6.h),
          Text(sub,
              textAlign: TextAlign.center,
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 12.sp, color: _kMuted, height: 1.4)),
        ],
      ),
    ),
  );
}

Widget _sectionLabel(String text) => Padding(
      padding: EdgeInsets.only(bottom: 8.h, top: 4.h),
      child: Text(text,
          style: AppFonts.spaceGrotesk.copyWith(
              fontSize: 13.sp, fontWeight: FontWeight.w800, color: _kText)),
    );

// ── Tab 1: Friends ────────────────────────────────────────────────────────────

class _FriendsTab extends StatelessWidget {
  final FriendsController c;
  const _FriendsTab({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final list = c.friends;
      if (list.isEmpty) {
        return _emptyState(
            Icons.group_outlined,
            'No friends yet',
            'Head to Find People, search a name or @username, '
                'and send your first request.');
      }
      return RefreshIndicator(
        color: _kRed,
        onRefresh: c.refreshAll,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.r),
          children: [
            _sectionLabel('${list.length} friend${list.length == 1 ? '' : 's'}'),
            for (final f in list)
              _personCard(
                user: f,
                trailing: Icon(Icons.people_alt_rounded,
                    color: _kRed.withOpacity(0.5), size: 20.r),
                onLongPress: () => _confirmRemove(f),
              ),
            SizedBox(height: 6.h),
            Center(
              child: Text('Hold a friend to remove them',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 11.sp, color: _kMuted)),
            ),
          ],
        ),
      );
    });
  }

  void _confirmRemove(FriendUser f) {
    Get.dialog(AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
      title: Text('Remove ${f.name}?',
          style: AppFonts.spaceGrotesk.copyWith(
              fontWeight: FontWeight.w800, fontSize: 16.sp)),
      content: Text("You'll disappear from each other's friends lists.",
          style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp)),
      actions: [
        TextButton(
          onPressed: Get.back,
          child: Text('Cancel',
              style: AppFonts.spaceGrotesk.copyWith(color: _kMuted)),
        ),
        TextButton(
          onPressed: () {
            Get.back();
            c.removeFriend(f);
          },
          child: Text('Remove',
              style: AppFonts.spaceGrotesk.copyWith(
                  color: _kRed, fontWeight: FontWeight.w700)),
        ),
      ],
    ));
  }
}

// ── Tab 2: Requests ───────────────────────────────────────────────────────────

class _RequestsTab extends StatelessWidget {
  final FriendsController c;
  const _RequestsTab({required this.c});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final inc = c.incoming;
      final out = c.sent;
      if (inc.isEmpty && out.isEmpty) {
        return _emptyState(Icons.mark_email_unread_outlined, 'No requests',
            'Incoming and sent friend requests will show up here.');
      }
      return RefreshIndicator(
        color: _kRed,
        onRefresh: c.refreshAll,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.r),
          children: [
            if (inc.isNotEmpty) ...[
              _sectionLabel('Incoming (${inc.length})'),
              for (final r in inc)
                _personCard(
                  user: r.user,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _pillButton('Accept', () => c.accept(r)),
                      SizedBox(width: 6.w),
                      _pillButton('Decline', () => c.decline(r),
                          filled: false, color: _kMuted),
                    ],
                  ),
                ),
              SizedBox(height: 14.h),
            ],
            if (out.isNotEmpty) ...[
              _sectionLabel('Sent (${out.length})'),
              for (final r in out)
                _personCard(
                  user: r.user,
                  trailing: _pillButton('Cancel', () => c.cancel(r),
                      filled: false, color: _kMuted),
                ),
            ],
          ],
        ),
      );
    });
  }
}

// ── Tab 3: Find People ────────────────────────────────────────────────────────

class _FindPeopleTab extends StatefulWidget {
  final FriendsController c;
  const _FindPeopleTab({required this.c});

  @override
  State<_FindPeopleTab> createState() => _FindPeopleTabState();
}

class _FindPeopleTabState extends State<_FindPeopleTab> {
  final TextEditingController _searchC = TextEditingController();

  FriendsController get c => widget.c;

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16.r),
      children: [
        // Claim-your-handle banner — you can't be found without one.
        Obx(() {
          // Reactive off the profile so the banner disappears after claiming.
          final username = c.myUsername;
          if (username != null) {
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Text('Your handle: @$username',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 12.sp, color: _kMuted)),
            );
          }
          return GestureDetector(
            onTap: _claimUsernameSheet,
            child: Container(
              margin: EdgeInsets.only(bottom: 14.h),
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: _kRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: _kRed.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.alternate_email, color: _kRed, size: 20.r),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                        'Claim your @username so friends can find you — tap here.',
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: _kText,
                            height: 1.4)),
                  ),
                ],
              ),
            ),
          );
        }),

        // Search field
        Container(
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: TextField(
            controller: _searchC,
            onChanged: c.search,
            textInputAction: TextInputAction.search,
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 14.sp, color: _kText),
            decoration: InputDecoration(
              hintText: 'Search by name or @username',
              hintStyle: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 13.sp, color: _kMuted),
              prefixIcon: Icon(Icons.search, color: _kMuted, size: 20.r),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            ),
          ),
        ),
        SizedBox(height: 14.h),

        // Results
        Obx(() {
          if (c.isSearching.value) {
            return Padding(
              padding: EdgeInsets.only(top: 30.h),
              child: Center(
                  child: CircularProgressIndicator(color: _kRed)),
            );
          }
          final results = c.searchResults;
          if (results.isEmpty) {
            return Padding(
              padding: EdgeInsets.only(top: 40.h),
              child: _emptyState(
                  Icons.person_search_outlined,
                  'Find your people',
                  'Type at least 2 letters of a name or @username. '
                      'Anyone on GoalShare can be added.'),
            );
          }
          return Column(
            children: [
              for (final u in results)
                _personCard(user: u, trailing: _actionFor(u)),
            ],
          );
        }),
      ],
    );
  }

  Widget _actionFor(FriendUser u) {
    switch (c.relationTo(u)) {
      case 'friend':
        return _pillButton('Friends', () {}, filled: false,
            color: const Color(0xff22C55E));
      case 'sent':
        return _pillButton('Pending', () {}, filled: false, color: _kMuted);
      case 'incoming':
        // They already asked us — sending back = instant accept server-side.
        return _pillButton('Accept', () => c.sendRequest(u));
      default:
        return _pillButton('Add', () => c.sendRequest(u));
    }
  }

  void _claimUsernameSheet() {
    final nameC = TextEditingController();
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 14.h),
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r)),
              ),
            ),
            Text('Claim your username',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
            SizedBox(height: 6.h),
            Text('3–20 characters. Lowercase letters, numbers, _ and . only.',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 12.sp, color: _kMuted)),
            SizedBox(height: 14.h),
            Container(
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: TextField(
                controller: nameC,
                autofocus: true,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 15.sp, color: _kText),
                decoration: InputDecoration(
                  prefixText: '@',
                  hintText: 'yourname',
                  hintStyle: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 14.sp, color: _kMuted),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 13.h),
                ),
              ),
            ),
            SizedBox(height: 18.h),
            GestureDetector(
              onTap: () async {
                final ok = await c.claimUsername(nameC.text);
                if (ok) Get.back();
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_kRed, _kRedDk]),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Center(
                  child: Text('Claim it',
                      style: AppFonts.spaceGrotesk.copyWith(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}
