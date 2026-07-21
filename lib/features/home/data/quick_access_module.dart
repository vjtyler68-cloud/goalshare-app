import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spanx/core/daily_checks/daily_check_service.dart';
import 'package:spanx/routes/app_routes.dart';

/// Stable module ids for the home "Quick Access" grid.
///
/// These strings are PERSISTED on device — never rename one once shipped or
/// users lose that card's saved position/visibility (a renamed id simply falls
/// back to "new module → visible at the end").
class QuickAccessModuleId {
  QuickAccessModuleId._();
  static const String priming = 'start_priming';
  static const String visionBoard = 'vision_board';
  static const String bible = 'bible';
  static const String gratitudeJournal = 'gratitude_journal';
  static const String leads = 'my_leads';
  static const String nutrition = 'my_nutrition';
  static const String budget = 'my_budget';
}

/// One module that CAN appear on the Quick Access grid.
///
/// Everything the grid and the "Add Card" library need to draw and open a card
/// lives here, so adding a future module is a one-entry change in
/// [QuickAccessRegistry.modules] — it then shows up automatically for every
/// user (appended, visible) and in the Add Card library once hidden.
class QuickAccessModule {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  /// DailyCheckFeature id — when set, the tile shows a green ✓ once the
  /// feature is done for the day.
  final String? checkFeature;

  const QuickAccessModule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.checkFeature,
  });
}

/// Single source of truth for every Quick Access module.
///
/// The order here is the DEFAULT dashboard order for a user who has never
/// customised the grid (it matches the grid that shipped before customisation
/// existed). Routes/taps are the exact ones the fixed grid used.
class QuickAccessRegistry {
  QuickAccessRegistry._();

  static final List<QuickAccessModule> modules = <QuickAccessModule>[
    QuickAccessModule(
      id: QuickAccessModuleId.priming,
      title: 'Start Priming',
      subtitle: 'Morning ritual',
      icon: Icons.self_improvement,
      color: const Color(0xff6366F1),
      onTap: () => Get.toNamed(AppRoutes.primingScreen),
      checkFeature: DailyCheckFeature.priming,
    ),
    QuickAccessModule(
      id: QuickAccessModuleId.visionBoard,
      title: 'Vision Board',
      subtitle: 'Dream big',
      icon: Icons.photo_library_outlined,
      color: const Color(0xff10B981),
      onTap: () {
        DailyCheckService.to.markDoneToday(DailyCheckFeature.vision);
        Get.toNamed(AppRoutes.visionPageScreen);
      },
      checkFeature: DailyCheckFeature.vision,
    ),
    QuickAccessModule(
      id: QuickAccessModuleId.bible,
      title: 'Bible',
      subtitle: 'Read offline',
      icon: Icons.menu_book_outlined,
      color: const Color(0xffF59E0B),
      onTap: () {
        DailyCheckService.to.markDoneToday(DailyCheckFeature.bible);
        Get.toNamed(AppRoutes.bibleScreen);
      },
      checkFeature: DailyCheckFeature.bible,
    ),
    QuickAccessModule(
      id: QuickAccessModuleId.gratitudeJournal,
      title: 'Gratitude Journal',
      // Subtitle used by the Add Card library only — on the dashboard this
      // tile renders live streak text (see HomeScreen._buildGratitudeTile).
      subtitle: 'Daily thanks',
      icon: Icons.wb_sunny_rounded,
      color: const Color(0xffF59E0B),
      onTap: () => Get.toNamed(AppRoutes.gratitudeScreen),
      checkFeature: DailyCheckFeature.gratitude,
    ),
    QuickAccessModule(
      id: QuickAccessModuleId.leads,
      title: 'My Leads',
      subtitle: 'Client list',
      icon: Icons.contacts_outlined,
      color: const Color(0xff0EA5E9),
      onTap: () => Get.toNamed(AppRoutes.leadsScreen),
    ),
    QuickAccessModule(
      id: QuickAccessModuleId.nutrition,
      title: 'My Nutrition',
      // Dashboard tile shows live calories instead (see _buildNutritionTile).
      subtitle: 'Track meals',
      icon: Icons.restaurant_rounded,
      color: const Color(0xff22C55E),
      onTap: () => Get.toNamed(AppRoutes.nutritionScreen),
      checkFeature: DailyCheckFeature.nutrition,
    ),
    QuickAccessModule(
      id: QuickAccessModuleId.budget,
      title: 'My Budget',
      subtitle: 'Track finances',
      icon: Icons.account_balance_wallet_outlined,
      color: const Color(0xffEC4899),
      onTap: () => Get.toNamed(AppRoutes.myBudgetScreen),
      checkFeature: DailyCheckFeature.budget,
    ),
  ];

  /// Null when a persisted config points at a module that no longer exists
  /// (e.g. a card removed in a later build) — callers just skip those.
  static QuickAccessModule? byId(String id) {
    for (final m in modules) {
      if (m.id == id) return m;
    }
    return null;
  }
}
