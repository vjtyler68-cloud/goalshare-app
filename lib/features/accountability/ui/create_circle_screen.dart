import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/features/friends/controller/friends_controller.dart';

import '../controller/circles_controller.dart';
import 'circle_screen.dart';

const _kBg = Color(0xffF6F4F2);
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// Start a squad: name it and add 2–4 friends (5 people max, including you).
class CreateCircleScreen extends StatefulWidget {
  const CreateCircleScreen({super.key});

  @override
  State<CreateCircleScreen> createState() => _CreateCircleScreenState();
}

class _CreateCircleScreenState extends State<CreateCircleScreen> {
  static const _maxFriends = 4; // + me = 5
  final _name = TextEditingController();
  final Set<String> _selected = {};
  bool _busy = false;

  Color get _accent => AppColors.primaryColor;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        if (_selected.length >= _maxFriends) {
          AppSnackBar.error('A circle is up to 5 people (you + 4).');
          return;
        }
        _selected.add(id);
      }
    });
  }

  Future<void> _create() async {
    if (_busy) return;
    if (_selected.isEmpty) {
      AppSnackBar.error('Add at least one friend to your circle.');
      return;
    }
    setState(() => _busy = true);
    final name = _name.text.trim().isEmpty ? 'Our Circle' : _name.text.trim();
    final ok =
        await CirclesController.to.createCircle(name, _selected.toList());
    setState(() => _busy = false);
    if (ok) {
      Get.off(() => const CircleScreen());
    } else {
      AppSnackBar.error(
          "Couldn't create the circle. You may already be in one.");
    }
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
        title: Text('New Circle',
            style: AppFonts.spaceGrotesk
                .copyWith(color: _kText, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 30.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name your circle',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
            SizedBox(height: 8.h),
            TextField(
              controller: _name,
              maxLength: 40,
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 14.sp, color: _kText, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                counterText: '',
                hintText: 'e.g. 5AM Club, Grind Squad',
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
            SizedBox(height: 18.h),
            Row(
              children: [
                Text('Add friends',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: _kText)),
                const Spacer(),
                Text('${_selected.length + 1}/5',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: _accent)),
              ],
            ),
            SizedBox(height: 12.h),
            _friends(),
            SizedBox(height: 24.h),
            GestureDetector(
              onTap: _create,
              child: Container(
                width: double.infinity,
                height: 54.h,
                decoration: BoxDecoration(
                    color: _accent, borderRadius: BorderRadius.circular(16.r)),
                alignment: Alignment.center,
                child: Text(_busy ? 'Creating…' : 'Create circle',
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

  Widget _friends() {
    final friends = FriendsController.to.friends;
    if (friends.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(18.r),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
        child: Text('Add friends from the People tab first.',
            textAlign: TextAlign.center,
            style:
                AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, color: _kMuted)),
      );
    }
    return Column(
      children: [
        for (final f in friends)
          GestureDetector(
            onTap: () => _toggle(f.id),
            child: Container(
              margin: EdgeInsets.only(bottom: 10.h),
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                    color: _selected.contains(f.id)
                        ? _accent
                        : const Color(0xffECE7E4),
                    width: 1.5),
              ),
              child: Row(
                children: [
                  _avatar(f.profile ?? '', f.name),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(f.name.isEmpty ? (f.username ?? 'Friend') : f.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: _kText)),
                  ),
                  Icon(
                    _selected.contains(f.id)
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: _selected.contains(f.id) ? _accent : _kMuted,
                    size: 24.r,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _avatar(String url, String name) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    Widget fill() => Center(
        child: Text(initial,
            style: AppFonts.spaceGrotesk.copyWith(
                color: _accent, fontSize: 15.sp, fontWeight: FontWeight.w800)));
    return Container(
      width: 40.r,
      height: 40.r,
      decoration: BoxDecoration(
          shape: BoxShape.circle, color: _accent.withOpacity(0.12)),
      child: ClipOval(
        child: url.isNotEmpty
            ? Image.network(url,
                fit: BoxFit.cover, errorBuilder: (_, __, ___) => fill())
            : fill(),
      ),
    );
  }
}
