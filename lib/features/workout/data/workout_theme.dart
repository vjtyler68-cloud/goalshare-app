import 'package:flutter/material.dart';

/// MY WORKOUT visual identity — a committed, high-contrast dark "gym mode".
///
/// Deliberately self-contained (not the app's themeable AppColors) so the logger
/// always reads as an aggressive, focused training surface no matter which app
/// theme the user picked. One accent for energy (flame orange-red), one for
/// wins (volt mint), used sparingly against near-black.
class WT {
  WT._();

  // Grounds
  static const Color bg = Color(0xFF0B0B0F);
  static const Color surface = Color(0xFF15151D);
  static const Color surfaceHi = Color(0xFF1E1E29);
  static const Color stroke = Color(0xFF2A2A38);

  // Text
  static const Color textHi = Color(0xFFF5F5FA);
  static const Color textMid = Color(0xFF9A9AAB);
  static const Color textLow = Color(0xFF5E5E70);

  // Accents
  static const Color flame = Color(0xFFFF5A3C); // energy / streak
  static const Color flameDeep = Color(0xFFE23D22);
  static const Color volt = Color(0xFF34E39A); // wins / PRs / completed
  static const Color amber = Color(0xFFFFC24B); // warmups / RPE mid
  static const Color danger = Color(0xFFFF4D6D); // failure sets

  static const LinearGradient flameGrad = LinearGradient(
    colors: [Color(0xFFFF7A3C), Color(0xFFE23D22)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient voltGrad = LinearGradient(
    colors: [Color(0xFF34E39A), Color(0xFF15B87A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color setTypeColor(String setTypeId) {
    switch (setTypeId) {
      case 'warmup':
        return amber;
      case 'drop':
        return const Color(0xFF7C5CFF);
      case 'failure':
        return danger;
      default:
        return textMid;
    }
  }
}
