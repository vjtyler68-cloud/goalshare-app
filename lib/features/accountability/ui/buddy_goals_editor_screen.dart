import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';

import '../controller/buddies_controller.dart';

const _kBg = Color(0xffF6F4F2);
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// Pick up to 5 specific goals you want your buddy to hold you accountable to.
class BuddyGoalsEditorScreen extends StatefulWidget {
  const BuddyGoalsEditorScreen({super.key});

  @override
  State<BuddyGoalsEditorScreen> createState() => _BuddyGoalsEditorScreenState();
}

class _BuddyGoalsEditorScreenState extends State<BuddyGoalsEditorScreen> {
  static const _max = 5;
  final List<TextEditingController> _fields = [];

  Color get _accent => AppColors.primaryColor;

  @override
  void initState() {
    super.initState();
    final existing = BuddiesController.to.profile.value?.buddyGoals ?? const [];
    for (final g in existing) {
      _fields.add(TextEditingController(text: g));
    }
    while (_fields.length < 3) {
      _fields.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (final c in _fields) {
      c.dispose();
    }
    super.dispose();
  }

  void _add() {
    if (_fields.length >= _max) return;
    setState(() => _fields.add(TextEditingController()));
  }

  void _remove(int i) {
    setState(() {
      _fields[i].dispose();
      _fields.removeAt(i);
    });
  }

  Future<void> _save() async {
    final goals = _fields.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    if (goals.isEmpty) {
      AppSnackBar.error('Add at least one goal.');
      return;
    }
    await BuddiesController.to.saveBuddyGoals(goals);
    AppSnackBar.success('Buddy goals saved 🤝');
    Get.back();
  }

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
        title: Text('Your Buddy Goals',
            style: AppFonts.spaceGrotesk
                .copyWith(color: _kText, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 30.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Pick up to 5 things you want your buddy to hold you accountable to. Keep them specific.',
                style: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 13.5.sp, height: 1.4, color: _kMuted)),
            SizedBox(height: 18.h),
            for (var i = 0; i < _fields.length; i++) _fieldRow(i),
            if (_fields.length < _max) ...[
              SizedBox(height: 4.h),
              GestureDetector(
                onTap: _add,
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: _accent, size: 20.r),
                    SizedBox(width: 8.w),
                    Text('Add a goal',
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: _accent)),
                  ],
                ),
              ),
            ],
            SizedBox(height: 26.h),
            GestureDetector(
              onTap: _save,
              child: Container(
                width: double.infinity,
                height: 54.h,
                decoration: BoxDecoration(
                    color: _accent, borderRadius: BorderRadius.circular(16.r)),
                alignment: Alignment.center,
                child: Text('Save goals',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldRow(int i) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            width: 26.r,
            height: 26.r,
            decoration:
                BoxDecoration(color: _accent.withOpacity(0.12), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('${i + 1}',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 12.sp, fontWeight: FontWeight.w800, color: _accent)),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              controller: _fields[i],
              maxLength: 80,
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 14.sp, color: _kText, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                counterText: '',
                hintText: 'e.g. Hit the gym 4× this week',
                hintStyle: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 13.sp, color: _kMuted),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide:
                      const BorderSide(color: Color(0xffE6E0DE), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: _accent, width: 1.5),
                ),
              ),
            ),
          ),
          if (_fields.length > 1)
            IconButton(
              onPressed: () => _remove(i),
              icon: Icon(Icons.close_rounded, color: _kMuted, size: 20.r),
            ),
        ],
      ),
    );
  }
}
