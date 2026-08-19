import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:spanx/core/alertdialogs/create_my_why_dialog.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/features/home/controller/home_controller.dart';
import 'package:spanx/features/home/data/reflections_prefs.dart';
import 'package:spanx/features/home/model/home_screen_model.dart';

/// Dedicated full-screen homes for "My Why" and "Affirmations", reached from
/// the Quick Access grid. They reuse [HomeController] — the SAME lists the app
/// already syncs to the backend and caches offline — so entries follow the user
/// to any device and are always available, even with no connection.

const _kBg = Color(0xffF6F4F2);
const _kCard = Color(0xffFFFFFF);
const _kText = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

Color get _kRed => AppColors.primaryColor;

const List<BoxShadow> _softShadow = [
  BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 3)),
];

// ── MY WHY ───────────────────────────────────────────────────────────────────
class MyWhyScreen extends StatelessWidget {
  const MyWhyScreen({super.key});

  HomeController get c => Get.isRegistered<HomeController>()
      ? Get.find<HomeController>()
      : Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      floatingActionButton: _AddFab(
        label: 'Add a why',
        onTap: () => CreateMyWhyDialog.show(
          'My Why',
          c.myWhyAffirmation,
          c.isLoading,
          c.createHomeMyWhy,
        ),
      ),
      body: _ReflectionScaffold(
        title: 'My Why',
        icon: Icons.local_fire_department_rounded,
        subtitle:
            'The deeper reason behind your goals. When motivation dips, this is'
            ' what brings it back. Tap to edit · hold to delete.',
        onRefresh: c.getHomeMyWhy,
        countLabel: () => c.homeMyWhyList.length,
        child: Obx(() {
          final list = c.homeMyWhyList;
          if (list.isEmpty) {
            return _EmptyState(
              emoji: '🔥',
              line: 'Add your reasons — your "why" is your fuel.',
            );
          }
          return Column(
            children: [
              for (int i = 0; i < list.length; i++) _whyCard(i, list[i]),
              SizedBox(height: 90.h),
            ],
          );
        }),
      ),
    );
  }

  Widget _whyCard(int idx, HomeMyWhyModel item) {
    return GestureDetector(
      onTap: () => CreateMyWhyDialog.showEdit(
        'My Why',
        c.myWhyAffirmation,
        c.isLoading,
        () => c.updateHomeMyWhy(item.id ?? ''),
        initialText: item.text ?? '',
      ),
      onLongPress: () => _confirmDelete(
        'Delete this why?',
        () => c.deleteHomeMyWhy(item.id ?? ''),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: _softShadow,
          border: Border(left: BorderSide(color: _kRed, width: 4)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('“',
                style: TextStyle(
                  fontSize: 40.sp,
                  height: 0.8,
                  color: _kRed.withOpacity(0.25),
                  fontWeight: FontWeight.w900,
                )),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.text ?? '',
                      style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: _kText,
                        height: 1.4,
                      )),
                  SizedBox(height: 4.h),
                  Text('Reason #${idx + 1}',
                      style: AppFonts.spaceGrotesk
                          .copyWith(fontSize: 10.sp, color: _kMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── AFFIRMATIONS ─────────────────────────────────────────────────────────────
class AffirmationsScreen extends StatelessWidget {
  const AffirmationsScreen({super.key});

  HomeController get c => Get.isRegistered<HomeController>()
      ? Get.find<HomeController>()
      : Get.put(HomeController());

  static const List<Color> _accents = [
    Color(0xff6366F1),
    Color(0xff10B981),
    Color(0xffF59E0B),
    Color(0xffEC4899),
    Color(0xff0EA5E9),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      floatingActionButton: _AddFab(
        label: 'Add affirmation',
        onTap: () => CreateMyWhyDialog.show(
          'Affirmations',
          c.myWhyAffirmation,
          c.isLoading,
          c.createHomeAffirmation,
        ),
      ),
      body: _ReflectionScaffold(
        title: 'Affirmations',
        icon: Icons.auto_awesome_rounded,
        subtitle:
            "Short, present-tense statements of who you're becoming. Read them "
            'daily to reshape your mindset. Tap to edit · hold to delete.',
        onRefresh: c.getHomeAffirmation,
        countLabel: () => c.homeMyAffirmationList.length,
        child: Obx(() {
          final list = c.homeMyAffirmationList;
          if (list.isEmpty) {
            return _EmptyState(
              emoji: '✨',
              line: 'Add affirmations — speak your future into existence.',
            );
          }
          return Column(
            children: [
              for (int i = 0; i < list.length; i++)
                _affirmationCard(i, list[i], _accents[i % _accents.length]),
              SizedBox(height: 90.h),
            ],
          );
        }),
      ),
    );
  }

  Widget _affirmationCard(int idx, HomeMyWhyModel item, Color accent) {
    return GestureDetector(
      onTap: () => CreateMyWhyDialog.showEdit(
        'Affirmation',
        c.myWhyAffirmation,
        c.isLoading,
        () => c.updateHomeAffirmation(item.id ?? ''),
        initialText: item.text ?? '',
      ),
      onLongPress: () => _confirmDelete(
        'Delete this affirmation?',
        () => c.deleteHomeAffirmation(item.id ?? ''),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: _softShadow,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [accent, accent.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text('${idx + 1}',
                    style: AppFonts.spaceGrotesk.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    )),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(item.text ?? '',
                  style: AppFonts.spaceGrotesk.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: _kText,
                    height: 1.4,
                  )),
            ),
            Icon(Icons.format_quote_rounded,
                color: accent.withOpacity(0.4), size: 22.r),
          ],
        ),
      ),
    );
  }
}

// ── Shared chrome ────────────────────────────────────────────────────────────

/// Red gradient hero header + scrollable, pull-to-refresh body shared by both
/// reflection screens.
class _ReflectionScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Future<void> Function() onRefresh;
  final int Function() countLabel;
  final Widget child;

  const _ReflectionScaffold({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onRefresh,
    required this.countLabel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_kRed, AppColors.primaryDarkColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 18.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: Get.back,
                        child: Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 24.r),
                      ),
                      SizedBox(width: 10.w),
                      Icon(icon, color: Colors.white, size: 22.r),
                      SizedBox(width: 8.w),
                      Text(title,
                          style: AppFonts.spaceGrotesk.copyWith(
                            color: Colors.white,
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w800,
                          )),
                      const Spacer(),
                      Obx(() => Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text('${countLabel()}',
                                style: AppFonts.spaceGrotesk.copyWith(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w800,
                                )),
                          )),
                      SizedBox(width: 6.w),
                      // Layout switch: put My Why + Affirmations back on the
                      // Home feed (original style). This card then disappears
                      // from Quick Access and the sections reappear on Home.
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded,
                            color: Colors.white, size: 22.r),
                        onSelected: (_) {
                          ReflectionsPrefs.to.setOnHome(true);
                          Get.back();
                          Get.snackbar('Moved to Home feed',
                              'My Why & Affirmations now show on your Home screen. Switch back anytime from there.',
                              snackPosition: SnackPosition.BOTTOM,
                              margin: const EdgeInsets.all(12),
                              duration: const Duration(seconds: 3));
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem<String>(
                            value: 'home',
                            child: Row(
                              children: [
                                Icon(Icons.view_agenda_rounded,
                                    size: 18.r, color: _kText),
                                SizedBox(width: 10.w),
                                Flexible(
                                  child: Text('Show on Home feed instead',
                                      style: AppFonts.spaceGrotesk.copyWith(
                                          fontSize: 13.sp, color: _kText)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(subtitle,
                      style: AppFonts.spaceGrotesk.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12.sp,
                        height: 1.45,
                      )),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: _kRed,
            onRefresh: onRefresh,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [child],
            ),
          ),
        ),
      ],
    );
  }
}

class _AddFab extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddFab({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onTap,
      backgroundColor: _kRed,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_rounded),
      label: Text(label,
          style: AppFonts.spaceGrotesk
              .copyWith(fontWeight: FontWeight.w800, color: Colors.white)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String emoji;
  final String line;
  const _EmptyState({required this.emoji, required this.line});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 80.h),
      child: Column(
        children: [
          Text(emoji, style: TextStyle(fontSize: 48.sp)),
          SizedBox(height: 14.h),
          Text(line,
              textAlign: TextAlign.center,
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 14.sp,
                color: _kMuted,
                height: 1.5,
              )),
          SizedBox(height: 8.h),
          Text('Tap the + button to add your first one.',
              textAlign: TextAlign.center,
              style: AppFonts.spaceGrotesk
                  .copyWith(fontSize: 12.sp, color: _kMuted)),
        ],
      ),
    );
  }
}

void _confirmDelete(String title, VoidCallback onConfirm) {
  Get.dialog(
    AlertDialog(
      backgroundColor: _kCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Text(title,
          style: AppFonts.spaceGrotesk
              .copyWith(fontWeight: FontWeight.w800, color: _kText)),
      content: Text('This can\'t be undone.',
          style: AppFonts.spaceGrotesk.copyWith(color: _kMuted)),
      actions: [
        TextButton(
          onPressed: Get.back,
          child: Text('Cancel',
              style: AppFonts.spaceGrotesk.copyWith(color: _kMuted)),
        ),
        TextButton(
          onPressed: () {
            Get.back();
            onConfirm();
          },
          child: Text('Delete',
              style: AppFonts.spaceGrotesk.copyWith(
                  color: _kRed, fontWeight: FontWeight.w800)),
        ),
      ],
    ),
  );
}
