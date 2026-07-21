import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/features/bible/controller/bible_controller.dart';
import 'package:spanx/features/bible/model/bible_mark.dart';
import 'package:spanx/core/const/app_colors.dart';

Color get _kRed => AppColors.primaryColor;
const _kBg     = Color(0xffF6F4F2);
const _kCard   = Color(0xffFFFFFF);
const _kText   = Color(0xff1A1010);
const _kMuted  = Color(0xff9E9090);

// 3-colour highlighter palette (marker pens) — order matches stored index
const List<Color> _kHighlights = [
  Color(0xffFFF176), // yellow
  Color(0xffA5D6A7), // green
  Color(0xffF48FB1), // pink
];

// ── 1. BOOK LIST SCREEN ────────────────────────────────────────────────────
class BibleScreen extends StatelessWidget {
  BibleScreen({super.key});

  final BibleController c = Get.put(BibleController());
  final TextEditingController search = TextEditingController();
  final RxString query = ''.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 130.h,
            backgroundColor: _kRed,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_kRed, AppColors.primaryDarkColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.menu_book_rounded, color: Colors.white70, size: 20.r),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'Holy Bible · KJV',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.spaceGrotesk.copyWith(
                                  color: Colors.white70, fontSize: 13.sp,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            // Saved highlights + notes library
                            GestureDetector(
                              onTap: () => Get.to(() => const BibleSavedScreen()),
                              child: Obx(() => Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.bookmark_rounded, color: Colors.white, size: 13.r),
                                    SizedBox(width: 4.w),
                                    Text(
                                      c.savedCount > 0 ? '${c.savedCount} saved' : 'Saved',
                                      style: AppFonts.spaceGrotesk.copyWith(
                                        color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                            ),
                            SizedBox(width: 8.w),
                            Obx(() => Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                '${c.cachedChapterCount} offline',
                                style: AppFonts.spaceGrotesk.copyWith(
                                  color: Colors.white, fontSize: 10.sp, fontWeight: FontWeight.w600,
                                ),
                              ),
                            )),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'Select a Book',
                          style: AppFonts.spaceGrotesk.copyWith(
                            color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 14.h),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(52.h),
              child: Container(
                color: _kRed,
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
                child: Container(
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: TextField(
                    controller: search,
                    onChanged: (v) => query.value = v.toLowerCase(),
                    style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 13.sp),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search books…',
                      hintStyle: AppFonts.spaceGrotesk.copyWith(color: Colors.white60, fontSize: 13.sp),
                      prefixIcon: Icon(Icons.search, color: Colors.white70, size: 18.r),
                      contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        body: Obx(() {
          final filtered = BibleData.books.where((b) {
            final q = query.value;
            return q.isEmpty || b['name'].toString().toLowerCase().contains(q);
          }).toList();

          final ot = filtered.where((b) => b['testament'] == 'OT').toList();
          final nt = filtered.where((b) => b['testament'] == 'NT').toList();

          return ListView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            children: [
              if (ot.isNotEmpty) ...[
                _testament('Old Testament', ot.length),
                SizedBox(height: 8.h),
                _bookGrid(ot),
                SizedBox(height: 20.h),
              ],
              if (nt.isNotEmpty) ...[
                _testament('New Testament', nt.length),
                SizedBox(height: 8.h),
                _bookGrid(nt),
                SizedBox(height: 60.h),
              ],
            ],
          );
        }),
      ),
    );
  }

  Widget _testament(String label, int count) {
    return Row(
      children: [
        Container(width: 3.w, height: 18.h, decoration: BoxDecoration(color: _kRed, borderRadius: BorderRadius.circular(2))),
        SizedBox(width: 8.w),
        Text(label, style: AppFonts.spaceGrotesk.copyWith(fontSize: 15.sp, fontWeight: FontWeight.w800, color: _kText)),
        SizedBox(width: 8.w),
        Text('$count books', style: AppFonts.spaceGrotesk.copyWith(fontSize: 11.sp, color: _kMuted)),
      ],
    );
  }

  Widget _bookGrid(List<Map<String, dynamic>> books) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.6,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.h,
      ),
      itemCount: books.length,
      itemBuilder: (_, i) {
        final book = books[i];
        return GestureDetector(
          onTap: () => Get.to(() => BibleBookScreen(book: book)),
          child: Container(
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            padding: EdgeInsets.all(10.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  book['name'] as String,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.spaceGrotesk.copyWith(fontSize: 11.sp, fontWeight: FontWeight.w700, color: _kText),
                ),
                Text(
                  '${book['chapters']} ch.',
                  style: AppFonts.spaceGrotesk.copyWith(fontSize: 9.sp, color: _kMuted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── 2. CHAPTER LIST SCREEN ─────────────────────────────────────────────────
class BibleBookScreen extends StatelessWidget {
  final Map<String, dynamic> book;
  const BibleBookScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<BibleController>();
    final name = book['name'] as String;
    final chapters = book['chapters'] as int;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kRed,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18.sp)),
            Text('$chapters chapters · KJV', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white70, fontSize: 12.sp)),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.r),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 1,
            crossAxisSpacing: 8.w,
            mainAxisSpacing: 8.h,
          ),
          itemCount: chapters,
          itemBuilder: (_, i) {
            final ch = i + 1;
            final cached = c.isChapterCached(name, ch);
            return GestureDetector(
              onTap: () => Get.to(() => BibleChapterScreen(book: name, chapter: ch)),
              child: Container(
                decoration: BoxDecoration(
                  color: cached ? _kRed : _kCard,
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Center(
                  child: Text(
                    '$ch',
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: cached ? Colors.white : _kText,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── 3. CHAPTER READER SCREEN ───────────────────────────────────────────────
class BibleChapterScreen extends StatefulWidget {
  final String book;
  final int chapter;
  const BibleChapterScreen({super.key, required this.book, required this.chapter});

  @override
  State<BibleChapterScreen> createState() => _BibleChapterScreenState();
}

class _BibleChapterScreenState extends State<BibleChapterScreen> {
  late final BibleController c;
  late int _chapter;
  double _fontSize = 16;

  @override
  void initState() {
    super.initState();
    c = Get.find<BibleController>();
    _chapter = widget.chapter;
    c.loadChapter(widget.book, _chapter);
  }

  int get _totalChapters {
    final book = BibleData.books.firstWhere((b) => b['name'] == widget.book, orElse: () => {'chapters': 1});
    return book['chapters'] as int;
  }

  void _go(int ch) {
    setState(() => _chapter = ch);
    c.loadChapter(widget.book, ch);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kRed,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Obx(() => Text(
          c.isLoading.value ? 'Loading…' : '${widget.book} $_chapter',
          style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17.sp),
        )),
        actions: [
          // Font size
          IconButton(
            icon: const Icon(Icons.text_decrease, color: Colors.white),
            onPressed: () => setState(() => _fontSize = (_fontSize - 1).clamp(12, 26)),
          ),
          IconButton(
            icon: const Icon(Icons.text_increase, color: Colors.white),
            onPressed: () => setState(() => _fontSize = (_fontSize + 1).clamp(12, 26)),
          ),
          // Offline indicator
          Obx(() => Padding(
            padding: EdgeInsets.only(right: 10.w),
            child: Icon(
              c.isCached.value ? Icons.offline_pin : Icons.cloud_outlined,
              color: c.isCached.value ? Colors.greenAccent : Colors.white70,
              size: 20.r,
            ),
          )),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (c.isLoading.value) {
                return Center(child: CircularProgressIndicator(color: _kRed));
              }
              if (c.error.value.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.r),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off_rounded, color: _kMuted, size: 48.r),
                        SizedBox(height: 16.h),
                        Text(
                          c.error.value,
                          textAlign: TextAlign.center,
                          style: AppFonts.spaceGrotesk.copyWith(color: _kMuted, fontSize: 14.sp, height: 1.5),
                        ),
                        SizedBox(height: 20.h),
                        ElevatedButton.icon(
                          onPressed: () => c.loadChapter(widget.book, _chapter),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(backgroundColor: _kRed, foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (c.verses.isEmpty) {
                return const Center(child: Text('No verses found.'));
              }
              return ListView.builder(
                padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 16.h),
                itemCount: c.verses.length,
                itemBuilder: (_, i) {
                  final v = c.verses[i];
                  final verseNo = (v['verse'] as num).toInt();
                  final verseText = v['text'] as String;
                  return Obx(() {
                    final hlIndex = c.highlightOf(widget.book, _chapter, verseNo);
                    final hlColor = (hlIndex != null &&
                            hlIndex >= 0 &&
                            hlIndex < _kHighlights.length)
                        ? _kHighlights[hlIndex]
                        : null;
                    final hasNote =
                        c.noteOf(widget.book, _chapter, verseNo).isNotEmpty;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _showVerseSheet(verseNo, verseText),
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              WidgetSpan(
                                child: Container(
                                  margin: EdgeInsets.only(right: 6.w),
                                  padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                                  decoration: BoxDecoration(
                                    color: _kRed.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text(
                                    '$verseNo',
                                    style: AppFonts.spaceGrotesk.copyWith(
                                      fontSize: 10.sp, fontWeight: FontWeight.w800, color: _kRed,
                                    ),
                                  ),
                                ),
                              ),
                              TextSpan(
                                text: verseText,
                                style: AppFonts.spaceGrotesk.copyWith(
                                  fontSize: _fontSize.sp,
                                  color: _kText,
                                  height: 1.65,
                                  fontWeight: FontWeight.w400,
                                  backgroundColor: hlColor,
                                ),
                              ),
                              if (hasNote)
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 5.w),
                                    child: Icon(
                                      Icons.sticky_note_2_rounded,
                                      size: 14.sp,
                                      color: _kRed.withOpacity(0.85),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  });
                },
              );
            }),
          ),

          // ── Chapter nav bar ──────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: _kCard,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Row(
              children: [
                _navBtn(
                  icon: Icons.chevron_left,
                  label: 'Prev',
                  enabled: _chapter > 1,
                  onTap: () => _go(_chapter - 1),
                ),
                const Spacer(),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.book}',
                      style: AppFonts.spaceGrotesk.copyWith(fontSize: 11.sp, color: _kMuted),
                    ),
                    Text(
                      'Chapter $_chapter of $_totalChapters',
                      style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w700, color: _kText),
                    ),
                  ],
                ),
                const Spacer(),
                _navBtn(
                  icon: Icons.chevron_right,
                  label: 'Next',
                  enabled: _chapter < _totalChapters,
                  onTap: () => _go(_chapter + 1),
                  isRight: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Verse actions: highlight + note ────────────────────────────────────────
  void _showVerseSheet(int verse, String verseText) {
    final current = c.highlightOf(widget.book, _chapter, verse);
    final note = c.noteOf(widget.book, _chapter, verse);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40.w, height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Center(
              child: Text(
                '${widget.book} $_chapter:$verse',
                style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 15.sp, fontWeight: FontWeight.w800, color: _kText,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Center(
              child: Text(
                'Highlight or add a note',
                style: AppFonts.spaceGrotesk.copyWith(fontSize: 12.sp, color: _kMuted),
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int i = 0; i < _kHighlights.length; i++)
                  _swatch(
                    color: _kHighlights[i],
                    selected: current == i,
                    onTap: () {
                      c.setHighlight(widget.book, _chapter, verse, verseText, i);
                      Navigator.pop(context);
                    },
                  ),
                _swatch(
                  color: Colors.white,
                  icon: Icons.format_color_reset_outlined,
                  selected: false,
                  onTap: () {
                    c.setHighlight(widget.book, _chapter, verse, verseText, null);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            SizedBox(height: 18.h),
            Divider(color: Colors.grey.shade200, height: 1),
            SizedBox(height: 16.h),
            if (note.isEmpty)
              _sheetBtn(
                label: 'Add a note',
                icon: Icons.note_add_outlined,
                filled: true,
                onTap: () {
                  Navigator.pop(context);
                  _showNoteEditor(verse, verseText, '');
                },
              )
            else ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.sticky_note_2_rounded, size: 16.r, color: _kRed),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        note,
                        style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 13.sp, color: _kText, height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Expanded(
                    child: _sheetBtn(
                      label: 'Edit note',
                      icon: Icons.edit_outlined,
                      filled: true,
                      onTap: () {
                        Navigator.pop(context);
                        _showNoteEditor(verse, verseText, note);
                      },
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: _sheetBtn(
                      label: 'Delete',
                      icon: Icons.delete_outline,
                      filled: false,
                      onTap: () {
                        c.setNote(widget.book, _chapter, verse, verseText, '');
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Note editor ────────────────────────────────────────────────────────────
  void _showNoteEditor(int verse, String verseText, String existing) {
    final ctrl = TextEditingController(text: existing);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // let the sheet rise above the keyboard
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w, height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                '${widget.book} $_chapter:$verse',
                style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 15.sp, fontWeight: FontWeight.w800, color: _kText,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                verseText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 12.sp, color: _kMuted, height: 1.4, fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: ctrl,
                autofocus: true,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, color: _kText, height: 1.4),
                decoration: InputDecoration(
                  hintText: 'Write your note…',
                  hintStyle: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, color: _kMuted),
                  filled: true,
                  fillColor: _kBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.all(14.r),
                ),
              ),
              SizedBox(height: 16.h),
              GestureDetector(
                onTap: () {
                  c.setNote(widget.book, _chapter, verse, verseText, ctrl.text);
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_kRed, AppColors.primaryDarkColor]),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Center(
                    child: Text(
                      'Save note',
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 15.sp, fontWeight: FontWeight.w800, color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(ctrl.dispose);
  }

  Widget _sheetBtn({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 14.w),
        decoration: BoxDecoration(
          color: filled ? _kRed : _kBg,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17.r, color: filled ? Colors.white : _kMuted),
            SizedBox(width: 7.w),
            Text(
              label,
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: filled ? Colors.white : _kMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _swatch({
    required Color color,
    required VoidCallback onTap,
    bool selected = false,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54.r,
        height: 54.r,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? _kText : Colors.grey.shade300,
            width: selected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: icon != null
            ? Icon(icon, color: _kMuted, size: 22.r)
            : (selected ? Icon(Icons.check, color: _kText, size: 22.r) : null),
      ),
    );
  }

  Widget _navBtn({required IconData icon, required String label, required bool enabled, required VoidCallback onTap, bool isRight = false}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: enabled ? _kRed : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: isRight
              ? [Text(label, style: AppFonts.spaceGrotesk.copyWith(color: enabled ? Colors.white : _kMuted, fontSize: 12.sp, fontWeight: FontWeight.w600)), Icon(icon, color: enabled ? Colors.white : _kMuted, size: 16.r)]
              : [Icon(icon, color: enabled ? Colors.white : _kMuted, size: 16.r), Text(label, style: AppFonts.spaceGrotesk.copyWith(color: enabled ? Colors.white : _kMuted, fontSize: 12.sp, fontWeight: FontWeight.w600))],
        ),
      ),
    );
  }
}

// ── 4. SAVED LIBRARY: HIGHLIGHTS & NOTES ───────────────────────────────────
enum _SavedFilter { all, highlights, notes }

class BibleSavedScreen extends StatefulWidget {
  const BibleSavedScreen({super.key});

  @override
  State<BibleSavedScreen> createState() => _BibleSavedScreenState();
}

class _BibleSavedScreenState extends State<BibleSavedScreen> {
  final BibleController c = Get.find<BibleController>();
  _SavedFilter _filter = _SavedFilter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kRed,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Highlights & Notes',
          style: AppFonts.spaceGrotesk.copyWith(
            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18.sp,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter chips live on the red header band
          Container(
            width: double.infinity,
            color: _kRed,
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
            child: Row(
              children: [
                _chip('All', _SavedFilter.all),
                SizedBox(width: 8.w),
                _chip('Highlights', _SavedFilter.highlights),
                SizedBox(width: 8.w),
                _chip('Notes', _SavedFilter.notes),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              var items = c.savedMarks;
              if (_filter == _SavedFilter.highlights) {
                items = items.where((m) => m.hasHighlight).toList();
              } else if (_filter == _SavedFilter.notes) {
                items = items.where((m) => m.hasNote).toList();
              }
              if (items.isEmpty) return _empty();
              return ListView.separated(
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 30.h),
                itemCount: items.length,
                separatorBuilder: (_, __) => SizedBox(height: 10.h),
                itemBuilder: (_, i) => _card(items[i]),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, _SavedFilter f) {
    final sel = _filter == f;
    return GestureDetector(
      onTap: () => setState(() => _filter = f),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: sel ? Colors.white : Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: AppFonts.spaceGrotesk.copyWith(
            color: sel ? _kRed : Colors.white,
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    final String title = _filter == _SavedFilter.notes
        ? 'No notes yet'
        : _filter == _SavedFilter.highlights
            ? 'No highlights yet'
            : 'Nothing saved yet';
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border_rounded, size: 54.r, color: _kMuted),
            SizedBox(height: 14.h),
            Text(
              title,
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 16.sp, fontWeight: FontWeight.w800, color: _kText,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Open any chapter and tap a verse to highlight it or add a note. It shows up here.',
              textAlign: TextAlign.center,
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 13.sp, color: _kMuted, height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(BibleMark m) {
    final hlColor = (m.color != null &&
            m.color! >= 0 &&
            m.color! < _kHighlights.length)
        ? _kHighlights[m.color!]
        : null;
    return GestureDetector(
      onTap: () => Get.to(() => BibleChapterScreen(book: m.book, chapter: m.chapter)),
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left colour bar — highlight colour, or a faint theme tint for note-only
              Container(
                width: 5.w,
                decoration: BoxDecoration(
                  color: hlColor ?? _kRed.withOpacity(0.25),
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(14.r)),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(14.w, 12.h, 8.w, 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              m.reference,
                              style: AppFonts.spaceGrotesk.copyWith(
                                fontSize: 13.sp, fontWeight: FontWeight.w800, color: _kRed,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _confirmRemove(m),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: EdgeInsets.all(4.r),
                              child: Icon(Icons.close, size: 16.r, color: _kMuted),
                            ),
                          ),
                        ],
                      ),
                      if (m.text.isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Text(
                          m.text,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 14.sp, color: _kText, height: 1.5,
                          ),
                        ),
                      ],
                      if (m.hasNote) ...[
                        SizedBox(height: 10.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: _kBg,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.sticky_note_2_rounded, size: 14.r, color: _kRed),
                              SizedBox(width: 7.w),
                              Expanded(
                                child: Text(
                                  m.note,
                                  style: AppFonts.spaceGrotesk.copyWith(
                                    fontSize: 13.sp, color: _kText, height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmRemove(BibleMark m) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(
          'Remove ${m.reference}?',
          style: AppFonts.spaceGrotesk.copyWith(
            fontSize: 16.sp, fontWeight: FontWeight.w800, color: _kText,
          ),
        ),
        content: Text(
          'This clears its highlight and note.',
          style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, color: _kMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 13.sp, fontWeight: FontWeight.w700, color: _kMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              c.removeMark(m.book, m.chapter, m.verse);
              Navigator.pop(ctx);
            },
            child: Text(
              'Remove',
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 13.sp, fontWeight: FontWeight.w800, color: _kRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
