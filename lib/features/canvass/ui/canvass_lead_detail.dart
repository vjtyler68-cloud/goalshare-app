import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:spanx/core/const/app_fonts.dart';

import '../controller/canvass_controller.dart';
import '../data/canvass_pin.dart';
import '../data/canvass_status.dart';

const _kBg = Color(0xffF6F6F9);
const _kText = Color(0xff17171C);
const _kMuted = Color(0xff8A8A96);
const _kBrand = Color(0xff0F172A);
const _kGold = Color(0xffF59E0B);

/// Canvass-style full Lead Detail — Accounts | Profile | History. Opened from
/// the map's Lead Quick Card or the Pipeline list.
class CanvassLeadDetailScreen extends StatefulWidget {
  final String pinId;
  const CanvassLeadDetailScreen({super.key, required this.pinId});

  @override
  State<CanvassLeadDetailScreen> createState() =>
      _CanvassLeadDetailScreenState();
}

class _CanvassLeadDetailScreenState extends State<CanvassLeadDetailScreen>
    with SingleTickerProviderStateMixin {
  final CanvassController c = CanvassController.to;
  late final TabController _tab;

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _kw = TextEditingController();
  final _perMonth = TextEditingController();
  final _perKwh = TextEditingController();

  CanvassPin? get _pin {
    for (final p in c.pins) {
      if (p.id == widget.pinId) return p;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    final p = _pin;
    if (p != null) {
      _name.text = p.homeownerName ?? '';
      _phone.text = p.phone ?? '';
      _email.text = p.contactEmail ?? '';
      _address.text = p.address;
      _kw.text = _fmtNum(p.systemSizeKw);
      _perMonth.text = _fmtNum(p.leaseRatePerMonth);
      _perKwh.text = _fmtNum(p.leaseRatePerKwh);
    }
  }

  String _fmtNum(num? n) => n == null ? '' : (n == n.roundToDouble() ? n.toInt().toString() : n.toString());

  @override
  void dispose() {
    _tab.dispose();
    for (final ctrl in [_name, _phone, _email, _address, _kw, _perMonth, _perKwh]) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final p = _pin;
      if (p == null) {
        return Scaffold(
          backgroundColor: _kBg,
          appBar: AppBar(backgroundColor: _kBrand, foregroundColor: Colors.white),
          body: Center(
            child: Text('Lead not found.',
                style: AppFonts.spaceGrotesk.copyWith(color: _kMuted)),
          ),
        );
      }
      final st = CanvassStatus.byCode(p.status);
      return Scaffold(
        backgroundColor: _kBg,
        appBar: AppBar(
          backgroundColor: _kBrand,
          foregroundColor: Colors.white,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.homeownerName?.isNotEmpty == true ? p.homeownerName! : p.shortAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 15.sp, fontWeight: FontWeight.w800)),
              Text('${st.label} · ${p.stageLabel}',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 10.5.sp, color: Colors.white70)),
            ],
          ),
          bottom: TabBar(
            controller: _tab,
            indicatorColor: _kGold,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            labelStyle: AppFonts.spaceGrotesk
                .copyWith(fontWeight: FontWeight.w800, fontSize: 12.5.sp),
            tabs: const [
              Tab(text: 'Accounts'),
              Tab(text: 'Profile'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tab,
          children: [_accounts(p), _profile(p), _history(p)],
        ),
      );
    });
  }

  // ── Accounts tab ────────────────────────────────────────────────────────────
  Widget _accounts(CanvassPin p) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 30.h),
      children: [
        _card(
          title: 'PIPELINE STAGE',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (var i = 0; i < CanvassPin.stages.length; i++)
                    Expanded(child: _stageChip(p, CanvassPin.stages[i], i)),
                ],
              ),
              SizedBox(height: 6.h),
              Text('Days in stage: ${_daysInStage(p)}',
                  style: AppFonts.spaceGrotesk
                      .copyWith(fontSize: 11.sp, color: _kMuted)),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        _quickActions(p),
        SizedBox(height: 12.h),
        _card(
          title: 'ACTION ITEMS',
          child: Column(
            children: [
              for (final e in CanvassPin.actionItemLabels.entries)
                _actionRow(p, e.key, e.value),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        _card(
          title: 'DEAL TERMS',
          child: Column(
            children: [
              _numField(_kw, 'System size (kW)', Icons.solar_power_outlined),
              SizedBox(height: 8.h),
              _numField(_perMonth, 'Lease \$ / month', Icons.calendar_month_outlined),
              SizedBox(height: 8.h),
              _numField(_perKwh, 'Lease \$ / kWh', Icons.bolt_outlined),
              SizedBox(height: 12.h),
              _saveBtn('Save deal terms', () {
                c.updatePin(p, {
                  'systemSizeKw': _kw.text.trim(),
                  'leaseRatePerMonth': _perMonth.text.trim(),
                  'leaseRatePerKwh': _perKwh.text.trim(),
                });
                _toast('Deal terms saved');
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stageChip(CanvassPin p, String stage, int i) {
    final on = p.stage == stage;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      child: GestureDetector(
        onTap: () => c.updatePin(p, {'stage': stage}),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 9.h),
          decoration: BoxDecoration(
              color: on ? _kGold : _kGold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10.r)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${i + 1}',
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                      color: on ? Colors.white : _kGold)),
              SizedBox(height: 2.h),
              Text(CanvassPin.stageLabels[stage]!,
                  style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                      color: on ? Colors.white : _kText)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActions(CanvassPin p) {
    return _card(
      title: 'QUICK ACTIONS',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _action(Icons.call_rounded, 'Call',
              (p.phone ?? '').isEmpty ? null : () => _launch('tel:${p.phone}')),
          _action(Icons.message_rounded, 'Text',
              (p.phone ?? '').isEmpty ? null : () => _launch('sms:${p.phone}')),
          _action(
              Icons.email_rounded,
              'Email',
              (p.contactEmail ?? '').isEmpty
                  ? null
                  : () => _launch('mailto:${p.contactEmail}')),
          _action(Icons.note_add_rounded, 'Note', () => _addNote(p)),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback? onTap) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46.r,
            height: 46.r,
            decoration: BoxDecoration(
                color: enabled ? _kBrand : Colors.grey.shade200,
                shape: BoxShape.circle),
            child: Icon(icon,
                color: enabled ? Colors.white : Colors.grey, size: 20.r),
          ),
          SizedBox(height: 5.h),
          Text(label,
              style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w700,
                  color: enabled ? _kText : _kMuted)),
        ],
      ),
    );
  }

  Widget _actionRow(CanvassPin p, String key, String label) {
    final done = p.actionDone(key);
    return GestureDetector(
      onTap: () => c.updatePin(p, {
        'actionItems': {key: !done}
      }),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            Icon(done ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 22.r, color: done ? const Color(0xff22C55E) : Colors.grey.shade400),
            SizedBox(width: 12.w),
            Text(label,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: done ? _kMuted : _kText,
                    decoration: done ? TextDecoration.lineThrough : null)),
          ],
        ),
      ),
    );
  }

  // ── Profile tab ─────────────────────────────────────────────────────────────
  Widget _profile(CanvassPin p) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 30.h),
      children: [
        _card(
          title: 'CONTACT',
          child: Column(
            children: [
              _txtField(_name, 'Homeowner name', Icons.person_outline_rounded),
              SizedBox(height: 8.h),
              _txtField(_phone, 'Phone', Icons.phone_outlined,
                  keyboard: TextInputType.phone),
              SizedBox(height: 8.h),
              _txtField(_email, 'Email', Icons.email_outlined,
                  keyboard: TextInputType.emailAddress),
              SizedBox(height: 8.h),
              _txtField(_address, 'Address', Icons.location_on_outlined),
              SizedBox(height: 12.h),
              _saveBtn('Save profile', () {
                c.updatePin(p, {
                  'homeownerName': _name.text.trim(),
                  'phone': _phone.text.trim(),
                  'contactEmail': _email.text.trim(),
                  'address': _address.text.trim(),
                });
                _toast('Profile saved');
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ── History tab ─────────────────────────────────────────────────────────────
  Widget _history(CanvassPin p) {
    final events = <Map<String, dynamic>>[];
    for (final h in p.statusHistory) {
      events.add({'kind': 'status', ...h});
    }
    for (final n in p.notesLog) {
      events.add({'kind': 'note', ...n});
    }
    events.sort((a, b) => (DateTime.tryParse('${b['at']}') ?? DateTime(0))
        .compareTo(DateTime.tryParse('${a['at']}') ?? DateTime(0)));

    if (events.isEmpty) {
      return Center(
        child: Text('No activity yet.',
            style: AppFonts.spaceGrotesk.copyWith(color: _kMuted, fontSize: 13.sp)),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 30.h),
      itemCount: events.length,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (_, i) => _historyRow(events[i]),
    );
  }

  Widget _historyRow(Map<String, dynamic> e) {
    final isNote = e['kind'] == 'note';
    final who = (e['repName'] ?? 'Rep').toString();
    final at = DateTime.tryParse('${e['at']}');
    final when = at == null ? '' : DateFormat('MMM d, h:mm a').format(at.toLocal());
    final title = isNote
        ? (e['text'] ?? '').toString()
        : 'Status → ${CanvassStatus.byCode(e['status']?.toString()).label}';
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12.r)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isNote ? Icons.sticky_note_2_outlined : Icons.timeline_rounded,
              size: 18.r, color: _kGold),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: _kText)),
                SizedBox(height: 2.h),
                Text('$who · $when',
                    style: AppFonts.spaceGrotesk
                        .copyWith(fontSize: 10.5.sp, color: _kMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared bits ─────────────────────────────────────────────────────────────
  int _daysInStage(CanvassPin p) {
    final u = p.updatedAt;
    if (u == null) return 0;
    return DateTime.now().difference(u).inDays;
  }

  Future<void> _addNote(CanvassPin p) async {
    final ctrl = TextEditingController();
    await Get.dialog(AlertDialog(
      backgroundColor: Colors.white,
      title: Text('New note',
          style: AppFonts.spaceGrotesk
              .copyWith(fontWeight: FontWeight.w800, color: _kText)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        maxLines: 3,
        style: AppFonts.spaceGrotesk.copyWith(color: _kText),
        decoration: const InputDecoration(hintText: 'What happened at this door?'),
      ),
      actions: [
        TextButton(onPressed: Get.back, child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            final t = ctrl.text.trim();
            Get.back();
            if (t.isNotEmpty) {
              c.updatePin(p, {'addNote': t});
              _toast('Note added');
            }
          },
          child: const Text('Add'),
        ),
      ],
    ));
  }

  void _launch(String uri) => launchUrl(Uri.parse(uri));

  void _toast(String msg) => Get.rawSnackbar(
        message: msg,
        duration: const Duration(seconds: 2),
        margin: EdgeInsets.all(12.r),
        borderRadius: 12,
        backgroundColor: _kBrand,
      );

  Widget _card({required String title, required Widget child}) => Container(
        padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 14.h),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: _kMuted)),
            SizedBox(height: 10.h),
            child,
          ],
        ),
      );

  Widget _txtField(TextEditingController ctrl, String hint, IconData icon,
          {TextInputType? keyboard}) =>
      _fieldBox(ctrl, hint, icon, keyboard: keyboard);

  Widget _numField(TextEditingController ctrl, String hint, IconData icon) =>
      _fieldBox(ctrl, hint, icon,
          keyboard: const TextInputType.numberWithOptions(decimal: true));

  Widget _fieldBox(TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? keyboard}) {
    return Container(
      decoration: BoxDecoration(
          color: _kBg, borderRadius: BorderRadius.circular(12.r)),
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Row(
        children: [
          Icon(icon, size: 18.r, color: _kMuted),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              controller: ctrl,
              keyboardType: keyboard,
              style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, color: _kText),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppFonts.spaceGrotesk
                    .copyWith(fontSize: 13.sp, color: _kMuted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 13.h),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveBtn(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
              color: _kBrand, borderRadius: BorderRadius.circular(24.r)),
          child: Center(
            child: Text(label,
                style: AppFonts.spaceGrotesk.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.sp)),
          ),
        ),
      );
}
