import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/const/app_fonts.dart';
import '../controller/stories_controller.dart';
import '../model/story_model.dart';
import 'story_ring.dart';

/// Full-screen, tap-through story viewer for one person's active stories.
///
/// * Auto-advances every 5s with segmented progress bars up top.
/// * Tap right → next, tap left → previous.
/// * Press-and-hold to pause, release to resume.
/// * Swipe down to close.
/// Hand-rolled (no external package) so it can never break a release build.
class StoryViewerScreen extends StatefulWidget {
  final UserStories group;
  final bool isMine;

  const StoryViewerScreen({
    super.key,
    required this.group,
    this.isMine = false,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  static const _perStory = Duration(seconds: 5);

  late final AnimationController _anim;
  int _index = 0;
  final Map<int, Uint8List> _decoded = {};

  List<Story> get _stories => widget.group.stories;
  Story get _current => _stories[_index];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: _perStory)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _next();
      });
    _restart();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Uint8List _bytes(int i) {
    return _decoded.putIfAbsent(i, () {
      try {
        return base64Decode(_stories[i].imageData);
      } catch (_) {
        return Uint8List(0);
      }
    });
  }

  void _restart() {
    _anim
      ..reset()
      ..forward();
    setState(() {});
  }

  void _next() {
    if (_index < _stories.length - 1) {
      _index++;
      _restart();
    } else {
      Get.back();
    }
  }

  void _prev() {
    if (_index > 0) {
      _index--;
      _restart();
    } else {
      _anim
        ..reset()
        ..forward();
    }
  }

  void _onTapUp(TapUpDetails d) {
    final w = context.size?.width ?? MediaQuery.of(context).size.width;
    if (d.localPosition.dx < w * 0.33) {
      _prev();
    } else {
      _next();
    }
  }

  Future<void> _confirmDelete() async {
    _anim.stop();
    final story = _current;
    await Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Delete story?',
            style: AppFonts.spaceGrotesk
                .copyWith(fontWeight: FontWeight.w800, fontSize: 17.sp)),
        content: Text('This removes it for everyone right away.',
            style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp)),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _anim.forward();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back(); // close dialog
              if (Get.isRegistered<StoriesController>()) {
                await Get.find<StoriesController>().deleteStory(story);
              }
              Get.back(); // close viewer
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: _onTapUp,
        onLongPressStart: (_) => _anim.stop(),
        onLongPressEnd: (_) {
          if (!_anim.isAnimating) _anim.forward();
        },
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) > 250) Get.back();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Photo ──────────────────────────────────────────────────────
            Center(child: _photo()),

            // ── Top scrim ──────────────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 160.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.55), Colors.transparent],
                  ),
                ),
              ),
            ),

            // ── Progress + header ──────────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                child: Column(
                  children: [
                    _progressBars(),
                    SizedBox(height: 10.h),
                    _header(),
                  ],
                ),
              ),
            ),

            // ── Caption ────────────────────────────────────────────────────
            if (_current.caption.trim().isNotEmpty)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7)
                      ],
                    ),
                  ),
                  padding: EdgeInsets.fromLTRB(20.w, 40.h, 20.w, 0),
                  child: SafeArea(
                    top: false,
                    child: Text(
                      _current.caption,
                      style: AppFonts.spaceGrotesk.copyWith(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
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

  Widget _photo() {
    final bytes = _bytes(_index);
    if (bytes.isEmpty) {
      return const Icon(Icons.broken_image_outlined,
          color: Colors.white38, size: 60);
    }
    return Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true);
  }

  Widget _progressBars() {
    return Row(
      children: List.generate(_stories.length, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 3,
                child: i < _index
                    ? Container(color: Colors.white)
                    : i > _index
                        ? Container(color: Colors.white.withOpacity(0.35))
                        : AnimatedBuilder(
                            animation: _anim,
                            builder: (_, __) => LinearProgressIndicator(
                              value: _anim.value,
                              backgroundColor: Colors.white.withOpacity(0.35),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _header() {
    return Row(
      children: [
        StoryRing(
          imageUrl: widget.group.authorImage,
          name: widget.group.authorName,
          size: 40,
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.isMine ? 'Your story' : widget.group.authorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.spaceGrotesk.copyWith(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700),
              ),
              Text(
                _current.ageLabel,
                style: AppFonts.spaceGrotesk
                    .copyWith(color: Colors.white70, fontSize: 11.sp),
              ),
            ],
          ),
        ),
        if (widget.isMine)
          IconButton(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.white),
          ),
        IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.close_rounded, color: Colors.white),
        ),
      ],
    );
  }
}
