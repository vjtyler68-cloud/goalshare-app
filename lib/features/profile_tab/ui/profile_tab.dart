import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_network_image.dart';
import 'package:spanx/features/achievements/achievements_controller.dart';
import 'package:spanx/features/mission/controller/mission_controller.dart';
import 'package:spanx/core/profile_photo/profile_photo_updater.dart';
import 'package:spanx/features/qr_connect/screen/qr_connect_screen.dart';
import 'package:spanx/features/friends/controller/friends_controller.dart';
import 'package:spanx/features/accountability/widgets/buddies_header_icon.dart';
import '../../../core/user_info/user_info_controller.dart';
import '../controller/profile_tab_controller.dart';
import 'package:spanx/core/const/app_colors.dart';
import 'package:spanx/core/network_caller/endpoints.dart';
import 'package:spanx/core/network_caller/network_config.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/routes/app_routes.dart';
import 'package:spanx/features/orgs/controller/org_controller.dart';
import 'package:spanx/features/orgs/data/org_models.dart';
import 'package:spanx/features/orgs/ui/org_switcher.dart';
import 'dart:convert';

Color get _kRed => AppColors.primaryColor;
Color get _kRedDk => AppColors.primaryDarkColor;
const _kBg    = Color(0xffF6F4F2);
const _kText  = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

class ProfileTabPage extends StatelessWidget {
  ProfileTabPage({Key? key}) : super(key: key);

  final controller     = Get.put(ProfileTabController());
  final userInfo       = Get.find<UserInfoController>();
  final achievements   = Get.find<AchievementsController>();
  final mission        = Get.find<MissionController>();

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

                  // Organization (admin dashboard / member status / join-create)
                  _buildOrgCard(),
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
      decoration: BoxDecoration(
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
                // QR "Add" button + a small Buddies shortcut stacked beneath it.
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Get.to(() => QrConnectScreen()),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 7.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20.r),
                            border:
                                Border.all(color: Colors.white.withOpacity(0.35)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.qr_code_2_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 6.w),
                              Text('Add',
                                  style: AppFonts.spaceGrotesk.copyWith(
                                      color: Colors.white,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      const BuddiesHeaderIcon(),
                    ],
                  ),
                ),
                SizedBox(height: 4.h),
                // Avatar: tap → menu (View Profile / Change Photo); hold → view big.
                GestureDetector(
                  onTap: () => _showAvatarMenu(
                      user?.fullName ?? '',
                      user?.email ?? '',
                      user?.profile ?? ''),
                  onLongPress: () => _openMyProfile(
                      user?.fullName ?? '',
                      user?.email ?? '',
                      user?.profile ?? ''),
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
                SizedBox(height: 10.h),
                // Public bio — friends see this on your profile. Tap to edit.
                _bioLine(user?.bio ?? ''),
                SizedBox(height: 12.h),
                // Friends + Badges (mutual friends replace one-way follow counts)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _HeroStat(
                        count: FriendsController.to.friends.length,
                        label: 'Friends'),
                    Container(width: 1, height: 24, color: Colors.white30, margin: EdgeInsets.symmetric(horizontal: 28.w)),
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

  /// The bio row in the hero. Empty → a subtle "Add a bio" prompt (only you see
  /// your own profile here); set → the bio text. Tap either to edit.
  Widget _bioLine(String bio) {
    final has = bio.trim().isNotEmpty;
    return GestureDetector(
      onTap: () => _editBio(bio),
      child: Container(
        constraints: BoxConstraints(maxWidth: 300.w),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(has ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.white.withOpacity(0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(has ? Icons.edit_note_rounded : Icons.add_rounded,
                color: Colors.white.withOpacity(0.9), size: 16.r),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                has ? bio : 'Add a bio',
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.spaceGrotesk.copyWith(
                    color: has ? Colors.white : Colors.white70,
                    fontSize: 12.5.sp,
                    height: 1.3,
                    fontWeight: has ? FontWeight.w600 : FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom-sheet editor for the public bio (160 chars). Saves via
  /// PUT /user/update-profile then refreshes /user/me so the hero updates.
  void _editBio(String current) {
    const kText = Color(0xff1A1010);
    const kMuted = Color(0xff9E9090);
    final ctrl = TextEditingController(text: current);
    final saving = false.obs;

    Get.bottomSheet(
      isScrollControlled: true,
      Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(Get.context!).viewInsets.bottom),
        child: Container(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                      color: const Color(0xffE6E1DE),
                      borderRadius: BorderRadius.circular(4.r)),
                ),
              ),
              Text('Your bio',
                  style: AppFonts.spaceGrotesk.copyWith(
                      color: kText,
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800)),
              SizedBox(height: 2.h),
              Text('Friends see this on your profile.',
                  style: AppFonts.spaceGrotesk
                      .copyWith(color: kMuted, fontSize: 12.5.sp)),
              SizedBox(height: 14.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xffF7F5F4),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: const Color(0xffEDE9E7)),
                ),
                child: TextField(
                  controller: ctrl,
                  autofocus: true,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 160,
                  style: AppFonts.spaceGrotesk
                      .copyWith(fontSize: 14.sp, color: kText),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Say something about yourself…',
                    hintStyle: AppFonts.spaceGrotesk
                        .copyWith(fontSize: 13.5.sp, color: kMuted),
                    counterStyle: AppFonts.spaceGrotesk
                        .copyWith(fontSize: 11.sp, color: kMuted),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Obx(() => GestureDetector(
                    onTap: saving.value
                        ? null
                        : () async {
                            saving.value = true;
                            final ok = await _saveBio(ctrl.text.trim());
                            saving.value = false;
                            if (ok) {
                              Get.back();
                            } else {
                              AppSnackBar.error('Could not save your bio.');
                            }
                          },
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [_kRed, _kRedDk]),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Text(saving.value ? 'Saving…' : 'Save bio',
                          style: AppFonts.spaceGrotesk.copyWith(
                              color: Colors.white,
                              fontSize: 14.5.sp,
                              fontWeight: FontWeight.w800)),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  /// PUT the new bio, then refresh the cached user so the hero re-renders.
  Future<bool> _saveBio(String bio) async {
    try {
      final res = await NetworkConfig.instance.ApiRequestHandler(
        RequestMethod.PUT,
        Urls.userUpdateProfile,
        jsonEncode({'bio': bio}),
        is_auth: true,
      );
      if (res != null && res['success'] == true) {
        await userInfo.refreshUserData();
        return true;
      }
    } catch (_) {}
    return false;
  }

  void _openMyProfile(String name, String email, String image) {
    // "View Profile" shows the photo big, full-screen (pinch to zoom).
    Get.to(() => _PhotoViewer(image: image, name: name),
        fullscreenDialog: true);
  }

  /// Tap the avatar → choose to view the full profile (bigger photo) or change
  /// the picture.
  void _showAvatarMenu(String name, String email, String image) {
    const kText = Color(0xff1A1010);
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(height: 6.h),
              ListTile(
                leading: Icon(Icons.person_rounded, color: _kRed),
                title: Text('View Profile',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: kText)),
                subtitle: Text('See your bigger picture',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 12.sp, color: Colors.black45)),
                onTap: () {
                  Get.back();
                  _openMyProfile(name, email, image);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_rounded, color: _kRed),
                title: Text('Change Photo',
                    style: AppFonts.spaceGrotesk.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: kText)),
                onTap: () {
                  Get.back();
                  ProfilePhotoUpdater.showOptions();
                },
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    );
  }

  // ── Organization card ──────────────────────────────────────────────────────

  Widget _buildOrgCard() {
    const kText = Color(0xff1A1010);
    final org = OrgController.to;
    return Obx(() {
      final o = org.myOrg.value;
      final IconData icon;
      final String title;
      final String subtitle;
      final VoidCallback onTap;
      if (o == null) {
        icon = Icons.groups_outlined;
        title = 'Join or create an organization';
        subtitle = 'School, sales team, or trainer/gym';
        onTap = () => Get.toNamed(AppRoutes.orgOnboardingScreen,
            arguments: {'fromProfile': true});
      } else if (o.isAdmin) {
        icon = Icons.dashboard_rounded;
        title = '${o.name} — Admin';
        subtitle = 'Open your ${o.orgType.adminLabel.toLowerCase()} dashboard';
        onTap = () => Get.toNamed(AppRoutes.orgAdminScreen);
      } else if (o.orgType == OrgType.salesOrg) {
        // Sales members get their private Team HQ (announcements/feed/goals).
        icon = Icons.workspaces_rounded;
        title = '${o.name} — Team HQ';
        subtitle = 'Announcements, team feed & goals';
        onTap = () => Get.toNamed(AppRoutes.orgSpaceScreen);
      } else {
        icon = Icons.verified_user_outlined;
        title = o.name;
        subtitle = '${o.orgType.memberLabel} · your data stays private';
        onTap = () => AppSnackBar.success(
            'You\'re a ${o.orgType.memberLabel.toLowerCase()} of ${o.name}');
      }
      return GestureDetector(
        onTap: onTap,
        onLongPress: o == null ? null : () => _confirmLeaveOrg(o),
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                    color: _kRed.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: _kRed, size: 22.r),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w800,
                            color: kText)),
                    SizedBox(height: 2.h),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.spaceGrotesk.copyWith(
                            fontSize: 12.sp, color: Colors.black45)),
                  ],
                ),
              ),
              if (o != null && (org.isOwner.value || org.hasMultipleOrgs))
                GestureDetector(
                  onTap: OrgSwitcher.show,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: EdgeInsets.only(right: 6.w),
                    child: Icon(Icons.swap_horiz_rounded,
                        color: _kRed, size: 20.r),
                  ),
                ),
              Icon(Icons.chevron_right, color: Colors.black26, size: 20.r),
            ],
          ),
        ),
      );
    });
  }

  void _confirmLeaveOrg(OrgSummary o) {
    Get.defaultDialog(
      title: 'Leave ${o.name}?',
      middleText: o.isAdmin
          ? 'You\'re the admin. Leaving removes your access to this organization.'
          : 'You\'ll lose access to this organization.',
      textConfirm: 'Leave',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: _kRed,
      onConfirm: () async {
        Get.back();
        await OrgController.to.leave();
        AppSnackBar.success('You left ${o.name}');
      },
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
                        valueColor: AlwaysStoppedAnimation<Color>(_kRed),
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
            Expanded(child: _StatChip(icon: mission.homesIconData, label: mission.homesLabel.value, value: achievements.totalHomesAllTime.value, color: const Color(0xff6366F1))),
            SizedBox(width: 8.w),
            Expanded(child: _StatChip(icon: mission.peopleIconData, label: mission.peopleLabel.value, value: achievements.totalPeopleAllTime.value, color: const Color(0xff10B981))),
            SizedBox(width: 8.w),
            Expanded(child: _StatChip(icon: mission.salesIconData, label: mission.salesLabel.value, value: achievements.totalSalesAllTime.value, color: _kRed)),
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

/// Full-screen "View Profile" photo — the big picture of the user's avatar,
/// pinch-to-zoom, tap X to close.
class _PhotoViewer extends StatelessWidget {
  final String image;
  final String name;
  const _PhotoViewer({required this.image, required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: image.isEmpty
                ? Container(
                    width: 200.w,
                    height: 200.w,
                    decoration: BoxDecoration(color: _kRed, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: Text(initial,
                        style: AppFonts.spaceGrotesk.copyWith(
                            color: Colors.white,
                            fontSize: 90.sp,
                            fontWeight: FontWeight.w800)),
                  )
                : InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Image.network(
                      image,
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white54)),
                      errorBuilder: (_, __, ___) => Icon(Icons.person,
                          color: Colors.white38, size: 120.sp),
                    ),
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: Get.back,
                    child: Container(
                      width: 42.w,
                      height: 42.w,
                      decoration: const BoxDecoration(
                          color: Colors.white24, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppFonts.spaceGrotesk.copyWith(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
        Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppFonts.spaceGrotesk.copyWith(fontSize: 8.sp, color: const Color(0xff9E9090), height: 1.3), textAlign: TextAlign.center),
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
