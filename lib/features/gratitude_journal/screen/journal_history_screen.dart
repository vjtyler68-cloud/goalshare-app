import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/routes/app_routes.dart';
import '../controller/journal_controller.dart';
import '../data/journal_entry.dart';
import '../widgets/mood_selector.dart';
import 'package:spanx/core/const/app_colors.dart';

Color get _kRed => AppColors.primaryColor;
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);
const _kBg = Color(0xffF6F4F2);
const _kStar = Color(0xffF59E0B);

class JournalHistoryScreen extends StatefulWidget {
  const JournalHistoryScreen({super.key});

  @override
  State<JournalHistoryScreen> createState() => _JournalHistoryScreenState();
}

class _JournalHistoryScreenState extends State<JournalHistoryScreen> {
  final JournalController c = JournalController.to;
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kRed,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: Get.back,
        ),
        title: Text(
          'Journal History',
          style: AppFonts.spaceGrotesk.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: Obx(() {
        if (!c.isReady.value) {
          return Center(child: CircularProgressIndicator(color: _kRed));
        }
        // touch reactive list so Obx tracks it
        final _ = c.entries.length;
        final results = c.search(_query);
        final onThisDay = _query.isEmpty ? c.onThisDay : <JournalEntry>[];

        return ListView(
          padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 40.h),
          children: [
            _statsCard(),
            SizedBox(height: 16.h),
            _searchBar(),
            SizedBox(height: 16.h),
            if (onThisDay.isNotEmpty) ...[
              _onThisDayCallout(onThisDay),
              SizedBox(height: 16.h),
            ],
            if (results.isEmpty)
              _emptyState()
            else
              ...results.map(_entryTile),
          ],
        );
      }),
    );
  }

  // ── stats ────────────────────────────────────────────────────────────────��─
  Widget _statsCard() {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _stat('🔥 Streak', '${c.currentStreak}',
                  '${c.currentStreak == 1 ? 'day' : 'days'}'),
              _statDivider(),
              _stat('🏆 Longest', '${c.longestStreak}',
                  '${c.longestStreak == 1 ? 'day' : 'days'}'),
              _statDivider(),
              _stat('📓 Entries', '${c.totalEntries}', 'total'),
            ],
          ),
          SizedBox(height: 16.h),
          Divider(color: Colors.grey.shade200, height: 1),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: _avgBlock('Avg · 7 days', c.avgLast7),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _avgBlock('Avg · 30 days', c.avgLast30),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Text('Last 7 days',
              style: AppFonts.spaceGrotesk.copyWith(fontSize: 10.sp, color: _kMuted)),
          SizedBox(height: 8.h),
          SizedBox(
            height: 42.h,
            child: CustomPaint(
              size: Size.infinite,
              painter: _SparklinePainter(c.last7Series),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, String unit) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: AppFonts.spaceGrotesk.copyWith(fontSize: 10.sp, color: _kMuted)),
          SizedBox(height: 4.h),
          Text(value,
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 22.sp, fontWeight: FontWeight.w900, color: _kText)),
          Text(unit,
              style: AppFonts.spaceGrotesk.copyWith(fontSize: 9.sp, color: _kMuted)),
        ],
      ),
    );
  }

  Widget _statDivider() =>
      Container(width: 1, height: 40.h, color: Colors.grey.shade200);

  Widget _avgBlock(String label, double avg) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppFonts.spaceGrotesk.copyWith(fontSize: 10.sp, color: _kMuted)),
          SizedBox(height: 4.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.star_rounded, color: _kStar, size: 16.r),
              SizedBox(width: 4.w),
              Text(
                avg == 0 ? '—' : avg.toStringAsFixed(1),
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 16.sp, fontWeight: FontWeight.w800, color: _kText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── search ───────────────────────────────────────────────────────────────��─
  Widget _searchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: _kMuted, size: 20.r),
          SizedBox(width: 8.w),
          Expanded(
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, color: _kText),
              decoration: InputDecoration(
                hintText: 'Search entries…',
                hintStyle:
                    AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, color: _kMuted),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              onTap: () {
                _search.clear();
                setState(() => _query = '');
              },
              child: Icon(Icons.close_rounded, color: _kMuted, size: 18.r),
            ),
        ],
      ),
    );
  }

  // ── on this day ──────────────────────────────────────────────────────────��─
  Widget _onThisDayCallout(List<JournalEntry> memories) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_kRed.withOpacity(0.08), _kStar.withOpacity(0.08)],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: _kRed.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: _kRed, size: 16.r),
              SizedBox(width: 6.w),
              Text('On this day',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 13.sp, fontWeight: FontWeight.w800, color: _kText)),
            ],
          ),
          SizedBox(height: 8.h),
          ...memories.map((e) => Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.journalDetailScreen,
                      arguments: e.date),
                  child: Row(
                    children: [
                      Text(_agoLabel(e.date),
                          style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: _kRed)),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          e.gratitudeItems.isNotEmpty
                              ? e.gratitudeItems.first
                              : e.dayText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 12.sp, color: _kText),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  String _agoLabel(DateTime d) {
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(d.year, d.month, d.day))
        .inDays;
    if (diff == 7) return '1 week ago';
    if (diff >= 28 && diff <= 31) return '1 month ago';
    if (diff >= 365) return '1 year ago';
    return DateFormat('MMM d, y').format(d);
  }

  // ── entry tile ───────────────────────────────────────────────────────────��─
  Widget _entryTile(JournalEntry e) {
    final firstLine = e.dayText.trim().isNotEmpty
        ? e.dayText.trim().split('\n').first
        : (e.gratitudeItems.isNotEmpty ? e.gratitudeItems.first : 'No notes');
    return GestureDetector(
      onTap: () =>
          Get.toNamed(AppRoutes.journalDetailScreen, arguments: e.date),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  DateFormat('EEE, MMM d, y').format(e.date),
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 13.sp, fontWeight: FontWeight.w800, color: _kText),
                ),
                if (e.edited) ...[
                  SizedBox(width: 6.w),
                  Text('· edited',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 9.sp,
                          fontStyle: FontStyle.italic,
                          color: _kMuted)),
                ],
                const Spacer(),
                if (e.mood != null)
                  Text(moodEmoji(e.mood), style: TextStyle(fontSize: 16.sp)),
              ],
            ),
            SizedBox(height: 6.h),
            if (e.starRating > 0)
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < e.starRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 14.r,
                    color: _kStar,
                  ),
                ),
              ),
            SizedBox(height: 6.h),
            Text(
              firstLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.spaceGrotesk.copyWith(fontSize: 12.sp, color: _kMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: EdgeInsets.only(top: 40.h),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.menu_book_rounded, color: _kRed.withOpacity(0.3), size: 44.r),
            SizedBox(height: 12.h),
            Text(
              _query.isEmpty ? 'No entries yet' : 'No matches found',
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 14.sp, fontWeight: FontWeight.w700, color: _kText),
            ),
            SizedBox(height: 4.h),
            Text(
              _query.isEmpty
                  ? 'Your saved entries will appear here.'
                  : 'Try a different keyword.',
              style: AppFonts.spaceGrotesk.copyWith(fontSize: 12.sp, color: _kMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lightweight sparkline (0..5) — no external chart dependency, so it can never
/// break the build if the charting package's API shifts.
class _SparklinePainter extends CustomPainter {
  _SparklinePainter(this.data);
  final List<double> data;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    const maxVal = 5.0;
    final n = data.length;
    final dx = n > 1 ? size.width / (n - 1) : size.width;

    final baseline = Paint()
      ..color = const Color(0xffE0DAD6)
      ..strokeWidth = 1;
    canvas.drawLine(
        Offset(0, size.height), Offset(size.width, size.height), baseline);

    Offset point(int i) {
      final v = data[i].clamp(0, maxVal);
      final y = size.height - (v / maxVal) * size.height;
      return Offset(i * dx, y);
    }

    final path = Path();
    final fill = Path();
    for (var i = 0; i < n; i++) {
      final p = point(i);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
        fill.moveTo(p.dx, size.height);
        fill.lineTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
        fill.lineTo(p.dx, p.dy);
      }
    }
    fill.lineTo((n - 1) * dx, size.height);
    fill.close();

    canvas.drawPath(
      fill,
      Paint()..color = _kRed.withOpacity(0.08),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = _kRed
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final dot = Paint()..color = _kRed;
    for (var i = 0; i < n; i++) {
      if (data[i] > 0) canvas.drawCircle(point(i), 2.5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) => old.data != data;
}
