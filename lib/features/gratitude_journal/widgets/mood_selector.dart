import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:spanx/core/const/app_fonts.dart';

const Color _kRed = Color(0xffE84040);
const Color _kText = Color(0xff1A1010);
const Color _kMuted = Color(0xff9E9090);
const Color _kBg = Color(0xffF6F4F2);

/// Canonical mood options, shared across entry / history / detail.
const List<Map<String, String>> kMoods = [
  {'key': 'great', 'emoji': '😄', 'label': 'Great'},
  {'key': 'good', 'emoji': '🙂', 'label': 'Good'},
  {'key': 'okay', 'emoji': '😐', 'label': 'Okay'},
  {'key': 'hard', 'emoji': '😟', 'label': 'Hard'},
  {'key': 'rough', 'emoji': '😣', 'label': 'Rough'},
];

String moodEmoji(String? key) {
  if (key == null) return '';
  final m = kMoods.firstWhere(
    (e) => e['key'] == key,
    orElse: () => const {'emoji': ''},
  );
  return m['emoji'] ?? '';
}

/// A row of 5 emoji mood chips. [value] is the selected mood key (nullable).
/// Tapping the selected chip again clears it (mood is optional).
class MoodSelector extends StatelessWidget {
  const MoodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: kMoods.map((m) {
        final selected = value == m['key'];
        return GestureDetector(
          onTap: () => onChanged(selected ? null : m['key']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 58.w,
            padding: EdgeInsets.symmetric(vertical: 8.h),
            decoration: BoxDecoration(
              color: selected ? _kRed.withOpacity(0.1) : _kBg,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: selected ? _kRed : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(m['emoji']!, style: TextStyle(fontSize: 22.sp)),
                SizedBox(height: 4.h),
                Text(
                  m['label']!,
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 9.sp,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? _kRed : _kMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
