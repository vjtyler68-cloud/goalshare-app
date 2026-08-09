import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/routes/app_routes.dart';

import '../controller/org_controller.dart';
import '../data/org_models.dart';

const _kBg = Color(0xffF6F4F2);
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// Post-signup step: "How are you using Goalshare?" Individual is the default
/// one-tap path (straight to profile setup); School / Sales / Gym branch into
/// join-or-create. Never blocks the individual user.
class OrgOnboardingScreen extends StatefulWidget {
  const OrgOnboardingScreen({super.key});

  @override
  State<OrgOnboardingScreen> createState() => _OrgOnboardingScreenState();
}

enum _Step { role, joinOrCreate, create, join, created }

class _OrgOnboardingScreenState extends State<OrgOnboardingScreen> {
  _Step _step = _Step.role;
  OrgType _type = OrgType.school;
  bool _busy = false;

  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  String _createdCode = '';

  Color get _accent => AppColors.primaryColor;

  /// Launched post-signup with a fullName String → continue into profile setup.
  /// Launched from Profile with {'fromProfile': true} → just pop back on finish.
  bool get _fromProfile {
    final a = Get.arguments;
    return a is Map && a['fromProfile'] == true;
  }

  String get _fullName {
    final a = Get.arguments;
    if (a is String) return a;
    if (a is Map) return (a['fullName'] ?? '').toString();
    return '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _continueToProfile() {
    if (_fromProfile) {
      Get.back();
    } else {
      Get.offNamed(AppRoutes.setUpProfileScreen, arguments: _fullName);
    }
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      AppSnackBar.error('Enter a name for your organization');
      return;
    }
    setState(() => _busy = true);
    final r = await OrgController.to.create(name, _type);
    setState(() => _busy = false);
    if (r.ok && r.org != null) {
      setState(() {
        _createdCode = r.org!.inviteCode;
        _step = _Step.created;
      });
    } else {
      AppSnackBar.error(r.message);
    }
  }

  Future<void> _join() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      AppSnackBar.error('Invite codes are 6 characters');
      return;
    }
    setState(() => _busy = true);
    final r = await OrgController.to.join(code);
    setState(() => _busy = false);
    if (r.ok) {
      AppSnackBar.success('You joined ${r.org?.name ?? 'the organization'}!');
      _continueToProfile();
    } else {
      AppSnackBar.error(r.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _body(),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    switch (_step) {
      case _Step.role:
        return _roleStep();
      case _Step.joinOrCreate:
        return _joinOrCreateStep();
      case _Step.create:
        return _createStep();
      case _Step.join:
        return _joinStep();
      case _Step.created:
        return _createdStep();
    }
  }

  // ── Step 1: role ────────────────────────────────────────────────────────────
  Widget _roleStep() {
    return SingleChildScrollView(
      key: const ValueKey('role'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8.h),
          Text('How are you using Goalshare?',
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 24.sp, fontWeight: FontWeight.w900, color: _kText)),
          SizedBox(height: 8.h),
          Text('Pick one — you can always change later.',
              style: AppFonts.spaceGrotesk
                  .copyWith(fontSize: 14.sp, color: _kMuted, height: 1.5)),
          SizedBox(height: 22.h),
          _roleCard(
            icon: Icons.person_rounded,
            title: 'Individual',
            subtitle: 'Just me. Fastest path — jump right in.',
            highlighted: true,
            onTap: _continueToProfile,
          ),
          SizedBox(height: 12.h),
          _roleCard(
            icon: Icons.school_rounded,
            title: 'School',
            subtitle: 'Students + a teacher/admin dashboard.',
            onTap: () => _pickType(OrgType.school),
          ),
          SizedBox(height: 12.h),
          _roleCard(
            icon: Icons.work_rounded,
            title: 'Sales Organization',
            subtitle: 'Reps + a manager dashboard.',
            onTap: () => _pickType(OrgType.salesOrg),
          ),
          SizedBox(height: 12.h),
          _roleCard(
            icon: Icons.fitness_center_rounded,
            title: 'Personal Training / Gym',
            subtitle: 'Trainer + trainees.',
            onTap: () => _pickType(OrgType.gym),
          ),
          SizedBox(height: 16.h),
          Center(
            child: TextButton(
              onPressed: _continueToProfile,
              child: Text('Skip for now',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: _kMuted)),
            ),
          ),
        ],
      ),
    );
  }

  void _pickType(OrgType t) => setState(() {
        _type = t;
        _step = _Step.joinOrCreate;
      });

  Widget _roleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    bool highlighted = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(18.r),
        decoration: BoxDecoration(
          color: highlighted ? _accent.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
              color: highlighted ? _accent : const Color(0xffEDE7E4),
              width: highlighted ? 1.8 : 1),
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
                  Row(
                    children: [
                      Text(title,
                          style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              color: _kText)),
                      if (highlighted) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                              color: _accent,
                              borderRadius: BorderRadius.circular(20.r)),
                          child: Text('Default',
                              style: AppFonts.spaceGrotesk.copyWith(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
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

  // ── Step 2: join or create ──────────────────────────────────────────────────
  Widget _joinOrCreateStep() {
    return Column(
      key: const ValueKey('joinOrCreate'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _backRow(() => setState(() => _step = _Step.role)),
        SizedBox(height: 8.h),
        Text('${_type.label}',
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 14.sp, fontWeight: FontWeight.w700, color: _accent)),
        SizedBox(height: 4.h),
        Text('Join or create?',
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 24.sp, fontWeight: FontWeight.w900, color: _kText)),
        SizedBox(height: 22.h),
        _roleCard(
          icon: Icons.add_business_rounded,
          title: _type.createLabel,
          subtitle: 'You become the ${_type.adminLabel.toLowerCase()} and get '
              'the dashboard.',
          onTap: () => setState(() => _step = _Step.create),
        ),
        SizedBox(height: 12.h),
        _roleCard(
          icon: Icons.login_rounded,
          title: _type.joinLabel,
          subtitle: 'Enter the code your ${_type.adminLabel.toLowerCase()} '
              'shared.',
          onTap: () => setState(() => _step = _Step.join),
        ),
      ],
    );
  }

  // ── Step 3a: create ─────────────────────────────────────────────────────────
  Widget _createStep() {
    return Column(
      key: const ValueKey('create'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _backRow(() => setState(() => _step = _Step.joinOrCreate)),
        SizedBox(height: 8.h),
        Text('Name your ${_type == OrgType.gym ? 'practice' : 'organization'}',
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 22.sp, fontWeight: FontWeight.w900, color: _kText)),
        SizedBox(height: 18.h),
        TextField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
          style: AppFonts.spaceGrotesk.copyWith(fontSize: 15.sp, color: _kText),
          decoration: InputDecoration(
            hintText: _type == OrgType.school
                ? 'e.g. Lincoln High — Coach Ray'
                : _type == OrgType.gym
                    ? 'e.g. Ray\'s Training'
                    : 'e.g. Apex Sales Team',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none),
          ),
        ),
        SizedBox(height: 22.h),
        _primaryBtn(_busy ? 'Creating…' : 'Create', _busy ? null : _create),
      ],
    );
  }

  // ── Step 3b: join ───────────────────────────────────────────────────────────
  Widget _joinStep() {
    return Column(
      key: const ValueKey('join'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _backRow(() => setState(() => _step = _Step.joinOrCreate)),
        SizedBox(height: 8.h),
        Text('Enter your invite code',
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 22.sp, fontWeight: FontWeight.w900, color: _kText)),
        SizedBox(height: 18.h),
        TextField(
          controller: _codeCtrl,
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          style: AppFonts.spaceGrotesk.copyWith(
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
              color: _kText),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            counterText: '',
            hintText: 'ABC123',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none),
          ),
        ),
        SizedBox(height: 22.h),
        _primaryBtn(_busy ? 'Joining…' : 'Join', _busy ? null : _join),
        SizedBox(height: 8.h),
        Center(
          child: TextButton(
            onPressed: _continueToProfile,
            child: Text('Skip for now',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: _kMuted)),
          ),
        ),
      ],
    );
  }

  // ── Step 4: created confirmation ────────────────────────────────────────────
  Widget _createdStep() {
    return Column(
      key: const ValueKey('created'),
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_rounded, color: _accent, size: 56.r),
        SizedBox(height: 16.h),
        Text('You\'re all set!',
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 24.sp, fontWeight: FontWeight.w900, color: _kText)),
        SizedBox(height: 8.h),
        Text('Share this code so your ${_type.memberLabel.toLowerCase()}s can '
            'join.',
            textAlign: TextAlign.center,
            style: AppFonts.spaceGrotesk
                .copyWith(fontSize: 14.sp, color: _kMuted, height: 1.5)),
        SizedBox(height: 20.h),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: _createdCode));
            AppSnackBar.success('Code copied');
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: _accent, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_createdCode,
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 30.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        color: _kText)),
                SizedBox(width: 12.w),
                Icon(Icons.copy_rounded, color: _accent, size: 22.r),
              ],
            ),
          ),
        ),
        SizedBox(height: 20.h),
        _primaryBtn('Share invite', () {
          final name = _nameCtrl.text.trim();
          SharePlus.instance.share(ShareParams(
              text: 'Join our $name on Goalshare: $_createdCode'));
        }),
        SizedBox(height: 12.h),
        TextButton(
          onPressed: _continueToProfile,
          child: Text('Continue',
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: _accent)),
        ),
      ],
    );
  }

  // ── Bits ────────────────────────────────────────────────────────────────────
  Widget _backRow(VoidCallback onTap) => GestureDetector(
        onTap: onTap,
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

  Widget _primaryBtn(String label, VoidCallback? onTap) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
            color: enabled ? _accent : _accent.withOpacity(0.4),
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
