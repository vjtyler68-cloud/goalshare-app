import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/user_info/user_info_controller.dart';
import 'package:spanx/features/achievements/achievements_controller.dart';
import 'package:spanx/features/community_profile/screen/community_profile_screen.dart';
import 'package:spanx/features/home/controller/home_controller.dart';
import 'package:spanx/features/home/subflow/todo/controller/daily_todo_controller.dart';
import 'package:spanx/features/motivationalNudges/controller/motivational_nudges_controller.dart';
import 'package:spanx/routes/app_routes.dart';

import '../../../core/alertdialogs/create_my_why_dialog.dart';
import '../../../core/global_widgets/app_loading.dart';
import '../subflow/todo/ui/daily_todo_page.dart';

// ─── Brand colours ─────────────────────────────────────────────────────────
const _kRed    = Color(0xffE84040);
const _kRedDark = Color(0xffBF2020);
const _kBg     = Color(0xffF6F4F2);
const _kCard   = Color(0xffFFFFFF);
const _kText   = Color(0xff1A1010);
const _kMuted  = Color(0xff9E9090);

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final HomeController controller        = Get.put(HomeController(), permanent: true);
  final UserInfoController userInfo      = Get.put(UserInfoController(), permanent: true);
  final MotivationalNudgesController mot = Get.put(MotivationalNudgesController(), permanent: true);
  final AchievementsController ach       = Get.put(AchievementsController(), permanent: true);
  final DailyTodoController todo         = Get.put(DailyTodoController(), permanent: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverHeader(),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 130.h),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStatsRow(),
                _gap(22),
                _buildSectionLabel('Today\'s Tasks', trailing: _todayBadge()),
                _gap(10),
                _buildTodoCard(),
                _gap(26),
                _buildSectionLabel('Quick Access'),
                _gap(10),
                _buildQuickGrid(),
                _gap(26),
                _buildSectionLabel('My Why', trailing: _addBtn(() {
                  CreateMyWhyDialog.show(
                    'My Why',
                    controller.myWhyAffirmation,
                    controller.isLoading,
                    controller.createHomeMyWhy,
                  );
                })),
                _gap(10),
                _buildMyWhyList(),
                _gap(26),
                _buildSectionLabel('Affirmations', trailing: _addBtn(() {
                  CreateMyWhyDialog.show(
                    'Affirmations',
                    controller.myWhyAffirmation,
                    controller.isLoading,
                    controller.createHomeAffirmation,
                  );
                })),
                _gap(10),
                _buildAffirmationsList(),
                _gap(26),
                _buildSectionLabel('Daily Spark'),
                _gap(10),
                _buildQuoteCard(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── SLIVER HEADER ──────────────────────────────────────────────────────────
  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 190.h,
      collapsedHeight: 70.h,
      pinned: true,
      stretch: true,
      backgroundColor: _kRed,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.blurBackground],
        background: _HeaderBackground(userInfo: userInfo),
        collapseMode: CollapseMode.pin,
      ),
      // Collapsed action row
      title: Obx(() {
        final name = userInfo.userData.value?.fullName ?? '';
        final first = name.split(' ').first;
        return Text(
          first.isEmpty ? 'Home' : 'Hi, $first',
          style: AppFonts.spaceGrotesk.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
          ),
        );
      }),
      actions: [
        _HeaderIcon(icon: Icons.people_outline, onTap: () => Get.to(() => CommunityProfileScreen())),
        _HeaderIcon(icon: Icons.chat_bubble_outline, onTap: () => Get.toNamed(AppRoutes.messagesScreen)),
        SizedBox(width: 8.w),
      ],
    );
  }

  // ── STATS ROW ──────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Obx(() {
      final streak = ach.currentStreak.value;
      final levelTitle = ach.levelTitle;
      final items = todo.items;
      final done = items.where((i) => i.done).length;
      final total = items.length;
      return Row(
        children: [
          _StatChip(label: 'Streak', value: streak == 0 ? '—' : '$streak day${streak == 1 ? '' : 's'}', icon: Icons.local_fire_department, color: const Color(0xffFF6B35)),
          SizedBox(width: 10.w),
          _StatChip(label: 'Tasks Done', value: total == 0 ? '0 / 5' : '$done / $total', icon: Icons.check_circle_outline, color: const Color(0xff22C55E)),
          SizedBox(width: 10.w),
          _StatChip(label: 'Level', value: levelTitle, icon: Icons.star_outline, color: const Color(0xffF59E0B)),
        ],
      );
    });
  }

  // ── TODO CARD ──────────────────────────────────────────────────────────────
  Widget _buildTodoCard() {
    return Container(
      decoration: _cardDecor(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: DailyTodoSection(),
      ),
    );
  }

  // ── QUICK GRID ─────────────────────────────────────────────────────────────
  Widget _buildQuickGrid() {
    final items = [
      _Action('Start Priming',  'Morning ritual',  Icons.self_improvement,          const Color(0xff6366F1), () => Get.toNamed(AppRoutes.primingScreen)),
      _Action('Vision Board',   'Dream big',       Icons.photo_library_outlined,    const Color(0xff10B981), () => Get.toNamed(AppRoutes.visionPageScreen)),
      _Action('Bible',          'Read offline',    Icons.menu_book_outlined,        const Color(0xffF59E0B), () => Get.toNamed(AppRoutes.bibleScreen)),
      _Action('My Budget',      'Track finances',  Icons.account_balance_wallet_outlined, const Color(0xffEC4899), () => Get.toNamed(AppRoutes.myBudgetScreen)),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: 1.55,
      children: items.map(_buildActionTile).toList(),
    );
  }

  Widget _buildActionTile(_Action a) {
    return GestureDetector(
      onTap: a.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: _softShadow,
        ),
        padding: EdgeInsets.all(14.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 38.r, height: 38.r,
              decoration: BoxDecoration(
                color: a.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(11.r),
              ),
              child: Icon(a.icon, color: a.color, size: 19.r),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.label, style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w700, color: _kText)),
                Text(a.subtitle, style: AppFonts.spaceGrotesk.copyWith(fontSize: 10.sp, color: _kMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── MY WHY LIST ────────────────────────────────────────────────────────────
  Widget _buildMyWhyList() {
    return Obx(() {
      if (controller.isLoading.value) return loading();
      final list = controller.homeMyWhyList;
      if (list.isEmpty) return _emptyState('Add your reasons — your "why" is your fuel.');
      return Column(
        children: list.asMap().entries.map((e) {
          final idx = e.key;
          final item = e.value;
          return GestureDetector(
            onLongPress: () => _confirmDelete('Delete My Why?', () => controller.deleteHomeMyWhy(item.id!)),
            child: Container(
              margin: EdgeInsets.only(bottom: 10.h),
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
                  // big quote mark
                  Text(
                    '“',
                    style: TextStyle(
                      fontSize: 40.sp,
                      height: 0.8,
                      color: _kRed.withOpacity(0.25),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.text ?? '',
                          style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: _kText,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Reason #${idx + 1} · Hold to delete',
                          style: AppFonts.spaceGrotesk.copyWith(fontSize: 10.sp, color: _kMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  // ── AFFIRMATIONS LIST ──────────────────────────────────────────────────────
  Widget _buildAffirmationsList() {
    return Obx(() {
      if (controller.isLoading.value) return loading();
      final list = controller.homeMyAffirmationList;
      if (list.isEmpty) return _emptyState('Add affirmations — speak your future into existence.');
      return Column(
        children: list.asMap().entries.map((e) {
          final idx  = e.key;
          final item = e.value;
          // cycle through soft accent colours
          final colours = [
            const Color(0xff6366F1),
            const Color(0xff10B981),
            const Color(0xffF59E0B),
            const Color(0xffEC4899),
            const Color(0xff0EA5E9),
          ];
          final accent = colours[idx % colours.length];
          return GestureDetector(
            onLongPress: () => _confirmDelete('Delete Affirmation?', () => controller.deleteHomeAffirmation(item.id!)),
            child: Container(
              margin: EdgeInsets.only(bottom: 10.h),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: _softShadow,
              ),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(
                children: [
                  // numbered circle
                  Container(
                    width: 38.r, height: 38.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [accent, accent.withOpacity(0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${idx + 1}',
                        style: AppFonts.spaceGrotesk.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.text ?? '',
                          style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: _kText,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 3.h),
                        Text(
                          'Hold to delete',
                          style: AppFonts.spaceGrotesk.copyWith(fontSize: 10.sp, color: _kMuted),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.format_quote_rounded, color: accent.withOpacity(0.4), size: 22.r),
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  // ── DAILY QUOTE ────────────────────────────────────────────────────────────
  Widget _buildQuoteCard() {
    return Obx(() {
      final quote = controller.randomMotivationLine.value;
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kRed, _kRedDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: [
            BoxShadow(color: _kRed.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        padding: EdgeInsets.all(22.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'Daily Spark ✦',
                    style: AppFonts.spaceGrotesk.copyWith(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Text(
              '“',
              style: TextStyle(
                fontSize: 52.sp,
                height: 0.6,
                color: Colors.white.withOpacity(0.3),
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              quote.isEmpty ? 'Tap below to ignite your day.' : quote,
              style: AppFonts.spaceGrotesk.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.55,
              ),
            ),
            SizedBox(height: 20.h),
            GestureDetector(
              onTap: () {
                final list = mot.motivationNudgesList;
                if (list.isNotEmpty) {
                  controller.randomMotivationLine.value =
                      list[controller.randomIndex()].title ?? '';
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, color: _kRed, size: 16.r),
                    SizedBox(width: 6.w),
                    Text(
                      'New spark',
                      style: AppFonts.spaceGrotesk.copyWith(
                        color: _kRed,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── SHARED HELPERS ─────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label, {Widget? trailing}) {
    return Row(
      children: [
        Text(
          label,
          style: AppFonts.spaceGrotesk.copyWith(
            fontSize: 17.sp,
            fontWeight: FontWeight.w800,
            color: _kText,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _todayBadge() {
    final now = DateTime.now();
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final label = '${months[now.month - 1]} ${now.day}';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _kRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: AppFonts.spaceGrotesk.copyWith(fontSize: 11.sp, fontWeight: FontWeight.w600, color: _kRed),
      ),
    );
  }

  Widget _addBtn(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32.r, height: 32.r,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: _kRed),
        child: const Icon(Icons.add, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.add_circle_outline, color: _kRed.withOpacity(0.4), size: 32.r),
          SizedBox(height: 8.h),
          Text(msg, textAlign: TextAlign.center,
            style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, color: _kMuted, height: 1.5)),
        ],
      ),
    );
  }

  void _confirmDelete(String title, VoidCallback onConfirm) {
    Get.defaultDialog(
      backgroundColor: Colors.white,
      title: title,
      middleText: 'Are you sure you want to delete this?',
      confirm: TextButton(
        onPressed: () { Get.back(); onConfirm(); },
        child: const Text('Delete', style: TextStyle(color: Colors.red)),
      ),
      cancel: TextButton(onPressed: Get.back, child: const Text('Cancel')),
    );
  }

  SizedBox _gap(double h) => SizedBox(height: h.h);

  BoxDecoration _cardDecor() => BoxDecoration(
    color: _kCard,
    borderRadius: BorderRadius.circular(20.r),
    boxShadow: _softShadow,
  );

  static final List<BoxShadow> _softShadow = [
    BoxShadow(color: Colors.black.withOpacity(0.055), blurRadius: 14, offset: const Offset(0, 4)),
  ];
}

// ─── HEADER BACKGROUND ─────────────────────────────────────────────────────
class _HeaderBackground extends StatelessWidget {
  final UserInfoController userInfo;
  const _HeaderBackground({required this.userInfo});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xffE84040), Color(0xff9B1414)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // decorative circles
        Positioned(top: -30, right: -40,
          child: _circle(160, Colors.white.withOpacity(0.06))),
        Positioned(bottom: 10, left: -50,
          child: _circle(130, Colors.white.withOpacity(0.05))),
        Positioned(top: 20, right: 60,
          child: _circle(60, Colors.white.withOpacity(0.08))),
        // content
        SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    // avatar
                    Obx(() {
                      final name = userInfo.userData.value?.fullName ?? '';
                      return _Avatar(name: name);
                    }),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Obx(() {
                        final name = userInfo.userData.value?.fullName ?? '';
                        final first = name.split(' ').first;
                        final h = DateTime.now().hour;
                        final greeting = h < 5 ? 'Good night' : h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(greeting, style: TextStyle(color: Colors.white70, fontSize: 13.sp, fontWeight: FontWeight.w500)),
                            Text(first.isEmpty ? 'Welcome!' : first,
                              style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 26.sp, fontWeight: FontWeight.w800)),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                // progress bar
                _ProgressBar(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  String _initials(String n) {
    final p = n.trim().split(RegExp(r'\s+'));
    if (p.isEmpty || p[0].isEmpty) return 'U';
    if (p.length == 1) return p[0][0].toUpperCase();
    return '${p[0][0]}${p[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52.r, height: 52.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
        border: Border.all(color: Colors.white, width: 2.5),
      ),
      child: Center(
        child: Text(
          _initials(name),
          style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18.sp),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar();

  @override
  Widget build(BuildContext context) {
    final todo = Get.find<DailyTodoController>();
    return Obx(() {
      final items = todo.items;
      final done = items.where((i) => i.done).length;
      final total = items.isEmpty ? 5 : items.length;
      final progress = items.isEmpty ? 0.0 : done / total;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Today's progress", style: TextStyle(color: Colors.white70, fontSize: 11.sp)),
              Text('$done / $total tasks', style: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: SizedBox(
              height: 7,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ],
      );
    });
  }
}

// ─── STAT CHIP ─────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18.r),
            SizedBox(height: 5.h),
            Text(value, style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w800, color: _kText)),
            Text(label, style: AppFonts.spaceGrotesk.copyWith(fontSize: 9.sp, color: _kMuted)),
          ],
        ),
      ),
    );
  }
}

// ─── NAV ICON ──────────────────────────────────────────────────────────────
class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.r, height: 36.r,
        margin: EdgeInsets.only(right: 4.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
        ),
        child: Icon(icon, color: Colors.white, size: 18.r),
      ),
    );
  }
}

// ─── ACTION DATA ───────────────────────────────────────────────────────────
class _Action {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Action(this.label, this.subtitle, this.icon, this.color, this.onTap);
}
