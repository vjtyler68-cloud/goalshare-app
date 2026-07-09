import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import '../controller/gratitude_controller.dart';
import '../data/gratitude_entry.dart';

const _kRed = Color(0xffE84040);
const _kRedDark = Color(0xff9B1414);
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);
const _kBg = Color(0xffF6F4F2);

class GratitudeJournalScreen extends StatelessWidget {
  GratitudeJournalScreen({super.key});

  final GratitudeController c = Get.put(GratitudeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kRed,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: Get.back,
        ),
        title: Text(
          'Gratitude Journal',
          style: AppFonts.spaceGrotesk.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
          ),
        ),
      ),
      floatingActionButton: Obx(() {
        if (!c.canAddMore) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          backgroundColor: _kRed,
          onPressed: () => _showEntryDialog(context),
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            'Add',
            style: AppFonts.spaceGrotesk.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14.sp,
            ),
          ),
        );
      }),
      body: Obx(() {
        if (!c.isReady.value) {
          return const Center(child: CircularProgressIndicator(color: _kRed));
        }
        return Column(
          children: [
            _dateBar(),
            _progressHeader(),
            Expanded(child: _list(context)),
          ],
        );
      }),
    );
  }

  // ── date navigator ──────────────────────────────────────────────────────────
  Widget _dateBar() {
    return Obx(() => Container(
          color: _kRed,
          padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 14.h),
          child: Row(
            children: [
              _navBtn(Icons.chevron_left, c.goPreviousDay),
              Expanded(
                child: GestureDetector(
                  onTap: c.isToday ? null : c.goToday,
                  child: Column(
                    children: [
                      Text(
                        c.headerDate,
                        style: AppFonts.spaceGrotesk.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        c.isToday ? c.subHeaderDate : '${c.subHeaderDate}  •  tap for today',
                        style: AppFonts.spaceGrotesk.copyWith(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Opacity(
                opacity: c.canGoForward ? 1 : 0.3,
                child: _navBtn(
                  Icons.chevron_right,
                  c.canGoForward ? c.goNextDay : () {},
                ),
              ),
            ],
          ),
        ));
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.r,
        height: 36.r,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22.r),
      ),
    );
  }

  // ── progress header ─────────────────────────────────────────────────────────
  Widget _progressHeader() {
    return Obx(() {
      final count = c.count;
      return Container(
        padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 6.h),
        child: Row(
          children: [
            Icon(Icons.favorite, color: _kRed, size: 16.r),
            SizedBox(width: 8.w),
            Text(
              'Grateful for',
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: _kText,
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: _kRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                '$count / $kMaxGratitude',
                style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: _kRed,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── list ────────────────────────────────────────────────────────────────────
  Widget _list(BuildContext context) {
    return Obx(() {
      final items = c.entries;
      if (items.isEmpty) {
        return _empty();
      }
      return ListView.builder(
        padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 100.h),
        itemCount: items.length,
        itemBuilder: (_, i) => _EntryTile(
          index: i + 1,
          entry: items[i],
          onEdit: () => _showEntryDialog(context, existing: items[i]),
          onDelete: () => c.remove(items[i].id),
        ),
      );
    });
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, color: _kRed.withOpacity(0.3), size: 48.r),
            SizedBox(height: 12.h),
            Text(
              'What are you grateful for?',
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: _kText,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Write down up to $kMaxGratitude things you appreciate today.',
              textAlign: TextAlign.center,
              style: AppFonts.spaceGrotesk.copyWith(fontSize: 12.sp, color: _kMuted),
            ),
          ],
        ),
      ),
    );
  }

  // ── add / edit dialog ─────────────────────────────────────────────────────��─
  void _showEntryDialog(BuildContext context, {GratitudeEntry? existing}) {
    if (existing == null && !c.canAddMore) {
      AppSnackBar.show(
        message: "Limit reached — up to $kMaxGratitude per day.",
        isSuccessful: false,
      );
      return;
    }

    final isEdit = existing != null;
    final textCtrl = TextEditingController(text: existing?.text ?? '');

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit' : "I'm grateful for...",
                style: AppFonts.spaceGrotesk.copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: _kText,
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: textCtrl,
                autofocus: true,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, color: _kText),
                decoration: InputDecoration(
                  hintText: 'e.g. my family, my health, a good coffee',
                  hintStyle: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, color: _kMuted),
                  filled: true,
                  fillColor: _kBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                ),
                onSubmitted: (_) => _submit(textCtrl, existing),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: Get.back,
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: _kBg,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Center(
                          child: Text('Cancel',
                              style: AppFonts.spaceGrotesk.copyWith(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: _kMuted)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _submit(textCtrl, existing),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_kRed, _kRedDark]),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Center(
                          child: Text(isEdit ? 'Save' : 'Add',
                              style: AppFonts.spaceGrotesk.copyWith(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit(TextEditingController textCtrl, GratitudeEntry? existing) {
    final text = textCtrl.text.trim();
    if (text.isEmpty) {
      Get.back();
      return;
    }
    if (existing == null) {
      c.add(text);
    } else {
      c.edit(existing.id, text);
    }
    Get.back();
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({
    required this.index,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final int index;
  final GratitudeEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26.r,
            height: 26.r,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _kRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: _kRed,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.text,
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: _kText,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  entry.updatedAt != null
                      ? 'Edited ${_stamp(entry.updatedAt!)}'
                      : 'Added ${_stamp(entry.createdAt)}',
                  style: AppFonts.spaceGrotesk.copyWith(fontSize: 9.sp, color: _kMuted),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: _kMuted, size: 18.r),
            onSelected: (val) {
              if (val == 'edit') onEdit();
              if (val == 'delete') onDelete();
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            color: Colors.white,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: Text('Edit',
                    style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp)),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete',
                    style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _stamp(DateTime dt) {
    final l = dt.toLocal();
    final h = l.hour % 12 == 0 ? 12 : l.hour % 12;
    final m = l.minute.toString().padLeft(2, '0');
    final ap = l.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ap';
  }
}
