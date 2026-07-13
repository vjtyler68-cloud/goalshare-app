import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_fonts.dart';

import '../controller/goals_controller.dart';
import '../data/goal.dart';
import '../ui/goal_celebration.dart';
import '../ui/goal_create_sheet.dart';

// ─── Brand colours ───────────────────────────────────────────────────────────
const _kRed = Color(0xffE84040);
const _kRedDk = Color(0xff9B1414);
const _kGreen = Color(0xff22C55E);
const _kBg = Color(0xffF6F4F2);
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// The "My Goals" tab — a fun, local-first goal tracker. Tap a goal to rack up
/// progress, watch the bar fill, and get a confetti burst when you finish.
class GoalsScreen extends StatelessWidget {
  GoalsScreen({super.key});

  final GoalsController c = Get.find<GoalsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Obx(() {
        if (!c.isReady.value) {
          return const Center(child: CircularProgressIndicator(color: _kRed));
        }
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(c: c)),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 100.h),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    for (final tf in GoalsController.timeframes) ...[
                      _Section(c: c, timeframe: tf),
                      SizedBox(height: 18.h),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.c});
  final GoalsController c;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, top + 16.h, 20.w, 20.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kRed, _kRedDk],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Obx(() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily · Weekly · Monthly · Yearly',
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 11.sp,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'My Goals',
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 28.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  GoalCreateSheet.show();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, color: Colors.white, size: 18),
                      SizedBox(width: 4.w),
                      Text(
                        'New',
                        style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 14.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          // Stat pills
          Row(
            children: [
              _stat('${c.activeCount}', 'Active'),
              SizedBox(width: 10.w),
              _stat('${c.completedCount}', 'Completed'),
              SizedBox(width: 10.w),
              _stat('${c.totalCount}', 'Total'),
            ],
          ),
          if (c.totalCount > 0) ...[
            SizedBox(height: 16.h),
            _OverallBar(progress: c.overallProgress),
            SizedBox(height: 8.h),
            Text(
              _motivation(c),
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 11.sp,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      )),
    );
  }

  Widget _stat(String value, String label) => Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 22.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 10.sp,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ),
      );

  String _motivation(GoalsController c) {
    if (c.totalCount == 0) return 'Set your first goal and start winning.';
    if (c.completedCount == c.totalCount) return 'Every goal crushed. Legend. 🔥';
    final pct = (c.overallProgress * 100).round();
    if (pct == 0) return 'Tap a goal to log your first win.';
    if (pct < 50) return '$pct% there — keep the momentum going.';
    if (pct < 100) return '$pct% done. You\'re so close!';
    return 'Almost home — finish strong.';
  }
}

class _OverallBar extends StatelessWidget {
  const _OverallBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: SizedBox(
        height: 8,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          builder: (_, v, __) => LinearProgressIndicator(
            value: v,
            backgroundColor: Colors.white.withOpacity(0.25),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}

// ─── Section (one timeframe bucket) ──────────────────────────────────────────
class _Section extends StatelessWidget {
  const _Section({required this.c, required this.timeframe});
  final GoalsController c;
  final String timeframe;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final goals = c.byTimeframe(timeframe);
      return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              GoalsController.bucketLabel(timeframe),
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 17.sp,
                fontWeight: FontWeight.w800,
                color: _kText,
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: _kRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                '${goals.length}',
                style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: _kRed,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        if (goals.isEmpty)
          _EmptyCard(timeframe: timeframe)
        else
          ...goals.map((g) => _GoalCard(key: ValueKey(g.id), c: c, goal: g)),
      ],
      );
    });
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.timeframe});
  final String timeframe;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        GoalCreateSheet.show(presetTimeframe: timeframe);
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 22.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: _kRed.withOpacity(0.18)),
        ),
        child: Column(
          children: [
            Icon(Icons.add_circle_outline, color: _kRed.withOpacity(0.5), size: 26.r),
            SizedBox(height: 6.h),
            Text(
              'Add a ${timeframe.toLowerCase()} goal',
              style: AppFonts.spaceGrotesk.copyWith(fontSize: 12.sp, color: _kMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Goal card (tap to progress) ─────────────────────────────────────────────
class _GoalCard extends StatefulWidget {
  const _GoalCard({super.key, required this.c, required this.goal});
  final GoalsController c;
  final Goal goal;

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.0,
      upperBound: 0.06,
    );
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  Future<void> _onTapProgress() async {
    final g = widget.goal;
    if (g.isCompleted) return;
    _bounce.forward().then((_) => _bounce.reverse());
    final justDone = await widget.c.increment(g.id);
    if (justDone) {
      HapticFeedback.heavyImpact();
      GoalCelebration.show();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _menu() {
    final g = widget.goal;
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetItem(Icons.edit_outlined, 'Edit', () {
              Get.back();
              GoalCreateSheet.show(existing: g);
            }),
            if (g.progress > 0 && !g.isCompleted)
              _sheetItem(Icons.remove_circle_outline, 'Undo last (-1)', () {
                Get.back();
                widget.c.decrement(g.id);
              }),
            _sheetItem(
              g.isCompleted ? Icons.refresh : Icons.check_circle_outline,
              g.isCompleted ? 'Mark as not done' : 'Mark complete',
              () async {
                Get.back();
                final done = await widget.c.toggleComplete(g.id);
                if (done) {
                  HapticFeedback.heavyImpact();
                  GoalCelebration.show();
                }
              },
            ),
            _sheetItem(Icons.delete_outline, 'Delete', () {
              Get.back();
              widget.c.deleteGoal(g.id);
            }, danger: true),
          ],
        ),
      ),
    );
  }

  Widget _sheetItem(IconData icon, String label, VoidCallback onTap,
      {bool danger = false}) {
    final color = danger ? _kRed : _kText;
    return ListTile(
      leading: Icon(icon, color: color, size: 22.r),
      title: Text(
        label,
        style: AppFonts.spaceGrotesk.copyWith(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.goal;
    final done = g.isCompleted;
    return AnimatedBuilder(
      animation: _bounce,
      builder: (_, child) => Transform.scale(scale: 1 - _bounce.value, child: child),
      child: GestureDetector(
        onTap: _onTapProgress,
        onLongPress: _menu,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: done ? _kGreen.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: done ? _kGreen.withOpacity(0.4) : Colors.grey.shade200,
            ),
            boxShadow: done
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Emoji avatar
              Container(
                width: 44.r,
                height: 44.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: done ? _kGreen.withOpacity(0.15) : _kBg,
                  shape: BoxShape.circle,
                ),
                child: done
                    ? const Icon(Icons.check_rounded, color: _kGreen, size: 24)
                    : Text(g.emoji, style: TextStyle(fontSize: 20.sp)),
              ),
              SizedBox(width: 12.w),
              // Title + progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      g.title,
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: done ? _kMuted : _kText,
                        decoration: done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6.r),
                      child: SizedBox(
                        height: 6,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: g.fraction),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOut,
                          builder: (_, v, __) => LinearProgressIndicator(
                            value: v,
                            backgroundColor: _kMuted.withOpacity(0.15),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              done ? _kGreen : _kRed,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      done ? 'Done 🎉' : '${g.progress} of ${g.target}',
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 10.sp,
                        color: done ? _kGreen : _kMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // Trailing action
              if (done)
                GestureDetector(
                  onTap: _menu,
                  behavior: HitTestBehavior.opaque,
                  child: Icon(Icons.more_vert, color: _kMuted, size: 20.r),
                )
              else
                Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [_kRed, _kRedDk]),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 22),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
