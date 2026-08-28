import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:spanx/core/const/app_fonts.dart';

import '../controller/canvass_controller.dart';
import '../data/canvass_pin.dart';
import '../data/canvass_status.dart';
import '../data/canvass_territory.dart';
import 'canvass_pin_sheet.dart';

const _kText = Color(0xff17171C);
const _kMuted = Color(0xff8A8A96);
const _kBg = Color(0xffF6F6F9);

/// Shown right after an admin finishes tracing an area — name it, pick a color,
/// assign reps, save. Resolves true when a territory is created.
Future<bool?> showCreateTerritorySheet(
    BuildContext context, List<LatLng> points) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TerritoryEditor(points: points),
  );
}

/// Tap an existing area — see who's assigned + the leads inside, reassign,
/// rename/recolor, or delete.
Future<void> showTerritorySheet(BuildContext context, CanvassTerritory t) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TerritoryView(territory: t),
  );
}

// ── Create / edit editor ──────────────────────────────────────────────────────
class _TerritoryEditor extends StatefulWidget {
  final List<LatLng>? points; // create
  final CanvassTerritory? territory; // edit
  const _TerritoryEditor({this.points, this.territory});

  @override
  State<_TerritoryEditor> createState() => _TerritoryEditorState();
}

class _TerritoryEditorState extends State<_TerritoryEditor> {
  final CanvassController c = CanvassController.to;
  final _name = TextEditingController();
  late String _color;
  final Set<String> _repIds = {};
  bool _busy = false;

  bool get _isEdit => widget.territory != null;

  @override
  void initState() {
    super.initState();
    final t = widget.territory;
    _name.text = t?.name ?? '';
    _color = t?.color ?? CanvassTerritory.palette.first;
    if (t != null) _repIds.addAll(t.assignedRepIds);
    // Make sure the roster is loaded so the rep list has names.
    c.ensureRoster().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    final reps = c.assignableReps;
    final ids = _repIds.toList();
    final names = [
      for (final id in ids)
        reps.firstWhere((r) => r.id == id, orElse: () => (id: id, name: 'Rep')).name
    ];
    final name = _name.text.trim().isEmpty ? 'Territory' : _name.text.trim();

    if (_isEdit) {
      await c.updateTerritory(widget.territory!, {
        'name': name,
        'color': _color,
        'assignedRepIds': ids,
        'assignedRepNames': names,
      });
      if (mounted) Navigator.pop(context);
    } else {
      final created = await c.createTerritory(
        points: widget.points!,
        name: name,
        color: _color,
        repIds: ids,
        repNames: names,
      );
      if (mounted) Navigator.pop(context, created != null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reps = c.assignableReps;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
        ),
        padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4.r)),
              ),
            ),
            SizedBox(height: 12.h),
            Text(_isEdit ? 'Edit area' : 'New area',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: _kText)),
            SizedBox(height: 12.h),
            _fieldWrap(TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, color: _kText),
              decoration: InputDecoration(
                hintText: 'Area name (e.g. West Robinson)',
                hintStyle: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 13.sp, color: _kMuted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
              ),
            )),
            SizedBox(height: 12.h),
            Text('COLOR',
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: _kMuted)),
            SizedBox(height: 8.h),
            Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children: [
                for (final hex in CanvassTerritory.palette)
                  _colorDot(hex),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Text('ASSIGN TO',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: _kMuted)),
                const Spacer(),
                if (_repIds.isNotEmpty)
                  Text('${_repIds.length} selected',
                      style: AppFonts.spaceGrotesk
                          .copyWith(fontSize: 11.sp, color: _kMuted)),
              ],
            ),
            SizedBox(height: 6.h),
            if (reps.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Text(
                    'No teammates yet. Reps show up once they join your team with your invite code.',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 12.5.sp, color: _kMuted, height: 1.4)),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 220.h),
                child: SingleChildScrollView(
                  child: Column(
                    children: [for (final r in reps) _repRow(r.id, r.name)],
                  ),
                ),
              ),
            SizedBox(height: 14.h),
            GestureDetector(
              onTap: _busy ? null : _save,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                    color: const Color(0xff0F172A),
                    borderRadius: BorderRadius.circular(26.r)),
                child: Center(
                  child: _busy
                      ? SizedBox(
                          width: 18.r,
                          height: 18.r,
                          child: const CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(_isEdit ? 'Save area' : 'Create area',
                          style: AppFonts.spaceGrotesk.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14.sp)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldWrap(Widget child) => Container(
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12.r)),
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: child,
      );

  Widget _colorDot(String hex) {
    final t = CanvassTerritory(id: '', orgId: '', color: hex);
    final selected = _color == hex;
    return GestureDetector(
      onTap: () => setState(() => _color = hex),
      child: Container(
        width: 34.r,
        height: 34.r,
        decoration: BoxDecoration(
          color: t.colorValue,
          shape: BoxShape.circle,
          border: Border.all(
              color: selected ? _kText : Colors.transparent, width: 2.5),
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : null,
      ),
    );
  }

  Widget _repRow(String id, String name) {
    final on = _repIds.contains(id);
    return InkWell(
      onTap: () => setState(() => on ? _repIds.remove(id) : _repIds.add(id)),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 9.h),
        child: Row(
          children: [
            Icon(on ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 22.r,
                color: on ? const Color(0xffF59E0B) : Colors.grey.shade400),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: _kText)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Territory detail view ─────────────────────────────────────────────────────
class _TerritoryView extends StatefulWidget {
  final CanvassTerritory territory;
  const _TerritoryView({required this.territory});

  @override
  State<_TerritoryView> createState() => _TerritoryViewState();
}

class _TerritoryViewState extends State<_TerritoryView> {
  final CanvassController c = CanvassController.to;

  CanvassTerritory get t =>
      c.territories.firstWhereOrNull((x) => x.id == widget.territory.id) ??
      widget.territory;

  void _confirmDelete() {
    Get.defaultDialog(
      title: 'Delete area?',
      middleText:
          'This removes the "${t.name}" area. Doors inside stay on the map.',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xffEF4444),
      onConfirm: () {
        c.deleteTerritory(t);
        Get.back();
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Recompute against live controller state.
      final territory = t;
      final leads = c.pinsInTerritory(territory);
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(maxHeight: 0.82.sh),
          decoration: BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
          ),
          padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4.r)),
                ),
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Container(
                    width: 14.r,
                    height: 14.r,
                    decoration: BoxDecoration(
                        color: territory.colorValue, shape: BoxShape.circle),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(territory.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            color: _kText)),
                  ),
                  if (c.isAdmin) ...[
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => _TerritoryEditor(territory: territory),
                        );
                      },
                      child: Icon(Icons.edit_rounded,
                          size: 20.r, color: _kMuted),
                    ),
                    SizedBox(width: 14.w),
                    GestureDetector(
                      onTap: _confirmDelete,
                      child: Icon(Icons.delete_outline_rounded,
                          size: 22.r, color: const Color(0xffEF4444)),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 8.h),
              // Assigned reps
              Wrap(
                spacing: 6.w,
                runSpacing: 6.h,
                children: [
                  if (territory.assignedRepNames.isEmpty)
                    _chip('Unassigned', _kMuted)
                  else
                    for (final n in territory.assignedRepNames)
                      _chip(n, const Color(0xffB45309),
                          bg: const Color(0xffF59E0B).withOpacity(0.16)),
                ],
              ),
              SizedBox(height: 14.h),
              Row(
                children: [
                  Text('LEADS IN THIS AREA',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: _kMuted)),
                  const Spacer(),
                  Text('${leads.length}',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w900,
                          color: _kText)),
                ],
              ),
              SizedBox(height: 6.h),
              Flexible(
                child: leads.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 18.h),
                        child: Text('No doors dropped inside this area yet.',
                            style: AppFonts.spaceGrotesk
                                .copyWith(fontSize: 12.5.sp, color: _kMuted)),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: leads.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8.h),
                        itemBuilder: (_, i) => _leadRow(leads[i]),
                      ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _chip(String label, Color fg, {Color? bg}) => Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
            color: bg ?? Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16.r)),
        child: Text(label,
            style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 11.5.sp, fontWeight: FontWeight.w700, color: fg)),
      );

  Widget _leadRow(CanvassPin p) {
    final st = CanvassStatus.byCode(p.status);
    final who = (p.homeownerName != null && p.homeownerName!.isNotEmpty)
        ? p.homeownerName!
        : p.shortAddress;
    final owner = (p.assignedRepName != null && p.assignedRepName!.isNotEmpty)
        ? p.assignedRepName!
        : p.repName;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        showCanvassPinSheet(context, pin: p);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12.r)),
        child: Row(
          children: [
            Container(
              width: 4.w,
              height: 40.h,
              decoration: BoxDecoration(
                  color: st.color, borderRadius: BorderRadius.circular(4.r)),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(who,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 13.5.sp,
                          fontWeight: FontWeight.w700,
                          color: _kText)),
                  SizedBox(height: 2.h),
                  Text('${st.label} · $owner',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.spaceGrotesk
                          .copyWith(fontSize: 11.sp, color: _kMuted)),
                ],
              ),
            ),
            if (p.phone != null && p.phone!.isNotEmpty)
              GestureDetector(
                onTap: () => launchUrl(Uri.parse('tel:${p.phone}')),
                child: Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: Icon(Icons.call_rounded,
                      size: 20.r, color: const Color(0xffF59E0B)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
