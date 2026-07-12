import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../const/app_colors.dart';
import '../const/app_fonts.dart';

/// App-styled, debounced search field reused across screens (Leads, Nutrition,
/// etc.). Pairs with `fuzzySearch`/`fuzzyScore` in core/search/fuzzy_match.dart.
///
/// - Debounces [onChanged] so filtering doesn't run on every keystroke.
/// - Shows a clear (✕) button when there's text.
/// - Matches the existing look: [AppColors.formBackgroundColor] fill,
///   [AppColors.primaryColor] focus, 15.r radius, Space Grotesk text.
class SmartSearchBar extends StatefulWidget {
  /// Called with the (debounced) query as the user types.
  final ValueChanged<String> onChanged;

  /// Optional: called immediately when the user submits from the keyboard.
  final ValueChanged<String>? onSubmitted;

  /// Optional external controller. If null, one is created and disposed here.
  final TextEditingController? controller;

  final String hintText;
  final Duration debounce;
  final bool autofocus;

  /// Optional outer margin (e.g. horizontal page padding).
  final EdgeInsetsGeometry? margin;

  const SmartSearchBar({
    super.key,
    required this.onChanged,
    this.onSubmitted,
    this.controller,
    this.hintText = 'Search…',
    this.debounce = const Duration(milliseconds: 220),
    this.autofocus = false,
    this.margin,
  });

  @override
  State<SmartSearchBar> createState() => _SmartSearchBarState();
}

class _SmartSearchBarState extends State<SmartSearchBar> {
  late final TextEditingController _controller;
  late final bool _ownsController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  // Rebuild for the clear-button visibility; debounce the outward callback.
  void _onControllerChanged() {
    setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.debounce, () {
      widget.onChanged(_controller.text);
    });
  }

  void _clear() {
    _controller.clear();
    _debounceTimer?.cancel();
    widget.onChanged(''); // fire immediately so the list resets at once
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;
    return Padding(
      padding: widget.margin ?? EdgeInsets.zero,
      child: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        textInputAction: TextInputAction.search,
        onSubmitted: widget.onSubmitted,
        style: AppFonts.spaceGrotesk.copyWith(
          fontSize: 14.sp,
          color: AppColors.blackColor,
        ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: AppFonts.spaceGrotesk.copyWith(
            fontSize: 14.sp,
            color: AppColors.greyColor70.withOpacity(0.6),
          ),
          prefixIcon: Icon(Icons.search, color: AppColors.greyColor70),
          suffixIcon: hasText
              ? IconButton(
                  icon: Icon(Icons.close, size: 18.sp, color: AppColors.greyColor70),
                  splashRadius: 18.r,
                  onPressed: _clear,
                )
              : null,
          filled: true,
          fillColor: AppColors.formBackgroundColor,
          contentPadding:
              EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.r),
            borderSide: BorderSide(color: AppColors.greyColor70, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.r),
            borderSide: BorderSide(color: AppColors.greyColor70, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15.r),
            borderSide: BorderSide(color: AppColors.primaryColor, width: 1.4),
          ),
        ),
      ),
    );
  }
}
