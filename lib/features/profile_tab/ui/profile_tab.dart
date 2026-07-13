import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_network_image.dart';
import 'package:spanx/features/achievements/achievements_controller.dart';
import 'package:spanx/features/editprofile/screen/edit_profile_screen.dart';
import 'package:spanx/features/qr_connect/screen/qr_connect_screen.dart';
import '../../../core/user_info/user_info_controller.dart';
import '../controller/profile_tab_controller.dart';

const _kRed   = Color(0xffE84040);
const _kRedDk = Color(0xff9B1414);
const _kBg    = Color(0xffF6F4F2);
const _kCard  = Color(0xffFFFFFF);
const _kText  = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

class ProfileTabPage extends StatelessWidget {
  ProfileTabPage({Key? key}) : super(key: key);

  final controller     = Get.put(ProfileTabController());
  final userInfo       = Get.find<UserInfoController>();
  final achievements   = Get.find<AchievementsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Hero header ───────────────────────────────────────────────
            _buildHero(),

            // ── Body ─────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Level card
                  _buildLevelCard(),
                  SizedBox(height: 16.h),

                  // Career stats
                  _buildCareerStats(),
                  SizedBox(height: 20.h),

                  // Achievements
                  _buildAchievementsSection(),
                  SizedBox(height: 20.h),

                  // Menu
                  _buildMenuSection(),
                  SizedBox(height: 80.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero ─────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kRed, _kRedDk],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h),
          child: Obx(() {
            final user = userInfo.userData.value;
            final initials = _initials(user?.fullName ?? 'U');
            return Column(
              children: [
                // QR "Add people" button
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Get.to(() => QrConnectScreen()),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: Colors.white.withOpacity(0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 6.w),
                          Text('Add', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
                // Avatar (tap to change picture)
                GestureDetector(
                  onTap: () => Get.to(() => EditProfileScreen()),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 80.r, height: 80.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: ClipOval(
                          child: user?.profile != null && user!.profile!.isNotEmpty
                              ? ResponsiveNetworkImage(
                                  imageUrl: user.profile!,
                                  shape: ImageShape.circle,
                                  fit: BoxFit.cover,
                                )
                              : Center(
                                  child: Text(initials, style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 28.sp, fontWeight: FontWeight.w800)),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          width: 26.r, height: 26.r,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: _kRed, width: 1.5),
                          ),
                          child: Icon(Icons.camera_alt_rounded, color: _kRed, size: 14.r),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                Text(user?.fullName ?? 'Loading...', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w800)),
                SizedBox(height: 2.h),
                Text(user?.email ?? '', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white70, fontSize: 13.sp)),
                SizedBox(height: 12.h),
                // Followers row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _HeroStat(count: userInfo.userFollowingCount.value, label: 'Following'),
                    Container(width: 1, height: 24, color: Colors.white30, margin: EdgeInsets.symmetric(horizontal: 24.w)),
                    _HeroStat(count: userInfo.userFollowerCount.value, label: 'Followers'),
                    Container(width: 1, height: 24, color: Colors.white30, margin: EdgeInsets.symmetric(horizontal: 24.w)),
                    _HeroStat(count: achievements.unlockedCount, label: 'Badges'),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ── Level card ────────────────────────────────────────────────────────────

  Widget _buildLevelCard() {
    return Obx(() {
      final lvl = achievements.level;
      final title = achievements.levelTitle;
      final progress = achievements.levelProgress;
      final xp = achievements.totalXP.value;

      return Container(
        padding: EdgeInsets.all(18.r),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xff1E293B), Color(0xff0F172A)]),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 56.r, height: 56.r,
              decoration: BoxDecoration(
                color: _kRed.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: _kRed, width: 2),
              ),
              child: Center(child: Text('$lvl', style: AppFonts.spaceGrotesk.copyWith(color: _kRed, fontSize: 22.sp, fontWeight: FontWeight.w900))),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 17.sp, fontWeight: FontWeight.w800)),
                      Text('$xp XP', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white54, fontSize: 12.sp)),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 7,
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withOpacity(0.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(_kRed),
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text('${(progress * 100).toInt()}% to Level ${lvl + 1}', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white38, fontSize: 10.sp)),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  // ── Career stats ──────────────────────────────────────────────────────────

  Widget _buildCareerStats() {
    return Obx(() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('All-Time Stats', style: AppFonts.spaceGrotesk.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w800, color: _kText)),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(child: _StatChip(icon: Icons.home_outlined, label: 'Homes\nKnocked', value: achievements.totalHomesAllTime.value, color: const Color(0xff6366F1))),
            SizedBox(width: 8.w),
            Expanded(child: _StatChip(icon: Icons.people_outline, label: 'People\nTalked To', value: achievements.totalPeopleAllTime.value, color: const Color(0xff10B981))),
            SizedBox(width: 8.w),
            Expanded(child: _StatChip(icon: Icons.attach_money, label: 'Total\nSales', value: achievements.totalSalesAllTime.value, color: _kRed)),
            SizedBox(width: 8.w),
            Expanded(child: _StatChip(icon: Icons.local_fire_department, label: 'Best\nStreak', value: achievements.bestStreak.value, color: const Color(0xffF97316))),
          ],
        ),
      ],
    ));
  }

  // ── Achievements ──────────────────────────────────────────────────────────

  Widget _buildAchievementsSection() {
    return Obx(() {
      final all = achievements.achievements;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Achievements', style: AppFonts.spaceGrotesk.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w800, color: _kText)),
              Text('${achievements.unlockedCount}/${all.length}', style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, color: _kMuted, fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: 10.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: all.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 8.w,
              mainAxisSpacing: 8.h,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (_, i) {
              final a = all[i];
              return GestureDetector(
                onTap: () => _showBadgeInfo(a),
                child: Column(
                  children: [
                    Container(
                      width: 48.r, height: 48.r,
                      decoration: BoxDecoration(
                        color: a.unlocked ? a.color.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: a.unlocked ? a.color.withOpacity(0.5) : Colors.grey.withOpacity(0.2), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          a.unlocked ? a.emoji : '🔒',
                          style: TextStyle(fontSize: 20.sp),
                        ),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      a.title.split(' ').first,
                      style: AppFonts.spaceGrotesk.copyWith(fontSize: 9.sp, color: a.unlocked ? _kText : _kMuted, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      );
    });
  }

  void _showBadgeInfo(Achievement a) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            SizedBox(height: 20.h),
            Text(a.unlocked ? a.emoji : '🔒', style: TextStyle(fontSize: 50.sp)),
            SizedBox(height: 12.h),
            Text(a.title, style: AppFonts.spaceGrotesk.copyWith(fontSize: 20.sp, fontWeight: FontWeight.w800, color: _kText)),
            SizedBox(height: 6.h),
            Text(a.description, style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, color: _kMuted), textAlign: TextAlign.center),
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: a.unlocked ? const Color(0xff22C55E).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(a.unlocked ? 'Unlocked!' : 'Not yet unlocked',
                style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w700, color: a.unlocked ? const Color(0xff22C55E) : _kMuted)),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  // ── Menu ─────────────────────────────────────────────────────────────────

  Widget _buildMenuSection() {
    final items = controller.menuItems + controller.preferencesItems;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account', style: AppFonts.spaceGrotesk.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w800, color: _kText)),
        SizedBox(height: 10.h),
        ...items.map((item) => _MenuItem(item: item)),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (name.isNotEmpty) return name[0].toUpperCase();
    return 'U';
  }
}

class _HeroStat extends StatelessWidget {
  final int count;
  final String label;
  const _HeroStat({required this.count, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text('$count', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.w800)),
      SizedBox(height: 2.h),
      Text(label, style: AppFonts.spaceGrotesk.copyWith(color: Colors.white70, fontSize: 11.sp)),
    ]);
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(children: [
        Container(
          width: 32.r, height: 32.r,
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 16),
        ),
        SizedBox(height: 6.h),
        Text('$value', style: AppFonts.spaceGrotesk.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w800, color: const Color(0xff1A1010))),
        Text(label, style: AppFonts.spaceGrotesk.copyWith(fontSize: 8.sp, color: const Color(0xff9E9090), height: 1.3), textAlign: TextAlign.center),
      ]),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final ProfileMenuItem item;
  const _MenuItem({required this.item});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(children: [
              item.icon != null
                  ? Icon(item.icon, size: 22, color: const Color(0xff9E9090))
                  : Image.asset(item.iconPath, width: 22.w, height: 22.h,
                      errorBuilder: (_, __, ___) => Icon(Icons.settings_outlined, size: 22, color: const Color(0xff9E9090))),
              SizedBox(width: 14.w),
              Expanded(child: Text(item.title, style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, fontWeight: FontWeight.w600, color: const Color(0xff1A1010)))),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xffB0AAAA)),
            ]),
          ),
        ),
      ),
    );
  }
}
