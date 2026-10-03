import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spanx/core/const/app_fonts.dart';

/// "Weeks of My Life" — a memento-mori life calendar: 88 years × 52 weeks =
/// 4,576 boxes, one per week. The weeks you've already lived fill in from your
/// birthday, the week you're in glows, and the rest sit empty — the whole point
/// of GoalShare in one screen: make them count.
///
/// Self-contained: the birthday is stored on-device (SharedPreferences), so no
/// controller or backend is needed. Pure Flutter — no native code.
class LifeWeeksScreen extends StatefulWidget {
  /// True when shown as a bottom-nav TAB (no back button; leaves room under the
  /// footer for the nav bar). False when pushed as its own route.
  final bool isTab;
  const LifeWeeksScreen({super.key, this.isTab = false});

  @override
  State<LifeWeeksScreen> createState() => _LifeWeeksScreenState();
}

class _LifeWeeksScreenState extends State<LifeWeeksScreen> {
  // Memento-mori palette — a serious, focused dark canvas so the grid lands.
  static const _bg = Color(0xff0B1120);
  static const _panel = Color(0xff111a2e);
  static const _lived = Color(0xffF97316); // weeks already spent
  static const _future = Color(0x1FFFFFFF); // faint outline for weeks to come
  static const _muted = Color(0xff8A93A6);

  static const int _years = 88;
  static const int _weeksPerYear = 52;
  static const int _total = _years * _weeksPerYear; // 4,576
  // Weeks older than this (≈ the last month) come pre-claimed (filled) — you
  // only actively claim the recent weeks. "all buttons come clicked up until the
  // last month."
  static const int _activeWeeks = 4;

  static const String _dobKey = 'life_weeks_dob';
  static const String _wonKey = 'life_weeks_won';

  DateTime? _dob;
  bool _loading = true;
  // Weeks the user has crossed off — the ones they made count. Bumping [_rev]
  // on every change tells the CustomPainter to repaint.
  final Set<int> _won = <int>{};
  int _rev = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_dobKey);
      if (raw != null) _dob = DateTime.tryParse(raw);
      final won = prefs.getString(_wonKey);
      if (won != null && won.isNotEmpty) {
        for (final s in won.split(',')) {
          final n = int.tryParse(s);
          if (n != null) _won.add(n);
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveWon() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_wonKey, _won.join(','));
    } catch (_) {}
  }

  /// Cross off (or un-cross) a week — only weeks you've actually lived.
  void _onGridTap(Offset pos, Size size) {
    final g = _gridGeo(size);
    if (g.cell <= 0) return;
    final col = ((pos.dx - g.ox) / (g.cell + g.gap)).floor();
    final row = ((pos.dy - g.oy) / (g.cell + g.gap)).floor();
    if (col < 0 || col >= _weeksPerYear || row < 0 || row >= _years) return;
    final idx = row * _weeksPerYear + col;
    // Only the recent weeks (the last month) + the current week are tappable —
    // everything older is already claimed automatically.
    if (idx < _activeStart || idx > _weeksLived) return;
    setState(() {
      if (!_won.remove(idx)) _won.add(idx);
      _rev++;
    });
    _saveWon();
  }

  /// Index where the "active" (manually-claimable) window starts — about a month
  /// of weeks back from now. Everything before this is auto-claimed/filled.
  int get _activeStart {
    final s = _weeksLived - _activeWeeks;
    return s < 0 ? 0 : s;
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'When were you born?',
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _lived,
            onPrimary: Colors.white,
            surface: _panel,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: _panel),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dobKey, picked.toIso8601String());
    } catch (_) {}
    if (mounted) setState(() => _dob = picked);
  }

  // ── Life math ────────────────────────────────────────────────────────────────
  int get _weeksLived {
    final dob = _dob;
    if (dob == null) return 0;
    final days = DateTime.now().difference(dob).inDays;
    if (days <= 0) return 0;
    return (days ~/ 7).clamp(0, _total);
  }

  int get _age {
    final dob = _dob;
    if (dob == null) return 0;
    final now = DateTime.now();
    var a = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      a--;
    }
    return a < 0 ? 0 : a;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: _lived, strokeWidth: 2))
            : Column(
                children: [
                  _header(),
                  Expanded(child: _dob == null ? _setupBody() : _gridBody()),
                ],
              ),
      ),
    );
  }

  Widget _header() => Padding(
        padding: EdgeInsets.fromLTRB(6.w, 6.h, 16.w, 4.h),
        child: Row(
          children: [
            if (!widget.isTab)
              IconButton(
                onPressed: Get.back,
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              )
            else
              SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WEEKS OF MY LIFE',
                    style: AppFonts.spaceGrotesk.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 17.sp,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    '88 years · 4,576 weeks',
                    style: AppFonts.spaceGrotesk
                        .copyWith(color: _muted, fontSize: 10.5.sp),
                  ),
                ],
              ),
            ),
            if (_dob != null)
              TextButton.icon(
                onPressed: _pickDob,
                icon: Icon(Icons.edit_calendar_rounded,
                    color: _lived, size: 16.r),
                label: Text('Birthday',
                    style: AppFonts.spaceGrotesk.copyWith(
                        color: _lived,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      );

  // ── First run: ask for the birthday ──────────────────────────────────────────
  Widget _setupBody() => Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.grid_view_rounded, size: 54.r, color: _lived),
              SizedBox(height: 18.h),
              Text(
                'See your whole life on one screen',
                textAlign: TextAlign.center,
                style: AppFonts.spaceGrotesk.copyWith(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    height: 1.25),
              ),
              SizedBox(height: 10.h),
              Text(
                'Every box is one week. Set your birthday and watch the weeks '
                'you\'ve lived fill in — a reminder to make the rest count.',
                textAlign: TextAlign.center,
                style: AppFonts.spaceGrotesk
                    .copyWith(color: _muted, fontSize: 12.5.sp, height: 1.4),
              ),
              SizedBox(height: 26.h),
              GestureDetector(
                onTap: _pickDob,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 30.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    color: _lived,
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                  child: Text('Set my birthday',
                      style: AppFonts.spaceGrotesk.copyWith(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      );

  // ── The life grid + stats ─────────────────────────────────────────────────────
  Widget _gridBody() {
    final lived = _weeksLived;
    final activeStart = _activeStart;
    // Claimed = the auto-filled past (everything before the last month) + any of
    // the recent weeks you've tapped.
    final claimed =
        activeStart + _won.where((i) => i >= activeStart && i <= lived).length;
    final pct = lived / _total * 100;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, widget.isTab ? 84.h : 14.h),
      child: Column(
        children: [
          Row(
            children: [
              _stat('AGE', '$_age'),
              _stat('LIVED', _fmt(lived)),
              _stat('CLAIMED', _fmt(claimed)),
              _stat('% LIVED', '${pct.toStringAsFixed(1)}%'),
            ],
          ),
          SizedBox(height: 10.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: (lived / _total).clamp(0.0, 1.0),
              minHeight: 6.h,
              backgroundColor: _future,
              valueColor: const AlwaysStoppedAnimation(_lived),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Pinch to zoom · tap a week to claim it 🔥',
            textAlign: TextAlign.center,
            style: AppFonts.spaceGrotesk
                .copyWith(color: _muted, fontSize: 10.5.sp),
          ),
          SizedBox(height: 10.h),
          Expanded(
            child: LayoutBuilder(
              builder: (ctx, cons) {
                final size = Size(cons.maxWidth, cons.maxHeight);
                // Pinch to zoom in on any stretch of weeks (and pan around);
                // pinch back out to see the whole life. Taps still map to the
                // right week at any zoom — InteractiveViewer hands the child
                // untransformed local coordinates.
                return InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 8.0,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) => _onGridTap(d.localPosition, size),
                    child: CustomPaint(
                      size: size,
                      painter: _LifeGridPainter(
                          lived: lived,
                          activeStart: activeStart,
                          won: _won,
                          rev: _rev),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'You\'ve claimed ${_fmt(claimed)} of 4,576 weeks — make the rest count.',
            textAlign: TextAlign.center,
            style: AppFonts.spaceGrotesk.copyWith(
                color: Colors.white,
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: AppFonts.spaceGrotesk.copyWith(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900)),
            SizedBox(height: 2.h),
            Text(label,
                style: AppFonts.spaceGrotesk.copyWith(
                    color: _muted,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6)),
          ],
        ),
      );

  String _fmt(int n) => NumberFormat.decimalPattern().format(n);
}

/// Shared grid geometry so the painter and the tap hit-test agree exactly.
({double cell, double gap, double ox, double oy}) _gridGeo(Size size) {
  const cols = 52, rows = 88, gap = 1.6;
  final cw = (size.width - gap * (cols - 1)) / cols;
  final ch = (size.height - gap * (rows - 1)) / rows;
  final cell = math.min(cw, ch);
  final gridW = cols * cell + (cols - 1) * gap;
  final gridH = rows * cell + (rows - 1) * gap;
  return (
    cell: cell,
    gap: gap,
    ox: (size.width - gridW) / 2,
    oy: (size.height - gridH) / 2,
  );
}

/// Draws the 88×52 grid, fit to the available space (whole life at a glance).
/// Crossed-off weeks glow bright; weeks lived-but-not-crossed sit dim; the
/// current week is marked; weeks to come are faint outlines.
class _LifeGridPainter extends CustomPainter {
  final int lived;
  final int activeStart; // weeks before this are auto-claimed (bright)
  final Set<int> won;
  final int rev;
  const _LifeGridPainter({
    required this.lived,
    required this.activeStart,
    required this.won,
    required this.rev,
  });

  static const int _cols = 52;
  static const int _rows = 88;

  static const _wonColor = Color(0xffF97316); // crossed off — made it count
  static const _livedColor = Color(0x66F97316); // lived, not yet crossed off
  static const _currentColor = Colors.white; // the week you're in
  static const _futureColor = Color(0x24FFFFFF); // weeks to come

  @override
  void paint(Canvas canvas, Size size) {
    final g = _gridGeo(size);
    final cell = g.cell;
    if (cell <= 0) return;
    final radius = Radius.circular(cell * 0.28);

    final wonPaint = Paint()
      ..color = _wonColor
      ..style = PaintingStyle.fill;
    final livedPaint = Paint()
      ..color = _livedColor
      ..style = PaintingStyle.fill;
    final currentPaint = Paint()
      ..color = _currentColor
      ..style = PaintingStyle.fill;
    final futureStroke = math.max(0.6, cell * 0.12);
    final futurePaint = Paint()
      ..color = _futureColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = futureStroke;
    // Soft glow ring around the current week so "you are here" pops.
    final glowPaint = Paint()
      ..color = _currentColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, cell * 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    for (var row = 0; row < _rows; row++) {
      for (var col = 0; col < _cols; col++) {
        final idx = row * _cols + col;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(g.ox + col * (cell + g.gap),
              g.oy + row * (cell + g.gap), cell, cell),
          radius,
        );
        if (won.contains(idx) || idx < activeStart) {
          // Claimed: everything older than the last month is auto-filled, plus
          // any recent week you've tapped.
          canvas.drawRRect(rect, wonPaint);
        } else if (idx < lived) {
          // The last ~month of lived weeks — your active, claimable zone.
          canvas.drawRRect(rect, livedPaint);
        } else if (idx == lived) {
          canvas.drawRRect(rect.inflate(cell * 0.15), glowPaint);
          canvas.drawRRect(rect, currentPaint);
        } else {
          canvas.drawRRect(rect.deflate(futureStroke / 2), futurePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_LifeGridPainter old) =>
      old.lived != lived || old.rev != rev || old.activeStart != activeStart;
}
