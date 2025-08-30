import 'package:flutter/material.dart';

/// A responsive sizing utility based on reference design size
abstract class AppSizes {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late Orientation orientation;

  /// Reference screen size (your design mockup size)
  static const double baseWidth = 430;   // e.g. iPhone 14 Pro Max width
  static const double baseHeight = 932;  // e.g. iPhone 14 Pro Max height

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    orientation = _mediaQueryData.orientation;
  }

  /// Scale height relative to design reference
  static double h(double inputHeight) {
    return (inputHeight / baseHeight) * screenHeight;
  }

  /// Scale width relative to design reference
  static double w(double inputWidth) {
    return (inputWidth / baseWidth) * screenWidth;
  }

  /// Scale font size (responsive text)
  static double sp(double inputSize) {
    // Taking min(width, height) to better adapt for tablets
    double scale = screenWidth / baseWidth;
    return inputSize * scale;
  }
}
