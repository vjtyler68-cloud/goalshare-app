import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:spanx/core/const/app_fonts.dart';

import '../controller/canvass_controller.dart';
import '../data/canvass_pin.dart';
import '../data/canvass_status.dart';
import 'canvass_lead_detail.dart';

const _kBg = Color(0xffF6F6F9);
const _kText = Color(0xff17171C);
const _kMuted = Color(0xff8A8A96);
const _kBrand = Color(0xff0F172A);
const _kGold = Color(0xffF59E0B);
const _kRed = Color(0xffEF4444);

enum _Sort { name, activity, days }

/// Canvass-style Pipeline funnel — Lead → Sale → Approved → Installed, with a
/// sortable, grouped lead list below. Reads the same pins the map uses.
class CanvassPipelineScreen extends StatefulWidget {
  const CanvassPipelineScreen({super.key});

  @override
  State<CanvassPipelineScreen> createState() => _CanvassPipelineScreenState();
}

class _CanvassPipelineScreenState extends State<CanvassPipelineScreen> {
  final CanvassController c = CanvassController.to;
  String? _stageFilter;
  _Sort _sort = _Sort.activity;

  String _displayName(CanvassPin p) =>
      (p.homeownerName?.isNotEmpty == true) ? p.homeownerName! : p.shortAddress;

  int _daysInStage(CanvassPin p) {
    final u = p.updatedAt;
    return u == null ? 0 : DateTime.now().difference(u).inDays;
  }

  String _latestEvent(CanvassPin p) {
    if (p.notesLog.isNotEmpty) {
      return (p.notesLog.last['text'] ?? '').toString();
    }
    return CanvassStatus.byCode(p.status).label;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBrand,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Pipeline',
            style: AppFonts.spaceGrotesk
                .copyWith(fontWeight: FontWeight.w800, fontSize: 17.sp)),
      ),
      body: Obx(() {
        // Only worked leads belong in the funnel — not un-knocked prospects.
        final all = c.pins.where((p) => p.status != 'NV').toList();
        final counts = {
          for (final s in CanvassPin.stages)
            s: all.where((p) => p.stage == s).length
        };
        final attention = all.where((p) => p.needsAttention).length;
        final avgDays = all.isEmpty
            ? 0
            : (all.map(_daysInStage).reduce((a, b) => a + b) / all.length)
                .round();

        var list = _stageFilter == null
            ? all
            : all.where((p) => p.stage == _stageFilter).toList();
        list = _sortList(list);

        return Column(
          children: [
            _funnel(counts),
            _stats(all.length, attention, avgDays),
            _sortRow(),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text('No leads here yet.',
                          style: AppFonts.spaceGrotesk
                              .copyWith(color: _kMuted, fontSize: 13.sp)))
                  : _leadList(list),
            ),
          ],
        );
      }),
    );
  }

  List<CanvassPin> _sortList(List<CanvassPin> list) {
    final l = [...list];
    switch (_sort) {
      case _Sort.name:
        l.sort((a, b) =>
            _displayName(a).toLowerCase().compareTo(_displayName(b).toLowerCase()));
        break;
      case _Sort.activity:
        l.sort((a, b) => (b.updatedAt ?? DateTime(0))
            .compareTo(a.updatedAt ?? DateTime(0)));
        break;
      case _Sort.days:
        l.sort((a, b) => _daysInStage(b).compareTo(_daysInStage(a)));
        break;
    }
    return l;
  }

  Widget _funnel(Map<String, int> counts) {
    return Container(
      color: _kBrand,
      padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 14.h),
      child: Row(
        children: [
          for (var i = 0; i < CanvassPin.stages.length; i++) ...[
            Expanded(child: _funnelCell(CanvassPin.stages[i], counts)),
            if (i < CanvassPin.stages.length - 1)
              Icon(Icons.chevron_right_rounded,
                  color: Colors.white38, size: 18.r),
          ],
        ],
      ),
    );
  }

  Widget _funnelCell(String stage, Map<String, int> counts) {
    final on = _stageFilter == stage;
    return GestureDetector(
      onTap: () => setState(() => _stageFilter = on ? null : stage),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        decoration: BoxDecoration(
            color: on ? _kGold : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10.r)),
        child: Column(
          children: [
            Text('${counts[stage] ?? 0}',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: on ? _kBrand : Colors.white)),
            Text(CanvassPin.stageLabels[stage]!,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 9.5.sp,
                    fontWeight: FontWeight.w700,
                    color: on ? _kBrand : Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _stats(int total, int attention, int avgDays) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 4.h),
      child: Row(
        children: [
          _statCard('$total', 'Total leads', _kText),
          SizedBox(width: 8.w),
          _statCard('$attention', 'Need attention', _kRed),
          SizedBox(width: 8.w),
          _statCard('$avgDays', 'Avg days in stage', _kText),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, Color color) => Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14.r)),
          child: Column(
            children: [
              Text(value,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w900,
                      color: color)),
              SizedBox(height: 2.h),
              Text(label,
                  textAlign: TextAlign.center,
                  style: AppFonts.spaceGrotesk
                      .copyWith(fontSize: 9.5.sp, color: _kMuted)),
            ],
          ),
        ),
      );

  Widget _sortRow() {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 6.h),
      child: Row(
        children: [
          Text('Sort:',
              style: AppFonts.spaceGrotesk
                  .copyWith(fontSize: 11.sp, color: _kMuted)),
          SizedBox(width: 8.w),
          _sortChip('Activity', _Sort.activity),
          SizedBox(width: 6.w),
          _sortChip('Name', _Sort.name),
          SizedBox(width: 6.w),
          _sortChip('Days', _Sort.days),
        ],
      ),
    );
  }

  Widget _sortChip(String label, _Sort s) {
    final on = _sort == s;
    return GestureDetector(
      onTap: () => setState(() => _sort = s),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
            color: on ? _kBrand : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: on ? _kBrand : const Color(0xffE6E6EC))),
        child: Text(label,
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: on ? Colors.white : _kText)),
      ),
    );
  }

  Widget _leadList(List<CanvassPin> list) {
    // Alphabetical section headers only when sorting by name.
    if (_sort != _Sort.name) {
      return ListView.separated(
        padding: EdgeInsets.fromLTRB(12.w, 6.h, 12.w, 30.h),
        itemCount: list.length,
        separatorBuilder: (_, __) => SizedBox(height: 8.h),
        itemBuilder: (_, i) => _leadRow(list[i]),
      );
    }
    final widgets = <Widget>[];
    String? letter;
    for (final p in list) {
      final l = _displayName(p).substring(0, 1).toUpperCase();
      if (l != letter) {
        letter = l;
        widgets.add(Padding(
          padding: EdgeInsets.fromLTRB(4.w, 12.h, 4.w, 6.h),
          child: Text(letter,
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w900,
                  color: _kMuted)),
        ));
      }
      widgets.add(Padding(
          padding: EdgeInsets.only(bottom: 8.h), child: _leadRow(p)));
    }
    return ListView(
      padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 30.h),
      children: widgets,
    );
  }

  Widget _leadRow(CanvassPin p) {
    final st = CanvassStatus.byCode(p.status);
    final attention = p.needsAttention;
    final pillText = attention
        ? '${CanvassPin.actionItemLabels[CanvassPin.actionItemLabels.keys.firstWhere((k) => !p.actionDone(k))]} missing'
        : st.label;
    final pillColor = attention ? _kRed : st.color;
    return GestureDetector(
      onTap: () => Get.to(() => CanvassLeadDetailScreen(pinId: p.id)),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12.r)),
        child: Row(
          children: [
            Container(
                width: 4.w,
                height: 40.h,
                decoration: BoxDecoration(
                    color: st.color, borderRadius: BorderRadius.circular(4.r))),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_displayName(p),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: _kText)),
                  SizedBox(height: 2.h),
                  Text(_latestEvent(p),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.spaceGrotesk
                          .copyWith(fontSize: 11.sp, color: _kMuted)),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                      color: pillColor.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10.r)),
                  child: Text(pillText,
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w700,
                          color: pillColor)),
                ),
                SizedBox(height: 3.h),
                Text(
                    p.updatedAt == null
                        ? ''
                        : DateFormat('MMM d').format(p.updatedAt!.toLocal()),
                    style: AppFonts.spaceGrotesk
                        .copyWith(fontSize: 9.sp, color: _kMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
