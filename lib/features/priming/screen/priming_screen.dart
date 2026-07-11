import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:spanx/core/const/app_fonts.dart';
import 'package:spanx/core/global_widgets/app_snackbar.dart';
import 'package:spanx/features/priming/controller/priming_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

const _kRed   = Color(0xffE84040);
const _kRedDk = Color(0xff9B1414);
const _kBg    = Color(0xffF6F4F2);
const _kCard  = Color(0xffFFFFFF);
const _kText  = Color(0xff1A1010);
const _kMuted = Color(0xff9E9090);

class PrimingScreen extends StatelessWidget {
  PrimingScreen({super.key});

  final PrimingController c = Get.put(PrimingController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kRed, _kRedDk],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
                child: Row(
                  children: [
                    GestureDetector(
                      // Tear the native player down BEFORE popping — popping
                      // with a live platform view leaves a gray ghost texture
                      // over the next screen on iOS.
                      onTap: () => c.closeScreen(),
                      child: Container(
                        width: 38.r, height: 38.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Morning Ritual', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white70, fontSize: 12.sp)),
                        Text('Priming', style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const Spacer(),
                    // 🔥 streak chip — the fun part. Shows current run of
                    // consecutive priming days; invites a day-1 start when 0.
                    Obx(() => Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        c.streak.value > 0
                            ? '🔥 ${c.streak.value}-day streak'
                            : '🔥 Start your streak',
                        style: AppFonts.spaceGrotesk.copyWith(
                          color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.w700,
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(18.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video card
                  Container(
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.r),
                      // Swapped for a static placeholder during screen exit so
                      // the native WKWebView is disposed before the route pops
                      // (prevents the iOS gray ghost-texture artifact).
                      child: Obx(() => c.isPlayerVisible.value
                          ? YoutubePlayer(
                              controller: c.ytController,
                              aspectRatio: 16 / 9,
                            )
                          : AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Container(
                                color: const Color(0xff1A1010),
                                child: Icon(Icons.play_circle_outline, color: Colors.white24, size: 42.r),
                              ),
                            )),
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // Guaranteed fallback: open the video directly in the YouTube
                  // app / browser. In-app WebView embeds can be unreliable on
                  // some iOS devices, so this always-works path ensures users
                  // can watch the priming video no matter what.
                  GestureDetector(
                    onTap: _openInYouTube,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: BoxDecoration(
                        color: _kRed.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: _kRed.withOpacity(0.25)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_circle_fill, color: _kRed, size: 20.r),
                          SizedBox(width: 8.w),
                          Text(
                            'Watch on YouTube',
                            style: AppFonts.spaceGrotesk.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: _kRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Info card
                  Container(
                    decoration: BoxDecoration(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    padding: EdgeInsets.all(18.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40.r, height: 40.r,
                              decoration: BoxDecoration(color: _kRed.withOpacity(0.1), borderRadius: BorderRadius.circular(12.r)),
                              child: const Icon(Icons.self_improvement, color: _kRed, size: 22),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Morning Priming', style: AppFonts.spaceGrotesk.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w800, color: _kText)),
                                  Text('Tony Robbins · ~10 min', style: AppFonts.spaceGrotesk.copyWith(fontSize: 11.sp, color: _kMuted)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 14.h),
                        Text(
                          'Start every morning with this powerful priming exercise to put yourself in the right state of mind. Breathe, visualize, and feel the energy you want to carry throughout your day.',
                          style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, color: _kMuted, height: 1.6),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Steps
                  _buildSteps(),
                  SizedBox(height: 24.h),

                  // Complete button
                  Obx(() => GestureDetector(
                    // closeScreen marks complete (streak++, celebration) and
                    // tears down the native player before popping.
                    onTap: () => c.closeScreen(complete: true),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: c.isCompleted.value
                              ? [const Color(0xff22C55E), const Color(0xff16A34A)]
                              : [_kRed, _kRedDk],
                        ),
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: (c.isCompleted.value ? const Color(0xff22C55E) : _kRed).withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            c.isCompleted.value ? Icons.check_circle : Icons.check_circle_outline,
                            color: Colors.white, size: 20.r,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            c.isCompleted.value ? 'Completed! ✓' : 'Mark as Complete',
                            style: AppFonts.spaceGrotesk.copyWith(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  )),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openInYouTube() async {
  final uri = Uri.parse('https://www.youtube.com/watch?v=$kPrimingVideoId');
  try {
    // externalApplication opens the YouTube app if installed, else Safari.
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    // Last-resort fallback: let the OS pick any handler.
    if (await launchUrl(uri)) return;
    AppSnackBar.error('Could not open the video. Please try again.');
  } catch (_) {
    AppSnackBar.error('Could not open the video. Please try again.');
  }
}

Widget _buildSteps() {
  final steps = [
    ('Breathe deeply',       'Take 3 slow, deep breaths and feel your body relax.', Icons.air),
    ('Feel gratitude',       'Think of 3 things you\'re grateful for. Feel them fully.', Icons.favorite_border),
    ('Visualize your goals', 'See your goals as already achieved. Feel the joy.', Icons.visibility_outlined),
    ('Send love & energy',   'Send positive energy to yourself and those you love.', Icons.wb_sunny_outlined),
  ];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('How to Prime', style: AppFonts.spaceGrotesk.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w800, color: _kText)),
      SizedBox(height: 12.h),
      ...steps.asMap().entries.map((e) {
        final i = e.key;
        final step = e.value;
        return Container(
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            children: [
              Container(
                width: 36.r, height: 36.r,
                decoration: BoxDecoration(shape: BoxShape.circle, color: _kRed.withOpacity(0.1)),
                child: Center(
                  child: Text('${i + 1}', style: AppFonts.spaceGrotesk.copyWith(fontSize: 14.sp, fontWeight: FontWeight.w800, color: _kRed)),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.$1, style: AppFonts.spaceGrotesk.copyWith(fontSize: 13.sp, fontWeight: FontWeight.w700, color: _kText)),
                    Text(step.$2, style: AppFonts.spaceGrotesk.copyWith(fontSize: 11.sp, color: _kMuted, height: 1.4)),
                  ],
                ),
              ),
              Icon(step.$3, color: _kRed.withOpacity(0.5), size: 18.r),
            ],
          ),
        );
      }),
    ],
  );
}
