import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import 'package:spanx/core/const/app_fonts.dart';

import '../controller/canvass_controller.dart';
import '../data/canvass_pin.dart';
import '../data/canvass_status.dart';

const _kText = Color(0xff17171C);
const _kMuted = Color(0xff8A8A96);
const _kBg = Color(0xffF6F6F9);

/// Open the pin editor. Pass [pin] to edit an existing one, or [dropAt] +
/// [address] to drop a new pin.
Future<void> showCanvassPinSheet(
  BuildContext context, {
  CanvassPin? pin,
  LatLng? dropAt,
  Map<String, String>? address,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _PinSheet(pin: pin, dropAt: dropAt, address: address ?? const {}),
  );
}

class _PinSheet extends StatefulWidget {
  final CanvassPin? pin;
  final LatLng? dropAt;
  final Map<String, String> address;
  const _PinSheet({this.pin, this.dropAt, required this.address});

  @override
  State<_PinSheet> createState() => _PinSheetState();
}

class _PinSheetState extends State<_PinSheet> {
  final CanvassController c = CanvassController.to;
  final _homeowner = TextEditingController();
  final _notes = TextEditingController();
  final _phone = TextEditingController();
  final _page = PageController();
  int _pageIndex = 0;
  bool _busy = false;

  // Local mirror of the pin's assignment so the sheet reflects changes live.
  String? _assignedRepId;
  String? _assignedRepName;

  bool get _isEdit => widget.pin != null;

  @override
  void initState() {
    super.initState();
    final p = widget.pin;
    if (p != null) {
      _homeowner.text = p.homeownerName ?? '';
      _notes.text = p.notes ?? '';
      _phone.text = p.phone ?? '';
      _assignedRepId = p.assignedRepId;
      _assignedRepName = p.assignedRepName;
    }
  }

  @override
  void dispose() {
    _homeowner.dispose();
    _notes.dispose();
    _phone.dispose();
    _page.dispose();
    super.dispose();
  }

  String get _title {
    final p = widget.pin;
    if (p != null) return p.shortAddress;
    final a = widget.address['address'] ?? '';
    if (a.isNotEmpty) return a;
    final ll = widget.dropAt;
    return ll == null
        ? 'New pin'
        : '${ll.latitude.toStringAsFixed(5)}, ${ll.longitude.toStringAsFixed(5)}';
  }

  Future<void> _pickStatus(CanvassStatus s) async {
    if (_busy) return;
    setState(() => _busy = true);
    if (_isEdit) {
      await c.updatePin(widget.pin!, {
        'status': s.code,
        'homeownerName': _homeowner.text.trim(),
        'notes': _notes.text.trim(),
        'phone': _phone.text.trim(),
      });
    } else {
      await c.drop(
        lat: widget.dropAt!.latitude,
        lng: widget.dropAt!.longitude,
        status: s.code,
        addr: widget.address,
        homeownerName: _homeowner.text.trim(),
        notes: _notes.text.trim(),
        phone: _phone.text.trim(),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _saveDetails() async {
    if (!_isEdit || _busy) return;
    setState(() => _busy = true);
    await c.updatePin(widget.pin!, {
      'homeownerName': _homeowner.text.trim(),
      'notes': _notes.text.trim(),
      'phone': _phone.text.trim(),
    });
    if (mounted) Navigator.pop(context);
  }

  void _confirmDelete() {
    Get.defaultDialog(
      title: 'Delete pin?',
      middleText: 'This removes the door and its history.',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xffEF4444),
      onConfirm: () {
        c.deletePin(widget.pin!);
        Get.back();
        Navigator.pop(context);
      },
    );
  }

  // ── Lead assignment ─────────────────────────────────────────────────────────
  Widget _assignSection() {
    final assigned = (_assignedRepId ?? '').isNotEmpty;

    // Reps only get a small read-only badge (and only when it's assigned).
    if (!c.isAdmin) {
      if (!assigned) return const SizedBox.shrink();
      return Padding(
        padding: EdgeInsets.only(top: 8.h),
        child: Align(
          alignment: Alignment.centerLeft,
          child: _assignedBadge('Assigned to $_assignedRepName'),
        ),
      );
    }

    // Admin: full assign / reassign control.
    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.grey.shade200)),
        child: Row(
          children: [
            Icon(Icons.person_pin_circle_rounded,
                size: 20.r, color: const Color(0xffF59E0B)),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('LEAD ASSIGNMENT',
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: _kMuted)),
                  SizedBox(height: 1.h),
                  Text(assigned ? _assignedRepName! : 'Not assigned',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: assigned ? _kText : _kMuted)),
                ],
              ),
            ),
            GestureDetector(
              onTap: _busy ? null : _openAssign,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                decoration: BoxDecoration(
                    color: const Color(0xff0F172A),
                    borderRadius: BorderRadius.circular(20.r)),
                child: Text(assigned ? 'Reassign' : 'Assign to rep',
                    style: AppFonts.spaceGrotesk.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.sp)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _assignedBadge(String label) => Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
            color: const Color(0xffF59E0B).withOpacity(0.14),
            borderRadius: BorderRadius.circular(20.r)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_pin_circle_rounded,
                size: 14.r, color: const Color(0xffB45309)),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xffB45309))),
            ),
          ],
        ),
      );

  Future<void> _openAssign() async {
    await c.ensureRoster();
    final reps = c.assignableReps;
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 6.h),
              child: Text('Assign this lead',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: _kText)),
            ),
            if (reps.isEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(18.w, 4.h, 18.w, 16.h),
                child: Text(
                    'No teammates yet. Reps show up here once they join your team with your invite code.',
                    style: AppFonts.spaceGrotesk
                        .copyWith(fontSize: 12.5.sp, color: _kMuted, height: 1.4)),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 340.h),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final r in reps)
                      _repRow(r.id, r.name, selected: r.id == _assignedRepId),
                  ],
                ),
              ),
            if ((_assignedRepId ?? '').isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(18.w, 6.h, 18.w, 6.h),
                child: GestureDetector(
                  onTap: () => _doAssign('', ''),
                  child: Row(
                    children: [
                      Icon(Icons.person_off_outlined,
                          size: 18.r, color: const Color(0xffEF4444)),
                      SizedBox(width: 8.w),
                      Text('Unassign',
                          style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xffEF4444))),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Widget _repRow(String id, String name, {required bool selected}) => InkWell(
        onTap: () => _doAssign(id, name),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
          child: Row(
            children: [
              CircleAvatar(
                radius: 15.r,
                backgroundColor: const Color(0xffF59E0B).withOpacity(0.18),
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: AppFonts.spaceGrotesk.copyWith(
                        color: const Color(0xffB45309),
                        fontWeight: FontWeight.w800,
                        fontSize: 12.sp)),
              ),
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
              if (selected)
                Icon(Icons.check_circle_rounded,
                    size: 20.r, color: const Color(0xffF59E0B)),
            ],
          ),
        ),
      );

  Future<void> _doAssign(String repId, String repName) async {
    Navigator.pop(context); // close the picker sheet
    final updated =
        await c.assign(widget.pin!, repId: repId, repName: repName);
    if (!mounted) return;
    setState(() {
      _assignedRepId =
          updated?.assignedRepId ?? (repId.isEmpty ? null : repId);
      _assignedRepName =
          updated?.assignedRepName ?? (repName.isEmpty ? null : repName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = _isEdit ? CanvassStatus.byCode(widget.pin!.status) : null;
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
            Row(
              children: [
                Icon(Icons.location_on_rounded,
                    color: current?.color ?? const Color(0xff8B5CF6), size: 22.r),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(_title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w800,
                          color: _kText)),
                ),
                if (_isEdit)
                  GestureDetector(
                    onTap: _confirmDelete,
                    child: Icon(Icons.delete_outline_rounded,
                        color: const Color(0xffEF4444), size: 22.r),
                  ),
              ],
            ),
            if (_isEdit) ...[
              SizedBox(height: 2.h),
              Text(
                  '${widget.pin!.repName} · visit ${widget.pin!.visitCount}'
                  '${current != null ? ' · ${current.label}' : ''}',
                  style:
                      AppFonts.spaceGrotesk.copyWith(fontSize: 11.sp, color: _kMuted)),
            ],
            if (_isEdit) _assignSection(),
            SizedBox(height: 12.h),
            _field(_homeowner, 'Homeowner name', Icons.person_outline_rounded),
            SizedBox(height: 8.h),
            _field(_phone, 'Phone', Icons.phone_outlined,
                keyboard: TextInputType.phone),
            SizedBox(height: 8.h),
            _field(_notes, 'Notes', Icons.notes_rounded, maxLines: 2),
            SizedBox(height: 14.h),
            Row(
              children: [
                Text(_isEdit ? 'UPDATE STATUS' : 'SET STATUS',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: _kMuted)),
                const Spacer(),
                Text(CanvassStatus.pageTitles[_pageIndex],
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: _kText)),
              ],
            ),
            SizedBox(height: 8.h),
            SizedBox(
              height: 168.h,
              child: PageView.builder(
                controller: _page,
                itemCount: 3,
                onPageChanged: (i) => setState(() => _pageIndex = i),
                itemBuilder: (_, page) {
                  final items = CanvassStatus.forPage(page + 1);
                  return GridView.count(
                    crossAxisCount: 3,
                    childAspectRatio: 1.55,
                    mainAxisSpacing: 8.h,
                    crossAxisSpacing: 8.w,
                    physics: const NeverScrollableScrollPhysics(),
                    children: items.map(_statusBtn).toList(),
                  );
                },
              ),
            ),
            SizedBox(height: 8.h),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                    3,
                    (i) => Container(
                          width: 7.r,
                          height: 7.r,
                          margin: EdgeInsets.symmetric(horizontal: 3.r),
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == _pageIndex
                                  ? _kText
                                  : Colors.grey.shade300),
                        )),
              ),
            ),
            if (_isEdit) ...[
              SizedBox(height: 10.h),
              GestureDetector(
                onTap: _saveDetails,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(color: Colors.grey.shade300)),
                  child: Center(
                    child: Text('Save details only',
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: _kText)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBtn(CanvassStatus s) {
    final selected = _isEdit && widget.pin!.status == s.code;
    return GestureDetector(
      onTap: () => _pickStatus(s),
      child: Container(
        decoration: BoxDecoration(
          color: s.color.withOpacity(selected ? 1 : 0.14),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
              color: s.color.withOpacity(selected ? 1 : 0.4),
              width: selected ? 2 : 1.2),
        ),
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(s.code,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: selected ? Colors.white : s.color)),
            SizedBox(height: 2.h),
            Text(s.label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 8.5.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.05,
                    color: selected
                        ? Colors.white
                        : _kText.withOpacity(0.75))),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      {int maxLines = 1, TextInputType? keyboard}) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12.r)),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 12.h),
            child: Icon(icon, size: 18.r, color: _kMuted),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              controller: ctrl,
              maxLines: maxLines,
              keyboardType: keyboard,
              textCapitalization: TextCapitalization.words,
              style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, color: _kText),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle:
                    AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, color: _kMuted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 11.h),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
