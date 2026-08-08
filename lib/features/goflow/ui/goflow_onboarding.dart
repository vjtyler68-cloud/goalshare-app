import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/const/app_fonts.dart';
import '../../friends/controller/friends_controller.dart';
import '../controller/goflow_controller.dart';
import '../data/goflow_models.dart';

const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// First-run questionnaire. Splits immediately by role: the person whose cycle
/// it is gets a few setup questions; a supporting partner just picks who they
/// are following. Calls back into [GoFlowController] which flips `onboarded`,
/// so the parent swaps to the real layout.
class GoFlowOnboarding extends StatefulWidget {
  const GoFlowOnboarding({super.key});

  @override
  State<GoFlowOnboarding> createState() => _GoFlowOnboardingState();
}

enum _Step { role, selfQuestions, partnerPick }

class _GoFlowOnboardingState extends State<GoFlowOnboarding> {
  _Step _step = _Step.role;

  // Self answers.
  DateTime? _lastPeriod;
  int _cycleLen = 28;
  int _periodLen = 5;

  Color get _accent => GoFlowController.to.accentColor;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastPeriod ?? now.subtract(const Duration(days: 7)),
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked != null) setState(() => _lastPeriod = picked);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 30.h),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _body(),
      ),
    );
  }

  Widget _body() {
    switch (_step) {
      case _Step.role:
        return _roleStep();
      case _Step.selfQuestions:
        return _selfStep();
      case _Step.partnerPick:
        return _partnerStep();
    }
  }

  // ── Step 1: role ────────────────────────────────────────────────────────────
  Widget _roleStep() {
    return Column(
      key: const ValueKey('role'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10.h),
        Icon(Icons.spa_rounded, size: 40.r, color: _accent),
        SizedBox(height: 14.h),
        Text('Welcome to GoFlow',
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 24.sp, fontWeight: FontWeight.w900, color: _kText)),
        SizedBox(height: 8.h),
        Text('A private, on-device cycle companion. First — who is this for?',
            style: AppFonts.spaceGrotesk
                .copyWith(fontSize: 14.sp, color: _kMuted, height: 1.5)),
        SizedBox(height: 22.h),
        _roleCard(
          icon: Icons.favorite_rounded,
          title: "I'm tracking my cycle",
          subtitle: 'Log flow, mood and energy, see your phases, and predict '
              'your next period.',
          onTap: () => setState(() => _step = _Step.selfQuestions),
        ),
        SizedBox(height: 14.h),
        _roleCard(
          icon: Icons.volunteer_activism_rounded,
          title: "I'm supporting my partner",
          subtitle: 'A simple view of your partner\'s phase with ways to show '
              'up for them. No logging.',
          onTap: () => setState(() => _step = _Step.partnerPick),
        ),
      ],
    );
  }

  Widget _roleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(18.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: _accent.withOpacity(0.25), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46.r,
              height: 46.r,
              decoration: BoxDecoration(
                  color: _accent.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: _accent, size: 24.r),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: _kText)),
                  SizedBox(height: 4.h),
                  Text(subtitle,
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 12.sp, color: _kMuted, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2a: self questions ─────────────────────────────────────────────────
  Widget _selfStep() {
    return Column(
      key: const ValueKey('self'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _backRow(),
        SizedBox(height: 6.h),
        Text('A few quick questions',
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 22.sp, fontWeight: FontWeight.w900, color: _kText)),
        SizedBox(height: 6.h),
        Text('These help GoFlow predict and show your phase. You can change '
            'them anytime.',
            style: AppFonts.spaceGrotesk
                .copyWith(fontSize: 13.sp, color: _kMuted, height: 1.5)),
        SizedBox(height: 20.h),
        Text('When did your last period start?',
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 14.sp, fontWeight: FontWeight.w700, color: _kText)),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
            decoration: BoxDecoration(
                color: const Color(0xffF6F4F2),
                borderRadius: BorderRadius.circular(12.r)),
            child: Row(
              children: [
                Icon(Icons.event_rounded, size: 20.r, color: _accent),
                SizedBox(width: 12.w),
                Text(
                    _lastPeriod == null
                        ? 'Tap to choose a date'
                        : '${_lastPeriod!.month}/${_lastPeriod!.day}/${_lastPeriod!.year}',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: _lastPeriod == null ? _kMuted : _kText)),
              ],
            ),
          ),
        ),
        SizedBox(height: 20.h),
        _qStepper('Typical cycle length', '$_cycleLen days',
            () => setState(() => _cycleLen = (_cycleLen - 1).clamp(15, 60)),
            () => setState(() => _cycleLen = (_cycleLen + 1).clamp(15, 60))),
        SizedBox(height: 12.h),
        _qStepper('Typical period length', '$_periodLen days',
            () => setState(() => _periodLen = (_periodLen - 1).clamp(1, 14)),
            () => setState(() => _periodLen = (_periodLen + 1).clamp(1, 14))),
        SizedBox(height: 26.h),
        _primaryBtn('Start tracking', _lastPeriod == null
            ? null
            : () {
                GoFlowController.to.completeSelfOnboarding(
                  lastPeriodStart: _lastPeriod!,
                  cycleLength: _cycleLen,
                  periodLength: _periodLen,
                );
              }),
        if (_lastPeriod == null) ...[
          SizedBox(height: 8.h),
          Center(
            child: Text('Choose your last period date to continue',
                style: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 11.5.sp, color: _kMuted)),
          ),
        ],
      ],
    );
  }

  // ── Step 2b: partner pick ───────────────────────────────────────────────────
  Widget _partnerStep() {
    return Column(
      key: const ValueKey('partner'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _backRow(),
        SizedBox(height: 6.h),
        Text('Who are you supporting?',
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 22.sp, fontWeight: FontWeight.w900, color: _kText)),
        SizedBox(height: 6.h),
        Text('Pick your partner from your friends. You\'ll see their phase '
            'only if they choose to share GoFlow with you.',
            style: AppFonts.spaceGrotesk
                .copyWith(fontSize: 13.sp, color: _kMuted, height: 1.5)),
        SizedBox(height: 18.h),
        Obx(() {
          final friends = FriendsController.to.friends;
          if (friends.isEmpty) {
            return Container(
              width: double.infinity,
              padding: EdgeInsets.all(22.r),
              decoration: BoxDecoration(
                  color: const Color(0xffF6F4F2),
                  borderRadius: BorderRadius.circular(16.r)),
              child: Column(
                children: [
                  Icon(Icons.group_add_outlined, size: 32.r, color: _kMuted),
                  SizedBox(height: 8.h),
                  Text('Add your partner as a friend first',
                      textAlign: TextAlign.center,
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w700,
                          color: _kText)),
                  SizedBox(height: 4.h),
                  Text('Then come back and choose them here.',
                      textAlign: TextAlign.center,
                      style: AppFonts.spaceGrotesk
                          .copyWith(fontSize: 12.sp, color: _kMuted)),
                ],
              ),
            );
          }
          return Column(
            children: [
              for (final f in friends)
                GestureDetector(
                  onTap: () {
                    final c = GoFlowController.to;
                    c.setRole(GoFlowRole.partner);
                    c.setPartner(f.id, f.name);
                    c.completeOnboarding();
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 10.h),
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: const Color(0xffEDE7E4))),
                    child: Row(
                      children: [
                        Container(
                          width: 40.r,
                          height: 40.r,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _accent.withOpacity(0.12)),
                          child: Center(
                            child: Text(
                                f.name.trim().isEmpty
                                    ? '?'
                                    : f.name.trim()[0].toUpperCase(),
                                style: AppFonts.spaceGrotesk.copyWith(
                                    color: _accent,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                              f.name.isNotEmpty ? f.name : (f.username ?? 'Friend'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.spaceGrotesk.copyWith(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: _kText)),
                        ),
                        Icon(Icons.chevron_right, size: 20.r, color: _kMuted),
                      ],
                    ),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  // ── Bits ────────────────────────────────────────────────────────────────────
  Widget _backRow() => GestureDetector(
        onTap: () => setState(() => _step = _Step.role),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: Row(
            children: [
              Icon(Icons.arrow_back, size: 18.r, color: _kMuted),
              SizedBox(width: 6.w),
              Text('Back',
                  style: AppFonts.spaceGrotesk
                      .copyWith(fontSize: 13.sp, color: _kMuted)),
            ],
          ),
        ),
      );

  Widget _qStepper(
      String label, String value, VoidCallback minus, VoidCallback plus) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
          color: const Color(0xffF6F4F2),
          borderRadius: BorderRadius.circular(12.r)),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: _kText)),
          ),
          _circleBtn(Icons.remove, minus),
          SizedBox(width: 12.w),
          SizedBox(
            width: 62.w,
            child: Text(value,
                textAlign: TextAlign.center,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
          ),
          SizedBox(width: 12.w),
          _circleBtn(Icons.add, plus),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30.r,
          height: 30.r,
          decoration: BoxDecoration(color: _accent, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 17.r),
        ),
      );

  Widget _primaryBtn(String label, VoidCallback? onTap) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
            color: enabled ? _accent : _accent.withOpacity(0.35),
            borderRadius: BorderRadius.circular(30.r)),
        child: Center(
          child: Text(label,
              style: AppFonts.spaceGrotesk.copyWith(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}
