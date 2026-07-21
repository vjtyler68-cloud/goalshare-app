import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';

import '../controller/mission_controller.dart';
import '../data/metric_icons.dart';

Color get _kRed => AppColors.primaryColor;
Color get _kRedDk => AppColors.primaryDarkColor;
const _kBg = Color(0xffF6F4F2);
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

/// Add / edit a user-defined stat card: name + icon picker.
/// Long-pressing a custom metric on the Mission screen opens this in edit mode.
class CustomStatSheet extends StatefulWidget {
  const CustomStatSheet({super.key, this.existing});

  final CustomMetric? existing;

  static Future<void> show({CustomMetric? existing}) {
    return Get.bottomSheet(
      CustomStatSheet(existing: existing),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  State<CustomStatSheet> createState() => _CustomStatSheetState();
}

class _CustomStatSheetState extends State<CustomStatSheet> {
  late final TextEditingController _nameCtrl;
  late String _iconKey;

  bool get _isEdit => widget.existing != null;

  MissionController get _c => Get.find<MissionController>();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _iconKey = widget.existing?.iconKey ?? kDefaultMetricIconKey;
    if (!kMetricIcons.containsKey(_iconKey)) _iconKey = kDefaultMetricIconKey;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      AppSnackBar.error('Give your stat a name first');
      return;
    }
    HapticFeedback.mediumImpact();
    final ok = _isEdit
        ? _c.editCustomMetric(widget.existing!.id, name: name, iconKey: _iconKey)
        : _c.addCustomMetric(name, iconKey: _iconKey);
    if (!ok) {
      AppSnackBar.error('You can track up to 4 custom stats.');
      return;
    }
    Get.back();
  }

  void _remove() {
    final m = widget.existing;
    if (m == null) return;
    HapticFeedback.mediumImpact();
    _c.removeCustomMetric(m.id);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h + bottomInset),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // grab handle
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEdit ? 'Edit Stat' : 'Add Your Own Stat',
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: _kText,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: Get.back,
                  child: Container(
                    width: 32.r,
                    height: 32.r,
                    decoration: const BoxDecoration(
                      color: _kBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 18.r, color: _kMuted),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              'Track anything you want on the Mission screen.',
              style: AppFonts.spaceGrotesk.copyWith(fontSize: 11.sp, color: _kMuted),
            ),
            SizedBox(height: 16.h),

            // Name
            _label('What are you tracking?'),
            SizedBox(height: 8.h),
            TextField(
              controller: _nameCtrl,
              autofocus: false,
              textCapitalization: TextCapitalization.words,
              style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, color: _kText),
              decoration: InputDecoration(
                hintText: 'e.g. Sales Calls, Chapters Read',
                hintStyle:
                    AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, color: _kMuted),
                filled: true,
                fillColor: _kBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
              ),
              onSubmitted: (_) => _save(),
            ),
            SizedBox(height: 18.h),

            // Icon picker
            _label('Pick an icon'),
            SizedBox(height: 8.h),
            GridView.count(
              crossAxisCount: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8.h,
              crossAxisSpacing: 8.w,
              children: kMetricIconKeys.map((key) {
                final sel = key == _iconKey;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _iconKey = key);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: sel ? _kRed.withOpacity(0.12) : _kBg,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: sel ? _kRed : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      metricIconFor(key),
                      size: 20.r,
                      color: sel ? _kRed : _kMuted,
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 24.h),

            // Save
            GestureDetector(
              onTap: _save,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 15.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_kRed, _kRedDk]),
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [
                    BoxShadow(
                      color: _kRed.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _isEdit ? 'Save Changes' : 'Add Stat',
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            if (_isEdit) ...[
              SizedBox(height: 8.h),
              Center(
                child: TextButton(
                  onPressed: _remove,
                  child: Text(
                    'Remove this stat',
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: _kMuted,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: AppFonts.spaceGrotesk.copyWith(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: _kText,
        ),
      );
}
