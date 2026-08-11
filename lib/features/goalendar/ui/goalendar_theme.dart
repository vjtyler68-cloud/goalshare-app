import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:spanx/core/const/app_fonts.dart';

/// Goalendar design tokens — a clean, premium light theme with the app's
/// indigo→violet brand for chrome (headers, buttons, selection).
class GCal {
  GCal._();

  static const Color bg = Color(0xffF6F5FB);
  static const Color card = Color(0xffFFFFFF);
  static const Color line = Color(0xffE6E3F0);
  static const Color text = Color(0xff1A1030);
  static const Color muted = Color(0xff8E88A3);
  static const Color indigo = Color(0xff4F46E5);
  static const Color violet = Color(0xff7C3AED);
  static const Color danger = Color(0xffEF4444);

  static const LinearGradient brand = LinearGradient(
    colors: [indigo, violet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static TextStyle get h1 => AppFonts.spaceGrotesk
      .copyWith(fontSize: 19.sp, fontWeight: FontWeight.w800, color: text);
  static TextStyle get body =>
      AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, color: text);
  static TextStyle get label => AppFonts.spaceGrotesk.copyWith(
      fontSize: 10.5.sp,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.6,
      color: muted);
}
