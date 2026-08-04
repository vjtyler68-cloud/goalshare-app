import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';

import '../controller/buddies_controller.dart';
import '../data/accountability_match.dart';
import '../data/buddy_options.dart';
import 'buddy_rating_sheet.dart';
import 'daily_proof_card.dart';

const _kBg = Color(0xffF6F4F2);
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);
const _kStar = Color(0xffF5B301);

/// The active-cycle view: who your buddy is, how long is left, a supportive
/// question to open with, tap-to-check-in, request-to-extend, and — once the
/// cycle ends — the rating prompt.
class AccountabilityMatchScreen extends StatelessWidget {
  const AccountabilityMatchScreen({super.key});

  Color get _accent => AppColors.primaryColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back, color: _kText)),
        title: Text('Your Buddy',
            style: AppFonts.spaceGrotesk
                .copyWith(color: _kText, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: Obx(() {
        final c = BuddiesController.to;
        final m = c.currentMatch.value;
        if (m == null) return _empty();
        final uid = c.myUserId;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 30.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buddyHero(m, uid),
              SizedBox(height: 14.h),
              _statusRow(m),
              SizedBox(height: 14.h),
              _icebreaker(m, uid),
              SizedBox(height: 14.h),
              _buddyGoalsCard(c, uid),
              _promptCard(),
              SizedBox(height: 14.h),
              _ourStreakCard(c),
              SizedBox(height: 14.h),
              const DailyProofCard(),
              SizedBox(height: 14.h),
              if (m.status == 'completed' || m.isOver)
                _ratingCard(c, m, uid)
              else
                _extendCard(c, m, uid),
              SizedBox(height: 18.h),
              Center(
                child: TextButton(
                  onPressed: () => _confirmLeave(c),
                  child: Text('End this partnership',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: _kMuted)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ── Buddy hero ──────────────────────────────────────────────────────────────
  Widget _buddyHero(AccountabilityMatch m, String uid) {
    final name = m.buddyNameFor(uid);
    final avatar = m.buddyAvatarFor(uid);
    final avg = m.buddyRatingAvgFor(uid);
    final cycles = m.buddyCyclesFor(uid);
    final reliable = avg >= 4.5 && cycles >= 5;
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent, AppColors.primaryDarkColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          _avatar(avatar, name, 62.r),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isEmpty ? 'Your buddy' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.spaceGrotesk.copyWith(
                        color: Colors.white,
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    if (cycles > 0 || avg > 0) ...[
                      const Icon(Icons.star_rounded,
                          color: Colors.white, size: 16),
                      SizedBox(width: 3.w),
                      Text(avg > 0 ? avg.toStringAsFixed(1) : 'New',
                          style: AppFonts.spaceGrotesk.copyWith(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700)),
                      Text('  ·  $cycles ${cycles == 1 ? 'cycle' : 'cycles'}',
                          style: AppFonts.spaceGrotesk.copyWith(
                              color: Colors.white70, fontSize: 13.sp)),
                    ] else
                      Text('New buddy',
                          style: AppFonts.spaceGrotesk.copyWith(
                              color: Colors.white70, fontSize: 13.sp)),
                  ],
                ),
                if (reliable) ...[
                  SizedBox(height: 8.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text('Reliable Buddy 🤝',
                        style: AppFonts.spaceGrotesk.copyWith(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Status row ──────────────────────────────────────────────────────────────
  Widget _statusRow(AccountabilityMatch m) {
    final days = m.daysRemaining();
    final completed = m.status == 'completed' || m.isOver;
    final label = completed
        ? 'Cycle complete'
        : (days == 0 ? 'Last day!' : '$days ${days == 1 ? 'day' : 'days'} left');
    final icon = completed ? Icons.flag_rounded : Icons.timer_outlined;
    return Row(
      children: [
        _chip(icon, label, completed ? _kMuted : _accent),
        SizedBox(width: 8.w),
        if (m.bothWantExtend && !completed)
          _chip(Icons.autorenew_rounded, 'Extending', const Color(0xff10B981)),
      ],
    );
  }

  // ── Icebreaker ──────────────────────────────────────────────────────────────
  Widget _icebreaker(AccountabilityMatch m, String uid) {
    final focus = m.buddyFocusFor(uid);
    final goal = m.buddyGoalFor(uid);
    final fun = m.buddyFunFactFor(uid);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Get to know them'),
          if (focus.isNotEmpty) _kv('Focus', focus),
          if (goal.isNotEmpty) _kv('This month', goal),
          if (fun.isNotEmpty) _kv('Fun fact', fun),
          if (focus.isEmpty && goal.isEmpty && fun.isEmpty)
            Text('They haven\'t added details yet.',
                style: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 13.sp, color: _kMuted)),
        ],
      ),
    );
  }

  // ── Buddy's goals ────────────────────────────────────────────────────────────
  Widget _buddyGoalsCard(BuddiesController c, String uid) {
    final goals = c.buddyGoals;
    if (goals.isEmpty) return const SizedBox.shrink();
    final buddyFirst =
        (c.currentMatch.value?.buddyNameFor(uid) ?? 'Your buddy')
            .trim()
            .split(' ')
            .first;
    return Column(
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cardTitle("$buddyFirst's goals"),
              for (final g in goals) _goalRow(g),
            ],
          ),
        ),
        SizedBox(height: 14.h),
      ],
    );
  }

  Widget _goalRow(Map<String, dynamic> g) {
    final title = (g['title'] ?? '').toString();
    final emoji = (g['emoji'] ?? '🎯').toString();
    final done = g['done'] == true;
    final progress = (g['progress'] as num?)?.toInt() ?? 0;
    final target = (g['target'] as num?)?.toInt() ?? 0;
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 16.sp)),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: done ? _kMuted : _kText,
                    decoration: done ? TextDecoration.lineThrough : null)),
          ),
          SizedBox(width: 8.w),
          if (done)
            Icon(Icons.check_circle, color: const Color(0xff22C55E), size: 18.r)
          else if (target > 0)
            Text('$progress/$target',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: _accent)),
        ],
      ),
    );
  }

  // ── Supportive daily prompt ─────────────────────────────────────────────────
  Widget _promptCard() {
    final prompt = BuddyOptions.promptForDay(DateTime.now());
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _accent.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.forum_rounded, color: _accent, size: 18.r),
              SizedBox(width: 8.w),
              Text('Today\'s check-in question',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: _accent)),
            ],
          ),
          SizedBox(height: 8.h),
          Text(prompt,
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 15.sp,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                  color: _kText)),
        ],
      ),
    );
  }

  // ── Our Streak ──────────────────────────────────────────────────────────────
  Widget _ourStreakCard(BuddiesController c) {
    final streak = c.ourStreak.value;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent, AppColors.primaryDarkColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        children: [
          Text('🔥', style: TextStyle(fontSize: 34.sp)),
          SizedBox(width: 14.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$streak',
                  style: AppFonts.spaceGrotesk.copyWith(
                      color: Colors.white,
                      fontSize: 30.sp,
                      height: 1.0,
                      fontWeight: FontWeight.w900)),
              Text('${streak == 1 ? 'day' : 'days'} · Our Streak',
                  style: AppFonts.spaceGrotesk.copyWith(
                      color: Colors.white70,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 120.w,
            child: Text('Both of you check in daily to keep it alive.',
                textAlign: TextAlign.right,
                style: AppFonts.spaceGrotesk
                    .copyWith(color: Colors.white70, fontSize: 11.sp)),
          ),
        ],
      ),
    );
  }

  // ── Extend (during cycle) ───────────────────────────────────────────────────
  Widget _extendCard(
      BuddiesController c, AccountabilityMatch m, String uid) {
    final mine = m.extendRequestedByMe(uid);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Loving this match?'),
          Text(
              mine
                  ? (m.bothWantExtend
                      ? 'You both want to keep going — you\'ll stay paired next week!'
                      : 'You asked to extend. If your buddy does too, you\'ll stay paired.')
                  : 'Ask to stay paired beyond this week if it\'s a great fit.',
              style: AppFonts.spaceGrotesk
                  .copyWith(fontSize: 12.5.sp, color: _kMuted)),
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: () => c.requestExtend(!mine),
            child: Container(
              height: 48.h,
              decoration: BoxDecoration(
                color: mine ? _accent.withOpacity(0.12) : Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                    color: mine ? _accent : const Color(0xffE6E0DE),
                    width: 1.5),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(mine ? Icons.favorite : Icons.favorite_border,
                      color: _accent, size: 18.r),
                  SizedBox(width: 8.w),
                  Text(mine ? 'Extension requested' : 'Request to extend',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: _accent)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Rating (cycle over) ─────────────────────────────────────────────────────
  Widget _ratingCard(
      BuddiesController c, AccountabilityMatch m, String uid) {
    final alreadyRated = m.myRating(uid) != null;
    final canRate = m.canRate(uid);
    if (alreadyRated) {
      return _card(
        child: Row(
          children: [
            const Icon(Icons.verified_rounded, color: Color(0xff10B981)),
            SizedBox(width: 10.w),
            Expanded(
              child: Text('You rated ${m.buddyNameFor(uid)} — nice work this cycle!',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w700,
                      color: _kText)),
            ),
          ],
        ),
      );
    }
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Cycle complete 🎉'),
          Text(
              canRate
                  ? 'How was your accountability buddy this week?'
                  : 'Rating needs at least ${AccountabilityMatch.minCheckInsToRate} check-ins — you logged ${m.myCheckIns(uid)}.',
              style: AppFonts.spaceGrotesk
                  .copyWith(fontSize: 12.5.sp, color: _kMuted)),
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: canRate
                ? () => showBuddyRatingSheet(m.buddyNameFor(uid))
                : null,
            child: Container(
              height: 50.h,
              decoration: BoxDecoration(
                color: canRate ? _kStar : _kMuted.withOpacity(0.35),
                borderRadius: BorderRadius.circular(14.r),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, color: Colors.white),
                  SizedBox(width: 8.w),
                  Text('Rate your buddy',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bits ────────────────────────────────────────────────────────────────────
  void _confirmLeave(BuddiesController c) {
    Get.defaultDialog(
      title: 'End partnership?',
      middleText:
          'You\'ll leave this buddy and can get matched again. This can\'t be undone.',
      textConfirm: 'End',
      textCancel: 'Keep',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.primaryColor,
      onConfirm: () {
        Get.back();
        c.leaveMatch();
        Get.back();
      },
    );
  }

  Widget _empty() => Center(
        child: Padding(
          padding: EdgeInsets.all(28.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.handshake_outlined, size: 54.r, color: _kMuted),
              SizedBox(height: 12.h),
              Text('No active buddy right now.',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: _kText)),
            ],
          ),
        ),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
          ],
        ),
        child: child,
      );

  Widget _cardTitle(String t) => Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Text(t,
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 15.sp, fontWeight: FontWeight.w800, color: _kText)),
      );

  Widget _kv(String k, String v) => Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k.toUpperCase(),
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: _kMuted)),
            SizedBox(height: 2.h),
            Text(v,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: _kText)),
          ],
        ),
      );

  Widget _chip(IconData icon, String label, Color color) => Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15.r, color: color),
            SizedBox(width: 6.w),
            Text(label,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ],
        ),
      );

  Widget _avatar(String url, String name, double size) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: ClipOval(
        child: url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialFill(initial, size),
              )
            : _initialFill(initial, size),
      ),
    );
  }

  Widget _initialFill(String initial, double size) => Center(
        child: Text(initial,
            style: AppFonts.spaceGrotesk.copyWith(
                color: Colors.white,
                fontSize: size * 0.4,
                fontWeight: FontWeight.w800)),
      );
}
