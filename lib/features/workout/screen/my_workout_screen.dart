import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../routes/app_routes.dart';
import '../controller/cardio_controller.dart';
import '../controller/workout_controller.dart';
import '../data/cardio_run.dart';
import '../data/exercise_library.dart';
import '../data/workout_models.dart';
import '../data/workout_theme.dart';
import '../widgets/workout_share_card.dart';
import 'cardio_tracking_screen.dart';

/// MY WORKOUT home — the dashboard reached from Quick Access.
class MyWorkoutScreen extends StatelessWidget {
  const MyWorkoutScreen({super.key});

  WorkoutController get c => WorkoutController.to;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WT.bg,
      body: SafeArea(
        child: Obx(() {
          if (!c.isReady) {
            return const Center(
                child: CircularProgressIndicator(color: WT.flame));
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _topBar()),
              SliverToBoxAdapter(child: _cardioResumeBanner()),
              SliverToBoxAdapter(child: _streakHeader()),
              if (c.hasActive)
                SliverToBoxAdapter(child: _resumeBanner()),
              SliverToBoxAdapter(child: _startSection()),
              SliverToBoxAdapter(child: _cardioSection()),
              SliverToBoxAdapter(child: _statsRow()),
              SliverToBoxAdapter(child: _heatmap()),
              SliverToBoxAdapter(child: _goalshareSection()),
              SliverToBoxAdapter(child: _runsSection()),
              SliverToBoxAdapter(child: _recentSection()),
              SliverToBoxAdapter(child: SizedBox(height: 40.h)),
            ],
          );
        }),
      ),
    );
  }

  // ------------------------------------------------------------------ top bar
  Widget _topBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 12.w, 4.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: Get.back,
            child: Icon(Icons.chevron_left, color: WT.textHi, size: 30.sp),
          ),
          SizedBox(width: 4.w),
          Text('MY WORKOUT',
              style: TextStyle(
                  color: WT.textHi,
                  fontWeight: FontWeight.w900,
                  fontSize: 20.sp,
                  letterSpacing: 1)),
          const Spacer(),
          GestureDetector(
            onTap: c.toggleUnit,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: WT.surfaceHi,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(c.unit.value.toUpperCase(),
                  style: TextStyle(
                      color: WT.textMid,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.sp)),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ streak header
  Widget _streakHeader() {
    final st = c.streak.value;
    final alive = c.streakAlive;
    return GestureDetector(
      onTap: () => showWorkoutShareDialog(
        eyebrow: 'On a roll',
        bigValue: '${st.current}',
        bigLabel: 'day streak',
        subtitle: 'Longest: ${st.longest} days · ${st.totalWorkouts} workouts',
        emoji: '🔥',
      ),
      child: Container(
        margin: EdgeInsets.fromLTRB(14.w, 6.h, 14.w, 6.h),
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: alive
                ? [const Color(0xFF221009), const Color(0xFF16161D)]
                : [WT.surface, WT.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
              color: alive ? WT.flame.withOpacity(0.4) : WT.stroke, width: 1.2),
        ),
        child: Row(
          children: [
            Text(alive ? '🔥' : '💤', style: TextStyle(fontSize: 46.sp)),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('${st.current}',
                          style: TextStyle(
                              color: WT.textHi,
                              fontWeight: FontWeight.w900,
                              fontSize: 44.sp,
                              height: 1)),
                      SizedBox(width: 6.w),
                      Padding(
                        padding: EdgeInsets.only(bottom: 6.h),
                        child: Text('DAY STREAK',
                            style: TextStyle(
                                color: WT.flame,
                                fontWeight: FontWeight.w800,
                                fontSize: 13.sp,
                                letterSpacing: 1)),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                      alive
                          ? (c.trainedToday
                              ? 'Locked in today. Beast. 💪'
                              : 'Train today to keep it alive.')
                          : 'Start a workout to light the flame.',
                      style: TextStyle(color: WT.textMid, fontSize: 12.5.sp)),
                  SizedBox(height: 10.h),
                  _weekDots(),
                ],
              ),
            ),
            Column(
              children: [
                Icon(Icons.emoji_events_rounded, color: WT.amber, size: 20.sp),
                SizedBox(height: 2.h),
                Text('${st.longest}',
                    style: TextStyle(
                        color: WT.textHi,
                        fontWeight: FontWeight.w900,
                        fontSize: 18.sp)),
                Text('best',
                    style: TextStyle(color: WT.textLow, fontSize: 10.sp)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _weekDots() {
    // Last 7 days; a dot lights if a workout landed that day.
    final now = DateTime.now();
    final trained = <String>{};
    for (final s in c.history) {
      final d = DateTime.fromMillisecondsSinceEpoch(s.startedAtMs);
      trained.add('${d.year}-${d.month}-${d.day}');
    }
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Row(
      children: List.generate(7, (i) {
        final day = now.subtract(Duration(days: 6 - i));
        final key = '${day.year}-${day.month}-${day.day}';
        final on = trained.contains(key);
        return Padding(
          padding: EdgeInsets.only(right: 8.w),
          child: Column(
            children: [
              Container(
                width: 18.w,
                height: 18.w,
                decoration: BoxDecoration(
                  gradient: on ? WT.flameGrad : null,
                  color: on ? null : WT.surfaceHi,
                  shape: BoxShape.circle,
                ),
                child: on
                    ? Icon(Icons.check, size: 11.sp, color: Colors.white)
                    : null,
              ),
              SizedBox(height: 3.h),
              Text(labels[day.weekday - 1],
                  style: TextStyle(color: WT.textLow, fontSize: 9.sp)),
            ],
          ),
        );
      }),
    );
  }

  // ------------------------------------------------------------ resume banner
  Widget _resumeBanner() {
    final s = c.active.value!;
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.activeWorkoutScreen),
      child: Container(
        margin: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 4.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          gradient: WT.flameGrad,
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Row(
          children: [
            const Icon(Icons.play_circle_fill, color: Colors.white),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Workout in progress',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15.sp)),
                  Text('${s.name} · ${s.totalSets} sets logged — tap to resume',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.9), fontSize: 12.sp)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ start section
  Widget _startSection() {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!c.hasActive)
            Row(
              children: [
                Expanded(
                  child: _bigBtn('START EMPTY', Icons.bolt, WT.flameGrad, () {
                    c.startEmpty();
                    Get.toNamed(AppRoutes.activeWorkoutScreen);
                  }),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _bigBtn(
                    'REPEAT LAST',
                    Icons.replay_rounded,
                    const LinearGradient(
                        colors: [Color(0xFF2A2A38), Color(0xFF1E1E29)]),
                    c.history.isEmpty
                        ? null
                        : () {
                            c.repeatLast();
                            Get.toNamed(AppRoutes.activeWorkoutScreen);
                          },
                  ),
                ),
              ],
            ),
          SizedBox(height: 16.h),
          _sectionTitle('Templates', 'Pick a split'),
          SizedBox(height: 10.h),
          SizedBox(
            height: 108.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ExerciseLibrary.templates.length,
              separatorBuilder: (_, __) => SizedBox(width: 10.w),
              itemBuilder: (_, i) {
                final t = ExerciseLibrary.templates[i];
                return _templateCard(t);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _bigBtn(
      String label, IconData icon, Gradient grad, VoidCallback? onTap) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.4 : 1,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            gradient: grad,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 24.sp),
              SizedBox(height: 6.h),
              Text(label,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.sp)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _templateCard(WorkoutTemplate t) {
    return GestureDetector(
      onTap: () {
        c.startFromTemplate(t);
        Get.toNamed(AppRoutes.activeWorkoutScreen);
      },
      child: Container(
        width: 150.w,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: WT.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: WT.stroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.emoji, style: TextStyle(fontSize: 24.sp)),
            const Spacer(),
            Text(t.name,
                style: TextStyle(
                    color: WT.textHi,
                    fontWeight: FontWeight.w900,
                    fontSize: 15.sp)),
            SizedBox(height: 2.h),
            Text(t.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: WT.textMid, fontSize: 11.sp)),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------- cardio resume banner
  /// Shows when a run/walk is tracking in the background so the user can leave
  /// this feature, use the rest of the app, and jump straight back in.
  Widget _cardioResumeBanner() {
    final cc = CardioController.to;
    return Obx(() {
      if (!cc.tracking.value) return const SizedBox.shrink();
      final miles = c.useMiles;
      final dist = (miles
              ? cc.distanceMeters.value / 1609.34
              : cc.distanceMeters.value / 1000)
          .toStringAsFixed(2);
      return GestureDetector(
        onTap: () => Get.to(() => CardioTrackingScreen(kind: cc.kind.value)),
        child: Container(
          margin: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 2.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            gradient: WT.voltGrad,
            borderRadius: BorderRadius.circular(18.r),
          ),
          child: Row(
            children: [
              const Icon(Icons.navigation_rounded, color: Colors.black),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${cc.emoji} ${cc.label} in progress${cc.paused.value ? ' · paused' : ''}',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 15.sp)),
                    Text(
                        '$dist ${miles ? 'mi' : 'km'} · ${formatDuration(cc.elapsedSec.value)} — tap to return',
                        style: TextStyle(
                            color: Colors.black.withOpacity(0.75),
                            fontSize: 12.sp)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black),
            ],
          ),
        ),
      );
    });
  }

  // -------------------------------------------------------------- cardio
  Widget _cardioSection() {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Run · Walk', 'GPS distance + live route map'),
          SizedBox(height: 10.h),
          Row(children: [
            Expanded(child: _cardioBtn('🏃', 'Start Run', 'run')),
            SizedBox(width: 10.w),
            Expanded(child: _cardioBtn('🚶', 'Start Walk', 'walk')),
          ]),
        ],
      ),
    );
  }

  Widget _cardioBtn(String emoji, String label, String kind) {
    return GestureDetector(
      onTap: () => Get.to(() => CardioTrackingScreen(kind: kind)),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: WT.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: WT.stroke),
        ),
        child: Column(children: [
          Text(emoji, style: TextStyle(fontSize: 26.sp)),
          SizedBox(height: 6.h),
          Text(label,
              style: TextStyle(
                  color: WT.textHi,
                  fontWeight: FontWeight.w900,
                  fontSize: 14.sp)),
        ]),
      ),
    );
  }

  Widget _runsSection() {
    if (c.runs.isEmpty) return const SizedBox.shrink();
    final miles = c.useMiles;
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 18.h, 14.w, 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Runs & Walks', '${c.runs.length} logged'),
          SizedBox(height: 10.h),
          // Every run/walk, newest first — tap any one to reopen its route map.
          ...c.runs.map((r) {
            final dist = (miles ? r.miles : r.km).toStringAsFixed(2);
            final pace =
                formatPace(miles ? r.paceSecPerMile : r.paceSecPerKm);
            return GestureDetector(
              onTap: () => Get.to(() => RunRouteViewer(run: r)),
              child: Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: WT.surface,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: WT.stroke),
                ),
                child: Row(
                  children: [
                    Text(r.emoji, style: TextStyle(fontSize: 22.sp)),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$dist ${miles ? 'mi' : 'km'} · ${r.label}',
                              style: TextStyle(
                                  color: WT.textHi,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.sp)),
                          Text(
                              '${_dateLabel(r.startedAt)} · ${formatDuration(r.movingSeconds)} · $pace ${miles ? '/mi' : '/km'}',
                              style: TextStyle(
                                  color: WT.textMid, fontSize: 11.5.sp)),
                        ],
                      ),
                    ),
                    Icon(Icons.map_outlined, color: WT.textMid, size: 18.sp),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // -------------------------------------------------------------- stats row
  Widget _statsRow() {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 4.h),
      child: Row(
        children: [
          _stat('${c.workoutsThisWeek}', 'this week', WT.flame),
          SizedBox(width: 10.w),
          _stat(_compact(c.volumeInLastDays(7)), '${c.unit.value} · 7d', WT.volt),
          SizedBox(width: 10.w),
          _stat('${c.totalPrs}', 'PRs', WT.amber),
        ],
      ),
    );
  }

  Widget _stat(String value, String label, Color accent) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: WT.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: WT.stroke),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 22.sp)),
            SizedBox(height: 2.h),
            Text(label,
                style: TextStyle(color: WT.textMid, fontSize: 11.sp)),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------- heatmap
  Widget _heatmap() {
    final data = c.muscleVolumeThisWeek();
    if (data.isEmpty) return const SizedBox.shrink();
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxV = entries.first.value <= 0 ? 1.0 : entries.first.value;
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 18.h, 14.w, 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Muscle Heatmap', 'Volume this week'),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: WT.surface,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: WT.stroke),
            ),
            child: Column(
              children: entries.take(6).map((e) {
                final pct = (e.value / maxV).clamp(0.05, 1.0);
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 5.h),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 74.w,
                        child: Text(e.key.label,
                            style: TextStyle(
                                color: WT.textMid,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600)),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 16.h,
                              decoration: BoxDecoration(
                                color: WT.surfaceHi,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: pct,
                              child: Container(
                                height: 16.h,
                                decoration: BoxDecoration(
                                  gradient: WT.flameGrad,
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(_compact(e.value),
                          style: TextStyle(
                              color: WT.textHi,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- Goalshare
  Widget _goalshareSection() {
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 18.h, 14.w, 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle('Goalshare', 'Chase it. Share it.'),
              const Spacer(),
              GestureDetector(
                onTap: _addGoalSheet,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: WT.surfaceHi,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text('+ New Goal',
                      style: TextStyle(
                          color: WT.flame,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.sp)),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          if (c.goals.isEmpty)
            _emptyGoals()
          else
            ...c.goals.map(_goalCard),
        ],
      ),
    );
  }

  Widget _emptyGoals() {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: WT.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: WT.stroke),
      ),
      child: Row(
        children: [
          Text('🎯', style: TextStyle(fontSize: 28.sp)),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
                'Set a target — a 315 bench, a 30-day streak — and share your progress card.',
                style: TextStyle(color: WT.textMid, fontSize: 12.5.sp)),
          ),
        ],
      ),
    );
  }

  Widget _goalCard(WorkoutGoal g) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: WT.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
            color: g.achieved ? WT.volt.withOpacity(0.5) : WT.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(g.title,
                    style: TextStyle(
                        color: WT.textHi,
                        fontWeight: FontWeight.w800,
                        fontSize: 15.sp)),
              ),
              if (g.achieved)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    gradient: WT.voltGrad,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text('DONE 🏆',
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 10.sp)),
                ),
              GestureDetector(
                onTap: () => _shareGoal(g),
                child: Padding(
                  padding: EdgeInsets.only(left: 10.w),
                  child: Icon(Icons.ios_share, color: WT.textMid, size: 18.sp),
                ),
              ),
              GestureDetector(
                onTap: () => c.deleteGoal(g.id),
                child: Padding(
                  padding: EdgeInsets.only(left: 10.w),
                  child: Icon(Icons.close, color: WT.textLow, size: 18.sp),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: LinearProgressIndicator(
              value: g.progress,
              minHeight: 10.h,
              backgroundColor: WT.surfaceHi,
              valueColor: AlwaysStoppedAnimation(
                  g.achieved ? WT.volt : WT.flame),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
              '${_fmt(g.current)} / ${_fmt(g.target)} ${g.unit}  ·  ${(g.progress * 100).round()}%',
              style: TextStyle(color: WT.textMid, fontSize: 12.sp)),
        ],
      ),
    );
  }

  void _shareGoal(WorkoutGoal g) {
    showWorkoutShareDialog(
      eyebrow: g.achieved ? 'Goal crushed' : 'Chasing',
      bigValue: _fmt(g.current),
      bigLabel: g.unit,
      subtitle: '${g.title} · ${(g.progress * 100).round()}% there',
      emoji: g.achieved ? '🏆' : '🎯',
      isPr: g.achieved,
    );
  }

  // --------------------------------------------------------------- recent
  Widget _recentSection() {
    if (c.history.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.fromLTRB(14.w, 18.h, 14.w, 4.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Recent Workouts', '${c.history.length} logged'),
          SizedBox(height: 10.h),
          ...c.history.take(8).map((s) {
            final d = s.startedAt;
            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: WT.surface,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: WT.stroke),
              ),
              child: Row(
                children: [
                  Text(s.emoji, style: TextStyle(fontSize: 22.sp)),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name,
                            style: TextStyle(
                                color: WT.textHi,
                                fontWeight: FontWeight.w800,
                                fontSize: 14.sp)),
                        Text(
                            '${_dateLabel(d)} · ${s.totalSets} sets · ${_compact(s.totalVolume)} ${c.unit.value}',
                            style:
                                TextStyle(color: WT.textMid, fontSize: 11.5.sp)),
                      ],
                    ),
                  ),
                  if (s.prCount > 0)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: WT.volt.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text('${s.prCount} PR',
                          style: TextStyle(
                              color: WT.volt,
                              fontWeight: FontWeight.w800,
                              fontSize: 11.sp)),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- goal sheet
  void _addGoalSheet() {
    final titleCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final type = GoalType.streak.obs;
    final exId = RxnString();

    String unitFor(GoalType t) {
      switch (t) {
        case GoalType.streak:
          return 'days';
        case GoalType.volume:
          return c.unit.value;
        case GoalType.lift1rm:
          return c.unit.value;
        case GoalType.bodyweight:
          return c.unit.value;
        case GoalType.reps:
          return 'reps';
        default:
          return '';
      }
    }

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(
            18.w, 16.h, 18.w, MediaQuery.of(Get.context!).viewInsets.bottom + 20.h),
        decoration: BoxDecoration(
          color: WT.surface,
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
                  decoration: BoxDecoration(
                      color: WT.stroke,
                      borderRadius: BorderRadius.circular(4.r))),
            ),
            SizedBox(height: 16.h),
            Text('New Goalshare goal',
                style: TextStyle(
                    color: WT.textHi,
                    fontWeight: FontWeight.w900,
                    fontSize: 18.sp)),
            SizedBox(height: 14.h),
            Obx(() => Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    GoalType.streak,
                    GoalType.lift1rm,
                    GoalType.volume,
                    GoalType.bodyweight,
                    GoalType.reps,
                    GoalType.custom,
                  ].map((t) {
                    final sel = type.value == t;
                    return GestureDetector(
                      onTap: () => type.value = t,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: sel ? WT.flame : WT.surfaceHi,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(t.label,
                            style: TextStyle(
                                color: sel ? Colors.white : WT.textMid,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.sp)),
                      ),
                    );
                  }).toList(),
                )),
            SizedBox(height: 14.h),
            Obx(() => type.value == GoalType.lift1rm
                ? Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: DropdownButtonFormField<String>(
                      value: exId.value,
                      dropdownColor: WT.surfaceHi,
                      isExpanded: true,
                      hint: Text('Choose lift',
                          style: TextStyle(color: WT.textLow)),
                      decoration: _fieldDecoration(),
                      style: TextStyle(color: WT.textHi, fontSize: 14.sp),
                      items: c.allExercises
                          .where((e) => !e.bodyweight && !e.timed)
                          .map((e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(e.name,
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (v) => exId.value = v,
                    ),
                  )
                : const SizedBox.shrink()),
            TextField(
              controller: titleCtrl,
              style: TextStyle(color: WT.textHi, fontSize: 15.sp),
              decoration: _fieldDecoration(hint: 'Goal name (e.g. 315 lb bench)'),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: targetCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: WT.textHi, fontSize: 15.sp),
              decoration: _fieldDecoration(hint: 'Target number'),
            ),
            SizedBox(height: 18.h),
            GestureDetector(
              onTap: () {
                final target = double.tryParse(targetCtrl.text.trim()) ?? 0;
                if (target <= 0) return;
                final title = titleCtrl.text.trim().isEmpty
                    ? type.value.label
                    : titleCtrl.text.trim();
                c.addGoal(WorkoutGoal(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  type: type.value,
                  title: title,
                  unit: unitFor(type.value),
                  target: target,
                  exerciseId: exId.value,
                  createdAtMs: DateTime.now().millisecondsSinceEpoch,
                ));
                Get.back();
              },
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                decoration: BoxDecoration(
                  gradient: WT.flameGrad,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Text('Create goal',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15.sp)),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  InputDecoration _fieldDecoration({String? hint}) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: WT.textLow, fontSize: 14.sp),
        filled: true,
        fillColor: WT.surfaceHi,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
      );

  // ----------------------------------------------------------------- helpers
  Widget _sectionTitle(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                color: WT.textHi,
                fontWeight: FontWeight.w900,
                fontSize: 17.sp)),
        Text(sub, style: TextStyle(color: WT.textMid, fontSize: 12.sp)),
      ],
    );
  }
}

String _fmt(num n) {
  if (n == n.roundToDouble()) return n.toInt().toString();
  return n.toStringAsFixed(1);
}

String _compact(num n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return _fmt(n);
}

String _dateLabel(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(d.year, d.month, d.day);
  final diff = today.difference(that).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return '$diff days ago';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[d.month - 1]} ${d.day}';
}
