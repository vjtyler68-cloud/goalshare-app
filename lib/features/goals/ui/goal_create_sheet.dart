import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';

import '../controller/goals_controller.dart';
import '../data/goal.dart';

const _kRed = Color(0xffE84040);
const _kRedDk = Color(0xff9B1414);
const _kBg = Color(0xffF6F4F2);
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

const List<String> _kEmojis = [
  '🎯', '🔥', '💪', '📞', '💰', '📚', '🏆', '⭐', '🚀', '🧠', '🙏', '🏃',
];

/// Light-weight bottom sheet to create OR edit a goal. Replaces the old
/// mission-centric "Create New Mission" dialog for the Goals tab.
class GoalCreateSheet extends StatefulWidget {
  const GoalCreateSheet({super.key, this.existing, this.presetTimeframe});

  final Goal? existing;
  final String? presetTimeframe;

  static Future<void> show({Goal? existing, String? presetTimeframe}) {
    return Get.bottomSheet(
      GoalCreateSheet(existing: existing, presetTimeframe: presetTimeframe),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<GoalCreateSheet> createState() => _GoalCreateSheetState();
}

class _GoalCreateSheetState extends State<GoalCreateSheet> {
  late final TextEditingController _titleCtrl;
  late String _emoji;
  late String _timeframe;
  late int _target;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    _titleCtrl = TextEditingController(text: g?.title ?? '');
    _emoji = g?.emoji ?? _kEmojis.first;
    _timeframe = g?.timeframe ??
        widget.presetTimeframe ??
        GoalsController.timeframes[1]; // default Weekly
    _target = g?.target ?? 1;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      AppSnackBar.error('Give your goal a name first');
      return;
    }
    HapticFeedback.mediumImpact();
    final c = Get.find<GoalsController>();
    if (_isEdit) {
      c.editGoal(
        widget.existing!.id,
        title: title,
        timeframe: _timeframe,
        target: _target,
        emoji: _emoji,
      );
    } else {
      c.addGoal(
        title: title,
        timeframe: _timeframe,
        target: _target,
        emoji: _emoji,
      );
    }
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h + bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // grab handle
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            Text(
              _isEdit ? 'Edit Goal' : 'New Goal',
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                color: _kText,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Keep it small and specific — you\'ll want to smash it.',
              style: AppFonts.spaceGrotesk.copyWith(fontSize: 11.sp, color: _kMuted),
            ),
            SizedBox(height: 16.h),

            // Title
            _label('What\'s the goal?'),
            SizedBox(height: 8.h),
            TextField(
              controller: _titleCtrl,
              autofocus: !_isEdit,
              textCapitalization: TextCapitalization.sentences,
              style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, color: _kText),
              decoration: InputDecoration(
                hintText: 'e.g. Get 3 closes',
                hintStyle: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, color: _kMuted),
                filled: true,
                fillColor: _kBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              ),
              onSubmitted: (_) => _save(),
            ),
            SizedBox(height: 18.h),

            // Emoji
            _label('Pick a vibe'),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: _kEmojis.map((e) {
                final sel = e == _emoji;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _emoji = e);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 42.r,
                    height: 42.r,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: sel ? _kRed.withOpacity(0.12) : _kBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: sel ? _kRed : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(e, style: TextStyle(fontSize: 18.sp)),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 18.h),

            // Timeframe
            _label('Timeframe'),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: GoalsController.timeframes.map((tf) {
                final sel = tf == _timeframe;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _timeframe = tf);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: sel ? _kRed : _kBg,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      tf,
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : _kMuted,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 18.h),

            // Target stepper
            _label('How many to win?'),
            SizedBox(height: 8.h),
            Row(
              children: [
                _stepBtn(Icons.remove, () {
                  if (_target > 1) {
                    HapticFeedback.selectionClick();
                    setState(() => _target--);
                  }
                }),
                Expanded(
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          '$_target',
                          style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.w800,
                            color: _kText,
                          ),
                        ),
                        Text(
                          _target == 1 ? 'just do it once' : 'times to complete',
                          style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 10.sp,
                            color: _kMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _stepBtn(Icons.add, () {
                  HapticFeedback.selectionClick();
                  setState(() => _target++);
                }),
              ],
            ),
            SizedBox(height: 24.h),

            // Save
            GestureDetector(
              onTap: _save,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_kRed, _kRedDk]),
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [
                    BoxShadow(
                      color: _kRed.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _isEdit ? 'Save Changes' : 'Add Goal',
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: AppFonts.spaceGrotesk.copyWith(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: _kText,
        ),
      );

  Widget _stepBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46.r,
          height: 46.r,
          decoration: BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: _kRed, size: 22.r),
        ),
      );
}
