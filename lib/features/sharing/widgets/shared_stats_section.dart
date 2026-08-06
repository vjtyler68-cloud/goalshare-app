import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';

import '../controller/sharing_controller.dart';
import '../data/shared_summary.dart';

const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// Renders whatever [userId] has chosen to share with the current user —
/// a nutrition and/or workout summary card. Shows nothing at all when they've
/// shared neither (so there's no hint the feature exists for non-granted views).
class SharedStatsSection extends StatefulWidget {
  final String userId;
  final String name;

  /// Vertical padding applied ONLY when there's something to show — so callers
  /// can space it like a normal card without leaving a gap when it's empty.
  final double topPad;
  final double bottomPad;
  const SharedStatsSection({
    super.key,
    required this.userId,
    this.name = '',
    this.topPad = 0,
    this.bottomPad = 0,
  });

  @override
  State<SharedStatsSection> createState() => _SharedStatsSectionState();
}

class _SharedStatsSectionState extends State<SharedStatsSection> {
  SharedStats _stats = const SharedStats();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await SharingController.to.statsFor(widget.userId);
    if (mounted) setState(() {
      _stats = s;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || !_stats.hasAny) return const SizedBox.shrink();
    final first = widget.name.trim().split(' ').first;
    final who = first.isEmpty ? 'They' : first;
    return Padding(
      padding: EdgeInsets.only(top: widget.topPad, bottom: widget.bottomPad),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 4.h),
        Row(
          children: [
            Icon(Icons.visibility_outlined,
                size: 16.r, color: AppColors.primaryColor),
            SizedBox(width: 6.w),
            Text('$who shared with you',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
          ],
        ),
        SizedBox(height: 12.h),
        if (_stats.nutrition != null) ...[
          _nutritionCard(_stats.nutrition!),
          SizedBox(height: 12.h),
        ],
        if (_stats.workout != null) _workoutCard(_stats.workout!),
      ],
      ),
    );
  }

  // ── Nutrition ───────────────────────────────────────────────────────────────
  Widget _nutritionCard(NutritionSummary n) {
    final proteinMode = n.trackingMode == 'protein' && n.proteinGoal != null;
    return _card(
      icon: Icons.restaurant_rounded,
      color: const Color(0xff22C55E),
      title: 'Nutrition today',
      updatedAtMs: n.updatedAtMs,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (proteinMode)
            _bigLine('${n.protein}g', 'of ${n.proteinGoal}g protein')
          else
            _bigLine('${n.calories}', 'of ${n.calorieBudget} cal'),
          SizedBox(height: 12.h),
          Row(
            children: [
              _macro('Protein', '${n.protein}g'),
              _macro('Carbs', '${n.carbs}g'),
              _macro('Fat', '${n.fat}g'),
            ],
          ),
        ],
      ),
    );
  }

  // ── Workout ─────────────────────────────────────────────────────────────────
  Widget _workoutCard(WorkoutSummary w) {
    final last = w.lastActivityDaysAgo == null
        ? 'No recent activity'
        : (w.lastActivityDaysAgo == 0
            ? '${w.lastActivity} today'
            : w.lastActivityDaysAgo == 1
                ? '${w.lastActivity} yesterday'
                : '${w.lastActivity} ${w.lastActivityDaysAgo}d ago');
    return _card(
      icon: Icons.fitness_center_rounded,
      color: const Color(0xffFF5A3C),
      title: 'Training',
      updatedAtMs: w.updatedAtMs,
      child: Row(
        children: [
          _stat('${w.currentStreak}', 'day streak', '🔥'),
          _stat('${w.workoutsThisWeek}', 'this week', '💪'),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LAST',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: _kMuted)),
                SizedBox(height: 2.h),
                Text(last,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: _kText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bits ────────────────────────────────────────────────────────────────────
  Widget _card({
    required IconData icon,
    required Color color,
    required String title,
    required int updatedAtMs,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30.r,
                height: 30.r,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 17.r),
              ),
              SizedBox(width: 10.w),
              Text(title,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: _kText)),
              const Spacer(),
              Text(_ago(updatedAtMs),
                  style: AppFonts.spaceGrotesk
                      .copyWith(fontSize: 10.5.sp, color: _kMuted)),
            ],
          ),
          SizedBox(height: 14.h),
          child,
        ],
      ),
    );
  }

  Widget _bigLine(String big, String rest) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(big,
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 30.sp, fontWeight: FontWeight.w900, color: _kText)),
        SizedBox(width: 6.w),
        Padding(
          padding: EdgeInsets.only(bottom: 3.h),
          child: Text(rest,
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 13.sp, fontWeight: FontWeight.w600, color: _kMuted)),
        ),
      ],
    );
  }

  Widget _macro(String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
            Text(label,
                style: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 11.sp, color: _kMuted)),
          ],
        ),
      );

  Widget _stat(String value, String label, String emoji) => Padding(
        padding: EdgeInsets.only(right: 18.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(value,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w900,
                      color: _kText)),
              SizedBox(width: 3.w),
              Text(emoji, style: TextStyle(fontSize: 13.sp)),
            ]),
            Text(label,
                style: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 11.sp, color: _kMuted)),
          ],
        ),
      );

  String _ago(int ms) {
    if (ms <= 0) return '';
    final diff = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(ms));
    if (diff.inMinutes < 60) return 'updated now';
    if (diff.inHours < 24) return 'updated ${diff.inHours}h ago';
    return 'updated ${diff.inDays}d ago';
  }
}
