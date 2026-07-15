import 'package:flutter/material.dart';

abstract class AppColors {
  // Themeable accent. Backed by mutable statics so the user-picked app theme
  // (Profile → App Theme) can swap them at runtime; exposed as getters so all
  // existing `AppColors.primaryColor` call sites keep working unchanged.
  static Color _primary = const Color(0xffF64A00);
  static Color _formBackground = const Color(0xffFFE9DD);

  static Color get primaryColor => _primary;
  static Color get formBackgroundColor => _formBackground;

  /// Applied by ThemeService — do not call directly from feature code.
  static void applyTheme({
    required Color primary,
    required Color formBackground,
  }) {
    _primary = primary;
    _formBackground = formBackground;
  }

  static final Color whiteColor = Color(0xffFFFFFF);
  static final Color greyColor70 = Color(0xff262222);
  static final Color blackColor = Colors.black;
  static final Color maroonColor = Color(0xffF60031);
  static final Color blueColor = Color(0xff0048FF);
  static final Color lightPinkColor = Color(0xffF2D1C3);
  static final Color greenColor = Colors.green;
  static final Color redColor = Colors.red;

}
