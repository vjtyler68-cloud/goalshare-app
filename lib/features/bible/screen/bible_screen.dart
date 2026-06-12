import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/features/bible/controller/bible_controller.dart';

const _kRed    = Color(0xffE84040);
const _kBg     = Color(0xffF6F4F2);
const _kCard   = Color(0xffFFFFFF);
const _kText   = Color(0xff1A1010);
const _kMuted  = Color(0xff9E9090);

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
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xffE84040), Color(0xff9B1414)],
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
                            Text(
                              'Holy Bible · KJV',
                              style: AppFonts.spaceGrotesk.copyWith(
                                color: Colors.white70, fontSize: 13.sp,
                              ),
                            ),
                            const Spacer(),
                            Obx(() => Container(
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                '${c.cachedChapterCount} chapters offline',
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
                return const Center(child: CircularProgressIndicator(color: _kRed));
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
                  return Padding(
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
                                '${v['verse']}',
                                style: AppFonts.spaceGrotesk.copyWith(
                                  fontSize: 10.sp, fontWeight: FontWeight.w800, color: _kRed,
                                ),
                              ),
                            ),
                          ),
                          TextSpan(
                            text: v['text'] as String,
                            style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: _fontSize.sp,
                              color: _kText,
                              height: 1.65,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
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
