import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controller/workout_controller.dart';
import '../data/workout_models.dart';
import '../data/workout_theme.dart';
import 'exercise_progress_screen.dart';
import 'workout_detail_screen.dart';

/// Full workout history — every completed session, searchable by exercise, plus
/// a jump-off to per-exercise strength progress charts.
class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  final WorkoutController c = WorkoutController.to;
  String _q = '';

  List<WorkoutSession> get _filtered {
    final q = _q.trim().toLowerCase();
    if (q.isEmpty) return c.history.toList();
    return c.history.where((s) {
      if (s.name.toLowerCase().contains(q)) return true;
      return s.exercises.any((e) => e.name.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WT.bg,
      appBar: AppBar(
        backgroundColor: WT.bg,
        elevation: 0,
        foregroundColor: WT.textHi,
        title: Text('History & Progress',
            style: TextStyle(
                color: WT.textHi, fontWeight: FontWeight.w800, fontSize: 17.sp)),
      ),
      body: Obx(() {
        final list = _filtered;
        return ListView(
          padding: EdgeInsets.fromLTRB(14.w, 4.h, 14.w, 30.h),
          children: [
            GestureDetector(
              onTap: _openProgressPicker,
              child: Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                    gradient: WT.voltGrad,
                    borderRadius: BorderRadius.circular(18.r)),
                child: Row(
                  children: [
                    Icon(Icons.trending_up_rounded, color: Colors.black, size: 24.r),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Strength Progress',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15.sp)),
                          Text('See any lift\'s trend over time',
                              style: TextStyle(
                                  color: Colors.black.withOpacity(0.7),
                                  fontSize: 11.5.sp)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.black),
                  ],
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              decoration: BoxDecoration(
                  color: WT.surface,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: WT.stroke)),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: WT.textMid, size: 20.r),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _q = v),
                      style: TextStyle(color: WT.textHi, fontSize: 14.sp),
                      decoration: InputDecoration(
                        hintText: 'Search by exercise…',
                        hintStyle:
                            TextStyle(color: WT.textMid, fontSize: 13.sp),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            if (list.isEmpty)
              Padding(
                padding: EdgeInsets.only(top: 60.h),
                child: Center(
                  child: Text(
                      c.history.isEmpty
                          ? 'No workouts yet — finish one and it lands here.'
                          : 'No workouts match "$_q".',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: WT.textMid, fontSize: 13.sp)),
                ),
              )
            else
              ...list.map(_sessionCard),
          ],
        );
      }),
    );
  }

  Widget _sessionCard(WorkoutSession s) {
    return GestureDetector(
      onTap: () => Get.to(() => WorkoutDetailScreen(session: s)),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
            color: WT.surface,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: WT.stroke)),
        child: Row(
          children: [
            Text(s.emoji, style: TextStyle(fontSize: 22.sp)),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: WT.textHi,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.sp)),
                  SizedBox(height: 2.h),
                  Text(
                      '${DateFormat('EEE, MMM d').format(s.startedAt)} · '
                      '${s.totalSets} sets · ${s.totalVolume.round()} vol',
                      style: TextStyle(color: WT.textMid, fontSize: 11.sp)),
                ],
              ),
            ),
            if (s.prCount > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                    color: WT.volt.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20.r)),
                child: Text('${s.prCount} PR',
                    style: TextStyle(
                        color: WT.volt,
                        fontWeight: FontWeight.w800,
                        fontSize: 10.sp)),
              ),
          ],
        ),
      ),
    );
  }

  void _openProgressPicker() {
    final exercises = c.trainedExercises;
    if (exercises.isEmpty) {
      Get.rawSnackbar(
          message: 'Log a workout first, then track its progress.',
          duration: const Duration(seconds: 2));
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: WT.surface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pick an exercise',
                  style: TextStyle(
                      color: WT.textHi,
                      fontWeight: FontWeight.w800,
                      fontSize: 16.sp)),
              SizedBox(height: 12.h),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: exercises
                      .map((e) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(e.name,
                                style: TextStyle(
                                    color: WT.textHi,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15.sp)),
                            trailing: Icon(Icons.chevron_right_rounded,
                                color: WT.textMid, size: 20.r),
                            onTap: () {
                              Navigator.pop(context);
                              Get.to(() => ExerciseProgressScreen(
                                  exerciseId: e.id, name: e.name));
                            },
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
