import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/const/app_images.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import '../controller/daily_todo_controller.dart';
import '../data/todo_item.dart';

/// A non-scrolling, embed-friendly section for use inside other scroll views.
class DailyTodoSection extends StatelessWidget {
  const DailyTodoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(DailyTodoController(), permanent: true);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // color: AppColors.lightPinkColor,
        image: DecorationImage(image: AssetImage(AppImages.bg_profiles), fit: BoxFit.fill),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.whiteColor),
      ),
      child: Obx(() {
        final items = c.items;
        final remaining = 3 - items.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header
            Row(
              children: [
                Text(
                  "Todos",
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greyColor70,
                  ),
                ),
                const Spacer(),
                Text(
                  'Left: $remaining',
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.greyColor70,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Add',
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _showAddDialog(context, c),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              DateTime.now().toLocal().toString().split(' ').first,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            const Divider(height: 0),

            // LIST (non-scrollable)
            if (items.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'No todos yet.',
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greyColor70,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 0),
                itemBuilder: (_, i) => _TodoTile(item: items[i], c: c),
              ),
          ],
        );
      }),
    );
  }

  void _showAddDialog(BuildContext context, DailyTodoController c) {
    final textCtrl = TextEditingController();
    Get.defaultDialog(
      backgroundColor: AppColors.lightPinkColor,
      title: 'Add Todo',
      titleStyle: AppFonts.spaceGrotesk.copyWith(
        fontSize: 16.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.greyColor70,
      ),
      content: TextField(
        controller: textCtrl,
        autofocus: true,
        decoration: InputDecoration(hintText: 'What do you need to do?'),
        style: AppFonts.spaceGrotesk.copyWith(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.greyColor70,
        ),
        onSubmitted: (_) => _submit(c, textCtrl),
      ),
      textConfirm: 'Add',
      textCancel: 'Cancel',
      onConfirm: () => _submit(c, textCtrl),
    );
  }

  void _submit(DailyTodoController c, TextEditingController textCtrl) {
    if (!c.canAddMore) {
      AppSnackbar.show(
        message: "Limit reached\nOnly 3 todos allowed for today.",
        isSuccess: false,
      );
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
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Checkbox(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.r),

        ),
        activeColor: AppColors.primaryColor,
        value: item.done,
        onChanged: (v) => c.toggleDone(item.id, v ?? false),
      ),
      title: Text(
        item.text,
        // style: TextStyle(
        //
        //   decoration: item.done ? TextDecoration.lineThrough : null,
        //   color: item.done ? Colors.grey : null,
        // ),
        style: AppFonts.spaceGrotesk.copyWith(
          fontSize: 16.sp,
          decoration: item.done ? TextDecoration.lineThrough : null,
          fontWeight: FontWeight.w700,
          color: item.done ? Colors.grey : null,
        ),
      ),
      subtitle: Text(
        item.done
            ? 'Completed: ${item.doneAt?.toLocal().toString().substring(0, 16) ?? ''}'
            : 'Created: ${item.createdAt.toLocal().toString().substring(0, 16)}',
        style: AppFonts.spaceGrotesk.copyWith(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'edit') _edit(context);
          if (value == 'delete') c.deleteTodo(item.id);
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'edit',
            child: Text(
              'Edit',
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Text(
              'Delete',
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        color: AppColors.lightPinkColor,
      ),
    );
  }

  void _edit(BuildContext context) {
    final editCtrl = TextEditingController(text: item.text);
    Get.defaultDialog(
      title: 'Edit Todo',
      titleStyle: AppFonts.spaceGrotesk.copyWith(
        fontSize: 16.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.greyColor70,
      ),
      backgroundColor: AppColors.lightPinkColor,
      content: TextField(
        controller: editCtrl,
        autofocus: true,
        style: AppFonts.spaceGrotesk.copyWith(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.greyColor70,
        ),
        onSubmitted: (_) {
          c.editText(item.id, editCtrl.text);
          Get.back();
        },
      ),
      textConfirm: 'Save',
      textCancel: 'Cancel',
      onConfirm: () {
        c.editText(item.id, editCtrl.text);
        Get.back();
      },
    );
  }
}
