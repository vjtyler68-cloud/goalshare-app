import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import '../controller/daily_todo_controller.dart';
import '../data/todo_item.dart';

const _kRed    = Color(0xffE84040);
const _kText   = Color(0xff1A1010);
const _kMuted  = Color(0xff9E9090);
const _kBg     = Color(0xffF6F4F2);

/// A non-scrolling, embed-friendly section for use inside other scroll views.
class DailyTodoSection extends StatelessWidget {
  const DailyTodoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(DailyTodoController(), permanent: true);

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Obx(() {
        final items = c.items;
        final done = items.where((i) => i.done).length;
        final remaining = 5 - items.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 32.r, height: 32.r,
                  decoration: BoxDecoration(
                    color: _kRed.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.checklist_rounded, color: _kRed, size: 16.r),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.viewingYesterday.value ? 'Yesterday\'s Tasks' : 'Today\'s Tasks',
                        style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, fontWeight: FontWeight.w800, color: _kText),
                      ),
                      // Date + day toggle: stayed up past midnight? Flip back to
                      // yesterday and still check things off.
                      GestureDetector(
                        onTap: c.toggleDayView,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(c.formatDate(c.activeDate.toString()),
                              style: AppFonts.spaceGrotesk.copyWith(fontSize: 10.sp, color: _kMuted)),
                            SizedBox(width: 6.w),
                            Icon(
                              c.viewingYesterday.value ? Icons.chevron_right : Icons.chevron_left,
                              size: 13.r, color: _kRed,
                            ),
                            Text(
                              c.viewingYesterday.value ? 'Back to today' : 'View yesterday',
                              style: AppFonts.spaceGrotesk.copyWith(
                                fontSize: 10.sp, fontWeight: FontWeight.w700, color: _kRed),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Progress pill
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: done == items.length && items.isNotEmpty
                        ? const Color(0xff22C55E).withOpacity(0.12)
                        : _kRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '$done/${items.length > 0 ? items.length : 5}',
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: done == items.length && items.isNotEmpty
                          ? const Color(0xff22C55E)
                          : _kRed,
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
                // Add button — today only (past days are check-off/edit only).
                if (remaining > 0 && !c.viewingYesterday.value)
                  GestureDetector(
                    onTap: () => _showAddDialog(context, c),
                    child: Container(
                      width: 32.r, height: 32.r,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: _kRed),
                      child: const Icon(Icons.add, color: Colors.white, size: 16),
                    ),
                  ),
              ],
            ),

            if (items.isNotEmpty) ...[
              SizedBox(height: 12.h),
              // Mini progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: SizedBox(
                  height: 4,
                  child: LinearProgressIndicator(
                    value: items.isEmpty ? 0 : done / items.length,
                    backgroundColor: _kRed.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(_kRed),
                  ),
                ),
              ),
            ],

            SizedBox(height: 10.h),

            // LIST
            if (items.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        c.viewingYesterday.value ? Icons.history_rounded : Icons.add_task_rounded,
                        color: _kRed.withOpacity(0.3), size: 32.r,
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        c.viewingYesterday.value
                            ? 'No tasks were added yesterday'
                            : 'Add up to 5 tasks for today',
                        style: AppFonts.spaceGrotesk.copyWith(fontSize: 12.sp, color: _kMuted)),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: items.asMap().entries.map((e) =>
                  _TodoTile(item: e.value, c: c)
                ).toList(),
              ),
          ],
        );
      }),
    );
  }

  void _showAddDialog(BuildContext context, DailyTodoController c) {
    final textCtrl = TextEditingController();
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Add Task", style: AppFonts.spaceGrotesk.copyWith(fontSize: 18.sp, fontWeight: FontWeight.w800, color: _kText)),
              SizedBox(height: 16.h),
              TextField(
                controller: textCtrl,
                autofocus: true,
                style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, color: _kText),
                decoration: InputDecoration(
                  hintText: 'What do you need to do?',
                  hintStyle: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, color: _kMuted),
                  filled: true,
                  fillColor: _kBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                ),
                onSubmitted: (_) => _submit(c, textCtrl, context),
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
                        child: Center(child: Text('Cancel', style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, fontWeight: FontWeight.w600, color: _kMuted))),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _submit(c, textCtrl, context),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_kRed, Color(0xff9B1414)]),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Center(child: Text('Add', style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white))),
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

  void _submit(DailyTodoController c, TextEditingController textCtrl, BuildContext context) {
    if (!c.canAddMore) {
      AppSnackBar.show(message: "Limit reached — only 5 tasks per day.", isSuccessful: false);
      return;
    }
    c.addTodo(textCtrl.text);
    Get.back();
  }
}

class _TodoTile extends StatelessWidget {
  const _TodoTile({required this.item, required this.c});
  final TodoItem item;
  final DailyTodoController c;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: item.done ? const Color(0xff22C55E).withOpacity(0.06) : _kBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: item.done ? const Color(0xff22C55E).withOpacity(0.3) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: () => c.toggleDone(item.id, !item.done),
            child: Container(
              margin: EdgeInsets.all(12.r),
              width: 22.r, height: 22.r,
              decoration: BoxDecoration(
                color: item.done ? const Color(0xff22C55E) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: item.done ? const Color(0xff22C55E) : _kMuted,
                  width: 2,
                ),
              ),
              child: item.done
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
          ),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.text,
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: item.done ? _kMuted : _kText,
                    decoration: item.done ? TextDecoration.lineThrough : null,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  item.done
                      ? 'Done ${item.doneAt?.toLocal().toString().substring(0, 16) ?? ''}'
                      : 'Added ${item.createdAt.toLocal().toString().substring(0, 16)}',
                  style: AppFonts.spaceGrotesk.copyWith(fontSize: 9.sp, color: _kMuted),
                ),
              ],
            ),
          ),
          // Actions
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: _kMuted, size: 18.r),
            onSelected: (val) {
              if (val == 'edit') _edit(context);
              if (val == 'delete') c.deleteTodo(item.id);
            },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            color: Colors.white,
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text('Edit', style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp))),
              PopupMenuItem(value: 'delete', child: Text('Delete', style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, color: Colors.red))),
            ],
          ),
        ],
      ),
    );
  }

  void _edit(BuildContext context) {
    final editCtrl = TextEditingController(text: item.text);
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        child: Padding(
          padding: EdgeInsets.all(24.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Task', style: AppFonts.spaceGrotesk.copyWith(fontSize: 18.sp, fontWeight: FontWeight.w800, color: _kText)),
              SizedBox(height: 16.h),
              TextField(
                controller: editCtrl,
                autofocus: true,
                style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _kBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                ),
                onSubmitted: (_) { c.editText(item.id, editCtrl.text); Get.back(); },
              ),
              SizedBox(height: 16.h),
              Row(children: [
                Expanded(child: GestureDetector(onTap: Get.back, child: Container(padding: EdgeInsets.symmetric(vertical: 12.h), decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(12.r)), child: Center(child: Text('Cancel', style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, fontWeight: FontWeight.w600, color: _kMuted)))))),
                SizedBox(width: 10.w),
                Expanded(child: GestureDetector(onTap: () { c.editText(item.id, editCtrl.text); Get.back(); }, child: Container(padding: EdgeInsets.symmetric(vertical: 12.h), decoration: BoxDecoration(gradient: const LinearGradient(colors: [_kRed, Color(0xff9B1414)]), borderRadius: BorderRadius.circular(12.r)), child: Center(child: Text('Save', style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, fontWeight: FontWeight.w700, color: Colors.white)))))),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
