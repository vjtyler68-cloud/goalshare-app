import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../const/app_colors.dart';

/// One selectable accent theme: the primary color plus the light tint used for
/// form fills, chosen to stay readable with the app's warm neutral background.
class AppThemeOption {
  final String id;
  final String name;
  final Color primary;
  final Color formBackground;
  const AppThemeOption(this.id, this.name, this.primary, this.formBackground);
}

/// User-selectable app color themes (Profile → App Theme). Persists the choice
/// and re-skins every screen that uses AppColors.primaryColor /
/// formBackgroundColor via Get.forceAppUpdate().
class ThemeService extends GetxService {
  static ThemeService get to => Get.isRegistered<ThemeService>()
      ? Get.find<ThemeService>()
      : Get.put(ThemeService(), permanent: true);

  static const String _kKey = 'app_theme_v1';

  /// The 6 themes VJ picked: Red, Blue, Green, Pink, Purple, Orange.
  /// Orange is the original brand accent and stays the default.
  static const List<AppThemeOption> options = [
    AppThemeOption('orange', 'Orange', Color(0xffF64A00), Color(0xffFFE9DD)),
    AppThemeOption('red', 'Red', Color(0xffE02D2D), Color(0xffFDE3E3)),
    AppThemeOption('blue', 'Blue', Color(0xff2563EB), Color(0xffE0EAFF)),
    AppThemeOption('green', 'Green', Color(0xff16A34A), Color(0xffDFF3E6)),
    AppThemeOption('pink', 'Pink', Color(0xffEC4899), Color(0xffFCE1EF)),
    AppThemeOption('purple', 'Purple', Color(0xff8B5CF6), Color(0xffECE4FC)),
  ];

  final RxString currentId = 'orange'.obs;

  AppThemeOption get current =>
      options.firstWhere((o) => o.id == currentId.value,
          orElse: () => options.first);

  /// Load the saved theme and apply it. Called once from main() before runApp
  /// so the very first frame already wears the user's color.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kKey);
      if (saved != null && options.any((o) => o.id == saved)) {
        currentId.value = saved;
      }
    } catch (_) {}
    final o = current;
    AppColors.applyTheme(primary: o.primary, formBackground: o.formBackground);
  }

  /// Apply + persist a theme and rebuild the whole app so every screen
  /// re-reads AppColors.
  Future<void> select(AppThemeOption option) async {
    currentId.value = option.id;
    AppColors.applyTheme(
        primary: option.primary, formBackground: option.formBackground);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kKey, option.id);
    } catch (_) {}
    Get.forceAppUpdate();
  }
}
