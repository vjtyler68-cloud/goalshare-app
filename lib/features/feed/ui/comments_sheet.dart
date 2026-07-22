import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/const/app_colors.dart';
import '../../../core/const/app_fonts.dart';
import '../controller/feed_controller.dart';
import '../model/activity.dart';

Color get _kRed => AppColors.primaryColor;
Color get _kRedDk => AppColors.primaryDarkColor;
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// A comment thread on one activity — the "accountability" heart of the feed
/// where friends drop encouragement.
class CommentsSheet {
  CommentsSheet._();

  static void show(FeedController controller, Activity activity) {
    Get.bottomSheet(
      _Body(controller: controller, activity: activity),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _Body extends StatefulWidget {
  final FeedController controller;
  final Activity activity;
  const _Body({required this.controller, required this.activity});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    FocusScope.of(context).unfocus();
    await widget.controller.addComment(widget.activity.id, text);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
        ),
        child: Column(
          children: [
            SizedBox(height: 12.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r)),
            ),
            SizedBox(height: 12.h),
            Text('Comments',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
            Divider(height: 20.h),
            Expanded(
              child: StreamBuilder<List<ActivityComment>>(
                stream: widget.controller.comments(widget.activity.id),
                builder: (context, snap) {
                  final comments = snap.data ?? const [];
                  if (comments.isEmpty) {
                    return Center(
                      child: Text('No comments yet — be the first to cheer them on.',
                          textAlign: TextAlign.center,
                          style: AppFonts.spaceGrotesk
                              .copyWith(fontSize: 13.sp, color: _kMuted)),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: comments.length,
                    itemBuilder: (_, i) => _commentRow(comments[i]),
                  );
                },
              ),
            ),
            _inputBar(),
          ],
        ),
      ),
    );
  }

  Widget _commentRow(ActivityComment c) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _avatar(c.authorImage, c.authorName),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(c.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: _kText)),
                    ),
                    SizedBox(width: 6.w),
                    Text(c.ageLabel,
                        style: AppFonts.spaceGrotesk
                            .copyWith(fontSize: 10.sp, color: _kMuted)),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(c.text,
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 13.sp, color: _kText, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(12.w, 8.h, 8.w, 8.h),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xffEEE9E6))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xffF6F4F2),
                  borderRadius: BorderRadius.circular(22.r),
                ),
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppFonts.spaceGrotesk
                      .copyWith(fontSize: 14.sp, color: _kText),
                  decoration: InputDecoration(
                    hintText: 'Add a comment…',
                    hintStyle: AppFonts.spaceGrotesk
                        .copyWith(fontSize: 13.sp, color: _kMuted),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 42.r,
                height: 42.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [_kRed, _kRedDk]),
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar(String url, String name) {
    final initial = name.trim().isEmpty ? 'U' : name.trim()[0].toUpperCase();
    final fallback = Container(
      width: 36.r,
      height: 36.r,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [_kRed, _kRedDk]),
      ),
      child: Text(initial,
          style: AppFonts.spaceGrotesk.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14.sp)),
    );
    if (url.trim().isEmpty) return fallback;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: 36.r,
        height: 36.r,
        fit: BoxFit.cover,
        placeholder: (_, __) => fallback,
        errorWidget: (_, __, ___) => fallback,
      ),
    );
  }
}
