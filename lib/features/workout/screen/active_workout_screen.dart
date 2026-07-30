import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../controller/workout_controller.dart';
import '../data/workout_models.dart';
import '../data/workout_theme.dart';
import '../widgets/workout_share_card.dart';

/// The low-friction Active Workout Logger.
class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  final WorkoutController c = WorkoutController.to;
  Worker? _celebWorker;

  @override
  void initState() {
    super.initState();
    // React to live PR / milestone signals raised deep in the controller.
    _celebWorker = ever(c.celebration, (String? kind) {
      if (kind == 'pr') {
        _flash('NEW PR! 🏆', 'You just beat your best. Screenshot-worthy.', WT.volt);
      } else if (kind == 'milestone') {
        _flash('🔥 ${c.milestoneValue.value}-DAY STREAK', 'Unstoppable. Keep it lit.',
            WT.flame);
      }
      c.clearCelebration();
    });
  }

  @override
  void dispose() {
    _celebWorker?.dispose();
    super.dispose();
  }

  void _flash(String title, String body, Color accent) {
    Get.rawSnackbar(
      messageText: Row(
        children: [
          Container(width: 4, height: 38, color: accent),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15.sp)),
                Text(body,
                    style: TextStyle(
                        color: WT.textMid, fontWeight: FontWeight.w600, fontSize: 12.sp)),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: WT.surfaceHi,
      borderColor: accent.withOpacity(0.5),
      borderWidth: 1.2,
      margin: EdgeInsets.all(12.w),
      borderRadius: 16.r,
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.TOP,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WT.bg,
      body: SafeArea(
        child: Obx(() {
          final s = c.active.value;
          if (s == null) {
            // Session was finished/discarded elsewhere — bounce home.
            WidgetsBinding.instance.addPostFrameCallback((_) => Get.back());
            return const SizedBox.shrink();
          }
          return Column(
            children: [
              _header(s),
              _RestBar(),
              Expanded(
                child: s.exercises.isEmpty
                    ? _emptyState()
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 120.h),
                        itemCount: s.exercises.length,
                        itemBuilder: (_, i) => _ExerciseCard(log: s.exercises[i]),
                      ),
              ),
            ],
          );
        }),
      ),
      floatingActionButton: Obx(() => c.active.value == null
          ? const SizedBox.shrink()
          : FloatingActionButton.extended(
              onPressed: _pickExercise,
              backgroundColor: WT.flame,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text('Add Exercise',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.sp)),
            )),
    );
  }

  Widget _header(WorkoutSession s) {
    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 18.h, 14.w, 12.h),
      decoration: const BoxDecoration(
        color: WT.surface,
        border: Border(bottom: BorderSide(color: WT.stroke)),
      ),
      child: Row(
        children: [
          _iconBtn(Icons.chevron_left, _confirmMinimise),
          SizedBox(width: 6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${s.emoji}  ${s.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: WT.textHi,
                        fontWeight: FontWeight.w900,
                        fontSize: 18.sp)),
                _ElapsedClock(startMs: s.startedAtMs),
              ],
            ),
          ),
          GestureDetector(
            onTap: _confirmFinish,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
              decoration: BoxDecoration(
                gradient: WT.voltGrad,
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Text('FINISH',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.sp,
                      letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38.w,
          height: 38.w,
          decoration: BoxDecoration(
            color: WT.surfaceHi,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: WT.textHi, size: 24.sp),
        ),
      );

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🏋️', style: TextStyle(fontSize: 56.sp)),
            SizedBox(height: 12.h),
            Text('Add your first exercise',
                style: TextStyle(
                    color: WT.textHi,
                    fontWeight: FontWeight.w800,
                    fontSize: 18.sp)),
            SizedBox(height: 6.h),
            Text('Tap “Add Exercise” to start logging. Your last numbers auto-fill.',
                textAlign: TextAlign.center,
                style: TextStyle(color: WT.textMid, fontSize: 13.sp)),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------- flows
  void _confirmMinimise() {
    // Leaving keeps the session alive (autosaved) — you can resume from home.
    Get.back();
  }

  void _confirmFinish() {
    final s = c.active.value;
    if (s == null) return;
    final vol = s.totalVolume;
    final sets = s.totalSets;
    Get.dialog(
      Dialog(
        backgroundColor: WT.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: EdgeInsets.all(22.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Finish workout?',
                  style: TextStyle(
                      color: WT.textHi,
                      fontWeight: FontWeight.w900,
                      fontSize: 19.sp)),
              SizedBox(height: 6.h),
              Text('$sets sets · ${_fmt(vol)} ${c.unit.value} total volume',
                  style: TextStyle(color: WT.textMid, fontSize: 13.sp)),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: _ghostBtn('Keep going', Get.back),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _solidBtn('Finish 💪', () {
                      Get.back(); // dialog
                      final streakBefore = c.streak.value.current;
                      c.finishWorkout();
                      Get.back(); // logger
                      _postFinishShare(streakBefore);
                    }),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              TextButton(
                onPressed: () {
                  Get.back();
                  _confirmDiscard();
                },
                child: Text('Discard workout',
                    style: TextStyle(color: WT.danger, fontSize: 13.sp)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _postFinishShare(int streakBefore) {
    final st = c.streak.value;
    // A satisfying green "completed" check first, then the share card.
    Get.dialog(
      Center(child: _completedCheckCard()),
      barrierColor: Colors.black54,
      barrierDismissible: false,
    );
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (Get.isDialogOpen ?? false) Get.back(); // close the check
      showWorkoutShareDialog(
        eyebrow: 'Workout complete',
        bigValue: '${st.current}',
        bigLabel: 'day streak',
        subtitle: 'Longest: ${st.longest} days · ${st.totalWorkouts} total workouts',
        emoji: '🔥',
      );
    });
  }

  Widget _completedCheckCard() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      tween: Tween(begin: 0.6, end: 1),
      builder: (_, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 34.w, vertical: 30.h),
        decoration: BoxDecoration(
          color: WT.surface,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: WT.volt.withOpacity(0.5), width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78.w,
              height: 78.w,
              decoration: BoxDecoration(
                  gradient: WT.voltGrad, shape: BoxShape.circle),
              child: Icon(Icons.check_rounded, color: Colors.black, size: 46.sp),
            ),
            SizedBox(height: 16.h),
            Text('Workout Complete!',
                style: TextStyle(
                    color: WT.textHi,
                    fontWeight: FontWeight.w900,
                    fontSize: 18.sp)),
            SizedBox(height: 4.h),
            Text('Saved to your history 💪',
                style: TextStyle(color: WT.textMid, fontSize: 13.sp)),
          ],
        ),
      ),
    );
  }

  void _confirmDiscard() {
    Get.dialog(
      Dialog(
        backgroundColor: WT.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: EdgeInsets.all(22.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Discard this workout?',
                  style: TextStyle(
                      color: WT.textHi,
                      fontWeight: FontWeight.w900,
                      fontSize: 18.sp)),
              SizedBox(height: 6.h),
              Text('Nothing will be saved. This can’t be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: WT.textMid, fontSize: 13.sp)),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(child: _ghostBtn('Cancel', Get.back)),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        c.discardWorkout();
                        Get.back(); // dialog
                        Get.back(); // logger
                      },
                      child: Container(
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                        decoration: BoxDecoration(
                          color: WT.danger,
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Text('Discard',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14.sp)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ghostBtn(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: 13.h),
          decoration: BoxDecoration(
            color: WT.surfaceHi,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Text(label,
              style: TextStyle(
                  color: WT.textHi, fontWeight: FontWeight.w700, fontSize: 14.sp)),
        ),
      );

  Widget _solidBtn(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: 13.h),
          decoration: BoxDecoration(
            gradient: WT.voltGrad,
            borderRadius: BorderRadius.circular(14.r),
          ),
          child: Text(label,
              style: TextStyle(
                  color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14.sp)),
        ),
      );

  // -------------------------------------------------------- exercise picker
  Future<void> _pickExercise() async {
    final searchCtrl = TextEditingController();
    final results = c.searchExercises('').obs;
    await Get.bottomSheet(
      Container(
        height: 0.82.sh,
        decoration: BoxDecoration(
          color: WT.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
        ),
        child: Column(
          children: [
            SizedBox(height: 10.h),
            Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                    color: WT.stroke, borderRadius: BorderRadius.circular(4.r))),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
              child: Row(
                children: [
                  Text('Add exercise',
                      style: TextStyle(
                          color: WT.textHi,
                          fontWeight: FontWeight.w900,
                          fontSize: 18.sp)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _createCustomExercise(),
                    child: Text('+ Custom',
                        style: TextStyle(
                            color: WT.flame,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.sp)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: TextField(
                controller: searchCtrl,
                style: TextStyle(color: WT.textHi, fontSize: 15.sp),
                onChanged: (v) => results.assignAll(c.searchExercises(v)),
                decoration: InputDecoration(
                  hintText: 'Search 40+ exercises…',
                  hintStyle: TextStyle(color: WT.textLow, fontSize: 14.sp),
                  prefixIcon: const Icon(Icons.search, color: WT.textMid),
                  filled: true,
                  fillColor: WT.surfaceHi,
                  contentPadding: EdgeInsets.symmetric(vertical: 4.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(height: 6.h),
            Expanded(
              child: Obx(() => ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    itemCount: results.length,
                    itemBuilder: (_, i) {
                      final ex = results[i];
                      return ListTile(
                        onTap: () {
                          c.addExerciseToActive(ex);
                          Get.back();
                        },
                        leading: Container(
                          width: 10.w,
                          height: 10.w,
                          decoration: BoxDecoration(
                            color: WT.setTypeColor('working'),
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(ex.name,
                            style: TextStyle(
                                color: WT.textHi,
                                fontWeight: FontWeight.w700,
                                fontSize: 15.sp)),
                        subtitle: Text(
                            '${ex.primary.label}${ex.bodyweight ? ' · Bodyweight' : ''}',
                            style: TextStyle(color: WT.textMid, fontSize: 12.sp)),
                        trailing: const Icon(Icons.add_circle_outline,
                            color: WT.flame),
                      );
                    },
                  )),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> _createCustomExercise() async {
    final nameCtrl = TextEditingController();
    final muscle = MuscleGroup.chest.obs;
    await Get.dialog(Dialog(
      backgroundColor: WT.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('New exercise',
                style: TextStyle(
                    color: WT.textHi,
                    fontWeight: FontWeight.w900,
                    fontSize: 18.sp)),
            SizedBox(height: 14.h),
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: WT.textHi, fontSize: 15.sp),
              decoration: InputDecoration(
                hintText: 'Exercise name',
                hintStyle: TextStyle(color: WT.textLow),
                filled: true,
                fillColor: WT.surfaceHi,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none),
              ),
            ),
            SizedBox(height: 12.h),
            Obx(() => Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: MuscleGroup.values
                      .where((m) => m != MuscleGroup.fullBody && m != MuscleGroup.other)
                      .map((m) => GestureDetector(
                            onTap: () => muscle.value = m,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 7.h),
                              decoration: BoxDecoration(
                                color: muscle.value == m
                                    ? WT.flame
                                    : WT.surfaceHi,
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(m.label,
                                  style: TextStyle(
                                      color: muscle.value == m
                                          ? Colors.white
                                          : WT.textMid,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ))
                      .toList(),
                )),
            SizedBox(height: 18.h),
            Row(
              children: [
                Expanded(child: _ghostBtn('Cancel', Get.back)),
                SizedBox(width: 12.w),
                Expanded(
                  child: _solidBtn('Add', () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final ex = await c.createCustomExercise(
                        nameCtrl.text.trim(), muscle.value);
                    c.addExerciseToActive(ex);
                    Get.back(); // dialog
                    Get.back(); // picker
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }
}

String _fmt(num n) {
  if (n == n.roundToDouble()) return n.toInt().toString();
  return n.toStringAsFixed(1);
}

// --------------------------------------------------------------- elapsed clock
class _ElapsedClock extends StatefulWidget {
  final int startMs;
  const _ElapsedClock({required this.startMs});

  @override
  State<_ElapsedClock> createState() => _ElapsedClockState();
}

class _ElapsedClockState extends State<_ElapsedClock> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final secs =
        (DateTime.now().millisecondsSinceEpoch - widget.startMs) ~/ 1000;
    final h = secs ~/ 3600;
    final m = (secs % 3600) ~/ 60;
    final s = secs % 60;
    final txt = h > 0
        ? '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '$m:${s.toString().padLeft(2, '0')}';
    return Row(
      children: [
        const Icon(Icons.timer_outlined, size: 13, color: WT.textMid),
        SizedBox(width: 4.w),
        Text(txt,
            style: TextStyle(
                color: WT.textMid,
                fontWeight: FontWeight.w700,
                fontSize: 12.sp,
                fontFeatures: const [FontFeature.tabularFigures()])),
      ],
    );
  }
}

// ------------------------------------------------------------------ rest bar
class _RestBar extends StatelessWidget {
  final WorkoutController c = WorkoutController.to;

  _RestBar();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final rem = c.restRemaining.value;
      if (rem <= 0) return const SizedBox.shrink();
      final total = c.restTotal.value.clamp(1, 100000);
      final progress = rem / total;
      final m = rem ~/ 60;
      final s = rem % 60;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: const BoxDecoration(
          color: WT.surfaceHi,
          border: Border(bottom: BorderSide(color: WT.stroke)),
        ),
        child: Row(
          children: [
            Text('RESTING',
                style: TextStyle(
                    color: WT.flame,
                    fontWeight: FontWeight.w900,
                    fontSize: 11.sp,
                    letterSpacing: 1.5)),
            SizedBox(width: 12.w),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6.r),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8.h,
                  backgroundColor: WT.stroke,
                  valueColor: const AlwaysStoppedAnimation(WT.flame),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Text('$m:${s.toString().padLeft(2, '0')}',
                style: TextStyle(
                    color: WT.textHi,
                    fontWeight: FontWeight.w900,
                    fontSize: 16.sp,
                    fontFeatures: const [FontFeature.tabularFigures()])),
            SizedBox(width: 10.w),
            _miniBtn('+15', () => c.addRest(15)),
            SizedBox(width: 6.w),
            _miniBtn('Skip', c.skipRest),
          ],
        ),
      );
    });
  }

  Widget _miniBtn(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: WT.surface,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(color: WT.stroke),
          ),
          child: Text(label,
              style: TextStyle(
                  color: WT.textHi, fontWeight: FontWeight.w800, fontSize: 12.sp)),
        ),
      );
}

// -------------------------------------------------------------- exercise card
class _ExerciseCard extends StatelessWidget {
  final ExerciseLog log;
  final WorkoutController c = WorkoutController.to;

  _ExerciseCard({required this.log});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      decoration: BoxDecoration(
        color: WT.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: WT.stroke),
      ),
      child: Column(
        children: [
          // header
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 6.w, 6.h),
            child: Row(
              children: [
                Container(
                  width: 8.w,
                  height: 26.h,
                  decoration: BoxDecoration(
                    gradient: WT.flameGrad,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(log.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: WT.textHi,
                              fontWeight: FontWeight.w900,
                              fontSize: 16.sp)),
                      Text(log.muscle.label,
                          style: TextStyle(color: WT.textMid, fontSize: 11.sp)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: WT.textMid),
                  onPressed: () => _menu(context),
                ),
              ],
            ),
          ),
          // column labels
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Row(
              children: [
                _hLabel('SET', 34.w),
                _hLabel('PREV', 62.w),
                Expanded(child: _hLabel(c.unit.value.toUpperCase(), null)),
                Expanded(child: _hLabel('REPS', null)),
                _hLabel('RPE', 42.w),
                SizedBox(width: 48.w, child: _hLabel('', null)),
              ],
            ),
          ),
          SizedBox(height: 4.h),
          // sets
          ...log.sets.map((s) => _SetRow(log: log, set: s)),
          // add set
          Padding(
            padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 12.h),
            child: GestureDetector(
              onTap: () => c.addSet(log),
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(vertical: 11.h),
                decoration: BoxDecoration(
                  color: WT.surfaceHi,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text('+ Add Set',
                    style: TextStyle(
                        color: WT.textHi,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.sp)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hLabel(String t, double? w) => SizedBox(
        width: w,
        child: Text(t,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: WT.textLow,
                fontWeight: FontWeight.w800,
                fontSize: 10.sp,
                letterSpacing: 0.5)),
      );

  void _menu(BuildContext context) {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: WT.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: WT.danger),
              title: Text('Remove exercise',
                  style: TextStyle(color: WT.textHi, fontSize: 15.sp)),
              onTap: () {
                c.removeExercise(log);
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------- set row
class _SetRow extends StatefulWidget {
  final ExerciseLog log;
  final SetEntry set;
  const _SetRow({required this.log, required this.set});

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  final WorkoutController c = WorkoutController.to;
  late final TextEditingController _w;
  late final TextEditingController _r;

  @override
  void initState() {
    super.initState();
    _w = TextEditingController(
        text: widget.set.weight == null ? '' : _fmt(widget.set.weight!));
    _r = TextEditingController(
        text: widget.set.reps == null ? '' : widget.set.reps.toString());
  }

  @override
  void dispose() {
    _w.dispose();
    _r.dispose();
    super.dispose();
  }

  int _setNumber() {
    // Position among working+ sets (warmups shown as "W").
    if (widget.set.type == SetType.warmup) return 0;
    var n = 0;
    for (final s in widget.log.sets) {
      if (s.type != SetType.warmup) {
        n++;
        if (identical(s, widget.set)) return n;
      }
    }
    return n;
  }

  @override
  Widget build(BuildContext context) {
    final set = widget.set;
    final prev = c.previousPerformance(widget.log.exerciseId);
    final idx = widget.log.sets.where((s) => s.type != SetType.warmup).toList().indexOf(set);
    final prevText = (idx >= 0 && idx < prev.length)
        ? '${_fmt(prev[idx].weight ?? 0)}×${prev[idx].reps ?? 0}'
        : '—';
    final done = set.done;
    final typeColor = WT.setTypeColor(set.type.id);

    return Dismissible(
      key: ValueKey(set.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: WT.danger.withOpacity(0.85),
        padding: EdgeInsets.only(right: 20.w),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => c.removeSet(widget.log, set),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: done ? WT.volt.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
          border: set.isPr
              ? Border.all(color: WT.volt.withOpacity(0.6))
              : null,
        ),
        child: Row(
          children: [
            // set number / type
            GestureDetector(
              onTap: _pickType,
              child: SizedBox(
                width: 34.w,
                child: Center(
                  child: Container(
                    width: 26.w,
                    height: 26.w,
                    decoration: BoxDecoration(
                      color: set.type == SetType.working
                          ? WT.surfaceHi
                          : typeColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: Text(
                        set.type == SetType.working
                            ? '${_setNumber()}'
                            : set.type.short,
                        style: TextStyle(
                            color: set.type == SetType.working
                                ? WT.textHi
                                : typeColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 12.sp),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // prev
            SizedBox(
              width: 62.w,
              child: Text(prevText,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: WT.textLow, fontSize: 12.sp)),
            ),
            // weight
            Expanded(child: _numField(_w, done, (v) {
              c.updateSet(widget.log, set, weight: double.tryParse(v) ?? 0);
            })),
            SizedBox(width: 6.w),
            // reps
            Expanded(child: _numField(_r, done, (v) {
              c.updateSet(widget.log, set, reps: int.tryParse(v) ?? 0);
            }, isInt: true)),
            SizedBox(width: 6.w),
            // rpe
            GestureDetector(
              onTap: _cycleRpe,
              child: SizedBox(
                width: 42.w,
                child: Center(
                  child: Text(
                    set.rpe == null ? '–' : _fmt(set.rpe!),
                    style: TextStyle(
                        color: set.rpe == null ? WT.textLow : WT.amber,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.sp),
                  ),
                ),
              ),
            ),
            // BIG checkmark
            GestureDetector(
              onTap: () => c.toggleSetDone(widget.log, set),
              child: Container(
                width: 46.w,
                height: 40.h,
                margin: EdgeInsets.only(left: 2.w),
                decoration: BoxDecoration(
                  gradient: done ? WT.voltGrad : null,
                  color: done ? null : WT.surfaceHi,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.check_rounded,
                    color: done ? Colors.black : WT.textLow, size: 24.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numField(TextEditingController ctrl, bool done, ValueChanged<String> onCh,
      {bool isInt = false}) {
    return TextField(
      controller: ctrl,
      onChanged: onCh,
      keyboardType: TextInputType.numberWithOptions(decimal: !isInt),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(isInt ? r'[0-9]' : r'[0-9.]')),
      ],
      textAlign: TextAlign.center,
      style: TextStyle(
          color: WT.textHi, fontWeight: FontWeight.w800, fontSize: 16.sp),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 10.h),
        hintText: '0',
        hintStyle: TextStyle(color: WT.textLow, fontSize: 15.sp),
        filled: true,
        fillColor: done ? WT.volt.withOpacity(0.08) : WT.surfaceHi,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _cycleRpe() {
    const seq = [null, 6.0, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0];
    final cur = widget.set.rpe;
    var i = seq.indexOf(cur);
    i = (i + 1) % seq.length;
    setState(() {});
    c.updateSet(widget.log, widget.set, rpe: seq[i]);
    widget.set.rpe = seq[i];
  }

  void _pickType() {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: WT.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: SetType.values.map((t) {
            return ListTile(
              leading: Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                    color: WT.setTypeColor(t.id), shape: BoxShape.circle),
              ),
              title: Text(t.label,
                  style: TextStyle(color: WT.textHi, fontSize: 15.sp)),
              onTap: () {
                c.updateSet(widget.log, widget.set, type: t);
                setState(() {});
                Get.back();
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
