import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/const/app_colors.dart';
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
  static const _reactionEmojis = ['❤️', '🔥', '😂', '🙌', '😮', '👏'];

  late final AnimationController _anim;
  int _index = 0;
  final Map<int, Uint8List> _decoded = {};

  /// Locally-mutable copies so reactions/comments update instantly after we
  /// persist them (the streamed group is a snapshot from when we opened).
  late final List<Story> _stories;
  Story get _current => _stories[_index];

  /// The big emoji that pops over the story after tapping a reaction.
  final RxnString _poppedEmoji = RxnString();

  StoriesController get _c => StoriesController.to;

  @override
  void initState() {
    super.initState();
    _stories = List<Story>.of(widget.group.stories);
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
    _c.markStorySeen(_current);
    _anim
      ..reset()
      ..forward();
    setState(() {});
  }

  /// Swap in a fresher copy of the current story (after a reaction/comment or a
  /// re-fetch) without disturbing playback position.
  void _replaceCurrent(Story fresh) {
    if (!mounted) return;
    setState(() => _stories[_index] = fresh);
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

  // ── Safety menu (others' stories): Report / Block ──────────────────────────
  void _showMenu() {
    _anim.stop();
    final who = widget.group.authorName.trim().isEmpty
        ? 'user'
        : widget.group.authorName.trim();
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10.h),
              _menuTile(Icons.flag_outlined, 'Report story', () {
                Get.back();
                _reportSheet();
              }),
              _menuTile(Icons.block, 'Block $who', () {
                Get.back();
                _confirmBlock(who);
              }, danger: true),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      if (mounted && !_anim.isAnimating) _anim.forward();
    });
  }

  Widget _menuTile(IconData icon, String label, VoidCallback onTap,
      {bool danger = false}) {
    final color = danger ? Colors.red : const Color(0xff1A1010);
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label,
          style: AppFonts.spaceGrotesk.copyWith(
              fontSize: 14.sp, fontWeight: FontWeight.w600, color: color)),
      onTap: onTap,
    );
  }

  void _reportSheet() {
    const reasons = [
      'Spam',
      'Inappropriate content',
      'Harassment or bullying',
      'Something else',
    ];
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
                child: Text('Report this story',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 16.sp, fontWeight: FontWeight.w800)),
              ),
              for (final r in reasons)
                _menuTile(Icons.chevron_right, r, () {
                  Get.back(); // reason sheet
                  StoriesController.to.reportStory(_current, r);
                  Get.back(); // close the viewer
                }),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      if (mounted && !_anim.isAnimating) _anim.forward();
    });
  }

  void _confirmBlock(String who) {
    Get.dialog(AlertDialog(
      backgroundColor: Colors.white,
      title: Text('Block $who?',
          style: AppFonts.spaceGrotesk
              .copyWith(fontWeight: FontWeight.w800, fontSize: 17.sp)),
      content: Text("You won't see their stories or posts anymore.",
          style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp)),
      actions: [
        TextButton(
          onPressed: () {
            Get.back();
            if (mounted && !_anim.isAnimating) _anim.forward();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Get.back(); // dialog
            StoriesController.to.blockAuthor(_current);
            Get.back(); // close the viewer
          },
          child: const Text('Block', style: TextStyle(color: Colors.red)),
        ),
      ],
    ));
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

  // ── Reactions (others' stories) ─────────────────────────────────────────────
  String? get _myReaction => _current.reactions[_c.myId];

  Future<void> _react(String emoji) async {
    HapticFeedback.mediumImpact();
    // Big pop over the story.
    _poppedEmoji.value = emoji;
    Future.delayed(const Duration(milliseconds: 850), () {
      if (mounted && _poppedEmoji.value == emoji) _poppedEmoji.value = null;
    });
    // Optimistic local update so the highlight moves immediately.
    final updated = Map<String, String>.of(_current.reactions);
    updated[_c.myId] = emoji;
    _replaceCurrent(_copyWith(_current, reactions: updated));
    await _c.setReaction(_current, emoji);
  }

  Story _copyWith(Story s,
      {Map<String, String>? reactions, List<StoryComment>? comments}) {
    return Story(
      id: s.id,
      authorId: s.authorId,
      authorName: s.authorName,
      authorImage: s.authorImage,
      imageData: s.imageData,
      caption: s.caption,
      createdAt: s.createdAt,
      expireAt: s.expireAt,
      viewers: s.viewers,
      reactions: reactions ?? s.reactions,
      comments: comments ?? s.comments,
    );
  }

  // ── Comments sheet (others' stories) ───────────────────────────────────────
  Future<void> _openComments() async {
    _anim.stop();
    // Pull the freshest comments before showing.
    final fresh = await _c.refreshStory(_current.id);
    if (fresh != null) _replaceCurrent(fresh);

    final comments = _current.comments.obs;
    final controller = TextEditingController();
    final sending = false.obs;

    await Get.bottomSheet(
      isScrollControlled: true,
      Builder(
        builder: (ctx) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            height: 0.7.sh,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                SizedBox(height: 10.h),
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 8.h),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Comments',
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 16.sp, fontWeight: FontWeight.w800)),
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    if (comments.isEmpty) {
                      return Center(
                        child: Text('No comments yet — say hi 👋',
                            style: AppFonts.spaceGrotesk.copyWith(
                                fontSize: 13.sp, color: Colors.grey.shade500)),
                      );
                    }
                    return ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: comments.length,
                      itemBuilder: (_, i) => _commentTile(comments[i]),
                    );
                  }),
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          minLines: 1,
                          maxLines: 3,
                          style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp),
                          decoration: InputDecoration(
                            hintText: 'Add a comment…',
                            hintStyle: AppFonts.spaceGrotesk.copyWith(
                                fontSize: 14.sp, color: Colors.grey.shade500),
                            filled: true,
                            fillColor: const Color(0xffF6F4F2),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 14.w, vertical: 10.h),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22.r),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Obx(() => IconButton(
                            onPressed: sending.value
                                ? null
                                : () async {
                                    final text = controller.text;
                                    if (text.trim().isEmpty) return;
                                    sending.value = true;
                                    final added =
                                        await _c.addComment(_current, text);
                                    sending.value = false;
                                    if (added != null) {
                                      HapticFeedback.selectionClick();
                                      controller.clear();
                                      comments.add(added);
                                      _replaceCurrent(_copyWith(_current,
                                          comments: comments.toList()));
                                    }
                                  },
                            icon: Icon(Icons.send_rounded,
                                color: AppColors.primaryColor),
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
    if (mounted && !_anim.isAnimating) _anim.forward();
  }

  Widget _commentTile(StoryComment c) {
    final info = _c.resolveUser(c.uid,
        fallbackName: c.name, fallbackImage: c.image);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StoryRing(imageUrl: info.image, name: info.name, size: 34),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.username.isNotEmpty ? '@${info.username}' : info.name,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 13.sp, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 2.h),
                Text(c.text,
                    style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Viewers + comments sheet (own stories) ──────────────────────────────────
  Future<void> _openViewers() async {
    _anim.stop();
    final fresh = await _c.refreshStory(_current.id);
    if (fresh != null) _replaceCurrent(fresh);
    final story = _current;

    await Get.bottomSheet(
      isScrollControlled: true,
      Container(
        height: 0.7.sh,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SafeArea(
          top: false,
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                SizedBox(height: 10.h),
                Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 8.h),
                TabBar(
                  labelColor: AppColors.primaryColor,
                  unselectedLabelColor: Colors.grey.shade500,
                  indicatorColor: AppColors.primaryColor,
                  labelStyle: AppFonts.spaceGrotesk
                      .copyWith(fontSize: 13.sp, fontWeight: FontWeight.w700),
                  tabs: [
                    Tab(text: 'Viewers (${story.viewers.length})'),
                    Tab(text: 'Comments (${story.comments.length})'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _viewersList(story),
                      story.comments.isEmpty
                          ? Center(
                              child: Text('No comments yet',
                                  style: AppFonts.spaceGrotesk.copyWith(
                                      fontSize: 13.sp,
                                      color: Colors.grey.shade500)),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              itemCount: story.comments.length,
                              itemBuilder: (_, i) =>
                                  _commentTile(story.comments[i]),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (mounted && !_anim.isAnimating) _anim.forward();
  }

  Widget _viewersList(Story story) {
    if (story.viewers.isEmpty) {
      return Center(
        child: Text('No views yet',
            style: AppFonts.spaceGrotesk
                .copyWith(fontSize: 13.sp, color: Colors.grey.shade500)),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: story.viewers.length,
      itemBuilder: (_, i) {
        final uid = story.viewers[i];
        final info = _c.resolveUser(uid);
        final reaction = story.reactions[uid];
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Row(
            children: [
              StoryRing(imageUrl: info.image, name: info.name, size: 34),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  info.username.isNotEmpty ? '@${info.username}' : info.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 13.sp, fontWeight: FontWeight.w600),
                ),
              ),
              if (reaction != null && reaction.isNotEmpty)
                Text(reaction, style: TextStyle(fontSize: 18.sp)),
            ],
          ),
        );
      },
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
                  padding: EdgeInsets.fromLTRB(20.w, 40.h, 20.w, 140.h),
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

            // ── Big emoji pop (reaction feedback) ──────────────────────────
            Positioned.fill(
              child: IgnorePointer(
                child: Obx(() {
                  final e = _poppedEmoji.value;
                  if (e == null) return const SizedBox.shrink();
                  return Center(child: _EmojiPop(emoji: e));
                }),
              ),
            ),

            // ── Bottom bar ─────────────────────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 8.h),
                  child: widget.isMine ? _ownFooter() : _reactionBar(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tapping the bottom controls must not advance/rewind the story.
  Widget _reactionBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(30.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final e in _reactionEmojis)
                GestureDetector(
                  onTap: () => _react(e),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 180),
                    scale: _myReaction == e ? 1.35 : 1.0,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.w),
                      child: Text(e, style: TextStyle(fontSize: 24.sp)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        GestureDetector(
          onTap: _openComments,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white70, width: 1.2),
              borderRadius: BorderRadius.circular(30.r),
            ),
            child: Row(
              children: [
                Text('Send a comment…',
                    style: AppFonts.spaceGrotesk
                        .copyWith(color: Colors.white70, fontSize: 14.sp)),
                const Spacer(),
                Icon(Icons.chat_bubble_outline,
                    color: Colors.white70, size: 18.sp),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _ownFooter() {
    return GestureDetector(
      onTap: _openViewers,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.remove_red_eye_outlined,
                color: Colors.white, size: 18.sp),
            SizedBox(width: 8.w),
            Text('${_current.viewers.length}',
                style: AppFonts.spaceGrotesk.copyWith(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700)),
            SizedBox(width: 6.w),
            Text('viewers',
                style: AppFonts.spaceGrotesk
                    .copyWith(color: Colors.white70, fontSize: 13.sp)),
            if (_current.comments.isNotEmpty) ...[
              SizedBox(width: 14.w),
              Icon(Icons.chat_bubble_outline,
                  color: Colors.white, size: 16.sp),
              SizedBox(width: 6.w),
              Text('${_current.comments.length}',
                  style: AppFonts.spaceGrotesk.copyWith(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700)),
            ],
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
                widget.group.authorUsername.isNotEmpty
                    ? '@${widget.group.authorUsername} · ${_current.ageLabel}'
                    : _current.ageLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
          )
        else
          IconButton(
            onPressed: _showMenu,
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.close_rounded, color: Colors.white),
        ),
      ],
    );
  }
}

/// A one-shot "pop" of a big emoji: springs up in scale while fading, then
/// gently drifts up and fades out — the delightful reaction flourish.
class _EmojiPop extends StatefulWidget {
  final String emoji;
  const _EmojiPop({required this.emoji});

  @override
  State<_EmojiPop> createState() => _EmojiPopState();
}

class _EmojiPopState extends State<_EmojiPop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  late final Animation<double> _rise;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..forward();
    _scale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.3, end: 1.25)
              .chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 45),
      TweenSequenceItem(tween: ConstantTween(1.25), weight: 20),
      TweenSequenceItem(
          tween: Tween(begin: 1.25, end: 1.4)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 35),
    ]).animate(_c);
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 25),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 35),
    ]).animate(_c);
    _rise = Tween<double>(begin: 0, end: -40.h)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _rise.value),
        child: Opacity(
          opacity: _opacity.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: _scale.value,
            child: Text(widget.emoji, style: TextStyle(fontSize: 90.sp)),
          ),
        ),
      ),
    );
  }
}
